import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/map_pin_model.dart';
import '../models/pet_model.dart';
import '../models/quest_model.dart';

class QuestController extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final SupabaseClient _supabase;

  bool _isLoading = false;
  String? _errorMessage;

  QuestController({FirebaseFirestore? firestore, SupabaseClient? supabase})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _supabase = supabase ?? Supabase.instance.client;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  int maxConcurrentTasksFor(int careIndex, String role) {
    if (role == 'coordinator' || role == 'admin' || careIndex >= 100) return 3;
    if (careIndex >= 30) return 2;
    return 1;
  }

  Stream<List<PetModel>> streamAvailablePets() {
    return _firestore.collection('pets').snapshots().map((snapshot) {
      final pets = snapshot.docs
          .map(PetModel.fromFirestore)
          .where((pet) => pet.verificationStatus != 'rejected')
          .toList();
      pets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return pets;
    });
  }

  Stream<List<MapPinModel>> streamBowlStations() {
    return _firestore
        .collection('map_pins')
        .where('type', isEqualTo: PinType.bowl.name)
        .snapshots()
        .map((snapshot) {
          final bowls = snapshot.docs.map((doc) {
            final data = doc.data();
            final updated = data['updatedAt'];
            return MapPinModel.fromBowlMap(
              data,
              id: doc.id,
              updatedAt: updated is Timestamp ? updated.toDate() : null,
            );
          }).toList();
          bowls.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          );
          return bowls;
        });
  }

  Stream<List<QuestModel>> watchQuests({String? categoryFilter}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('quests')
        .orderBy('deadlineAt', descending: false);

    if (categoryFilter != null && categoryFilter != 'all') {
      query = query.where('category', isEqualTo: categoryFilter);
    }

    return query.snapshots().map(
      (snap) => snap.docs.map(QuestModel.fromFirestore).toList(),
    );
  }

  Future<bool> createQuest({
    required String category,
    required String type,
    required String title,
    String? description,
    required String zoneId,
    required String zoneName,
    List<String> bowlLocations = const [],
    String? petId,
    String? petName,
    Duration validFor = const Duration(hours: 3),
  }) async {
    if (validFor < const Duration(minutes: 1) ||
        validFor > const Duration(hours: 24)) {
      _errorMessage =
          'Quest open window must be between 1 minute and 24 hours.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final docRef = _firestore.collection('quests').doc();
      final quest = QuestModel(
        questId: docRef.id,
        category: category,
        type: type,
        title: title.trim(),
        description: description?.trim(),
        zoneId: zoneId,
        zoneName: zoneName,
        bowlLocations: bowlLocations,
        petId: petId,
        petName: petName,
        status: 'open',
        deadlineAt: DateTime.now().add(validFor),
        createdAt: DateTime.now(),
      );

      await docRef.set(quest.toMap());
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create quest: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> claimQuest({
    required String questId,
    required String uid,
    required String email,
    required String status,
    required String role,
    required int careIndex,
    bool isSuspended = false,
  }) async {
    if (status != 'approved' || isSuspended) {
      _errorMessage =
          'Your account must be approved and active to claim quests.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final activeSnap = await _firestore
          .collection('quests')
          .where('claimedByUid', isEqualTo: uid)
          .where('status', isEqualTo: 'claimed')
          .get();

      final maxTasks = maxConcurrentTasksFor(careIndex, role);
      if (activeSnap.docs.length >= maxTasks) {
        _errorMessage =
            'Task limit reached ($maxTasks active task${maxTasks == 1 ? '' : 's'} for your current Care Index tier).';
        return false;
      }

      final questRef = _firestore.collection('quests').doc(questId);

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(questRef);
        if (!snap.exists) {
          throw StateError('Quest no longer exists.');
        }
        final data = snap.data()!;
        if (data['status'] != 'open') {
          throw StateError('Another volunteer just claimed this quest.');
        }

        tx.update(questRef, {
          'status': 'claimed',
          'claimedByUid': uid,
          'claimedByEmail': email,
          'deadlineAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(minutes: 45)),
          ),
        });
      });

      return true;
    } catch (e) {
      _errorMessage = e is StateError ? e.message : 'Unable to claim quest: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> completeQuest({
    required QuestModel quest,
    required String uid,
    required Uint8List compressedImageBytes,
    String? proofNote,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final storagePath =
        'quests/${quest.questId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      // 1. Upload compressed proof bytes to Supabase Storage (tomalaga-public)
      await _supabase.storage
          .from('tomalaga-public')
          .uploadBinary(
            storagePath,
            compressedImageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from('tomalaga-public')
          .getPublicUrl(storagePath);

      final questRef = _firestore.collection('quests').doc(quest.questId);
      final userRef = _firestore.collection('users').doc(uid);

      // 2. Atomically complete quest, award Care Index, and sync shift/pet docs
      await _firestore.runTransaction((tx) async {
        final questSnap = await tx.get(questRef);
        if (!questSnap.exists) throw StateError('Quest not found.');
        final qData = questSnap.data()!;
        if (qData['status'] != 'claimed' || qData['claimedByUid'] != uid) {
          throw StateError(
            'Only the assigned volunteer can complete this quest.',
          );
        }

        final userSnap = await tx.get(userRef);
        final uData = userSnap.data() ?? {};
        final currentCareIndex = (uData['careIndex'] as num?)?.toInt() ?? 0;
        final currentCompleted =
            (uData['completedQuestsCount'] as num?)?.toInt() ?? 0;

        DocumentSnapshot<Map<String, dynamic>>? shiftSnap;
        if (quest.isShiftLinked) {
          shiftSnap = await tx.get(
            _firestore.collection('shifts').doc(quest.shiftId!),
          );
        }

        tx.update(questRef, {
          'status': 'completed',
          'proofPhotoUrl': publicUrl,
          'proofNote': proofNote?.trim(),
          'completedAt': FieldValue.serverTimestamp(),
        });

        tx.update(userRef, {
          'careIndex': currentCareIndex + quest.rewardPoints,
          'completedQuestsCount': currentCompleted + 1,
        });

        // Mark volunteer slot completed on parent shift if shift-linked
        if (shiftSnap != null && shiftSnap.exists) {
          final sData = shiftSnap.data()!;
          final rawList = List<Map<String, dynamic>>.from(
            (sData['volunteers'] as List<dynamic>? ?? []).map(
              (e) => Map<String, dynamic>.from(e),
            ),
          );
          for (final entry in rawList) {
            if (entry['uid'] == uid) {
              entry['status'] = 'completed';
            }
          }
          tx.update(shiftSnap.reference, {'volunteers': rawList});
        }

        // Refresh pet freshness timestamp if linked to a specific campus pet
        if (quest.petId != null && quest.petId!.isNotEmpty) {
          final petRef = _firestore.collection('pets').doc(quest.petId!);
          tx.update(petRef, {
            'lastUpdated': FieldValue.serverTimestamp(),
            'isOutdated': false,
          });
        }
      });

      return true;
    } catch (e) {
      // Roll back uploaded proof file if Firestore transaction failed
      try {
        await _supabase.storage.from('tomalaga-public').remove([storagePath]);
      } catch (_) {}

      _errorMessage = e is StateError
          ? e.message
          : 'Failed to submit proof: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
