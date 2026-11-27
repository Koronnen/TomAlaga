import 'package:flutter/material.dart';
import '../../models/map_pin_model.dart';
import 'campus_map_canvas.dart';
import 'package:google_fonts/google_fonts.dart';

/// Returned when the user confirms a pin inside the full-screen map overlay.
class PickedMapLocation {
  final double mapX;
  final double mapY;
  final String zoneId;
  final String zoneName;
  final CampusLandmark? nearestLandmark;

  const PickedMapLocation({
    required this.mapX,
    required this.mapY,
    required this.zoneId,
    required this.zoneName,
    this.nearestLandmark,
  });
}

/// Opens the full-screen map picker overlay from any button or preview card.
Future<PickedMapLocation?> showCampusMapPickerOverlay(
  BuildContext context, {
  String title = 'Pin Campus Location',
  PinType pinType = PinType.cat,
  String pinTitle = 'Selected Location',
  PickedMapLocation? initialLocation,
  List<MapPinModel> existingPins = const [],
  List<CampusLandmark> landmarks = const [],
  String confirmButtonLabel = 'Confirm Pin Location',
}) {
  return Navigator.of(context).push<PickedMapLocation>(
    MaterialPageRoute(
      fullscreenDialog: true, // Uses close (X) button & avoids iOS swipe-back vs pan conflict
      builder: (_) => _FullScreenMapPickerPage(
        title: title,
        pinType: pinType,
        pinTitle: pinTitle,
        initialLocation: initialLocation,
        existingPins: existingPins,
        landmarks: landmarks,
        confirmButtonLabel: confirmButtonLabel,
      ),
    ),
  );
}

/// Tappable read-only map preview card for forms (Pet Registration, Incident Report, etc.).
class CampusMapPickerField extends StatelessWidget {
  final PickedMapLocation? value;
  final ValueChanged<PickedMapLocation> onChanged;
  final List<CampusLandmark> landmarks;
  final List<MapPinModel> existingPins;
  final PinType pinType;
  final String pinTitle;
  final String overlayTitle;
  final String? errorText;

  const CampusMapPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.landmarks = const [],
    this.existingPins = const [],
    this.pinType = PinType.cat,
    this.pinTitle = 'Pinned Spot',
    this.overlayTitle = 'Pin Campus Location',
    this.errorText,
  });

  List<MapPinModel> get _previewPins {
    if (value == null) return existingPins;
    return [
      ...existingPins,
      MapPinModel(
        id: 'preview_confirmed_pin',
        type: pinType,
        title: pinTitle,
        zoneId: value!.zoneId,
        zoneName: value!.zoneName,
        nearestLandmark: value!.nearestLandmark?.name,
        mapX: value!.mapX,
        mapY: value!.mapY,
        subtitle: '',
        updatedAt: DateTime.now(),
      ),
    ];
  }

  Future<void> _openOverlay(BuildContext context) async {
    final picked = await showCampusMapPickerOverlay(
      context,
      title: overlayTitle,
      pinType: pinType,
      pinTitle: pinTitle,
      initialLocation: value,
      existingPins: existingPins,
      landmarks: landmarks,
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = errorText != null
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).dividerColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _openOverlay(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                foregroundDecoration: BoxDecoration(
                  border: Border.all(
                      color: errorText != null ? Colors.white : Colors.black,
                    ),
                    borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Read-only preview so form scrolling never fights map panning
                    IgnorePointer(
                      child: CampusMapCanvas(
                        pins: _previewPins,
                        placementMode: PinPlacementMode.none,
                        showPlacementOverlay: false,
                        landmarks: landmarks,
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(backgroundColor: Color(0xFFFEC00F), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                        onPressed: () => _openOverlay(context),
                        icon: Icon(
                          value == null ? Icons.add_location_alt : Icons.edit_location_alt,
                          size: 18,
                        ),
                        label: Text(value == null ? 'Tap to Pin Map' : 'Adjust Pin', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (value != null)
          Text(
            'Pinned: ${value!.nearestLandmark?.name ?? value!.zoneName} '
            '(${value!.mapX.toStringAsFixed(2)}, ${value!.mapY.toStringAsFixed(2)})',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          Text(
            errorText ?? 'Tap the map above to open full-screen pin placement.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: errorText != null ? Theme.of(context).colorScheme.error : null,
                ),
          ),
      ],
    );
  }
}

class _FullScreenMapPickerPage extends StatefulWidget {
  final String title;
  final PinType pinType;
  final String pinTitle;
  final PickedMapLocation? initialLocation;
  final List<MapPinModel> existingPins;
  final List<CampusLandmark> landmarks;
  final String confirmButtonLabel;

  const _FullScreenMapPickerPage({
    required this.title,
    required this.pinType,
    required this.pinTitle,
    this.initialLocation,
    this.existingPins = const [],
    this.landmarks = const [],
    required this.confirmButtonLabel,
  });

  @override
  State<_FullScreenMapPickerPage> createState() =>
      _FullScreenMapPickerPageState();
}

class _FullScreenMapPickerPageState extends State<_FullScreenMapPickerPage> {
  late PinPlacementMode _mode;
  MapPinModel? _draftPin;

  @override
  void initState() {
    super.initState();
    // If re-editing an existing pin, open in tapToPin with that pin visible;
    // otherwise open in centerPin for easy mobile panning.
    if (widget.initialLocation != null) {
      _mode = PinPlacementMode.tapToPin;
      _draftPin = _buildDraft(
        widget.initialLocation!.mapX,
        widget.initialLocation!.mapY,
      );
    } else {
      _mode = PinPlacementMode.centerPin;
    }
  }

  CampusLandmark? _findLandmarkByName(String? name) {
    if (name == null) return null;
    for (final lm in widget.landmarks) {
      if (lm.name == name) return lm;
    }
    return null;
  }

  MapPinModel _buildDraft(double normX, double normY) {
    final (zoneId, zoneName) = MapPinModel.detectZone(normX, normY);
    final nearestName =
        MapPinModel.findNearestLandmark(normX, normY, widget.landmarks);
    return MapPinModel(
      id: 'picker_draft_pin',
      type: widget.pinType,
      title: widget.pinTitle,
      zoneId: zoneId,
      zoneName: zoneName,
      nearestLandmark: nearestName,
      mapX: normX,
      mapY: normY,
      subtitle: '',
      updatedAt: DateTime.now(),
    );
  }

  void _handleDraftChanged(double normX, double normY) {
    setState(() {
      _draftPin = _buildDraft(normX, normY);
    });
  }

  void _handleConfirmed(double normX, double normY) {
    final (zoneId, zoneName) = MapPinModel.detectZone(normX, normY);
    final nearestName =
        MapPinModel.findNearestLandmark(normX, normY, widget.landmarks);
    Navigator.of(context).pop(
      PickedMapLocation(
        mapX: normX,
        mapY: normY,
        zoneId: zoneId,
        zoneName: zoneName,
        nearestLandmark: _findLandmarkByName(nearestName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: CampusMapCanvas(
          pins: widget.existingPins,
          draftPin: _draftPin,
          placementMode: _mode,
          showModeToggle: true,
          showPlacementOverlay: true,
          landmarks: widget.landmarks,
          confirmButtonLabel: widget.confirmButtonLabel,
          onPlacementModeChanged: (nextMode) {
            setState(() {
              _mode = nextMode;
            });
          },
          onDraftChanged: _handleDraftChanged,
          onConfirmedLocation: _handleConfirmed,
        ),
      ),
    );
  }
}