import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftVolunteer {
  final String uid;
  final String email;
  final String status; // 'reserved' | 'checked_in' | 'completed' | 'no_show'
  final String? linkedQuestId;
  final DateTime? reservedAt;
  final DateTime? checkedInAt;

  const ShiftVolunteer({
    required this.uid,
    required this.email,
    this.status = 'reserved',
    this.linkedQuestId,
    this.reservedAt,
    this.checkedInAt,
  });

  String get displayName =>
      email.contains('@') ? email.split('@').first : email;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'status': status,
      'linkedQuestId': linkedQuestId,
      'reservedAt': reservedAt != null ? Timestamp.fromDate(reservedAt!) : null,
      'checkedInAt': checkedInAt != null
          ? Timestamp.fromDate(checkedInAt!)
          : null,
    };
  }

  factory ShiftVolunteer.fromMap(Map<String, dynamic> map) {
    return ShiftVolunteer(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      status: map['status'] ?? 'reserved',
      linkedQuestId: map['linkedQuestId'],
      reservedAt: (map['reservedAt'] as Timestamp?)?.toDate(),
      checkedInAt: (map['checkedInAt'] as Timestamp?)?.toDate(),
    );
  }
}

class ShiftModel {
  final String shiftId;
  final String seriesId;
  final String seriesTitle;
  final String category; // 'feeding' | 'healthcare'
  final bool zoneRestricted;
  final String title;
  final String zoneId;
  final String zoneName;
  final String? petId;
  final String? petName;
  final List<String> bowlLocations;
  final DateTime startTime;
  final DateTime endTime;
  final int capacity;
  final List<ShiftVolunteer> volunteers;

  const ShiftModel({
    required this.shiftId,
    required this.seriesId,
    required this.seriesTitle,
    this.category = 'feeding',
    this.zoneRestricted = true,
    required this.title,
    required this.zoneId,
    required this.zoneName,
    this.petId,
    this.petName,
    this.bowlLocations = const [],
    required this.startTime,
    required this.endTime,
    this.capacity = 2,
    this.volunteers = const [],
  });

  int get spotsFilled => volunteers.where((v) => v.status != 'no_show').length;

  int get spotsRemaining => (capacity - spotsFilled).clamp(0, capacity);

  bool get isFull => spotsFilled >= capacity;
  bool get isHealthcare => category == 'healthcare';
  bool get hasEnded => endTime.isBefore(DateTime.now());

  bool get canCheckInNow {
    final now = DateTime.now();
    final earliest = startTime.subtract(const Duration(minutes: 30));
    return !now.isBefore(earliest) && !now.isAfter(endTime);
  }

  String get dateKey =>
      '${startTime.year.toString().padLeft(4, '0')}-'
      '${startTime.month.toString().padLeft(2, '0')}-'
      '${startTime.day.toString().padLeft(2, '0')}';

  ShiftVolunteer? volunteerFor(String uid) {
    for (final v in volunteers) {
      if (v.uid == uid) return v;
    }
    return null;
  }

  bool hasUser(String uid) => volunteerFor(uid) != null;

  Map<String, dynamic> toMap() {
    return {
      'shiftId': shiftId,
      'seriesId': seriesId,
      'seriesTitle': seriesTitle,
      'category': category,
      'zoneRestricted': zoneRestricted,
      'title': title,
      'zoneId': zoneId,
      'zoneName': zoneName,
      'petId': petId,
      'petName': petName,
      'bowlLocations': bowlLocations,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'capacity': capacity,
      'volunteers': volunteers.map((v) => v.toMap()).toList(),
    };
  }

  factory ShiftModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawVolunteers = map['volunteers'] as List<dynamic>? ?? [];
    return ShiftModel(
      shiftId: docId ?? map['shiftId'] ?? '',
      seriesId: map['seriesId'] ?? 'default_series',
      seriesTitle: map['seriesTitle'] ?? map['title'] ?? 'Scheduled Run',
      category: map['category'] ?? 'feeding',
      zoneRestricted: map['zoneRestricted'] ?? true,
      title: map['title'] ?? '',
      zoneId: map['zoneId'] ?? '',
      zoneName: map['zoneName'] ?? '',
      petId: map['petId'],
      petName: map['petName'],
      bowlLocations: List<String>.from(map['bowlLocations'] ?? []),
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      capacity: map['capacity'] ?? 2,
      volunteers: rawVolunteers
          .map(
            (item) => ShiftVolunteer.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  factory ShiftModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ShiftModel.fromMap(doc.data() ?? {}, docId: doc.id);
  }
}
