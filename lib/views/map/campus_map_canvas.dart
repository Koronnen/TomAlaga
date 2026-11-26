import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/map_pin_model.dart';

class CampusMapCanvas extends StatefulWidget {
  final String mapPath;
  final List<MapPinModel> pins;
  final MapPinModel? draftPin;
  final PinPlacementMode placementMode;
  final ValueChanged<PinPlacementMode>? onPlacementModeChanged;
  final void Function(double normX, double normY)? onDraftChanged;
  final void Function(double normX, double normY)? onConfirmedLocation;
  final ValueChanged<MapPinModel>? onPinTap;
  final List<CampusLandmark> landmarks;
  final bool showModeToggle;
  final String confirmButtonLabel;

  const CampusMapCanvas({
    super.key,
    this.mapPath = 'assets/maps/user_campus_map_cropped.svg',
    this.pins = const [],
    this.draftPin,
    this.placementMode = PinPlacementMode.none,
    this.onPlacementModeChanged,
    this.onDraftChanged,
    this.onConfirmedLocation,
    this.onPinTap,
    this.landmarks = const [],
    this.showModeToggle = true,
    this.confirmButtonLabel = 'Confirm Pin Location',
  });

  @override
  State<CampusMapCanvas> createState() => _CampusMapCanvasState();
}

class _CampusMapCanvasState extends State<CampusMapCanvas> {
  final TransformationController _transformController = TransformationController();

  double _viewportWidth = 1;
  double _viewportHeight = 1;
  double _mapSize = 1;
  double _centerNormX = 0.5;
  double _centerNormY = 0.5;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_recomputeCenterCoordinate);
  }

  @override
  void dispose() {
    _transformController.removeListener(_recomputeCenterCoordinate);
    _transformController.dispose();
    super.dispose();
  }

  void _recomputeCenterCoordinate(){
    // Only recompute when actively placing via center-pin mode
    if (widget.placementMode != PinPlacementMode.centerPin) return;
    if (_mapSize <= 1 || _viewportHeight <= 1 || _viewportWidth <= 1) return;

    final inverse = Matrix4.inverted(_transformController.value);
    final viewportCenter = Offset(_viewportWidth / 2, _viewportHeight / 2);
    final mapPoint = MatrixUtils.transformPoint(inverse, viewportCenter);

    final nx = (mapPoint.dx / _mapSize).clamp(0.0, 1.0);
    final ny = (mapPoint.dy / _mapSize).clamp(0.0, 1.0);

    if ((nx - _centerNormX).abs() > 0.0005 || (ny - _centerNormY).abs() > 0.0005 ) {
      setState(() {
        _centerNormX = nx;
        _centerNormY = ny;
      });
      // Removed onDraftChanged call — zone/landmark info is computed
      // locally in build(), avoiding a double-rebuild through the controller.
    }
  }

  void _handleConfirm() {
    if (widget.placementMode == PinPlacementMode.centerPin) {
      widget.onConfirmedLocation?.call(_centerNormX, _centerNormY);
    } else if (widget.placementMode == PinPlacementMode.tapToPin && widget.draftPin != null) {
      widget.onConfirmedLocation?.call(widget.draftPin!.mapX, widget.draftPin!.mapY);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlacing = widget.placementMode != PinPlacementMode.none;
    final currentX = widget.placementMode == PinPlacementMode.centerPin ? _centerNormX : (widget.draftPin?.mapX ?? 0.5); // default to center
    final currentY = widget.placementMode == PinPlacementMode.centerPin ? _centerNormY : (widget.draftPin?.mapY ?? 0.5);

    // Only compute zone/landmark when actively placing a pin
    String activeZoneName = '';
    String? activeLandmark;
    if (isPlacing) {
      final(_, zoneName) = MapPinModel.detectZone(currentX, currentY);
      activeZoneName = zoneName;
      activeLandmark = MapPinModel.findNearestLandmark(currentX, currentY, widget.landmarks);
    }

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        _viewportHeight = outerConstraints.maxHeight;
        _viewportWidth = outerConstraints.maxWidth;
        final squareSide = _viewportWidth < _viewportHeight ? _viewportWidth : _viewportHeight; //get the longer side and take it as the side for all
        _mapSize = squareSide > 0 ? squareSide : 1;

        return Stack(
          children: [
            Center(
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 1.0,
                maxScale: 5.0,
                constrained: false,
                child: SizedBox(
                  width: _mapSize,
                  height: _mapSize,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: widget.placementMode == PinPlacementMode.tapToPin 
                                                      ? (details) {
                                                        final nx = (details.localPosition.dx / _mapSize).clamp(0.0, 1.0);
                                                        final ny = (details.localPosition.dy / _mapSize).clamp(0.0, 1.0);
                                                        widget.onDraftChanged?.call(nx, ny);
                                                      }
                                                      : null,
                    child: Stack(
                      children: [
                        RepaintBoundary(
                          child: SvgPicture.asset(
                            widget.mapPath,
                            width: _mapSize,
                            height: _mapSize,
                            fit: BoxFit.fill,
                          ),
                        ),
                        ...widget.pins.map((pin) {
                          final isBowl = pin.type == PinType.bowl;
                          return Positioned(
                            left: pin.mapX * _mapSize - 16,
                            top: pin.mapY * _mapSize - 32,
                            child: GestureDetector(
                              onTap: () => widget.onPinTap?.call(pin),
                              child: Icon(
                                isBowl ? Icons.rice_bowl : Icons.pets,
                                color: isBowl ? Colors.blue.shade700 : Colors.deepOrange,
                                size: 32,
                              ),
                            ),
                          );
                        }),

                        if (widget.placementMode == PinPlacementMode.tapToPin && widget.draftPin != null)
                          Positioned(
                            left: widget.draftPin!.mapX * _mapSize - 18,
                            top: widget.draftPin!.mapY * _mapSize - 36,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 36,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.placementMode == PinPlacementMode.centerPin)
              IgnorePointer(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -18),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 36,
                    ),
                  ),
                ),
              ),
            if (isPlacing)
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          activeLandmark != null ? 'Near $activeLandmark -- $activeZoneName' : activeZoneName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center
                        ),
                        Text (
                          '(${currentX.toStringAsFixed(2)}, ${currentY.toStringAsFixed(2)})',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (widget.showModeToggle && widget.onPlacementModeChanged != null)
                          ...[
                            const SizedBox(height: 8),
                            SegmentedButton(
                              segments: const [
                                ButtonSegment(
                                  value: PinPlacementMode.centerPin,
                                  label: Text('Center Pin'),
                                  icon: Icon(Icons.my_location),
                                ),
                                ButtonSegment(
                                  value: PinPlacementMode.tapToPin,
                                  label: Text('Tap Map'),
                                  icon: Icon(Icons.touch_app),
                                ),
                              ],
                              selected: {widget.placementMode},
                              onSelectionChanged: (set) => widget.onPlacementModeChanged!(set.first),
                            ),
                          ],
                      ],
                    ),
                  ),
                ),
              ),

              if (isPlacing && widget.onConfirmedLocation != null)
                Positioned(
                  bottom: 14,
                  left: 16,
                  right: 16,
                  child: FilledButton.icon(
                    onPressed: widget.placementMode == PinPlacementMode.tapToPin && widget.draftPin == null
                                                        ? null : _handleConfirm,
                    icon: const Icon(Icons.check),
                    label: Text(widget.confirmButtonLabel),
                  ),
                ),
          ],
        );
      },
    );
  }
}

