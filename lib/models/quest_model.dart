import 'package:cloud_firestore/cloud_firestore.dart';

class QuestModel {
  final String questId;
  final String category; // 'feeding' | 'healthcare'
  final String type; // 'feeding' | 'maintenance' | 'checkup' | 'caregiving' | 'shift_feeding' | 'shift_caregiving'
  final String title;
  final String? description;
  final String zoneId;
  final String zoneName;
  final List<String> bowlLocations;
  final String? petId;
  final String? petName;
  final String? shiftId; // Non-null when spawned via Shift check-in
  final String status; // 'open' | 'claimed' | 'completed'
  final String? claimedByUid;
  final String? claimedByEmail;
  final DateTime? scheduledStart;
  final DateTime deadlineAt;
  final String? proofPhotoUrl;
  final String? proofNote;
  final DateTime? completedAt;
  final DateTime? createdAt;

  const QuestModel({
    required this.questId,
    this.category = 'feeding',
    required this.type,
    required this.title,
    this.description,
    required this.zoneId,
    required this.zoneName,
    this.bowlLocations = const [],
    this.petId,
    this.petName,
    this.shiftId,
    this.status = 'open',
    this.claimedByUid,
    this.claimedByEmail,
    this.scheduledStart,
    required this.deadlineAt,
    this.proofPhotoUrl,
    this.proofNote,
    this.completedAt,
    this.createdAt,
  });

  bool get isShiftLinked => shiftId != null && shiftId!.isNotEmpty;
  bool get isHealthcare => category == 'healthcare';
  int get rewardPoints => isShiftLinked ? 25 : 20;

  String get claimerDisplayName {
    if (claimedByEmail == null || claimedByEmail!.isEmpty) return 'Volunteer';
    return claimedByEmail!.contains('@')
        ? claimedByEmail!.split('@').first
        : claimedByEmail!;
  }

  Map<String, dynamic> toMap() {
    return {
      'questId': questId,
      'category': category,
      'type': type,
      'title': title,
      'description': description,
      'zoneId': zoneId,
      'zoneName': zoneName,
      'bowlLocations': bowlLocations,
      'petId': petId,
      'petName': petName,
      'shiftId': shiftId,
      'status': status,
      'claimedByUid': claimedByUid,
      'claimedByEmail': claimedByEmail,
      'scheduledStart': scheduledStart != null
          ? Timestamp.fromDate(scheduledStart!)
          : null,
      'deadlineAt': Timestamp.fromDate(deadlineAt),
      'proofPhotoUrl': proofPhotoUrl,
      'proofNote': proofNote,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory QuestModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return QuestModel(
      questId: docId ?? map['questId'] ?? '',
      category: map['category'] ?? 'feeding',
      type: map['type'] ?? 'feeding',
      title: map['title'] ?? '',
      description: map['description'],
      zoneId: map['zoneId'] ?? '',
      zoneName: map['zoneName'] ?? '',
      bowlLocations: List<String>.from(map['bowlLocations'] ?? []),
      petId: map['petId'],
      petName: map['petName'],
      shiftId: map['shiftId'],
      status: map['status'] ?? 'open',
      claimedByUid: map['claimedByUid'],
      claimedByEmail: map['claimedByEmail'],
      scheduledStart: (map['scheduledStart'] as Timestamp?)?.toDate(),
      deadlineAt: (map['deadlineAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      proofPhotoUrl: map['proofPhotoUrl'],
      proofNote: map['proofNote'],
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory QuestModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return QuestModel.fromMap(doc.data() ?? {}, docId: doc.id);
  }
}
