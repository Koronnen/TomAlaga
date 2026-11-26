import 'package:flutter/foundation.dart';
import '../models/map_pin_model.dart';
import '../utils/campus_map_landmark_constants.dart';

enum MapLayerFilter { all, bowls, cats }

class MapController extends ChangeNotifier {
  MapLayerFilter layerFilter = MapLayerFilter.all;
  String selectedZoneId = 'all';
  PinPlacementMode placementMode = PinPlacementMode.none; //default, dapat pindutin nila
  PinType newPinType = PinType.cat;
  MapPinModel? draftPin;

  List<CampusLandmark> get landmarks => CampusMapLandmarkConstants.ustLandmarks;

  final List<MapPinModel> _pins = [
    MapPinModel(
      id: 'bowl_1',
      type: PinType.bowl,
      title: 'Botanical Gate Station',
      zoneId: 'zone_1_nw',
      zoneName: MapPinModel.zones['zone_1_nw']!,
      nearestLandmark: 'Botanical Garden',
      mapX: 0.35,
      mapY: 0.42,
      subtitle: 'Daily 7:30 AM & 4:30 PM • Kibble & water',
      updatedAt: DateTime.now(),
    ),
    MapPinModel(
      id: 'cat_1',
      type: PinType.cat,
      title: 'Mingming (Sample)',
      zoneId: 'zone_1_nw',
      zoneName: MapPinModel.zones['zone_1_nw']!,
      nearestLandmark: 'UST Church',
      mapX: 0.27,
      mapY: 0.44,
      subtitle: 'Spotted near path • Due for weekly check-in',
      needsHealthCheck: true,
      updatedAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    MapPinModel(
      id: 'cat_2',
      type: PinType.cat,
      title: 'Calico Sighting #2',
      zoneId: 'zone_6_se',
      zoneName: MapPinModel.zones['zone_6_se']!,
      nearestLandmark: 'Roque Ruano Building',
      mapX: 0.82,
      mapY: 0.78,
      subtitle: 'Resting near shaded wall',
      needsHealthCheck: false,
      updatedAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
  ];

  List<MapPinModel> get filteredPins {
    return _pins.where((pin) {
      final layerMatch = switch (layerFilter) {
        MapLayerFilter.all => true,
        MapLayerFilter.bowls => pin.type == PinType.bowl,
        MapLayerFilter.cats => pin.type == PinType.cat,
      };
      final zoneMatch = selectedZoneId == 'all' || pin.zoneId == selectedZoneId;
      return layerMatch && zoneMatch;
    }).toList();
  }

  List<MapPinModel> get healthCheckPins {
    return _pins.where((pin) => pin.type == PinType.cat && pin.needsHealthCheck).toList();
  }

  void setLayerFilter(MapLayerFilter filter) {
    layerFilter = filter;
    notifyListeners();
  }

  void setZoneFilter(String zoneId) {
    selectedZoneId = zoneId;
    notifyListeners();
  }

  void togglePlacementMode({PinType? type}){
    if (type != null) newPinType = type;
    if (placementMode == PinPlacementMode.none) {
      placementMode = PinPlacementMode.centerPin;
    } else {
      placementMode = PinPlacementMode.none;
      draftPin = null;
    }
    notifyListeners();
  }

  void setPlacementMode(PinPlacementMode mode) {
    placementMode = mode;
    if (mode != PinPlacementMode.tapToPin) {
      draftPin = null;
    }
    notifyListeners();
  }

  void setNewPinType(PinType type) {
    newPinType = type;
    notifyListeners();
  }

  void updateDraftCoordinate(double x, double y) {
    final (zoneId, zoneName) = MapPinModel.detectZone(x, y);
    final landmark = MapPinModel.findNearestLandmark(x, y, CampusMapLandmarkConstants.ustLandmarks);
    draftPin = MapPinModel(
      id: 'draft',
      type: newPinType,
      title: '',
      zoneId: zoneId,
      zoneName: zoneName,
      nearestLandmark: landmark,
      mapX: x,
      mapY: y,
      subtitle: '',
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void addPin({
    required double x,
    required double y,
    required PinType type,
    required String title,
    required String subtitle,
    String? linkedPetId
  }) {
    final (zoneId, zoneName) = MapPinModel.detectZone(x, y);
    final landmark = MapPinModel.findNearestLandmark(x, y, CampusMapLandmarkConstants.ustLandmarks);

    _pins.add(
      MapPinModel(
        id: 'pin_${DateTime.now().millisecondsSinceEpoch}', //YES im using it
        type: type,
        title: title.trim().isEmpty ? (type == PinType.bowl ? 'Feeding Bowl' : 'Cat Sighting') : title.trim(), // in case walang nilagay.. although this will prolly be a radio button or sumn
        zoneId: zoneId,
        zoneName: zoneName,
        nearestLandmark: landmark,
        mapX: x,
        mapY: y,
        subtitle: subtitle.trim(),
        linkedPetId: linkedPetId,
        updatedAt: DateTime.now(),
      ),
    );
    placementMode = PinPlacementMode.none;
    draftPin = null; //not a draft anymore
    notifyListeners();
  }
}