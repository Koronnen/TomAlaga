import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/quest_model.dart';
import '../models/shift_model.dart';

class ShiftController extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  bool _isLoading = false;
  String? _errorMessage;

  ShiftController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

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

  /// Streams upcoming shifts: includes Home-Zone feeding shifts AND all Cross-Zone healthcare shifts.
  Stream<List<ShiftModel>> watchVisibleShifts({String? homeZoneId}) {
    final cutoff = DateTime.now().subtract(const Duration(hours: 2));
    return _firestore
        .collection('shifts')
        .where('endTime', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('endTime', descending: false)
        .snapshots()
        .map((snap) {
          return snap.docs.map(ShiftModel.fromFirestore).where((shift) {
            if (!shift.zoneRestricted) {
              return true; // Open across all campus zones
            }
            if (homeZoneId == null || homeZoneId.isEmpty) return true;
            return shift.zoneId == homeZoneId;
          }).toList();
        });
  }

  /// Batch-generates daily shift documents for the Cinema Seat Calendar (max 60 days).
  Future<bool> batchCreateShifts({
    required String seriesTitle,
    required String category, // 'feeding' | 'healthcare'
    required bool zoneRestricted,
    required String zoneId,
    required String zoneName,
    String? petId,
    String? petName,
    List<String> bowlLocations = const [],
    required DateTime startDate,
    required DateTime endDate,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    int capacity = 2,
  }) async {
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    if (normalizedEnd.isBefore(normalizedStart)) {
      _errorMessage = 'End date cannot be earlier than start date.';
      notifyListeners();
      return false;
    }

    final totalDays = normalizedEnd.difference(normalizedStart).inDays + 1;
    if (totalDays > 60) {
      _errorMessage = 'Batch schedule generation is capped at 60 days.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final batch = _firestore.batch();
      final seriesId = 'series_${DateTime.now().millisecondsSinceEpoch}';

      for (int i = 0; i < totalDays; i++) {
        final day = normalizedStart.add(Duration(days: i));
        final startTime = DateTime(
          day.year,
          day.month,
          day.day,
          startHour,
          startMinute,
        );
        final endTime = DateTime(
          day.year,
          day.month,
          day.day,
          endHour,
          endMinute,
        );

        final docRef = _firestore.collection('shifts').doc();
        final shift = ShiftModel(
          shiftId: docRef.id,
          seriesId: seriesId,
          seriesTitle: seriesTitle.trim(),
          category: category,
          zoneRestricted: zoneRestricted,
          title: seriesTitle.trim(),
          zoneId: zoneId,
          zoneName: zoneName,
          petId: petId,
          petName: petName,
          bowlLocations: bowlLocations,
          startTime: startTime,
          endTime: endTime,
          capacity: capacity,
          volunteers: const [],
        );

        batch.set(docRef, shift.toMap());
      }

      await batch.commit();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to generate shift schedule: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Atomically reserves one or more selected dates from the Cinema Seat Calendar.
  Future<bool> batchReserveShifts({
    required List<String> shiftIds,
    required String uid,
    required String email,
    required String status,
    bool isSuspended = false,
  }) async {
    if (shiftIds.isEmpty) return false;
    if (status != 'approved' || isSuspended) {
      _errorMessage = 'Your account must be approved to reserve shifts.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await _firestore.runTransaction((tx) async {
        final refs = shiftIds
            .map((id) => _firestore.collection('shifts').doc(id))
            .toList();
        final snaps = <DocumentSnapshot<Map<String, dynamic>>>[];
        for (final ref in refs) {
          snaps.add(await tx.get(ref));
        }

        for (final snap in snaps) {
          if (!snap.exists) {
            throw StateError(
              'One of the selected dates is no longer available.',
            );
          }
          final shift = ShiftModel.fromFirestore(snap);
          if (shift.hasUser(uid)) {
            throw StateError('You already booked ${shift.dateKey}.');
          }
          if (shift.isFull) {
            throw StateError('All seats are now full on ${shift.dateKey}.');
          }

          final updatedVolunteers = [
            ...shift.volunteers,
            ShiftVolunteer(
              uid: uid,
              email: email,
              status: 'reserved',
              reservedAt: DateTime.now(),
            ),
          ];

          tx.update(snap.reference, {
            'volunteers': updatedVolunteers.map((v) => v.toMap()).toList(),
          });
        }
      });

      return true;
    } catch (e) {
      _errorMessage = e is StateError
          ? e.message
          : 'Unable to reserve selected shifts: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancels a reservation: free >= 2 hours prior, -5 pts (0 floor) if < 2 hours prior.
  Future<bool> cancelShiftReservation({
    required String shiftId,
    required String uid,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final shiftRef = _firestore.collection('shifts').doc(shiftId);
      final userRef = _firestore.collection('users').doc(uid);

      await _firestore.runTransaction((tx) async {
        final shiftSnap = await tx.get(shiftRef);
        if (!shiftSnap.exists) throw StateError('Shift not found.');
        final shift = ShiftModel.fromFirestore(shiftSnap);

        final volunteer = shift.volunteerFor(uid);
        if (volunteer == null || volunteer.status != 'reserved') {
          throw StateError('No cancellable reservation found.');
        }

        final isLateCancel =
            shift.startTime.difference(DateTime.now()).inMinutes < 120;

        DocumentSnapshot<Map<String, dynamic>>? userSnap;
        if (isLateCancel) {
          userSnap = await tx.get(userRef);
        }

        final remainingVolunteers = shift.volunteers
            .where((v) => v.uid != uid)
            .toList();
        tx.update(shiftRef, {
          'volunteers': remainingVolunteers.map((v) => v.toMap()).toList(),
        });

        if (isLateCancel && userSnap != null && userSnap.exists) {
          final currentPts =
              (userSnap.data()?['careIndex'] as num?)?.toInt() ?? 0;
          tx.update(userRef, {'careIndex': (currentPts - 5).clamp(0, 999999)});
        }
      });

      return true;
    } catch (e) {
      _errorMessage = e is StateError
          ? e.message
          : 'Unable to cancel reservation: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Shift-to-Quest Bridge: checks in the volunteer and spawns a linked Quest (+25 pts).
  Future<String?> checkInAndSpawnQuest({
    required String shiftId,
    required String uid,
    required String email,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final shiftRef = _firestore.collection('shifts').doc(shiftId);
      final newQuestRef = _firestore.collection('quests').doc();

      await _firestore.runTransaction((tx) async {
        final shiftSnap = await tx.get(shiftRef);
        if (!shiftSnap.exists) throw StateError('Shift not found.');
        final shift = ShiftModel.fromFirestore(shiftSnap);

        final existing = shift.volunteerFor(uid);
        if (existing == null || existing.status != 'reserved') {
          throw StateError('You must have an active reservation to check in.');
        }

        final updatedVolunteers = shift.volunteers.map((v) {
          if (v.uid != uid) return v;
          return ShiftVolunteer(
            uid: v.uid,
            email: v.email,
            status: 'checked_in',
            linkedQuestId: newQuestRef.id,
            reservedAt: v.reservedAt,
            checkedInAt: DateTime.now(),
          );
        }).toList();

        final spawnedQuest = QuestModel(
          questId: newQuestRef.id,
          category: shift.category,
          type: shift.isHealthcare ? 'shift_caregiving' : 'shift_feeding',
          title: shift.title,
          description: shift.isHealthcare
              ? 'Scheduled healthcare run for ${shift.petName ?? 'campus pet'}.'
              : 'Scheduled zone run (${shift.bowlLocations.join(', ')}).',
          zoneId: shift.zoneId,
          zoneName: shift.zoneName,
          bowlLocations: shift.bowlLocations,
          petId: shift.petId,
          petName: shift.petName,
          shiftId: shift.shiftId,
          status: 'claimed',
          claimedByUid: uid,
          claimedByEmail: email,
          scheduledStart: shift.startTime,
          deadlineAt: shift.endTime,
          createdAt: DateTime.now(),
        );

        tx.update(shiftRef, {
          'volunteers': updatedVolunteers.map((v) => v.toMap()).toList(),
        });
        tx.set(newQuestRef, spawnedQuest.toMap());
      });

      return newQuestRef.id;
    } catch (e) {
      _errorMessage = e is StateError ? e.message : 'Check-in failed: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }
}
