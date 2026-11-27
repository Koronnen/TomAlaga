import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tomalaga/views/auth/login_view.dart';
import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../models/campaign_model.dart';
import '../views/test_campaign_view.dart';

class HomeView extends StatefulWidget {
  final AuthController controller;

  const HomeView({
    super.key,
    required this.controller,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  final HomeController _homeController = HomeController();
  late final TabController _tabController;

  final Map<String, TextEditingController> _amountControllers = {};
  final Map<String, TextEditingController> _noteControllers = {};
  CampaignModel? _selectedAdoptionPet;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  TextEditingController _amountCtrlFor(String key) {
    return _amountControllers.putIfAbsent(key, () => TextEditingController());
  }

  TextEditingController _noteCtrlFor(String key) {
    return _noteControllers.putIfAbsent(key, () => TextEditingController());
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _amountControllers.values) {
      c.dispose();
    }
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    _homeController.dispose();
    super.dispose();
  }

  Widget _sectionContainer({
    required Widget child,
    Color color = const Color.fromARGB(255, 223, 223, 223),
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black),
      ),
      child: child,
    );
  }

  ButtonStyle _buttonStyle({
    Color backgroundColor = Colors.white,
    Color foregroundColor = Colors.black,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
        side: const BorderSide(color: Colors.black),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.inter(
        color: Colors.black87,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.inter(color: Colors.black54, fontSize: 12),
      filled: true,
      fillColor: const Color.fromARGB(87, 254, 190, 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black54),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black87),
      ),
    );
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _buildQuickStatusContainer() {
    return _sectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Status',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEC00F),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.black),
                ),
                child: Text(
                  'URGENT',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.black, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Active Need: Evening feeding needed near Roque Ruaño & Main Bldg.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.restaurant_outlined,
                          color: Colors.black, size: 20),
                      const SizedBox(height: 6),
                      Text(
                        '4',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Unclaimed Feeding Quests',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.medical_services_outlined,
                          color: Colors.black, size: 20),
                      const SizedBox(height: 6),
                      Text(
                        '2',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Pet Checkups Due',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewTile({
    required String title,
    required String subtitle,
    required String badgeText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFEC00F),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.black),
            ),
            child: Text(
              badgeText,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestsAndShiftsContainer() {
    return _sectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.black),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFFFEC00F),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.black),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(text: 'Active Quests'),
                Tab(text: 'Upcoming Shifts'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 155,
            child: TabBarView(
              controller: _tabController,
              children: [
                Column(
                  children: [
                    _previewTile(
                      title: 'Morning Feeding - Lovers Lane',
                      subtitle: 'Assigned to you • 7:30 AM',
                      badgeText: '+15 pts',
                    ),
                    _previewTile(
                      title: 'Water Bowl Refill - Arch of the Centuries',
                      subtitle: 'In Progress • 10:00 AM',
                      badgeText: '+10 pts',
                    ),
                  ],
                ),
                Column(
                  children: [
                    _previewTile(
                      title: 'Afternoon Patrol - Main Building',
                      subtitle: 'Tomorrow • 2:00 PM - 4:00 PM',
                      badgeText: 'Confirmed',
                    ),
                    _previewTile(
                      title: 'Weekend Feeding - Quadricentennial Park',
                      subtitle: 'Sat, Nov 28 • 8:00 AM - 9:30 AM',
                      badgeText: 'Open',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDonate(CampaignModel campaign) async {
    final amountCtrl = _amountCtrlFor(campaign.id);
    final noteCtrl = _noteCtrlFor(campaign.id);
    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;

    try {
      await _homeController.submitDonation(
        campaign: campaign,
        amount: amount,
        note: noteCtrl.text,
      );
      amountCtrl.clear();
      noteCtrl.clear();
      _showMessage(
        'Thank you! Recorded PHP ${amount.toStringAsFixed(0)} donation.',
      );
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openAdoptDialog(CampaignModel campaign) async {
    final contactCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black),
        ),
        title: Text(
          campaign.title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: contactCtrl,
              decoration: _inputDecoration(
                label: 'Contact Number / Messenger',
                hint: 'e.g. 0917-XXX-XXXX',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              minLines: 2,
              maxLines: 3,
              decoration: _inputDecoration(
                label: 'Home Environment & Experience',
                hint: 'Tell us briefly about your home & pet experience...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: GoogleFonts.inter(color: Colors.black87)),
          ),
          ElevatedButton(
            style: _buttonStyle(backgroundColor: const Color(0xFFC8E6C9)),
            onPressed: () async {
              try {
                await _homeController.submitAdoptionInquiry(
                  campaign: campaign,
                  contact: contactCtrl.text,
                  reason: reasonCtrl.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _showMessage('Adoption inquiry submitted! We will reach out.');
              } catch (e) {
                _showMessage(e.toString().replaceFirst('Exception: ', ''));
              }
            },
            child: const Text('Submit Inquiry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(CampaignModel campaign) {
    final isDonation = campaign.isDonation;
    final progress = (isDonation && campaign.goalAmount > 0)
        ? (campaign.raisedAmount / campaign.goalAmount).clamp(0.0, 1.0)
        : 0.0;
    final isSubmitting =
        _homeController.submittingCampaignIds.contains(campaign.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  campaign.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDonation
                      ? const Color(0xFFFEC00F)
                      : const Color(0xFFC8E6C9),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.black),
                ),
                child: Text(
                  isDonation ? 'DONATION' : 'ADOPTION',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            campaign.description,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
          ),
          if (isDonation) ...[
            if (campaign.goalAmount > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color.fromARGB(255, 223, 223, 223),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFFFEC00F)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'PHP ${campaign.raisedAmount.toStringAsFixed(0)} raised of PHP ${campaign.goalAmount.toStringAsFixed(0)} goal',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountCtrlFor(campaign.id),
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: _inputDecoration(
                      label: 'Amount (PHP)',
                      hint: '100',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _noteCtrlFor(campaign.id),
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: _inputDecoration(
                      label: 'Ref # / Note',
                      hint: 'Optional',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: _buttonStyle(
                  backgroundColor: const Color(0xFFFEC00F),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                onPressed: isSubmitting ? null : () => _handleDonate(campaign),
                child: Text(isSubmitting ? 'Submitting...' : 'Donate'),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: _buttonStyle(
                  backgroundColor: const Color(0xFFC8E6C9),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () => _openAdoptDialog(campaign),
                child: const Text('Inquire / Adopt'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdoptionDropdownCard(List<CampaignModel> adoptionPets) {
    if (adoptionPets.isEmpty) return const SizedBox.shrink();

    final currentSelection =
        adoptionPets.any((p) => p.id == _selectedAdoptionPet?.id)
            ? adoptionPets.firstWhere((p) => p.id == _selectedAdoptionPet?.id)
            : adoptionPets.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Adopt a Campus Pet',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFC8E6C9),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.black),
                ),
                child: Text(
                  'ADOPTION',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<CampaignModel>(
            value: currentSelection,
            isExpanded: true,
            decoration: _inputDecoration(label: 'Select Pet for Adoption'),
            items: adoptionPets.map((pet) {
              return DropdownMenuItem<CampaignModel>(
                value: pet,
                child: Text(
                  pet.title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.black),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedAdoptionPet = val);
              }
            },
          ),
          if (currentSelection.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              currentSelection.description,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: _buttonStyle(
                backgroundColor: const Color(0xFFC8E6C9),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () => _openAdoptDialog(currentSelection),
              child: const Text('Inquire / Adopt'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignsContainer() {
    return ListenableBuilder(
      listenable: _homeController,
      builder: (context, _) {
        return _sectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Donation & Adoption Campaigns',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<CampaignModel>>(
                stream: _homeController.watchActiveCampaigns(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(
                          color: Color(0xFFFEC00F),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Text(
                      'Could not load campaigns: ${snapshot.error}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    );
                  }

                  final campaigns = snapshot.data ?? [];
                  final donationCampaigns =
                      campaigns.where((c) => c.isDonation).toList();
                  final adoptionPets =
                      campaigns.where((c) => c.isAdoption).toList();

                  if (donationCampaigns.isEmpty && adoptionPets.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Text(
                        'No active donation or adoption campaigns right now.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ...donationCampaigns.map(_buildCampaignCard),
                      _buildAdoptionDropdownCard(adoptionPets),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: Text(
          "TomAlaga",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
                );
              },
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFEC00F),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.build_circle_outlined),
            tooltip: 'Test Campaigns',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CampaignTestView()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildQuickStatusContainer(),
            const SizedBox(height: 16),
            _buildQuestsAndShiftsContainer(),
            const SizedBox(height: 16),
            _buildCampaignsContainer(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}