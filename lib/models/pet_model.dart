import 'package:cloud_firestore/cloud_firestore.dart';

class PetModel {
  final String? id;
  final String name;
  final String description;
  final String location;
  final double? mapX;
  final double? mapY;
  final String? zoneId;
  final String? landmarkId;
  final String neutered;
  final String vaccination;
  final String condition;
  final String imageUrl;
  final String registeredBy;
  final String verificationStatus;
  final DateTime? createdAt; // null while the server timestamp is pending
  final DateTime? lastUpdated;

  const PetModel({
    this.id,
    required this.name,
    this.description = '',
    required this.location,
    this.mapX,
    this.mapY,
    this.zoneId,
    this.landmarkId = '',
    this.neutered = 'Unknown',
    this.vaccination = 'Unknown',
    this.condition = '',
    this.imageUrl = '',
    this.registeredBy = '',
    this.verificationStatus = 'pending',
    this.createdAt,
    this.lastUpdated,
  });

  bool get hasPin => mapX != null && mapY != null;
  bool get isVisibleOnPublicMap => verificationStatus == 'verified' && hasPin;

  factory PetModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final created = map['createdAt'];
    final updated = map['lastUpdated'];
    return PetModel(
      id: id,
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      location: (map['location'] ?? '').toString(),
      mapX: (map['mapX'] as num?)?.toDouble(),
      mapY: (map['mapY'] as num?)?.toDouble(),
      zoneId: map['zoneId']?.toString(),
      landmarkId: (map['landmarkId'] ?? '').toString(),
      neutered: (map['neutered'] ?? 'Unknown').toString(),
      vaccination: (map['vaccination'] ?? 'Unknown').toString(),
      condition: (map['condition'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      verificationStatus: (map['verificationStatus'] ?? 'pending').toString(),
      registeredBy: (map['registeredBy'] ?? '').toString(),
      createdAt: created is Timestamp ? created.toDate() : null,
      lastUpdated: updated is Timestamp ? updated.toDate() : null,
    );  
  }

  factory PetModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return PetModel.fromMap(doc.data() ?? {}, id: doc.id);
  }

  /// Uses a server timestamp for `createdAt`; `id` is never written
  /// (it is the Firestore document id).
  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'description': description.trim(),
      'location': location.trim(),
      'mapX': mapX,
      'mapY': mapY,
      'zoneId': zoneId,
      'landmarkId': landmarkId,
      'neutered': neutered,
      'vaccination': vaccination,
      'condition': condition.trim(),
      'imageUrl': imageUrl,
      'verificationStatus': verificationStatus,
      'registeredBy': registeredBy,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  PetModel copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    double? mapX,
    double? mapY,
    String? zoneId,
    String? landmarkId,
    String? neutered,
    String? vaccination,
    String? condition,
    String? imageUrl,
    String? verificationStatus,
    String? registeredBy,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return PetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      mapX: mapX ?? this.mapX,
      mapY: mapY ?? this.mapY,
      zoneId: zoneId ?? this.zoneId,
      landmarkId: landmarkId ?? this.landmarkId,
      neutered: neutered ?? this.neutered,
      vaccination: vaccination ?? this.vaccination,
      condition: condition ?? this.condition,
      imageUrl: imageUrl ?? this.imageUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      registeredBy: registeredBy ?? this.registeredBy,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}