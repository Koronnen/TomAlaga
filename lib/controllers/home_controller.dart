import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/campaign_model.dart';

class HomeController extends ChangeNotifier {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  final Set<String> submittingCampaignIds = {};

  Stream<List<CampaignModel>> watchActiveCampaigns() {
    return _firestore
        .collection('campaigns')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CampaignModel.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Future<void> submitDonation({
    required CampaignModel campaign,
    required double amount,
    required String note,
  }) async {
    if (amount <= 0) {
      throw Exception('Please enter a valid donation amount in PHP.');
    }

    submittingCampaignIds.add(campaign.id);
    notifyListeners();

    try {
      final user = _auth.currentUser;
      final campaignRef = _firestore.collection('campaigns').doc(campaign.id);
      final batch = _firestore.batch();

      batch.update(campaignRef, {
        'raisedAmount': FieldValue.increment(amount),
      });

      batch.set(campaignRef.collection('responses').doc(), {
        'type': 'donation',
        'amount': amount,
        'note': note.trim(),
        'uid': user?.uid ?? '',
        'email': user?.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } finally {
      submittingCampaignIds.remove(campaign.id);
      notifyListeners();
    }
  }

  Future<void> submitAdoptionInquiry({
    required CampaignModel campaign,
    required String contact,
    required String reason,
  }) async {
    if (contact.trim().isEmpty) {
      throw Exception('Please enter your contact number or Messenger.');
    }

    final user = _auth.currentUser;
    await _firestore
        .collection('campaigns')
        .doc(campaign.id)
        .collection('responses')
        .add({
      'type': 'adoption_inquiry',
      'contact': contact.trim(),
      'message': reason.trim(),
      'uid': user?.uid ?? '',
      'email': user?.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createTempCampaign({
    required String type,
    required String title,
    required String description,
    double goalAmount = 0.0,
    String? petId,
  }) async {
    if (title.trim().isEmpty) {
      throw Exception('Please enter a campaign title.');
    }

    final user = _auth.currentUser;
    await _firestore.collection('campaigns').add({
      'type': type,
      'title': title.trim(),
      'description': description.trim(),
      'goalAmount': type == 'donation' ? goalAmount : 0.0,
      'raisedAmount': 0.0,
      'status': 'active',
      if (petId != null && petId.isNotEmpty) 'petId': petId,
      'createdBy': user?.uid ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List> watchPreexistingCats() {
    return _firestore.collection('pets').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList(),
        );
  }

  Future<void> deleteCampaign(String campaignId) async {
    await _firestore.collection('campaigns').doc(campaignId).delete();
  }
}