import '../models/site.dart';

const List<Site> walesSites = [
  Site(
    id: 'rhossili_upper',
    name: 'Rhossili Upper',
    latitude: 51.5686,
    longitude: -4.2869,
    elevation: 183, // 600ft
    takeOffHeight: 183,
    takeoffHeightFt: 600,
    faceDirection: 270.0,
    difficulty: SiteDifficulty.novice,
    bhpaRating: 'CP',
    optimalWindDirections: [
      WindDirectionRange(min: 250.0, max: 290.0, description: 'WSW-WNW (Main Ridge)'),
    ],
  ),
  Site(
    id: 'rhossili_lower',
    name: 'Rhossili Lower',
    latitude: 51.5735,
    longitude: -4.2912,
    elevation: 122, // 400ft
    takeOffHeight: 122,
    takeoffHeightFt: 400,
    faceDirection: 270.0,
    difficulty: SiteDifficulty.novice,
    bhpaRating: 'CP',
    optimalWindDirections: [
      WindDirectionRange(min: 250.0, max: 290.0, description: 'WSW-WNW (Main Ridge)'),
    ],
  ),
  Site(
    id: 'rhossili_cliffs',
    name: 'Rhossili Cliffs',
    latitude: 51.5620,
    longitude: -4.2980,
    elevation: 183, // 600ft
    takeOffHeight: 183,
    takeoffHeightFt: 600,
    faceDirection: 337.5,
    difficulty: SiteDifficulty.novice,
    bhpaRating: 'CP',
    optimalWindDirections: [
      WindDirectionRange(min: 315.0, max: 360.0, description: 'NW-N (Cliffs)'),
    ],
  ),
  Site(
    id: 'heol_senni',
    name: 'Heol Senni',
    latitude: 51.8825,
    longitude: -3.5813,
    elevation: 547, // 1795ft
    takeOffHeight: 547,
    takeoffHeightFt: 1795,
    faceDirection: 45.0,
    difficulty: SiteDifficulty.advanced,
    bhpaRating: 'CP',
    optimalWindDirections: [
      WindDirectionRange(min: 23.0, max: 70.0, description: 'NNE–ENE'),
    ],
  ),
  Site(
    id: 'abernant',
    name: 'Abernant',
    latitude: 51.8755,
    longitude: -4.4167,
    elevation: 350, // 1148ft
    takeOffHeight: 350,
    takeoffHeightFt: 1148,
    faceDirection: 90.0,
    difficulty: SiteDifficulty.intermediate,
    bhpaRating: 'CP',
    optimalWindDirections: [
      WindDirectionRange(min: 75.0, max: 105.0, description: 'E'),
    ],
  ),
  Site(
    id: 'bryncaws',
    name: 'Bryncaws',
    latitude: 51.7139,
    longitude: -3.7875,
    elevation: 352, // 1155ft
    takeOffHeight: 352,
    takeoffHeightFt: 1155,
    faceDirection: 112.0,
    difficulty: SiteDifficulty.intermediate,
    bhpaRating: 'CP',
    optimalWindDirections: [
      WindDirectionRange(min: 90.0, max: 135.0, description: 'E–SE'),
    ],
  ),
  Site(
    id: 'cwmafan',
    name: 'Cwmafan',
    latitude: 51.6140,
    longitude: -3.7664,
    elevation: 350, // 1148ft
    takeOffHeight: 350,
    takeoffHeightFt: 1148,
    faceDirection: 170.0,
    difficulty: SiteDifficulty.intermediate,
    bhpaRating: 'CP',
    optimalWindDirections: [
      WindDirectionRange(min: 135.0, max: 200.0, description: 'SE–SSW'),
    ],
  ),
  Site(
    id: 'cwmparc',
    name: 'Cwmparc',
    latitude: 51.6453,
    longitude: -3.5492,
    elevation: 490, // 1608ft
    takeOffHeight: 490,
    takeoffHeightFt: 1608,
    faceDirection: 40.0,
    difficulty: SiteDifficulty.intermediate,
    bhpaRating: 'CP',
    optimalWindDirections: [
      WindDirectionRange(min: 20.0, max: 60.0, description: 'NNE–ENE'),
    ],
  ),
  Site(
    id: 'fan_gyhirych',
    name: 'Fan Gyhirych',
    latitude: 51.8589,
    longitude: -3.6269,
    elevation: 698, // 2290ft
    takeOffHeight: 698,
    takeoffHeightFt: 2290,
    faceDirection: 315.0,
    difficulty: SiteDifficulty.advanced,
    bhpaRating: 'Pilot',
    optimalWindDirections: [
      WindDirectionRange(min: 220.0, max: 50.0, description: 'SW–NE'),
    ],
  ),
  Site(
    id: 'fan_hir',
    name: 'Fan Hir',
    latitude: 51.8680,
    longitude: -3.7080,
    elevation: 750, // 2460ft
    takeOffHeight: 750,
    takeoffHeightFt: 2460,
    faceDirection: 45.0,
    difficulty: SiteDifficulty.advanced,
    bhpaRating: 'Pilot',
    optimalWindDirections: [
      WindDirectionRange(min: 23.0, max: 70.0, description: 'NNE–E'),
    ],
  ),
  Site(
    id: 'ferryside',
    name: 'Ferryside',
    latitude: 51.7660,
    longitude: -4.3660,
    elevation: 91, // 300ft
    takeOffHeight: 91,
    takeoffHeightFt: 300,
    faceDirection: 255.0,
    difficulty: SiteDifficulty.novice,
    bhpaRating: 'CP',
    optimalWindDirections: [
      WindDirectionRange(min: 220.0, max: 290.0, description: 'SW–WNW'),
    ],
  ),
  Site(
    id: 'graig_fawr',
    name: 'Graig Fawr',
    latitude: 51.7465,
    longitude: -3.9954,
    elevation: 250, // 820ft
    takeOffHeight: 250,
    takeoffHeightFt: 820,
    faceDirection: 310.0,
    difficulty: SiteDifficulty.intermediate,
    bhpaRating: 'CP',
    optimalWindDirections: [
      WindDirectionRange(min: 290.0, max: 330.0, description: 'WNW–NNW'),
    ],
  ),
  Site(
    id: 'lletty_siac',
    name: 'Lletty Siac',
    latitude: 51.7200,
    longitude: -3.7800,
    elevation: 244, // 800ft
    takeOffHeight: 244,
    takeoffHeightFt: 800,
    faceDirection: 270.0,
    difficulty: SiteDifficulty.intermediate,
    bhpaRating: 'CP',
    optimalWindDirections: [
      WindDirectionRange(min: 250.0, max: 290.0, description: 'W–WNW'),
    ],
  ),
  Site(
    id: 'newgale',
    name: 'Newgale',
    latitude: 51.8510,
    longitude: -5.1320,
    elevation: 55, // 180ft
    takeOffHeight: 55,
    takeoffHeightFt: 180,
    faceDirection: 270.0,
    difficulty: SiteDifficulty.novice,
    bhpaRating: 'CP',
    optimalWindDirections: [
      WindDirectionRange(min: 260.0, max: 280.0, description: 'WSW–WNW'),
    ],
  ),
  Site(
    id: 'rhiw_wen',
    name: 'Rhiw Wen',
    latitude: 51.8480,
    longitude: -4.0170,
    elevation: 594, // 1950ft
    takeOffHeight: 594,
    takeoffHeightFt: 1950,
    faceDirection: 0.0,
    difficulty: SiteDifficulty.advanced,
    bhpaRating: 'CP',
    optimalWindDirections: [
      WindDirectionRange(min: 335.0, max: 25.0, description: 'NNW–NNE'),
    ],
  ),
  Site(
    id: 'seven_sisters',
    name: 'Seven Sisters',
    latitude: 51.7650,
    longitude: -3.7140,
    elevation: 396, // 1300ft
    takeOffHeight: 396,
    takeoffHeightFt: 1300,
    faceDirection: 335.0,
    difficulty: SiteDifficulty.intermediate,
    bhpaRating: 'CP',
    optimalWindDirections: [
      WindDirectionRange(min: 310.0, max: 360.0, description: 'NW–N'),
    ],
  ),
  Site(
    id: 'southerndown',
    name: 'Southerndown',
    latitude: 51.4460,
    longitude: -3.6130,
    elevation: 42, // 138ft
    takeOffHeight: 42,
    takeoffHeightFt: 138,
    faceDirection: 215.0,
    difficulty: SiteDifficulty.novice,
    bhpaRating: 'CP',
    optimalWindDirections: [
      WindDirectionRange(min: 200.0, max: 230.0, description: 'SW'),
    ],
  ),
];
