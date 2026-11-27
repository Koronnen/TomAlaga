import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pet_model.dart';

/// Pet records live in Cloud Firestore (`pets` collection).
/// Supabase Storage is used only to host the cat photo.
class PetRegistrationController extends ChangeNotifier {
  static const String bucketName = 'TomAlaga-public';
  static const String collectionName = 'pets';

  // Words ignored when comparing descriptions.
  static const Set<String> _stopWords = {
    'the', 'and', 'with', 'that', 'this', 'from', 'have', 'has', 'was',
    'are', 'cat', 'kitty', 'usually', 'often', 'very', 'also', 'near',
    'ang', 'ng', 'na', 'sa', 'at', 'mga', 'yung', 'pusa', 'may', 'ay',
  };

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;
  String? errorMessage;
  List<PetModel> potentialDuplicates = [];

  Uint8List? selectedImageBytes;
  String? selectedImageName;

  CollectionReference<Map<String, dynamic>> get _pets =>
      _firestore.collection(collectionName);

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void clearSelectedImage() {
    selectedImageBytes = null;
    selectedImageName = null;
    notifyListeners();
  }

  /// Works on Web and Android/iOS because it only relies on XFile.readAsBytes().
  Future<void> pickImage() async {
    try {
      errorMessage = null;
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (file == null) return;
      selectedImageBytes = await file.readAsBytes();
      selectedImageName = file.name;
    } catch (e) {
      errorMessage = 'Failed to pick image: $e';
    }
    notifyListeners();
  }

  bool _similar(String a, String b) {
    final x = a.trim().toLowerCase();
    final y = b.trim().toLowerCase();
    if (x.isEmpty || y.isEmpty) return false;
    return x == y || x.contains(y) || y.contains(x);
  }

