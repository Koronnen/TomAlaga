import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/home_controller.dart';
import '../models/campaign_model.dart';

class CampaignTestView extends StatefulWidget {
  const CampaignTestView({super.key});

  @override
  State<CampaignTestView> createState() => _CampaignTestViewState();
}

class _CampaignTestViewState extends State<CampaignTestView> {
  final HomeController _homeController = HomeController();

  String _selectedType = 'donation';
  String? _selectedExistingCatId;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _goalCtrl = TextEditingController();

  bool _isCreating = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _goalCtrl.dispose();
    _homeController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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

  Future<void> _handleCreateCustom() async {
    setState(() => _isCreating = true);
    try {
      await _homeController.createTempCampaign(
        type: _selectedType,
        title: _titleCtrl.text,
        description: _descCtrl.text,
        goalAmount: double.tryParse(_goalCtrl.text.trim()) ?? 5000.0,
        petId: _selectedType == 'adoption' ? _selectedExistingCatId : null,
      );
      _titleCtrl.clear();
      _descCtrl.clear();
      setState(() => _selectedExistingCatId = null);
      _showMessage('Campaign added to Firestore!');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _confirmDelete(CampaignModel campaign) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black),
        ),
        title: Text(
          'Delete Campaign?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'Delete "${campaign.title}" permanently from Firestore?',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Cancel', style: GoogleFonts.inter(color: Colors.black87)),
          ),
          ElevatedButton(
            style: _buttonStyle(
              backgroundColor: Colors.red.shade100,
              foregroundColor: Colors.red.shade900,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _homeController.deleteCampaign(campaign.id);
      _showMessage('Deleted "${campaign.title}".');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Widget _buildQuickAddersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 223, 223, 223),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1-Tap Temp Adders',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: _buttonStyle(backgroundColor: const Color(0xFFFEC00F)),
                onPressed: () async {
                  try {
                    await _homeController.createTempCampaign(
                      type: 'donation',
                      title: 'Temp Kibble Fund #${DateTime.now().second}',
                      description: 'Quick test donation campaign.',
                      goalAmount: 5000.0,
                    );
                    _showMessage('Added temp donation!');
                  } catch (e) {
                    _showMessage(e.toString().replaceFirst('Exception: ', ''));
                  }
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ Temp Donation'),
              ),
              ElevatedButton.icon(
                style: _buttonStyle(backgroundColor: const Color(0xFFC8E6C9)),
                onPressed: () async {
                  try {
                    await _homeController.createTempCampaign(
                      type: 'adoption',
                      title: 'Temp Adopt "Muning" #${DateTime.now().second}',
                      description: 'Quick test adoption listing.',
                    );
                    _showMessage('Added temp adoption!');
                  } catch (e) {
                    _showMessage(e.toString().replaceFirst('Exception: ', ''));
                  }
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ Temp Adoption'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBuilderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 223, 223, 223),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Campaign Builder',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: _inputDecoration(label: 'Type'),
            items: [
              DropdownMenuItem(
                value: 'donation',
                child: Text('Donation', style: GoogleFonts.inter(fontSize: 13)),
              ),
              DropdownMenuItem(
                value: 'adoption',
                child: Text('Adoption', style: GoogleFonts.inter(fontSize: 13)),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedType = val;
                  _selectedExistingCatId = null;
                });
              }
            },
          ),
          if (_selectedType == 'adoption') ...[
            const SizedBox(height: 12),
            StreamBuilder<List>(
              stream: _homeController.watchPreexistingCats(),
              builder: (context, snapshot) {
                final cats = snapshot.data ?? [];
                if (cats.isEmpty) {
                  return Text(
                    'No preexisting cats found in Firestore.',
                    style:
                        GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                  );
                }

                return DropdownButtonFormField<String>(
                  value: _selectedExistingCatId,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    label: 'Pick Preexisting Cat (Optional)',
                  ),
                  items: cats.map((cat) {
                    final catName =
                        (cat['name'] ?? cat['title'] ?? 'Unnamed Cat')
                            .toString();
                    return DropdownMenuItem<String>(
                      value: cat['id'].toString(),
                      child: Text(
                        catName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (catId) {
                    if (catId == null) return;
                    final picked = cats.firstWhere(
                      (c) => c['id'].toString() == catId,
                    );
                    final name =
                        (picked['name'] ?? picked['title'] ?? 'Campus Cat')
                            .toString();
                    final desc = (picked['description'] ??
                            picked['bio'] ??
                            picked['notes'] ??
                            '')
                        .toString();

                    setState(() {
                      _selectedExistingCatId = catId;
                      _titleCtrl.text = 'Adopt "$name"';
                      _descCtrl.text = desc;
                    });
                  },
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: _inputDecoration(
              label: 'Title',
              hint: _selectedType == 'donation'
                  ? 'e.g. Campus Cat Kibble Fund'
                  : 'e.g. Adopt "Snow"',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            minLines: 2,
            maxLines: 3,
            decoration: _inputDecoration(
              label: 'Description',
              hint: 'Short details...',
            ),
          ),
          if (_selectedType == 'donation') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _goalCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                label: 'Goal (PHP)',
                hint: '5000',
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: _buttonStyle(
                backgroundColor: const Color(0xFFFEC00F),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isCreating ? null : _handleCreateCustom,
              child: Text(_isCreating ? 'Creating...' : 'Create Campaign'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCampaignsManager() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 223, 223, 223),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage / Delete Active Campaigns',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<CampaignModel>>(
            stream: _homeController.watchActiveCampaigns(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFEC00F)),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'Error: ${snapshot.error}',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.red),
                );
              }

              final campaigns = snapshot.data ?? [];
              if (campaigns.isEmpty) {
                return Text(
                  'No active campaigns in Firestore.',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                );
              }

              return Column(
                children: campaigns.map((campaign) {
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
                                campaign.title,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                campaign.isDonation
                                    ? 'DONATION • PHP ${campaign.raisedAmount.toStringAsFixed(0)} / ${campaign.goalAmount.toStringAsFixed(0)}'
                                    : 'ADOPTION • ${campaign.description}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          tooltip: 'Delete',
                          onPressed: () => _confirmDelete(campaign),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Campaign Test & Debug',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildQuickAddersSection(),
            const SizedBox(height: 16),
            _buildCustomBuilderSection(),
            const SizedBox(height: 16),
            _buildActiveCampaignsManager(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}