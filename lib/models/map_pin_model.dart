enum PinType { bowl,cat }

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
    required this.mapY
  });
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

  static const Map<String, String> zones = {
    'zone_1_nw' : 'Zone 1 | P. Noval - Dapitan',
    'zone_2_nc' : 'Zone 2 | Central North (Main & Library)',
    'zone_3_ne' : 'Zone 3 | Lacson - Dapitan (Hospital)',
    'zone_4_sw' : 'Zone 4 | P. Noval - Espana (Field & BGPOP)',
    'zone_5_sc' : 'Zone 5 | Central South (Benavides Garden)',
    'zone_6_se' : 'Zone 6 | Lacson - Espana (Carpark & Engineering)',
  };

  static (String zoneid, String zoneName) detectZone(double x, double y) {
    final isNorth = y < 0.5;

    if (x < 0.39) {
      return isNorth ? ('zone_1_nw', zones['zone_1_nw']!) : ('zone_4_sw', zones['zone_4_sw']!);
    } else if (x < 0.57) {
      return isNorth ? ('zone_2_nc', zones['zone_2_nc']!) : ('zone_5_sc', zones['zone_5_sc']!);
    } else {
      return isNorth ? ('zone_3_ne', zones['zone_3_ne']!) : ('zone_6_se', zones['zone_6_se']!);
    }
  }

  static String? findNearestLandmark(double x, double y, List<CampusLandmark> landmarks) {
    if (landmarks.isEmpty) return null;
    CampusLandmark? closest;
    double bestDistanceSquared = double.infinity; //classic minimization loop trust

    for (final landmark in landmarks ) {
      final distanceX = landmark.mapX - x;
      final distanceY = landmark.mapY - y;
      final distanceSquared = (distanceX * distanceX) + (distanceY * distanceY); //who cares about dart:math am I right?
      if (distanceSquared < bestDistanceSquared) {
        bestDistanceSquared = distanceSquared;
        closest = landmark;
      }
    }
    return closest?.name;
  }
}