import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/services/flight_logic.dart';
import 'package:weather_app/models/weather_data.dart';
import 'package:weather_app/models/site.dart';
import 'package:weather_app/utils/unit_converter.dart';
import 'package:weather_app/models/wind_band.dart';

void main() {
  group('FlightLogic Tests', () {
    final mockSite = Site(
      id: 'rhossili',
      name: 'Rhossili',
      latitude: 51.56,
      longitude: -4.29,
      elevation: 183,
      faceDirection: 270.0,
      bhpaRating: 'CP',
      optimalWindDirections: [
        WindDirectionRange(min: 240, max: 300),
      ],
      takeOffHeight: 130, // Coastal
      takeoffHeightFt: 600,
      difficulty: SiteDifficulty.intermediate,
    );

    WeatherData createMockData({
      double windSpeed = 23,
      double windDirection = 270,
      double precipitation = 0,
      double temp = 15,
      double dew = 5,
    }) {
      return WeatherData(
        time: '2024-03-20T12:00:00Z',
        temperature: temp,
        windSpeed: windSpeed,
        windGusts: windSpeed * 1.05,
        windDirection: windDirection,
        precipitationProbability: (precipitation > 0) ? 50 : 0,
        cloudCover: 20,
        dewPoint: dew,
        weatherCode: 0,
        precipitation: precipitation,
        visibility: 10000,
        relativeHumidity: 50,
        surfacePressure: 1013,
        uvIndex: 5,
        cape: 0,
        liftedIndex: 5,
      );
    }

    test('calculateCloudbase', () {
      expect(FlightLogic.calculateCloudbase(20, 10), 1250.0);
    });

    test('evaluateCondition - Custom Wind Bands (Label Match)', () {
      // Setup a custom band
      WindBandSettings.currentBands.value = [
        const WindBand(min: 10, max: 15, label: 'PERFECTO', color: Colors.green),
      ];
      
      // 20 kmh * 0.621371 * 1.15 = 14.29 mph (Falls in PERFECTO)
      final mockData = createMockData(windSpeed: 20, windDirection: 270);
      final eval = FlightLogic.evaluateCondition(mockData, mockSite);
      
      expect(eval.primaryWord, 'PERFECTO');
      expect(eval.color, Colors.green);
    });

    test('evaluateCondition - No Band Match (Blank Label)', () {
      // Setup bands that don't cover the speed
      WindBandSettings.currentBands.value = [
        const WindBand(min: 0, max: 5, label: 'LIGHT', color: Colors.grey),
      ];
      
      // 20 kmh * 0.621371 * 1.15 = 14.29 mph (None match)
      final mockData = createMockData(windSpeed: 20, windDirection: 270);
      final eval = FlightLogic.evaluateCondition(mockData, mockSite);
      
      expect(eval.primaryWord, '');
    });

    test('evaluateCondition - Blown Out (respects band if available)', () {
      // 50 km/h * 0.621 * 1.15 = 35.7 mph
      WindBandSettings.currentBands.value = [
        const WindBand(min: 30, max: 100, label: 'DANGER', color: Colors.red),
      ];
      final mockData = createMockData(windSpeed: 50, windDirection: 270);
      final eval = FlightLogic.evaluateCondition(mockData, mockSite);
      expect(eval.primaryWord, 'DANGER');
      
      // Reset
      WindBandSettings.currentBands.value = WindBandSettings.defaultBands;
    });

    test('calculateKzt Tiers', () {
      expect(FlightLogic.calculateKzt(100), 1.15); // Coastal
      expect(FlightLogic.calculateKzt(300), 1.35); // Hill
      expect(FlightLogic.calculateKzt(600), 1.25); // Mountain
    });
  });
}
