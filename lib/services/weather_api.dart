import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/site.dart';
import '../models/weather_data.dart';
import '../utils/unit_converter.dart';

class WeatherApi {
  static const String baseUrl = 'https://api.open-meteo.com/v1/forecast';
  // Cache to store forecasts to prevent redundant calls and handle 429s.
  static final Map<String, List<WeatherData>> _cache = {};
  static DateTime? _lastFetchTime;
  static void clearCache() {
    _cache.clear();
    _lastFetchTime = null;
  }

  Future<List<WeatherData>> fetchForecast(Site site) async {
    final result = await fetchForecastBatch([site]);
    return result[site.id] ?? [];
  }

  Future<Map<String, List<WeatherData>>> fetchForecastBatch(
    List<Site> sites,
  ) async {
    if (sites.isEmpty) return {};
    // Check if we have a fresh cache for ALL requested sites
    bool allCached = true;
    for (var site in sites) {
      if (!_cache.containsKey(site.id)) {
        allCached = false;
        break;
      }
    }
    // Cache is valid for 10 minutes to prevent API spamming
    if (allCached &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 10) {
      return Map.fromEntries(sites.map((s) => MapEntry(s.id, _cache[s.id]!)));
    }
    final model = WeatherSettings.selectedModel.value.apiValue;
    final modelParam = '&models=${model ?? 'ukmo_seamless'}';
    // Construct batched comma-separated coordinates
    final lats = sites.map((s) => s.latitude).join(',');
    final lons = sites.map((s) => s.longitude).join(',');
    final uri = Uri.parse(
      '$baseUrl?latitude=$lats&longitude=$lons'
      '&hourly=temperature_2m,precipitation_probability,cloudcover,wind_speed_10m,wind_direction_10m,wind_gusts_10m,dewpoint_2m,weathercode,precipitation,visibility,relative_humidity_2m,surface_pressure,uv_index,cape,lifted_index'
      '&daily=sunrise,sunset'
      '&timezone=Europe%2FLondon$modelParam',
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final now = DateTime.now();
      _lastFetchTime = now;
      Map<String, List<WeatherData>> results = {};
      // Open-Meteo returns an ARRAY of responses if multiple locations are requested
      if (json is List) {
        for (int s = 0; s < sites.length; s++) {
          final hourly = json[s]['hourly'];
          final daily = json[s]['daily'];
          results[sites[s].id] = _parseHourly(hourly, daily, now);
          _cache[sites[s].id] = results[sites[s].id]!;
        }
      } else {
        // Single location response returns a JSON object
        final hourly = json['hourly'];
        final daily = json['daily'];
        results[sites[0].id] = _parseHourly(hourly, daily, now);
        _cache[sites[0].id] = results[sites[0].id]!;
      }
      return results;
    } else {
      throw Exception('Failed to load weather data: ${response.statusCode}');
    }
  }

  List<WeatherData> _parseHourly(dynamic hourly, dynamic daily, DateTime now) {
    if (hourly == null) return [];
    final List<dynamic> times = hourly['time'];
    
    // Create a map of date -> {sunrise, sunset}
    final Map<String, Map<String, String>> dailySolar = {};
    if (daily != null && daily['time'] != null) {
      final List<dynamic> dTimes = daily['time'];
      final List<dynamic> dSunrise = daily['sunrise'];
      final List<dynamic> dSunset = daily['sunset'];
      for (int i = 0; i < dTimes.length; i++) {
        dailySolar[dTimes[i]] = {
          'sunrise': dSunrise[i],
          'sunset': dSunset[i],
        };
      }
    }

    List<WeatherData> forecasts = [];
    for (int i = 0; i < times.length; i++) {
      try {
        final timeStr = times[i] as String;
        final dateKey = timeStr.substring(0, 10);
        final solar = dailySolar[dateKey];

        final data = WeatherData.fromJson(
          hourly, 
          i,
          sunrise: solar?['sunrise'],
          sunset: solar?['sunset'],
        );
        final dataTime = DateTime.parse(data.time);
        // Include all data for the current day (starting from 00:00)
        // and all future data.
        final midnightToday = DateTime(now.year, now.month, now.day);
        if (dataTime.isAfter(
          midnightToday.subtract(const Duration(seconds: 1)),
        )) {
          forecasts.add(data);
        }
      } catch (e) {
        // Skip malformed entries
      }
    }
    return forecasts;
  }
}
