import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/care_index_log_model.dart';
import '../models/user_model.dart';

class CareIndexController {
  /// Upper bound for a single award. Keep in sync with firestore.rules.
  static const int maxPointsPerAward = 50;

  final FirebaseFirestore _firestore;

  CareIndexController({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _logsRef(String uid) =>
      _userRef(uid).collection('care_index_logs');

  /// Awards points for [activity] and records an audit log in one atomic batch.
  /// Quests also increment `completedQuestsCount` by 1.
  /// Throws [ArgumentError] for invalid points or [FirebaseException] on failure.
  Future<void> awardPoints({
    required String uid,
    required CareActivityType activity,
    int? customPoints,
    String? description,
  }) async {
    final points = customPoints ?? activity.defaultPoints;
    if (uid.isEmpty) {
      throw ArgumentError('uid must not be empty');
    }
    if (points < 1 || points > maxPointsPerAward) {
      throw ArgumentError(
          'points must be between 1 and $maxPointsPerAward (got $points)');
    }

    final batch = _firestore.batch();

    final userUpdates = <String, dynamic>{
      'careIndex': FieldValue.increment(points),
    };
    if (activity == CareActivityType.quest) {
      userUpdates['completedQuestsCount'] = FieldValue.increment(1);
    }
    batch.update(_userRef(uid), userUpdates);

    final log = CareIndexLog(
      uid: uid,
      activityType: activity,
      points: points,
      description: description,
    );
    batch.set(_logsRef(uid).doc(), log.toMap());

    await batch.commit();
  }

  /// Real-time stream of the user profile; null if the document does not exist.
  Stream<AppUser?> streamUser(String uid) {
    return _userRef(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return AppUser.fromMap({...data, 'uid': snapshot.id});
    });
  }

  /// Real-time stream of the most recent logs, newest first.
  Stream<List<CareIndexLog>> streamLogs(String uid, {int limit = 20}) {
    return _logsRef(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(CareIndexLog.fromFirestore).toList());
  }
}