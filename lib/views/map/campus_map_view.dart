import 'package:flutter/material.dart';
import '../../controllers/map_controller.dart';
import '../../models/map_pin_model.dart';
import 'campus_map_canvas.dart';

class CampusMapView extends StatefulWidget {
  const CampusMapView({super.key});

  @override
  State<CampusMapView> createState() => _CampusMapViewState();
}

class _CampusMapViewState extends State<CampusMapView> {
  final MapController _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openSavePinDialog(double normX, double normY) async {
    PinType selectedType = _controller.newPinType;
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();

    final (zoneId, zoneName) = MapPinModel.detectZone(normX, normY);
    final nearestLandmark = MapPinModel.findNearestLandmark(
      normX,
      normY,
      _controller.landmarks,
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Save Map Pin'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Zone: $zoneName'),
                  if (nearestLandmark != null)
                    Text('Near: $nearestLandmark'),
                  const SizedBox(height: 12),
                  SegmentedButton<PinType>(
                    segments: const [
                      ButtonSegment(
                        value: PinType.cat,
                        label: Text('Cat'),
                      ),
                      ButtonSegment(
                        value: PinType.bowl,
                        label: Text('Bowl'),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (set) {
                      setDialogState(() => selectedType = set.first);
                      _controller.setNewPinType(set.first);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: selectedType == PinType.cat
                          ? 'Cat Name / Label'
                          : 'Bowl Station Name',
                    ),
                  ),
                  TextField(
                    controller: subtitleController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _controller.addPin(
                      x: normX,
                      y: normY,
                      type: selectedType,
                      title: titleController.text,
                      subtitle: subtitleController.text,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onPinTap(MapPinModel pin) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${pin.title} • ${pin.zoneName}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final isPlacing =
            _controller.placementMode != PinPlacementMode.none;

        return Scaffold(
          appBar: AppBar(
            title: const Text('UST Campus Map'),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _controller.togglePlacementMode(),
            icon: Icon(isPlacing ? Icons.close : Icons.add_location_alt),
            label: Text(isPlacing ? 'Cancel' : 'Add Pin'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _controller.layerFilter == MapLayerFilter.all,
                      onSelected: (_) =>
                          _controller.setLayerFilter(MapLayerFilter.all),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Bowls'),
                      selected:
                          _controller.layerFilter == MapLayerFilter.bowls,
                      onSelected: (_) =>
                          _controller.setLayerFilter(MapLayerFilter.bowls),
                    ),
                    const SizedBox(width: 6),
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
                            child: Text(e.key),
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
                  mapPath: 'assets/maps/ust_campus_map_cropped.svg',
                  pins: _controller.filteredPins,
                  draftPin: _controller.draftPin,
                  placementMode: _controller.placementMode,
                  landmarks: _controller.landmarks,
                  onPlacementModeChanged: _controller.setPlacementMode,
                  onDraftChanged: _controller.updateDraftCoordinate,
                  onConfirmedLocation: _openSavePinDialog,
                  onPinTap: _onPinTap,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}