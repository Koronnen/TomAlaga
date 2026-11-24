import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String status;
  final String role;
  final int completedQuestsCount;
  final int careIndex;

  AppUser({
    required this.uid,
    required this.email,
    this.status = 'PENDING',
    this.role = 'volunteer',
    this.completedQuestsCount = 0,
    this.careIndex = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'status': status,
      'role': role,
      'completedQuestsCount': completedQuestsCount,
      'careIndex': careIndex,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      status: map['status'] ?? 'pending',
      role: map['role'] ?? 'volunteer',
      completedQuestsCount: map['completedQuestsCount'] ?? 0,
      careIndex: map['careIndex'] ?? 0,
    );
  }
}