enum SiteDifficulty { novice, intermediate, advanced }

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
  final int elevation; // metres MSL (used for API)
  final int takeOffHeight; // metres MSL (used for API)
  final int takeoffHeightFt; // feet MSL (for display)
  final List<WindDirectionRange> optimalWindDirections;
  final double faceDirection; // primary degrees the hill faces
  final SiteDifficulty difficulty;
  final String bhpaRating; // e.g. "CP", "Pilot"

  const Site({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.elevation,
    required this.takeOffHeight,
    required this.takeoffHeightFt,
    required this.optimalWindDirections,
    required this.faceDirection,
    this.difficulty = SiteDifficulty.intermediate,
    this.bhpaRating = 'CP',
  });
}
