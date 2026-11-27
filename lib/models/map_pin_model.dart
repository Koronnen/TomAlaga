enum PinType { bowl, cat }

enum PinPlacementMode { none, centerPin, tapToPin }

class CampusLandmark {
  final String id;
  final String name;
  final String zoneId;
  final double mapX;
  final double mapY;

  const CampusLandmark({
    required this.id,
    required this.name,
    required this.zoneId,
    required this.mapX,
    required this.mapY,
  });
}

class _ZoneBounds {
  final String zoneId;
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  const _ZoneBounds({
    required this.zoneId,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  bool contains(double x, double y) =>
      x >= minX && x <= maxX && y >= minY && y <= maxY;
}

class MapPinModel {
  final String id;
  final PinType type;
  final String title;
  final String zoneId;
  final String zoneName;
  final String? nearestLandmark;
  final double mapX;
  final double mapY;
  final String subtitle;
  final String? linkedPetId;
  final bool needsHealthCheck;
  final DateTime updatedAt;

  const MapPinModel({
    required this.id,
    required this.type,
    required this.title,
    required this.zoneId,
    required this.zoneName,
    this.nearestLandmark,
    required this.mapX,
    required this.mapY,
    required this.subtitle,
    this.linkedPetId,
    this.needsHealthCheck = false,
    required this.updatedAt,
  });

  factory MapPinModel.fromBowlMap(
    Map<String, dynamic> data, {
    required String id,
    List<CampusLandmark> landmarks = const [],
    DateTime? updatedAt,
  }) {
    final mapX = (data['mapX'] as num?)?.toDouble() ?? 0.5;
    final mapY = (data['mapY'] as num?)?.toDouble() ?? 0.5;
    final (detectedZoneId, detectedZoneName) = detectZone(mapX, mapY);
    final zoneId = (data['zoneId'] ?? detectedZoneId).toString();

    return MapPinModel(
      id: id,
      type: PinType.bowl,
      title: (data['title'] ?? 'Feeding Station').toString(),
      zoneId: zoneId,
      zoneName: (data['zone'] ?? zones[zoneId] ?? detectedZoneName).toString(),
      nearestLandmark: findNearestLandmark(mapX, mapY, landmarks),
      mapX: mapX,
      mapY: mapY,
      subtitle: (data['notes'] ?? '').toString(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static const String otherZoneId = 'other_feeding_areas';

  static const Map<String, String> zones = {
    'area_1': 'Area 1',
    'area_2': 'Area 2',
    'area_3': 'Area 3',
    'area_4': 'Area 4',
    'area_5': 'Area 5',
    otherZoneId: 'Other feeding areas',
  };

  /// Normalized (0.0–1.0) bounding boxes matching the 5 black borders on the map.
  static const List<_ZoneBounds> _areaBounds = [
    // Area 1: Top-Right (San Martin De Porres)
    _ZoneBounds(
      zoneId: 'area_1',
      minX: 0.660,
      minY: 0.106,
      maxX: 0.835,
      maxY: 0.326,
    ),
    // Area 2: Bottom-Left (BGPOP, UST Field, Beato Angelico, P. Noval Court)
    _ZoneBounds(
      zoneId: 'area_2',
      minX: 0.085,
      minY: 0.453,
      maxX: 0.386,
      maxY: 0.903,
    ),
    // Area 3: Top-Left (Botanical Garden, TARC, Church, Benavides Bldg, etc.)
    _ZoneBounds(
      zoneId: 'area_3',
      minX: 0.085,
      minY: 0.110,
      maxX: 0.376,
      maxY: 0.448,
    ),
    // Area 4: Top-Center (St. Raymunds Penafort, Library, Q-Park, Henry Sy, Tan Yan Kee)
    _ZoneBounds(
      zoneId: 'area_4',
      minX: 0.400,
      minY: 0.120,
      maxX: 0.656,
      maxY: 0.336,
    ),
    // Area 5: Bottom-Right (Roque Ruano, Quadricentennial Pavilion, Carpark, Gym, Albertus)
    _ZoneBounds(
      zoneId: 'area_5',
      minX: 0.583,
      minY: 0.518,
      maxX: 0.895,
      maxY: 0.903,
    ),
  ];

  static (String zoneId, String zoneName) detectZone(double x, double y) {
    for (final bounds in _areaBounds) {
      if (bounds.contains(x, y)) {
        return (bounds.zoneId, zones[bounds.zoneId]!);
      }
    }
    return (otherZoneId, zones[otherZoneId]!);
  }

  static String? findNearestLandmark(
    double x,
    double y,
    List<CampusLandmark> landmarks,
  ) {
    if (landmarks.isEmpty) return null;
    CampusLandmark? closest;
    double bestDistanceSquared = double.infinity;

    for (final landmark in landmarks) {
      final distanceX = landmark.mapX - x;
      final distanceY = landmark.mapY - y;
      final distanceSquared = (distanceX * distanceX) + (distanceY * distanceY);
      if (distanceSquared < bestDistanceSquared) {
        bestDistanceSquared = distanceSquared;
        closest = landmark;
      }
    }
    return closest?.name;
  }
}
