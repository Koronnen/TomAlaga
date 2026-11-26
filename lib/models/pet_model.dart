class PetModel {
  final String? id;
  final String name;
  final String description;
  final String campusLocation;
  final String neutered;
  final String vaccinationStatus;
  final String condition;
  final String photoUrl;
  final String verificationStatus;
  final DateTime? createdAt;

  const PetModel({
    this.id,
    required this.name,
    this.description = '',
    required this.campusLocation,
    this.neutered = 'Unknown',
    this.vaccinationStatus = 'Unknown',
    this.condition = '',
    this.photoUrl = '',
    this.verificationStatus = 'pending',
    this.createdAt,
  });

  factory PetModel.fromMap(Map<String, dynamic> map) {
    return PetModel(
      id: map['id']?.toString(),
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      campusLocation: (map['campus_location'] ?? '').toString(),
      neutered: (map['neutered'] ?? 'Unknown').toString(),
      vaccinationStatus: (map['vaccination_status'] ?? 'Unknown').toString(),
      condition: (map['condition'] ?? '').toString(),
      photoUrl: (map['photo_url'] ?? '').toString(),
      verificationStatus: (map['verification_status'] ?? 'pending').toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  /// Omits `id` and `created_at` when null so the database defaults apply.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'campus_location': campusLocation,
      'neutered': neutered,
      'vaccination_status': vaccinationStatus,
      'condition': condition,
      'photo_url': photoUrl,
      'verification_status': verificationStatus,
    };
    if (id != null) map['id'] = id;
    if (createdAt != null) map['created_at'] = createdAt!.toIso8601String();
    return map;
  }

  PetModel copyWith({String? photoUrl, String? verificationStatus}) {
    return PetModel(
      id: id,
      name: name,
      description: description,
      campusLocation: campusLocation,
      neutered: neutered,
      vaccinationStatus: vaccinationStatus,
      condition: condition,
      photoUrl: photoUrl ?? this.photoUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt,
    );
  }
}