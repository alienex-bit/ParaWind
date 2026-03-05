import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SpeedUnit { kph, mph, knots, mps }

enum DistanceUnit { km, miles }

enum HeightUnit { meters, feet }

enum PressureUnit { hpa, mbar }

enum WeatherModel { ukv, ecmwf, icon }

extension WeatherModelExtension on WeatherModel {
  String get displayName {
    switch (this) {
      case WeatherModel.ukv:
        return 'UKV - Launch wind detail';
      case WeatherModel.ecmwf:
        return 'ECMWF - Big picture flow';
      case WeatherModel.icon:
        return 'ICON - Second opinion check';
    }
  }

  String get shortName {
    switch (this) {
      case WeatherModel.ukv:
        return 'UKV';
      case WeatherModel.ecmwf:
        return 'ECMWF';
      case WeatherModel.icon:
        return 'ICON';
    }
  }

  String? get apiValue {
    switch (this) {
      case WeatherModel.ukv:
        return 'ukmo_seamless';
      case WeatherModel.ecmwf:
        return 'ecmwf_ifs';
      case WeatherModel.icon:
        return 'icon_seamless';
    }
  }
}

class UnitSettings {
  static final ValueNotifier<SpeedUnit> selectedUnit = ValueNotifier<SpeedUnit>(
    SpeedUnit.mph,
  );
  static final ValueNotifier<DistanceUnit> selectedDistanceUnit =
      ValueNotifier<DistanceUnit>(DistanceUnit.miles);
  static final ValueNotifier<HeightUnit> selectedHeightUnit =
      ValueNotifier<HeightUnit>(HeightUnit.feet);
  static final ValueNotifier<PressureUnit> selectedPressureUnit =
      ValueNotifier<PressureUnit>(PressureUnit.hpa);
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // Speed
    final savedSpeed = prefs.getInt('speed_unit') ?? SpeedUnit.mph.index;
    if (savedSpeed >= 0 && savedSpeed < SpeedUnit.values.length) {
      selectedUnit.value = SpeedUnit.values[savedSpeed];
    }
    selectedUnit.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('speed_unit', selectedUnit.value.index);
    });
    // Distance
    final savedDist = prefs.getInt('distance_unit') ?? DistanceUnit.miles.index;
    if (savedDist >= 0 && savedDist < DistanceUnit.values.length) {
      selectedDistanceUnit.value = DistanceUnit.values[savedDist];
    }
    selectedDistanceUnit.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('distance_unit', selectedDistanceUnit.value.index);
    });
    // Height
    final savedHeight = prefs.getInt('height_unit') ?? HeightUnit.feet.index;
    if (savedHeight >= 0 && savedHeight < HeightUnit.values.length) {
      selectedHeightUnit.value = HeightUnit.values[savedHeight];
    }
    selectedHeightUnit.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('height_unit', selectedHeightUnit.value.index);
    });
    // Pressure
    final savedPressure =
        prefs.getInt('pressure_unit') ?? PressureUnit.hpa.index;
    if (savedPressure >= 0 && savedPressure < PressureUnit.values.length) {
      selectedPressureUnit.value = PressureUnit.values[savedPressure];
    }
    selectedPressureUnit.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pressure_unit', selectedPressureUnit.value.index);
    });
  }

  static double convertKmh(double kmh) {
    switch (selectedUnit.value) {
      case SpeedUnit.mph:
        return kmh * 0.621371;
      case SpeedUnit.knots:
        return kmh * 0.539957;
      case SpeedUnit.mps:
        return kmh / 3.6;
      case SpeedUnit.kph:
        return kmh;
    }
  }

  static String get unitString {
    switch (selectedUnit.value) {
      case SpeedUnit.mph:
        return 'mph';
      case SpeedUnit.knots:
        return 'kts';
      case SpeedUnit.mps:
        return 'm/s';
      case SpeedUnit.kph:
        return 'km/h';
    }
  }

  static double convertDistance(double km) {
    if (selectedDistanceUnit.value == DistanceUnit.miles) {
      return km * 0.621371;
    }
    return km;
  }

  static String get distanceUnitString =>
      selectedDistanceUnit.value == DistanceUnit.miles ? 'mi' : 'km';
  static double convertHeight(double meters) {
    if (selectedHeightUnit.value == HeightUnit.feet) {
      return meters * 3.28084;
    }
    return meters;
  }

  static String get heightUnitString =>
      selectedHeightUnit.value == HeightUnit.feet ? 'ft' : 'm';
  static double convertPressure(double hpa) {
    // hPa and mbar are actually 1:1, but keeping the logic for consistency
    return hpa;
  }

  static String degreesToCompass(double degrees) {
    return compassPoints[((degrees % 360) / 22.5).round() % 16];
  }

  static double compassToDegrees(String direction) {
    int index = compassPoints.indexOf(direction.toUpperCase());
    if (index == -1) return 0.0;
    return index * 22.5;
  }

  static const List<String> compassPoints = [
    'N',
    'NNE',
    'NE',
    'ENE',
    'E',
    'ESE',
    'SE',
    'SSE',
    'S',
    'SSW',
    'SW',
    'WSW',
    'W',
    'WNW',
    'NW',
    'NNW',
  ];

  static const List<String> cloudCoverOctas = [
    '0/8 (Clear)',
    '1/8 (Few)',
    '2/8 (Few)',
    '3/8 (Scattered)',
    '4/8 (Scattered)',
    '5/8 (Broken)',
    '6/8 (Broken)',
    '7/8 (Broken)',
    '8/8 (Overcast)',
  ];

  static String get pressureUnitString =>
      selectedPressureUnit.value == PressureUnit.hpa ? 'hPa' : 'mbar';
}

class ThemeSettings {
  static final ValueNotifier<ThemeMode> selectedTheme =
      ValueNotifier<ThemeMode>(ThemeMode.dark);
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt('theme_mode') ?? ThemeMode.dark.index;
    if (idx >= 0 && idx < ThemeMode.values.length) {
      selectedTheme.value = ThemeMode.values[idx];
    }
    selectedTheme.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', selectedTheme.value.index);
    });
  }
}

class WeatherSettings {
  static final ValueNotifier<WeatherModel> selectedModel =
      ValueNotifier<WeatherModel>(WeatherModel.ukv);
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt('weather_model') ?? WeatherModel.ukv.index;
    if (idx >= 0 && idx < WeatherModel.values.length) {
      selectedModel.value = WeatherModel.values[idx];
    }
    selectedModel.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('weather_model', selectedModel.value.index);
    });
  }
}
