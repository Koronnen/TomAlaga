import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/map_controller.dart';
import '../../models/map_pin_model.dart';
import '../../models/pet_model.dart';
import '../../views/auth/login_view.dart';
import 'campus_map_canvas.dart';
import 'campus_map_picker.dart';

class CampusMapView extends StatefulWidget {
  const CampusMapView({super.key});

  @override
  State<CampusMapView> createState() => _CampusMapViewState();
}

class _CampusMapViewState extends State<CampusMapView> {
  final MapController _controller = MapController();

  @override
  void initState() {
    super.initState();
    _controller.startListening();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  ButtonStyle _buttonStyle({
    Color backgroundColor = Colors.white,
    Color foregroundColor = Colors.black,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
        side: const BorderSide(color: Colors.black, width: 1),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 13,
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
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.inter(color: Colors.black54, fontSize: 12),
      filled: true,
      fillColor: const Color.fromARGB(87, 254, 190, 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  Future<void> _openSaveBowlDialog(double normX, double normY) async {
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
        title: Text(
          'Add Feeding Bowl Station',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: _inputDecoration(
                label: 'Station Name',
                hint: 'e.g. Botanical Gate Bowl',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: _inputDecoration(
                label: 'Notes',
                hint: 'Feeding schedule or food/water status',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.black87),
            ),
          ),
          ElevatedButton(
            style: _buttonStyle(backgroundColor: const Color(0xFFFEC00F)),
            onPressed: () async {
              final email =
                  FirebaseAuth.instance.currentUser?.email ?? 'volunteer';
              await _controller.addBowlStation(
                x: normX,
                y: normY,
                title: titleCtrl.text,
                notes: notesCtrl.text,
                updatedBy: email,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Bowl'),
          ),
        ],
      ),
    );
  }

  Future<void> _openLogWellbeingDialog(PetModel pet) async {
    if (pet.id == null) return;

    const statusOptions = [
      'Healthy & Active',
      'Needs Food / Water',
      'Minor Injury / Limping',
      'Sick / Lethargic',
      'Needs Vet Attention',
    ];

    String selectedStatus = statusOptions.contains(pet.condition)
        ? pet.condition
        : statusOptions.first;
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.black, width: 1),
          ),
          title: Text(
            'Log Wellbeing • ${pet.name}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: _inputDecoration(label: 'Current Condition'),
                items: statusOptions
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedStatus = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: _inputDecoration(
                  label: 'Wellbeing Notes',
                  hint: 'Appetite, behavior, wounds, or care given...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startSightingPinUpdate(PetModel pet, MapPinModel pin) async {
    if (pet.id == null) return;

    final picked = await showCampusMapPickerOverlay(
      context,
      title: 'Update ${pet.name}\'s Sighting',
      pinType: PinType.cat,
      pinTitle: pet.name,
      initialLocation: PickedMapLocation(
        mapX: pin.mapX,
        mapY: pin.mapY,
        zoneId: pin.zoneId,
        zoneName: pin.zoneName,
      ),
      existingPins: _controller.filteredPins
          .where((p) => p.id != pin.id)
          .toList(),
      landmarks: _controller.landmarks,
      confirmButtonLabel: 'Save New Sighting Pin',
    );

    if (picked == null || !mounted) return;

    final nextLocation = picked.nearestLandmark?.name ?? picked.zoneName;
    try {
      await _controller.updatePetSighting(
        petId: pet.id!,
        location: nextLocation,
        mapX: picked.mapX,
        mapY: picked.mapY,
        zoneId: picked.zoneId,
        landmarkId: picked.nearestLandmark?.id ?? '',
      );
      _showMessage('Updated ${pet.name}\'s location to $nextLocation.');
    } catch (e) {
      _showMessage('Failed to update sighting: $e');
    }
  }

  void _handlePinTap(MapPinModel pin) {
    if (pin.type == PinType.cat) {
      final pet = _controller.getPetById(pin.linkedPetId);
      if (pet != null) {
        _showPetBottomSheet(pet, pin);
        return;
      }
    }
    _showBowlBottomSheet(pin);
  }

  void _showPetBottomSheet(PetModel pet, MapPinModel pin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.black, width: 1),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: pet.imageUrl.isNotEmpty
                          ? Image.network(
                              pet.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                width: 80,
                                height: 80,
                                child: Icon(Icons.pets, size: 36),
                              ),
                            )
                          : const SizedBox(
                              width: 80,
                              height: 80,
                              child: Icon(Icons.pets, size: 36),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.name,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pet.location} • ${pin.zoneName}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        if (pin.needsHealthCheck) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEC00F),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black),
                            ),
                            child: Text(
                              'Due for 7-day check-in',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (pet.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  pet.description,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _infoBadge('Neutered: ${pet.neutered}'),
                  if (pet.vaccination.isNotEmpty)
                    _infoBadge('Vaccine: ${pet.vaccination}'),
                  if (pet.condition.isNotEmpty)
                    _infoBadge('Condition: ${pet.condition}'),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: _buttonStyle(
                        backgroundColor: const Color(0xFFFEC00F),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        _openLogWellbeingDialog(pet);
                      },
                      icon: const Icon(Icons.favorite_border, size: 18),
                      label: const Text('Log Wellbeing'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: _buttonStyle(backgroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        _startSightingPinUpdate(pet, pin);
                      },
                      icon: const Icon(Icons.edit_location_alt, size: 18),
                      label: const Text('Update Pin'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 223, 223, 223),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }

  void _showBowlBottomSheet(MapPinModel pin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.black, width: 1),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.rice_bowl, color: Colors.black, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pin.title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${pin.zoneName}${pin.nearestLandmark != null ? ' • Near ${pin.nearestLandmark}' : ''}',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
              ),
              if (pin.subtitle.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  pin.subtitle,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.black),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayerChip(String label, MapLayerFilter filter) {
    final selected = _controller.layerFilter == filter;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      selected: selected,
      showCheckmark: false,
      selectedColor: const Color(0xFFFEC00F),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
        side: const BorderSide(color: Colors.black, width: 1),
      ),
      onSelected: (_) => _controller.setLayerFilter(filter),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final isPlacing = _controller.placementMode != PinPlacementMode.none;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text("UST Campus Map", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  icon: const Icon(Icons.logout),
                  color: const Color(0xFFFEC00F),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginView()),
                    );
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFEC00F),
                    foregroundColor: Colors.black,         
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                _controller.togglePlacementMode(type: PinType.bowl),
            backgroundColor: isPlacing ? Colors.white : const Color(0xFFFEC00F),
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
              side: const BorderSide(color: Colors.black, width: 1),
            ),
            icon: Icon(isPlacing ? Icons.close : Icons.rice_bowl),
            label: Text(
              isPlacing ? 'Cancel' : 'Drop Bowl',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
          body: Column(
            children: [
              if (_controller.isLoading)
                const LinearProgressIndicator(color: Color(0xFFFEC00F)),
              if (_controller.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _controller.errorMessage!,
                    style: GoogleFonts.inter(
                      color: const Color.fromARGB(255, 113, 3, 3),
                      fontSize: 12,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filters: ', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            _buildLayerChip('Both', MapLayerFilter.all),
                            const SizedBox(width: 6),
                            _buildLayerChip('Feeding Bowls', MapLayerFilter.bowls),
                            const SizedBox(width: 6),
                            _buildLayerChip('Pets', MapLayerFilter.cats),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 223, 223, 223),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _controller.selectedZoneId,
                          dropdownColor: Colors.white,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 'all',
                              child: Text('All Campus Zones'),
                            ),
                            ...MapPinModel.zones.entries.map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) _controller.setZoneFilter(val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: CampusMapCanvas(
                  pins: _controller.filteredPins,
                  draftPin: _controller.draftPin,
                  placementMode: _controller.placementMode,
                  landmarks: _controller.landmarks,
                  confirmButtonLabel: 'Confirm Bowl Location',
                  onPlacementModeChanged: _controller.setPlacementMode,
                  onDraftChanged: _controller.updateDraftCoordinate,
                  onConfirmedLocation: _openSaveBowlDialog,
                  onPinTap: _handlePinTap,
                ),
              ),
              
            ],
          ),
        );
      },
    );
  }
}