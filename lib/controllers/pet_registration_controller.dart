import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pet_model.dart';

class PetRegistrationController extends ChangeNotifier {
  static const String bucketName = 'TomAlaga-public';
  static const String tableName = 'pets';

  // Words ignored when comparing descriptions.
  static const Set<String> _stopWords = {
    'the', 'and', 'with', 'that', 'this', 'from', 'have', 'has', 'was',
    'are', 'cat', 'kitty', 'usually', 'often', 'very', 'also', 'near',
    'ang', 'ng', 'na', 'sa', 'at', 'mga', 'yung', 'pusa', 'may', 'ay',
  };

  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;
  String? errorMessage;
  List<PetModel> petsList = [];
  List<PetModel> potentialDuplicates = [];

  Uint8List? selectedImageBytes;
  String? selectedImageName;

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
  /// campus location is similar AND whose description shares at least
  /// two keywords with the new description.
  Future<List<PetModel>> checkDuplicates({
    required String name,
    required String campusLocation,
    required String description,
  }) async {
    _setLoading(true);
    errorMessage = null;
    potentialDuplicates = [];
    try {
      final data = await _supabase
          .from(tableName)
          .select()
          .neq('verification_status', 'rejected');

      final candidates = (data as List)
          .map((row) => PetModel.fromMap(Map<String, dynamic>.from(row)))
          .toList();

      final newKeywords = _keywords(description);

      potentialDuplicates = candidates.where((pet) {
        final nameMatch = _similar(pet.name, name);
        final sameLocation = _similar(pet.campusLocation, campusLocation);
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

  /// Uploads the photo (if any), then inserts the cat with status 'pending'.
  /// Returns true on success.
  Future<bool> registerPet({
    required String name,
    required String description,
    required String campusLocation,
    required String neutered,
    required String vaccinationStatus,
    required String condition,
  }) async {
    _setLoading(true);
    errorMessage = null;
    try {
      String photoUrl = '';

      if (selectedImageBytes != null) {
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
        photoUrl = _supabase.storage.from(bucketName).getPublicUrl(path);
      }

      final vaccines = vaccinationStatus.trim();

      final pet = PetModel(
        name: name.trim(),
        description: description.trim(),
        campusLocation: campusLocation.trim(),
        neutered: neutered,
        vaccinationStatus: vaccines.isEmpty ? 'Unknown' : vaccines,
        condition: condition.trim(),
        photoUrl: photoUrl,
        verificationStatus: 'pending',
      );

      await _supabase.from(tableName).insert(pet.toMap());

      selectedImageBytes = null;
      selectedImageName = null;
      _setLoading(false);
      return true;
    } catch (e) {
      errorMessage = 'Failed to register cat: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchPets() async {
    _setLoading(true);
    errorMessage = null;
    try {
      final data = await _supabase
          .from(tableName)
          .select()
          .order('created_at', ascending: false);
      petsList = (data as List)
          .map((row) => PetModel.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    } catch (e) {
      errorMessage = 'Failed to load cats: $e';
    }
    _setLoading(false);
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
      await _supabase
          .from(tableName)
          .update({'verification_status': status}).eq('id', id);

      final index = petsList.indexWhere((p) => p.id == id);
      if (index != -1) {
        petsList[index] = petsList[index].copyWith(verificationStatus: status);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      errorMessage = 'Failed to update status: $e';
      _setLoading(false);
      return false;
    }
  }
}