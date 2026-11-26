import 'package:cloud_firestore/cloud_firestore.dart';

enum CareActivityType {
  quest('quest', 'Quest', 10),
  healthCheck('health_check', 'Health Check', 8),
  donation('donation', 'Donation', 15),
  feedingRun('feeding_run', 'Feeding Run', 5);

  final String value;
  final String label;
  final int defaultPoints;

  const CareActivityType(this.value, this.label, this.defaultPoints);

  /// Falls back to [quest] for unknown values.
  static CareActivityType fromValue(String? value) {
    return CareActivityType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CareActivityType.quest,
    );
  }
}

class CareIndexLog {
  final String? id;
  final String uid;
  final CareActivityType activityType;
  final int points;
  final String? description;
  final DateTime? createdAt; // null while the server timestamp is pending

  const CareIndexLog({
    this.id,
    required this.uid,
    required this.activityType,
    required this.points,
    this.description,
    this.createdAt,
  });

  factory CareIndexLog.fromMap(Map<String, dynamic> map, {String? id}) {
    final created = map['createdAt'];
    return CareIndexLog(
      id: id,
      uid: (map['uid'] ?? '').toString(),
      activityType: CareActivityType.fromValue(map['activityType']?.toString()),
      points: (map['points'] as num?)?.toInt() ?? 0,
      description: map['description']?.toString(),
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  factory CareIndexLog.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return CareIndexLog.fromMap(doc.data() ?? {}, id: doc.id);
  }

  /// Uses a server timestamp for `createdAt`. `description` is omitted when empty.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'activityType': activityType.value,
      'points': points,
      'createdAt': FieldValue.serverTimestamp(),
    };
    final desc = description?.trim();
    if (desc != null && desc.isNotEmpty) map['description'] = desc;
    return map;
  }
}