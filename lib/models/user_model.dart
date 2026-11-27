import 'package:cloud_firestore/cloud_firestore.dart';
import 'care_points.dart';

enum TrustTier {
  suspended('Suspended', 0),
  verifiedVolunteer('Verified Volunteer', 0),
  activeCaregiver('Active Caregiver', CarePoints.activeTierThreshold),
  trustedCaregiver('Trusted Caregiver', CarePoints.trustedTierThreshold);

  final String label;
  final int minPoints;
  const TrustTier(this.label, this.minPoints);
}

class AppUser {
  final String uid;
  final String email;
  final String role;
  final bool isSuspended;
  final int completedQuestsCount;
  final int careIndex;

  AppUser({
    required this.uid,
    required this.email,
    this.role = 'volunteer',
    this.isSuspended = false,
    this.completedQuestsCount = 0,
    this.careIndex = 0,
  });

  bool get isStaff => role == 'coordinator' || role == 'admin';

  TrustTier get trustTier {
    if (isSuspended) return TrustTier.suspended;
    if (isStaff || careIndex >= CarePoints.trustedTierThreshold) {
      return TrustTier.trustedCaregiver;
    }
    if (careIndex >= CarePoints.activeTierThreshold) {
      return TrustTier.activeCaregiver;
    }
    return TrustTier.verifiedVolunteer;
  }

  bool get canParticipate => !isSuspended;

  bool get canEditPetDetails =>
      !isSuspended && trustTier.index >= TrustTier.activeCaregiver.index;

  bool get canRegisterPets =>
      !isSuspended && trustTier == TrustTier.trustedCaregiver;

  bool get canApplyForAdoption =>
      !isSuspended && trustTier == TrustTier.trustedCaregiver;

  int get maxConcurrentTasks =>
      trustTier.index >= TrustTier.activeCaregiver.index ? 2 : 1;

  int get pointsToNextTier {
    if (isSuspended || isStaff) return 0;
    if (careIndex < CarePoints.activeTierThreshold) {
      return CarePoints.activeTierThreshold - careIndex;
    }
    if (careIndex < CarePoints.trustedTierThreshold) {
      return CarePoints.trustedTierThreshold - careIndex;
    }
    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'isSuspended': isSuspended,
      'completedQuestsCount': completedQuestsCount,
      'careIndex': careIndex,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'volunteer',
      isSuspended: map['isSuspended'] == true,
      completedQuestsCount:
          (map['completedQuestsCount'] as num?)?.toInt() ?? 0,
      careIndex: (map['careIndex'] as num?)?.toInt() ?? 0,
    );
  }
}