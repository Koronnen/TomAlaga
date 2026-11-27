import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../controllers/map_controller.dart';
import '../../models/map_pin_model.dart';
import '../../models/pet_model.dart';
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

  Future<void> _openSaveBowlDialog(double normX, double normY) async {
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Feeding Bowl Station'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Station Name',
                hintText: 'e.g. Botanical Gate Bowl',
              ),
            ),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Feeding schedule or food/water status',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: pet.imageUrl.isNotEmpty
                        ? Image.network(
                            pet.imageUrl,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              width: 76,
                              height: 76,
                              child: Icon(Icons.pets, size: 36),
                            ),
                          )
                        : const SizedBox(
                            width: 76,
                            height: 76,
                            child: Icon(Icons.pets, size: 36),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pet.location} • ${pin.zoneName}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (pin.needsHealthCheck) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Due for 7-day check-in',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: Colors.deepOrange),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (pet.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(pet.description),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(label: Text('Neutered: ${pet.neutered}')),
                  if (pet.vaccination.isNotEmpty)
                    Chip(label: Text('Vaccine: ${pet.vaccination}')),
                  if (pet.condition.isNotEmpty)
                    Chip(label: Text('Condition: ${pet.condition}')),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  _startSightingPinUpdate(pet, pin);
                },
                icon: const Icon(Icons.edit_location_alt),
                label: const Text('Update Sighting Pin'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBowlBottomSheet(MapPinModel pin) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pin.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(pin.zoneName),
              if (pin.subtitle.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(pin.subtitle),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final isPlacing = _controller.placementMode != PinPlacementMode.none;

        return Scaffold(
          appBar: AppBar(title: const Text('UST Campus Map')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                _controller.togglePlacementMode(type: PinType.bowl),
            icon: Icon(isPlacing ? Icons.close : Icons.rice_bowl),
            label: Text(isPlacing ? 'Cancel' : 'Drop Bowl'),
          ),
          body: Column(
            children: [
              if (_controller.isLoading) const LinearProgressIndicator(),
              if (_controller.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _controller.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _controller.layerFilter == MapLayerFilter.all,
                      onSelected: (_) =>
                          _controller.setLayerFilter(MapLayerFilter.all),
                    ),
                    const SizedBox(width: 4),
                    ChoiceChip(
                      label: const Text('Bowls'),
                      selected: _controller.layerFilter == MapLayerFilter.bowls,
                      onSelected: (_) =>
                          _controller.setLayerFilter(MapLayerFilter.bowls),
                    ),
                    const SizedBox(width: 4),
                    ChoiceChip(
                      label: const Text('Cats'),
                      selected: _controller.layerFilter == MapLayerFilter.cats,
                      onSelected: (_) =>
                          _controller.setLayerFilter(MapLayerFilter.cats),
                    ),
                    const Spacer(),
                    DropdownButton<String>(
                      value: _controller.selectedZoneId,
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('All Zones'),
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
                  ],
                ),
              ),
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