import 'package:cloud_firestore/cloud_firestore.dart';

class PetModel {
  final String? id;
  final String name;
  final String description;
  final String location;
  final String neutered;
  final String vaccination;
  final String condition;
  final String imageUrl;
  final String verificationStatus;
  final DateTime? createdAt; // null while the server timestamp is pending

  const PetModel({
    this.id,
    required this.name,
    this.description = '',
    required this.location,
    this.neutered = 'Unknown',
    this.vaccination = 'Unknown',
    this.condition = '',
    this.imageUrl = '',
    this.verificationStatus = 'pending',
    this.createdAt,
  });

  factory PetModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final created = map['createdAt'];
    return PetModel(
      id: id,
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      location: (map['location'] ?? '').toString(),
      neutered: (map['neutered'] ?? 'Unknown').toString(),
      vaccination: (map['vaccination'] ?? 'Unknown').toString(),
      condition: (map['condition'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      verificationStatus: (map['verificationStatus'] ?? 'pending').toString(),
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  factory PetModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return PetModel.fromMap(doc.data() ?? {}, id: doc.id);
  }

  /// Uses a server timestamp for `createdAt`; `id` is never written
  /// (it is the Firestore document id).
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'neutered': neutered,
      'vaccination': vaccination,
      'condition': condition,
      'imageUrl': imageUrl,
      'verificationStatus': verificationStatus,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}