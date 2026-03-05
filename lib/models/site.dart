class WindDirectionRange {
  final double min; // degrees
  final double max; // degrees
  final String description;
  const WindDirectionRange({
    required this.min,
    required this.max,
    this.description = '',
  });
}

class Site {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int elevation; // meters
  final int takeOffHeight; // meters (often same as elevation)
  final List<WindDirectionRange> optimalWindDirections;
  final double faceDirection; // primary degrees the hill faces
  const Site({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.elevation,
    required this.takeOffHeight,
    required this.optimalWindDirections,
    required this.faceDirection,
  });
}

const List<Site> walesSites = [
  Site(
    id: 'rhossili',
    name: 'Rhossili',
    latitude: 51.5686,
    longitude: -4.2869,
    elevation: 122,
    takeOffHeight: 122,
    faceDirection: 270.0, // West
    optimalWindDirections: [
      WindDirectionRange(
        min: 247.5,
        max: 292.5,
        description: 'WSW-WNW (Main Ridge)',
      ),
      WindDirectionRange(min: 315.0, max: 360.0, description: 'NW-N (Cliffs)'),
    ],
  ),
  Site(
    id: 'heol_senni_fan_bwlch_chwyth',
    name: 'Heol Senni',
    latitude: 51.8825,
    longitude: -3.5813,
    elevation: 505,
    takeOffHeight: 505,
    faceDirection: 45.0, // NE
    optimalWindDirections: [
      WindDirectionRange(min: 15.0, max: 85.0, description: 'NNE to ENE'),
    ],
  ),
  Site(
    id: 'abernant',
    name: 'Abernant',
    latitude: 51.8755,
    longitude: -4.4167,
    elevation: 350,
    takeOffHeight: 350,
    faceDirection: 90.0, // E
    optimalWindDirections: [
      WindDirectionRange(min: 67.5, max: 112.5, description: 'E'),
    ],
  ),
  Site(
    id: 'bryncaws',
    name: 'Bryncaws',
    latitude: 51.7139,
    longitude: -3.7875,
    elevation: 418,
    takeOffHeight: 418,
    faceDirection: 112.0, // ESE
    optimalWindDirections: [
      WindDirectionRange(min: 67.5, max: 157.5, description: 'E-SE'),
    ],
  ),
  Site(
    id: 'cwmafan',
    name: 'Cwmafan',
    latitude: 51.6140,
    longitude: -3.7664,
    elevation: 350,
    takeOffHeight: 350,
    faceDirection: 170.0, // S
    optimalWindDirections: [
      WindDirectionRange(min: 135.0, max: 202.5, description: 'SE-SSW'),
    ],
  ),
  Site(
    id: 'cwmparc',
    name: 'Cwmparc',
    latitude: 51.6453,
    longitude: -3.5492,
    elevation: 488,
    takeOffHeight: 488,
    faceDirection: 45.0, // NE
    optimalWindDirections: [
      WindDirectionRange(min: 22.5, max: 67.5, description: 'NNE-ENE'),
    ],
  ),
  Site(
    id: 'fan_gyhirych',
    name: 'Fan Gyhirych',
    latitude: 51.8589,
    longitude: -3.6269,
    elevation: 722,
    takeOffHeight: 722,
    faceDirection: 315.0, // NW
    optimalWindDirections: [
      WindDirectionRange(min: 225.0, max: 45.0, description: 'SW-W-NW-NE'),
    ],
  ),
  Site(
    id: 'fan_hir',
    name: 'Fan Hir',
    latitude: 51.8680,
    longitude: -3.7080,
    elevation: 750,
    takeOffHeight: 750,
    faceDirection: 67.0, // ENE
    optimalWindDirections: [
      WindDirectionRange(min: 22.5, max: 112.5, description: 'NNE-E'),
    ],
  ),
  Site(
    id: 'ferryside',
    name: 'Ferryside',
    latitude: 51.7660,
    longitude: -4.3660,
    elevation: 91,
    takeOffHeight: 91,
    faceDirection: 260.0, // W
    optimalWindDirections: [
      WindDirectionRange(min: 225.0, max: 292.5, description: 'SW-WNW'),
    ],
  ),
  Site(
    id: 'graig_fawr',
    name: 'Graig Fawr',
    latitude: 51.7465,
    longitude: -3.9954,
    elevation: 250,
    takeOffHeight: 250,
    faceDirection: 315.0, // NW
    optimalWindDirections: [
      WindDirectionRange(min: 292.5, max: 337.5, description: 'WNW-NNW'),
    ],
  ),
  Site(
    id: 'lletty_siac',
    name: 'Lletty Siac',
    latitude: 51.7200,
    longitude: -3.7800,
    elevation: 244,
    takeOffHeight: 244,
    faceDirection: 280.0, // WNW
    optimalWindDirections: [
      WindDirectionRange(min: 270.0, max: 292.5, description: 'W-WNW'),
    ],
  ),
  Site(
    id: 'newgale',
    name: 'Newgale',
    latitude: 51.8510,
    longitude: -5.1320,
    elevation: 43,
    takeOffHeight: 43,
    faceDirection: 270.0, // W
    optimalWindDirections: [
      WindDirectionRange(min: 247.5, max: 292.5, description: 'WSW-WNW'),
    ],
  ),
  Site(
    id: 'rhiw_wen',
    name: 'Rhiw Wen',
    latitude: 51.8480,
    longitude: -4.0170,
    elevation: 594,
    takeOffHeight: 594,
    faceDirection: 0.0, // N
    optimalWindDirections: [
      WindDirectionRange(min: 337.5, max: 22.5, description: 'NNW-NNE'),
    ],
  ),
  Site(
    id: 'seven_sisters',
    name: 'Seven Sisters',
    latitude: 51.7650,
    longitude: -3.7140,
    elevation: 396,
    takeOffHeight: 396,
    faceDirection: 335.0, // NNW
    optimalWindDirections: [
      WindDirectionRange(min: 315.0, max: 360.0, description: 'NW-N'),
    ],
  ),
  Site(
    id: 'southerndown',
    name: 'Southerndown',
    latitude: 51.4460,
    longitude: -3.6130,
    elevation: 42,
    takeOffHeight: 42,
    faceDirection: 225.0, // SW
    optimalWindDirections: [
      WindDirectionRange(min: 202.5, max: 247.5, description: 'SW'),
    ],
  ),
];
