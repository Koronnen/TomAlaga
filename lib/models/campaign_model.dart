class CampaignModel {
  final String id;
  final String type;
  final String title;
  final String description;
  final double goalAmount;
  final double raisedAmount;
  final String status;
  final String? petId;

  const CampaignModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.goalAmount = 0,
    this.raisedAmount = 0,
    this.status = 'active',
    this.petId,
  });

  bool get isDonation => type == 'donation';
  bool get isAdoption => type == 'adoption';

  factory CampaignModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return CampaignModel(
      id: id,
      type: (map['type'] ?? 'donation').toString(),
      title: (map['title'] ?? 'Campaign').toString(),
      description: (map['description'] ?? '').toString(),
      goalAmount: (map['goalAmount'] as num?)?.toDouble() ?? 0,
      raisedAmount: (map['raisedAmount'] as num?)?.toDouble() ?? 0,
      status: (map['status'] ?? 'active').toString(),
      petId: map['petId']?.toString(),
    );
  }
}