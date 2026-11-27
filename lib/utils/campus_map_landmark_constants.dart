import '../models/map_pin_model.dart';

class CampusMapLandmarkConstants {
  static const List<CampusLandmark> ustLandmarks = [
    // Zone 1: Northwest (P. Noval – Dapitan)
    CampusLandmark(id: 'lm_tarc', name: 'TARC', zoneId: 'zone_1_nw', mapX: 0.21, mapY: 0.16),
    CampusLandmark(id: 'lm_centlab', name: 'Central Laboratory', zoneId: 'zone_1_nw', mapX: 0.13, mapY: 0.25),
    CampusLandmark(id: 'lm_seminary', name: 'Seminary Grounds', zoneId: 'zone_1_nw', mapX: 0.13, mapY: 0.36),
    CampusLandmark(id: 'lm_pnoval_court', name: 'P. Noval Court', zoneId: 'zone_1_nw', mapX: 0.13, mapY: 0.46),
    CampusLandmark(id: 'lm_benavides_bldg', name: 'Benavides Building', zoneId: 'zone_1_nw', mapX: 0.32, mapY: 0.24),
    CampusLandmark(id: 'lm_church', name: 'UST Church', zoneId: 'zone_1_nw', mapX: 0.24, mapY: 0.39),
    CampusLandmark(id: 'lm_botanical', name: 'Botanical Garden', zoneId: 'zone_1_nw', mapX: 0.35, mapY: 0.37),

    // Zone 2: North-Central (Dapitan Center)
    CampusLandmark(id: 'lm_henry_sy', name: 'Henry Sy Sr. Hall', zoneId: 'zone_2_nc', mapX: 0.45, mapY: 0.15),
    CampusLandmark(id: 'lm_tan_yan_kee', name: 'Tan Yan Kee Building', zoneId: 'zone_2_nc', mapX: 0.52, mapY: 0.14),
    CampusLandmark(id: 'lm_library', name: 'Miguel de Benavides Library', zoneId: 'zone_2_nc', mapX: 0.48, mapY: 0.22),
    CampusLandmark(id: 'lm_qpark', name: 'Quadricentennial Park', zoneId: 'zone_2_nc', mapX: 0.48, mapY: 0.29),
    CampusLandmark(id: 'lm_main', name: 'Main Building', zoneId: 'zone_2_nc', mapX: 0.48, mapY: 0.40),

    // Zone 3: Northeast (Lacson – Dapitan)
    CampusLandmark(id: 'lm_raymund', name: 'St. Raymund Peñafort Bldg.', zoneId: 'zone_3_ne', mapX: 0.63, mapY: 0.25),
    CampusLandmark(id: 'lm_martin', name: 'St. Martin de Porres Building', zoneId: 'zone_3_ne', mapX: 0.73, mapY: 0.21),
    CampusLandmark(id: 'lm_rosarium', name: 'Rosarium', zoneId: 'zone_3_ne', mapX: 0.63, mapY: 0.39),
    CampusLandmark(id: 'lm_health', name: 'Health Service', zoneId: 'zone_3_ne', mapX: 0.62, mapY: 0.46),
    CampusLandmark(id: 'lm_hospital', name: 'UST Hospital', zoneId: 'zone_3_ne', mapX: 0.73, mapY: 0.41),
    CampusLandmark(id: 'lm_hosp_clin', name: 'UST Hospital Clinical Division', zoneId: 'zone_3_ne', mapX: 0.87, mapY: 0.21),
    CampusLandmark(id: 'lm_hosp_ext', name: 'UST Hospital Extension Bldg.', zoneId: 'zone_3_ne', mapX: 0.87, mapY: 0.40),

    // Zone 4: Southwest (P. Noval – España)
    CampusLandmark(id: 'lm_bgpop', name: 'BGPOP', zoneId: 'zone_4_sw', mapX: 0.14, mapY: 0.57),
    CampusLandmark(id: 'lm_pool', name: 'Pool', zoneId: 'zone_4_sw', mapX: 0.14, mapY: 0.67),
    CampusLandmark(id: 'lm_beato', name: 'Beato Angelico Building', zoneId: 'zone_4_sw', mapX: 0.13, mapY: 0.83),
    CampusLandmark(id: 'lm_field', name: 'UST Field', zoneId: 'zone_4_sw', mapX: 0.28, mapY: 0.69),

    // Zone 5: South-Central (España Center)
    CampusLandmark(id: 'lm_plaza_mayor', name: 'Plaza Mayor', zoneId: 'zone_5_sc', mapX: 0.48, mapY: 0.51),
    CampusLandmark(id: 'lm_benavides_garden', name: 'Benavides Garden', zoneId: 'zone_5_sc', mapX: 0.48, mapY: 0.70),

    // Zone 6: Southeast (Lacson – España)
    CampusLandmark(id: 'lm_carpark', name: 'UST Carpark', zoneId: 'zone_6_se', mapX: 0.67, mapY: 0.59),
    CampusLandmark(id: 'lm_gym', name: 'Practice Gym', zoneId: 'zone_6_se', mapX: 0.67, mapY: 0.67),
    CampusLandmark(id: 'lm_pavilion', name: 'Quadricentennial Pavilion', zoneId: 'zone_6_se', mapX: 0.67, mapY: 0.77),
    CampusLandmark(id: 'lm_albertus', name: 'Albertus Magnus Building', zoneId: 'zone_6_se', mapX: 0.86, mapY: 0.61),
    CampusLandmark(id: 'lm_ruano', name: 'Roque Ruano Building', zoneId: 'zone_6_se', mapX: 0.86, mapY: 0.80),
];
}