  Set<String> _keywords(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9ñ]+'))
        .where((w) => w.length >= 4 && !_stopWords.contains(w))
        .toSet();
  }

  /// Finds existing (non-rejected) cats whose name is similar, OR whose
  /// location is similar AND whose description shares at least two keywords
  /// with the new description.
  Future<List<PetModel>> checkDuplicates({
    required String name,
    required String location,
    required String description,
  }) async {
    _setLoading(true);
    errorMessage = null;
    potentialDuplicates = [];
    try {
      final snapshot = await _pets.get();
      final candidates = snapshot.docs
          .map(PetModel.fromFirestore)
          .where((pet) => pet.verificationStatus != 'rejected')
          .toList();

      final newKeywords = _keywords(description);

      potentialDuplicates = candidates.where((pet) {
        final nameMatch = _similar(pet.name, name);
        final sameLocation = _similar(pet.location, location);
        final overlap =
            _keywords(pet.description).intersection(newKeywords).length;
        return nameMatch || (sameLocation && overlap >= 2);
      }).toList();
    } catch (e) {
      errorMessage = 'Failed to check duplicates: $e';
      potentialDuplicates = [];
    }
    _setLoading(false);
    return potentialDuplicates;
  }

  String _extensionOf(String filename) {
    if (!filename.contains('.')) return 'jpg';
    final ext = filename.split('.').last.toLowerCase();
    return ext.isEmpty ? 'jpg' : ext;
  }

  String _contentTypeFor(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  /// 1) Uploads the photo (if any) to Supabase Storage.
  /// 2) Saves the cat to Firestore with verificationStatus 'pending'.
  /// If step 2 fails, the uploaded photo is removed from Supabase Storage.
  /// Returns true on success.
  Future<bool> registerPet({
    required String name,
    required String description,
    required String location,
    required String neutered,
    required String vaccination,
    required String condition,
    double? mapX,
    double? mapY,
    String? zoneId,
    String? landmarkId,
    String? registeredBy,
  }) async {
    _setLoading(true);
    errorMessage = null;

    String imageUrl = '';
    String? uploadedPath;

    // Step 1: photo -> Supabase Storage
    if (selectedImageBytes != null) {
      try {
        final ext = _extensionOf(selectedImageName ?? 'photo.jpg');
        final path = 'pets/${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _supabase.storage.from(bucketName).uploadBinary(
              path,
              selectedImageBytes!,
              fileOptions: FileOptions(
                contentType: _contentTypeFor(ext),
                upsert: false,
              ),
            );
        uploadedPath = path;
        imageUrl = _supabase.storage.from(bucketName).getPublicUrl(path);
      } catch (e) {
        errorMessage = 'Photo upload failed: $e';
        _setLoading(false);
        return false;
      }
    }

    // Step 2: record -> Cloud Firestore
    try {
      final vaccines = vaccination.trim();
      final cleanZoneId = zoneId?.trim();
      final pet = PetModel(
        name: name.trim(),
        description: description.trim(),
        location: location.trim(),
        mapX: mapX,
        mapY: mapY,
        zoneId: (cleanZoneId == null || cleanZoneId.isEmpty) ? null : cleanZoneId,
        landmarkId: landmarkId?.trim() ?? '',
        neutered: neutered,
        vaccination: vaccines.isEmpty ? 'Unknown' : vaccines,
        condition: condition.trim(),
        imageUrl: imageUrl,
        registeredBy: (registeredBy ?? _auth.currentUser?.uid ?? '').trim(),
        verificationStatus: 'pending',
      );

      await _pets.add(pet.toMap());

      selectedImageBytes = null;
      selectedImageName = null;
      _setLoading(false);
      return true;
    } catch (e) {
      var message = 'Failed to save cat: $e';

      // Roll back the uploaded photo so no orphaned file remains.
      if (uploadedPath != null) {
        var removed = false;
        try {
          final result =
              await _supabase.storage.from(bucketName).remove([uploadedPath]);
          // Supabase returns an empty list (no error) if nothing was deleted,
          // e.g. when the bucket has no DELETE policy.
          removed = result.isNotEmpty;
        } catch (_) {
          removed = false;
        }
        if (!removed) {
          message += '\nThe uploaded photo could not be removed '
              'automatically ($uploadedPath).';
        }
      }

      errorMessage = message;
      _setLoading(false);
      return false;
    }
  }

  /// Live directory, newest first.
  Stream<List<PetModel>> streamPets() {
    return _pets
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(PetModel.fromFirestore).toList());
  }

  /// Live verified pets that have map coordinates.
  Stream<List<PetModel>> streamPublicMapPets() {
    return _pets
        .where('verificationStatus', isEqualTo: 'verified')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(PetModel.fromFirestore)
              .where((pet) => pet.isVisibleOnPublicMap)
              .toList(),
        );
  }

  /// Updates the campus map pin fields for an existing pet.
  Future<bool> updatePetPin({
    required String id,
    required double mapX,
    required double mapY,
    String? zoneId,
    String? landmarkId,
  }) async {
    _setLoading(true);
    errorMessage = null;
    try {
      final cleanZoneId = zoneId?.trim();
      await _pets.doc(id).update({
        'mapX': mapX,
        'mapY': mapY,
        'zoneId':
            (cleanZoneId == null || cleanZoneId.isEmpty) ? null : cleanZoneId,
        'landmarkId': landmarkId?.trim() ?? '',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      _setLoading(false);
      return true;
    } catch (e) {
      errorMessage = 'Failed to update map pin: $e';
      _setLoading(false);
      return false;
    }
  }

  /// [status] must be 'verified' or 'rejected'.
  Future<bool> updateVerificationStatus(String id, String status) async {
    if (status != 'verified' && status != 'rejected') {
      errorMessage = 'Invalid status: $status';
      notifyListeners();
      return false;
    }
    _setLoading(true);
    errorMessage = null;
    try {
      await _pets.doc(id).update({
        'verificationStatus': status,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      _setLoading(false);
      return true;
    } catch (e) {
      errorMessage = 'Failed to update status: $e';
      _setLoading(false);
      return false;
    }
  }
}