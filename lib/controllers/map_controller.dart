import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/map_pin_model.dart';
import '../models/pet_model.dart';
import '../utils/campus_map_landmark_constants.dart';

enum MapLayerFilter { all, bowls, cats }

class MapController extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  MapController({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  MapLayerFilter layerFilter = MapLayerFilter.all;
  String selectedZoneId = 'all';
  PinPlacementMode placementMode = PinPlacementMode.none;
  PinType newPinType = PinType.cat;
  MapPinModel? draftPin;

  bool isLoading = true;
  String? errorMessage;

  List<CampusLandmark> get landmarks => CampusMapLandmarkConstants.ustLandmarks;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _petsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _bowlsSub;

  final Map<String, PetModel> _verifiedPetsById = {};
  List<MapPinModel> _petPins = [];
  List<MapPinModel> _bowlPins = [];

  List<MapPinModel> get _allPins => [..._bowlPins, ..._petPins];

  List<MapPinModel> get filteredPins {
    return _allPins.where((pin) {
      final matchesLayer = switch (layerFilter) {
        MapLayerFilter.all => true,
        MapLayerFilter.bowls => pin.type == PinType.bowl,
        MapLayerFilter.cats => pin.type == PinType.cat,
      };
      final matchesZone =
          selectedZoneId == 'all' || pin.zoneId == selectedZoneId;
      return matchesLayer && matchesZone;
    }).toList();
  }

  List<MapPinModel> get healthCheckPins {
    return _petPins.where((pin) => pin.needsHealthCheck).toList();
  }

  PetModel? getPetById(String? petId) {
    if (petId == null) return null;
    return _verifiedPetsById[petId];
  }

  void startListening() {
    _petsSub?.cancel();
    _bowlsSub?.cancel();

    _petsSub = _firestore
        .collection('pets')
        .where('verificationStatus', isEqualTo: 'verified')
        .snapshots()
        .listen(
      (snapshot) {
        _verifiedPetsById.clear();
        final nextPetPins = <MapPinModel>[];

        for (final doc in snapshot.docs) {
          final pet = PetModel.fromMap(doc.data(), id: doc.id);
          _verifiedPetsById[doc.id] = pet;

          if (pet.mapX == null || pet.mapY == null) continue;

          final (detectedZoneId, detectedZoneName) =
              MapPinModel.detectZone(pet.mapX!, pet.mapY!);
          final resolvedZoneId =
              (pet.zoneId != null && pet.zoneId!.isNotEmpty)
                  ? pet.zoneId!
                  : detectedZoneId;
          final resolvedZoneName =
              MapPinModel.zones[resolvedZoneId] ?? detectedZoneName;
          final nearestLandmark = _resolveLandmarkName(pet) ??
              MapPinModel.findNearestLandmark(
                pet.mapX!,
                pet.mapY!,
                landmarks,
              );

          final lastSeen = pet.lastUpdated ?? pet.createdAt;
          final overdueCheck = lastSeen == null ||
              DateTime.now().difference(lastSeen).inDays >= 7;

          nextPetPins.add(
            MapPinModel(
              id: 'pet_${doc.id}',
              type: PinType.cat,
              title: pet.name,
              zoneId: resolvedZoneId,
              zoneName: resolvedZoneName,
              nearestLandmark: nearestLandmark,
              mapX: pet.mapX!,
              mapY: pet.mapY!,
              subtitle: pet.location,
              linkedPetId: doc.id,
              needsHealthCheck: overdueCheck,
              updatedAt: lastSeen ?? DateTime.now(),
            ),
          );
        }

        _petPins = nextPetPins;
        isLoading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (err) {
        isLoading = false;
        errorMessage = 'Failed to load verified pets: $err';
        notifyListeners();
      },
    );

    _bowlsSub = _firestore
        .collection('map_pins')
        .where('type', isEqualTo: 'bowl')
        .snapshots()
        .listen(
      (snapshot) {
        _bowlPins = snapshot.docs.map((doc) {
          final data = doc.data();
          final x = (data['mapX'] as num?)?.toDouble() ?? 0.5;
          final y = (data['mapY'] as num?)?.toDouble() ?? 0.5;
          final (zoneId, zoneName) = MapPinModel.detectZone(x, y);
          return MapPinModel(
            id: doc.id,
            type: PinType.bowl,
            title: (data['title'] ?? 'Feeding Station').toString(),
            zoneId: (data['zoneId'] ?? zoneId).toString(),
            zoneName: (data['zone'] ?? zoneName).toString(),
            nearestLandmark:
                MapPinModel.findNearestLandmark(x, y, landmarks),
            mapX: x,
            mapY: y,
            subtitle: (data['notes'] ?? '').toString(),
            updatedAt:
                (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList();
        notifyListeners();
      },
      onError: (err) {
        isLoading = false;
        errorMessage = 'Failed to load feeding stations: $err';
        notifyListeners();
      },
    );
  }

  String? _resolveLandmarkName(PetModel pet) {
    final landmarkId = pet.landmarkId;
    if (landmarkId == null || landmarkId.isEmpty) return null;
    for (final lm in landmarks) {
      if (lm.id == landmarkId) return lm.name;
    }
    return null;
  }

  Future<void> updatePetSighting({
    required String petId,
    required String location,
    required double mapX,
    required double mapY,
    required String zoneId,
    String landmarkId = '',
  }) async {
    await _firestore.collection('pets').doc(petId).update({
      'location': location.trim(),
      'mapX': mapX,
      'mapY': mapY,
      'zoneId': zoneId,
      'landmarkId': landmarkId,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addBowlStation({
    required double x,
    required double y,
    required String title,
    required String notes,
    required String updatedBy,
  }) async {
    final (zoneId, zoneName) = MapPinModel.detectZone(x, y);
    await _firestore.collection('map_pins').add({
      'type': PinType.bowl.name,
      'title': title.trim().isEmpty ? 'Feeding Station' : title.trim(),
      'zone': zoneName,
      'zoneId': zoneId,
      'mapX': x,
      'mapY': y,
      'notes': notes.trim(),
      'updatedBy': updatedBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    placementMode = PinPlacementMode.none;
    draftPin = null;
    notifyListeners();
  }

  void setLayerFilter(MapLayerFilter filter) {
    layerFilter = filter;
    notifyListeners();
  }

  void setZoneFilter(String zoneId) {
    selectedZoneId = zoneId;
    notifyListeners();
  }

  void togglePlacementMode({PinType? type}) {
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

  void updateDraftCoordinate(double x, double y) {
    final (zoneId, zoneName) = MapPinModel.detectZone(x, y);
    final landmark = MapPinModel.findNearestLandmark(x, y, landmarks);
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

  @override
  void dispose() {
    _petsSub?.cancel();
    _bowlsSub?.cancel();
    super.dispose();
  }
}