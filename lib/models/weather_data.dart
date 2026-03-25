class WeatherData {
  final String time;
  final double temperature;
  final double windSpeed; // km/h
  final double windGusts; // km/h
  final double windDirection; // degrees
  final int precipitationProbability;
  final int cloudCover; // %
  final double dewPoint; //
  final int weatherCode;
  final double precipitation; // mm
  final double visibility; // meters
  final int relativeHumidity; // %
  final double surfacePressure; // hPa/mbar
  final double uvIndex;
  final double cape; // J/kg
  final double liftedIndex; //
  final String? sunrise; // ISO string
  final String? sunset;  // ISO string

  WeatherData({
    required this.time,
    required this.temperature,
    required this.windSpeed,
    required this.windGusts,
    required this.windDirection,
    required this.precipitationProbability,
    required this.cloudCover,
    required this.dewPoint,
    required this.weatherCode,
    required this.precipitation,
    required this.visibility,
    required this.relativeHumidity,
    required this.surfacePressure,
    required this.uvIndex,
    required this.cape,
    required this.liftedIndex,
    this.sunrise,
    this.sunset,
  });
  factory WeatherData.fromJson(
    Map<String, dynamic> hourlyJson,
    int index, {
    String? sunrise,
    String? sunset,
  }) {
    return WeatherData(
      time: hourlyJson['time'][index],
      temperature: _toDouble(_getValue(hourlyJson, 'temperature_2m', index)),
      windSpeed: _toDouble(_getValue(hourlyJson, 'wind_speed_10m', index)),
      windGusts: _toDouble(_getValue(hourlyJson, 'wind_gusts_10m', index)),
      windDirection: _toDouble(
        _getValue(hourlyJson, 'wind_direction_10m', index),
      ),
      precipitationProbability: _toInt(
        _getValue(hourlyJson, 'precipitation_probability', index),
      ),
      cloudCover: _toInt(_getValue(hourlyJson, 'cloudcover', index)),
      dewPoint: _toDouble(_getValue(hourlyJson, 'dewpoint_2m', index)),
      weatherCode: _toInt(_getValue(hourlyJson, 'weathercode', index)),
      precipitation: _toDouble(_getValue(hourlyJson, 'precipitation', index)),
      visibility: _toDouble(_getValue(hourlyJson, 'visibility', index)),
      relativeHumidity: _toInt(
        _getValue(hourlyJson, 'relative_humidity_2m', index),
      ),
      surfacePressure: _toDouble(
        _getValue(hourlyJson, 'surface_pressure', index),
      ),
      uvIndex: _toDouble(_getValue(hourlyJson, 'uv_index', index)),
      cape: _toDouble(_getValue(hourlyJson, 'cape', index)),
      liftedIndex: _toDouble(_getValue(hourlyJson, 'lifted_index', index)),
      sunrise: sunrise,
      sunset: sunset,
    );
  }
  static dynamic _getValue(Map<String, dynamic> json, String key, int index) {
    // If the exact key exists, use it
    if (json.containsKey(key)) return json[key][index];
    // Otherwise look for keys that start with the prefix (e.g. temperature_2m_ecmwf_ifs)
    final actualKey = json.keys.firstWhere(
      (k) => k.startsWith(key),
      orElse: () => key,
    );
    return json[actualKey]?[index];
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    return (val is int) ? val.toDouble() : val as double;
  }

  static int _toInt(dynamic val) {
    if (val == null) return 0;
    return (val as int);
  }
}
