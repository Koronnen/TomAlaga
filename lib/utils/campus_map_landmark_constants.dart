import '../models/map_pin_model.dart';

class CampusMapLandmarkConstants {
  static const List<CampusLandmark> ustLandmarks = [
    // Area 1: San Martin De Porres
    CampusLandmark(id: 'lm_martin', name: 'St. Martin de Porres Building', zoneId: 'area_1', mapX: 0.73, mapY: 0.21),

    // Area 2: BGPOP
    CampusLandmark(id: 'lm_pnoval_court', name: 'P. Noval Court', zoneId: 'area_2', mapX: 0.13, mapY: 0.46),
    CampusLandmark(id: 'lm_bgpop', name: 'BGPOP', zoneId: 'area_2', mapX: 0.14, mapY: 0.57),
    CampusLandmark(id: 'lm_pool', name: 'Pool', zoneId: 'area_2', mapX: 0.14, mapY: 0.67),
    CampusLandmark(id: 'lm_beato', name: 'Beato Angelico Building', zoneId: 'area_2', mapX: 0.13, mapY: 0.83),
    CampusLandmark(id: 'lm_field', name: 'UST Field', zoneId: 'area_2', mapX: 0.28, mapY: 0.69),

    // Area 3: Botanical Garden, TARC
    CampusLandmark(id: 'lm_tarc', name: 'TARC', zoneId: 'area_3', mapX: 0.21, mapY: 0.16),
    CampusLandmark(id: 'lm_centlab', name: 'Central Laboratory', zoneId: 'area_3', mapX: 0.13, mapY: 0.25),
    CampusLandmark(id: 'lm_seminary', name: 'Seminary Grounds', zoneId: 'area_3', mapX: 0.13, mapY: 0.36),
    CampusLandmark(id: 'lm_benavides_bldg', name: 'Benavides Building', zoneId: 'area_3', mapX: 0.32, mapY: 0.24),
    CampusLandmark(id: 'lm_church', name: 'UST Church', zoneId: 'area_3', mapX: 0.24, mapY: 0.39),
    CampusLandmark(id: 'lm_botanical', name: 'Botanical Garden', zoneId: 'area_3', mapX: 0.35, mapY: 0.37),

    // Area 4: St. Raymunds Penafort
    CampusLandmark(id: 'lm_henry_sy', name: 'Henry Sy Sr. Hall', zoneId: 'area_4', mapX: 0.45, mapY: 0.15),
    CampusLandmark(id: 'lm_tan_yan_kee', name: 'Tan Yan Kee Building', zoneId: 'area_4', mapX: 0.52, mapY: 0.14),
    CampusLandmark(id: 'lm_library', name: 'Miguel de Benavides Library', zoneId: 'area_4', mapX: 0.48, mapY: 0.22),
    CampusLandmark(id: 'lm_qpark', name: 'Quadricentennial Park', zoneId: 'area_4', mapX: 0.48, mapY: 0.29),
    CampusLandmark(id: 'lm_raymund', name: 'St. Raymund Peñafort Bldg.', zoneId: 'area_4', mapX: 0.63, mapY: 0.25),

    // Area 5: Roque Ruano, Quadricentennial Pavilion
    CampusLandmark(id: 'lm_carpark', name: 'UST Carpark', zoneId: 'area_5', mapX: 0.67, mapY: 0.59),
    CampusLandmark(id: 'lm_gym', name: 'Practice Gym', zoneId: 'area_5', mapX: 0.67, mapY: 0.67),
    CampusLandmark(id: 'lm_pavilion', name: 'Quadricentennial Pavilion', zoneId: 'area_5', mapX: 0.67, mapY: 0.77),
    CampusLandmark(id: 'lm_albertus', name: 'Albertus Magnus Building', zoneId: 'area_5', mapX: 0.86, mapY: 0.61),
    CampusLandmark(id: 'lm_ruano', name: 'Roque Ruano Building', zoneId: 'area_5', mapX: 0.86, mapY: 0.80),

    // Other feeding areas (outside all five red outlined zones)
    CampusLandmark(id: 'lm_main', name: 'Main Building', zoneId: 'other_feeding_areas', mapX: 0.48, mapY: 0.40),
    CampusLandmark(id: 'lm_rosarium', name: 'Rosarium', zoneId: 'other_feeding_areas', mapX: 0.63, mapY: 0.39),
    CampusLandmark(id: 'lm_health', name: 'Health Service', zoneId: 'other_feeding_areas', mapX: 0.62, mapY: 0.46),
    CampusLandmark(id: 'lm_hospital', name: 'UST Hospital', zoneId: 'other_feeding_areas', mapX: 0.73, mapY: 0.41),
    CampusLandmark(id: 'lm_hosp_clin', name: 'UST Hospital Clinical Division', zoneId: 'other_feeding_areas', mapX: 0.87, mapY: 0.21),
    CampusLandmark(id: 'lm_hosp_ext', name: 'UST Hospital Extension Bldg.', zoneId: 'other_feeding_areas', mapX: 0.87, mapY: 0.40),
    CampusLandmark(id: 'lm_plaza_mayor', name: 'Plaza Mayor', zoneId: 'other_feeding_areas', mapX: 0.48, mapY: 0.51),
    CampusLandmark(id: 'lm_benavides_garden', name: 'Benavides Garden', zoneId: 'other_feeding_areas', mapX: 0.48, mapY: 0.70),
  ];
}