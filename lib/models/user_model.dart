import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  // Care Index thresholds. Change these in one place to retune privileges.
  static const int volunteerThreshold = 20;
  static const int caretakerThreshold = 50; // unlocks editing pet info
  static const int guardianThreshold = 100; // unlocks adding new pets

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
      completedQuestsCount: (map['completedQuestsCount'] as num?)?.toInt() ?? 0,
      careIndex: (map['careIndex'] as num?)?.toInt() ?? 0,
    );
  }

  // ---- Care Index privileges ----

  /// Volunteers with enough Care Index can edit campus pet info.
  bool get canEditPetInfo => careIndex >= caretakerThreshold;

  /// Highly active volunteers can add new pets to the catalog.
  bool get canAddPets => careIndex >= guardianThreshold;

  String get careTier {
    if (careIndex >= guardianThreshold) return 'Guardian';
    if (careIndex >= caretakerThreshold) return 'Caretaker';
    if (careIndex >= volunteerThreshold) return 'Volunteer';
    return 'Newcomer';
  }

  /// Name of the next tier, or null when already at the top.
  String? get nextTier {
    if (careIndex >= guardianThreshold) return null;
    if (careIndex >= caretakerThreshold) return 'Guardian';
    if (careIndex >= volunteerThreshold) return 'Caretaker';
    return 'Volunteer';
  }

  /// Points still needed to reach [nextTier]; 0 when already at the top.
  int get pointsToNextTier {
    if (careIndex >= guardianThreshold) return 0;
    if (careIndex >= caretakerThreshold) return guardianThreshold - careIndex;
    if (careIndex >= volunteerThreshold) return caretakerThreshold - careIndex;
    return volunteerThreshold - careIndex;
  }

  List<String> get unlockedPrivileges {
    final list = <String>['View campus pets'];
    if (canEditPetInfo) list.add('Edit campus pet info');
    if (canAddPets) list.add('Add new pets to the catalog');
    return list;
  }
}