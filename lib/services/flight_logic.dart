import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../models/site.dart';
import '../utils/unit_converter.dart';

// 6-state status: prime → soarable → marginal → caution → unflyable → storm
enum FlightStatus { prime, soarable, marginal, caution, unflyable, storm }

class TimelineHour {
  final int hour;
  final Color color;
  final FlightStatus status;
  final bool isPast;
  final bool isDirOptimal;
  final WeatherData? data;
  const TimelineHour({
    required this.hour,
    required this.color,
    required this.status,
    this.isPast = false,
    this.isDirOptimal = false,
    this.data,
  });
}

class FlightEvaluation {
  final FlightStatus status;
  final String primaryWord;     // e.g. "PRIME", "BLOWN", "CLAGGED", "STORM"
  final String secondaryReason; // e.g. "Direction & strength ideal", "Too strong"
  final int riskScore;          // 0–100 weighted penalty score
  final List<String> notes;
  final Color color;
  final int dirScore;
  final int speedScore;
  final int gustScore;
  final int rainScore;
  final int cloudScore;
  final int instabilityScore;
  final double angleDiff;
  final double effectiveWindMph;
  final List<TimelineHour> timeline;
  final double gustFactor;
  final double cloudbaseAgl;
  final double cloudbaseMsl;

  const FlightEvaluation({
    required this.status,
    required this.primaryWord,
    this.secondaryReason = '',
    this.riskScore = 0,
    this.notes = const [],
    required this.color,
    this.angleDiff = 0,
    this.effectiveWindMph = 0,
    this.timeline = const [],
    this.gustFactor = 1.0,
    this.cloudbaseAgl = 0,
    this.cloudbaseMsl = 0,
    this.dirScore = 0,
    this.speedScore = 0,
    this.gustScore = 0,
    this.rainScore = 0,
    this.cloudScore = 0,
    this.instabilityScore = 0,
  });

  // Backward compat: verdict used by build3DayForecastWidgets and detail screen
  String get verdict => secondaryReason.isNotEmpty
      ? '$primaryWord\n$secondaryReason'
      : primaryWord;
  String get label => primaryWord;
  String get reason => notes.isNotEmpty ? notes.join(', ') : primaryWord;
}

class FlightLogic {
  // ── Colours ──────────────────────────────────────────────────────────────

  // ── Legacy constants (kept for backward compat) ───────────────────────
  static const double minFlyableWindMph  = 5.0;
  static const double maxFlyableWindMph  = 20.0;
  static const double optimalWindMinMph  = 12.0;
  static const double optimalWindMaxMph  = 18.0;
  static const double maxFlyableGustsMph = 22.0;
  static const double optimalGustsMph    = 18.0;
  static const double hToMph             = 0.621371;

  static bool isWindSafe(double windMph, double gustMph) =>
      windMph >= minFlyableWindMph &&
      windMph <= maxFlyableWindMph &&
      gustMph <= maxFlyableGustsMph;

  static bool isWindSpeedSafe(double windKmh, double gustKmh) =>
      isWindSafe(windKmh * hToMph, gustKmh * hToMph);

  // ── Cloudbase ────────────────────────────────────────────────────────────
  /// Returns metres AGL above the measurement point (≈ above the site).
  static double calculateCloudbase(double tempC, double dewPointC) =>
      125.0 * (tempC - dewPointC);

  /// Returns cloudbase in metres MSL.
  static double calculateCloudbaseMsl(
          double tempC, double dewPointC, double siteElevationM) =>
      calculateCloudbase(tempC, dewPointC) + siteElevationM;

  // ── Terrain factor ───────────────────────────────────────────────────────
  static double calculateKzt(double takeoffHeight) {
    if (takeoffHeight < 150) return 1.15; // Coastal / Dune
    if (takeoffHeight < 500) return 1.35; // Valley / Low Hill
    return 1.25;                          // High Mountain (laminar)
  }

  /// Returns terrain-adjusted wind speed in km/h for display.
  static double terrainAdjustedKmh(double windKmh, double takeoffHeight) =>
      windKmh * calculateKzt(takeoffHeight);

  // ── 3-day forecast widgets ───────────────────────────────────────────────
  static List<Widget> build3DayForecastWidgets(
    List<WeatherData> forecastData,
    Site site,
  ) {
    final Map<String, List<WeatherData>> dailyData = {};
    for (var wd in forecastData) {
      if (wd.time.length >= 10) {
        dailyData.putIfAbsent(wd.time.substring(0, 10), () => []).add(wd);
      }
    }
    final sortedDays = dailyData.keys.toList()..sort();
    final List<Widget> widgets = [];
    for (int i = 1; i < sortedDays.length && widgets.length < 3; i++) {
      FlightEvaluation best = const FlightEvaluation(
        status: FlightStatus.unflyable,
        primaryWord: '',
        color: Colors.transparent,
      );
      for (var wd in dailyData[sortedDays[i]]!) {
        final h = int.tryParse(
                wd.time.contains('T')
                    ? wd.time.split('T')[1].split(':')[0]
                    : '0') ??
            0;
        if (h >= 8 && h <= 19) {
          final eval = evaluateCondition(wd, site);
          final isFlyable = eval.status == FlightStatus.prime ||
              eval.status == FlightStatus.soarable;
          final isMarginal = eval.status == FlightStatus.marginal ||
              eval.status == FlightStatus.caution;
          if (isFlyable) { best = eval; break; }
          if (isMarginal && best.status == FlightStatus.unflyable) { best = eval; }
        }
      }
      final dt = DateTime.parse(sortedDays[i]);
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      widgets.add(Text(
        '${days[dt.weekday - 1]}: ${best.primaryWord}',
        style: TextStyle(fontWeight: FontWeight.bold, color: best.color),
      ));
    }
    return widgets;
  }

  // ── Core evaluation ──────────────────────────────────────────────────────
  static Color getColorForSpeed(int roundedSpeed) {
    final bands = WindBandSettings.currentBands.value;
    final match = bands.where((b) => roundedSpeed >= b.min && roundedSpeed <= b.max).lastOrNull;
    return match?.color ?? Colors.white70; // Fallback to visible white instead of transparent
  }

  static FlightEvaluation evaluateCondition(WeatherData wd, Site site) {
    // Thresholds per difficulty
    final double minFly, optMin, optMax, maxFly, maxGusts, maxGF;
    switch (site.difficulty) {
      case SiteDifficulty.novice:
        minFly = 5.0;  optMin = 8.0;  optMax = 15.0;
        maxFly = 18.0; maxGusts = 20.0; maxGF = 1.5;
        break;
      case SiteDifficulty.advanced:
        minFly = 7.0;  optMin = 12.0; optMax = 22.0;
        maxFly = 26.0; maxGusts = 28.0; maxGF = 2.0;
        break;
      default: // intermediate
        minFly = 5.0;  optMin = 10.0; optMax = 18.0;
        maxFly = 22.0; maxGusts = 24.0; maxGF = 1.7;
        break;
    }

    // Wind calcs
    final double kzt       = calculateKzt(site.takeOffHeight.toDouble());
    final double speedMph  = (wd.windSpeed * hToMph) * kzt;
    final double gustMph   = (wd.windGusts  * hToMph) * kzt;
    final double gustFactor = speedMph > 0
        ? (gustMph / speedMph).clamp(1.0, 3.0)
        : 1.0;

    // Cloudbase (clearance above takeoff, corrected for MSL)
    final double cloudbaseAgl = calculateCloudbase(wd.temperature, wd.dewPoint);
    final double cloudbaseMsl = cloudbaseAgl + site.elevation;
    final double clearance    = cloudbaseMsl - site.takeOffHeight;

    // ── Pre-lookup Band for Color ───────────────────────────────────────
    // Round to match the UI precisely (e.g. 19.6 -> 20)
    final int speedR = speedMph.round();
    final int gustR  = gustMph.round();
    
    // Always use the most severe of speed or gust for the color stripe
    final int colorLookupSpeed = (gustR > maxGusts.round() || speedR > maxFly.round() || wd.precipitationProbability > 50) 
        ? math.max(speedR, gustR) 
        : speedR;
    
    // Wind Band Match (for labels) - using rounded speed to match UI
    final matchedBand = WindBandSettings.currentBands.value
        .where((b) => speedR >= b.min && speedR <= b.max)
        .lastOrNull;

    final colorBand = WindBandSettings.currentBands.value
        .where((b) => colorLookupSpeed >= b.min && colorLookupSpeed <= b.max)
        .lastOrNull; // Pick the most severe matching band (e.g. 20 matches 20-99 instead of 0-20)
    final Color bandColor = colorBand?.color ?? Colors.transparent;

    // ── Hard override: storm ────────────────────────────────────────────
    if (wd.weatherCode == 95 || wd.weatherCode == 96 || wd.weatherCode == 99 ||
        wd.cape > 1500 || wd.liftedIndex < -5) {
      return FlightEvaluation(
        status: FlightStatus.storm,
        primaryWord: matchedBand?.label ?? '',
        secondaryReason: '',
        riskScore: 100,
        notes: ['Storm risk'],
        color: bandColor,
        effectiveWindMph: speedMph,
        gustFactor: gustFactor,
        cloudbaseAgl: cloudbaseAgl,
        cloudbaseMsl: cloudbaseMsl,
      );
    }

    // ── Scoring (0–100) ──────────────────────────────────────────────────
    int score = 0;
    final List<String> notes = [];

    // Direction (0–35 pts)
    bool isDirectionOn = false;
    for (var range in site.optimalWindDirections) {
      if (_isWithin(wd.windDirection, range.min, range.max)) {
        isDirectionOn = true;
        break;
      }
    }

    final int dirScore;
    if (isDirectionOn) {
      dirScore = 0;
    } else {
      dirScore = 35;
      notes.add('Wind direction off (${UnitSettings.degreesToCompass(wd.windDirection)})');
    }
    score += dirScore;

    // Speed (0–30 pts)
    final int speedScore;
    if (speedMph < minFly) {
      speedScore = 30; notes.add('Too light');
    } else if (speedMph > maxFly) {
      speedScore = 30; notes.add('Too strong');
    } else if (speedMph < optMin) {
      speedScore = 8;  notes.add('Light winds');
    } else if (speedMph > optMax) {
      speedScore = 12; notes.add('Strong winds');
    } else {
      speedScore = 0;
    }
    score += speedScore;

    // Gusts (0–20 pts)
    final int gustScore;
    if (gustFactor > maxGF || gustMph > maxGusts) {
      gustScore = 20; notes.add('Dangerous gusts');
    } else if (gustFactor > maxGF * 0.85 || gustMph > maxGusts * 0.85) {
      gustScore = 10; notes.add('Gusty');
    } else if (gustFactor > 1.4) {
      gustScore = 5;  notes.add('Some gusts');
    } else {
      gustScore = 0;
    }
    score += gustScore;

    // Rain (0–15 pts)
    final int rainScore;
    if (wd.precipitation > 0.5 || wd.precipitationProbability > 50) {
      rainScore = 15; notes.add('Rain on site');
    } else if (wd.precipitation > 0.1 || wd.precipitationProbability > 30) {
      rainScore = 10; notes.add('Rain likely');
    } else if (wd.precipitationProbability > 10) {
      rainScore = 5;  notes.add('Rain possible');
    } else {
      rainScore = 0;
    }
    score += rainScore;

    // Cloudbase clearance (0–15 pts)
    final int cloudScore;
    if (clearance < 50) {
      cloudScore = 15; notes.add('Hill in cloud');
    } else if (clearance < 150) {
      cloudScore = 10; notes.add('Low ceiling');
    } else if (clearance < 300) {
      cloudScore = 5;  notes.add('Marginal ceiling');
    } else {
      cloudScore = 0;
    }
    score += cloudScore;

    // Instability (0–10 pts)
    final int instabilityScore;
    if (wd.cape > 1000 || wd.liftedIndex < -3) {
      instabilityScore = 10; notes.add('High instability');
    } else if (wd.cape > 500 || wd.liftedIndex < 0) {
      instabilityScore = 7;  notes.add('Unstable air');
    } else if (wd.cape > 200) {
      instabilityScore = 3;  notes.add('Some instability');
    } else {
      instabilityScore = 0;
    }
    score += instabilityScore;

    // Visibility (0–15 pts)
    final int visScore;
    if (wd.visibility < 1000) {
      visScore = 15; notes.add('Poor visibility');
    } else if (wd.visibility < 3000) {
      visScore = 8;  notes.add('Hazy');
    } else if (wd.visibility < 5000) {
      visScore = 3;
    } else {
      visScore = 0;
    }
    score += visScore;

    score = score.clamp(0, 100);

    // ── Priority Rules & Mapping ─────────────────────────────────────────
    FlightStatus status;
    String primaryWord;
    Color color;
    String secondaryReason = '';

    // 1. CLAGGED IN (Rule 3)
    if (cloudbaseMsl <= site.takeOffHeight) {
      status = FlightStatus.unflyable;
      primaryWord = 'CLAGGED IN';
      color = bandColor;
    }
    // 3. THUNDER & DANGEROUS GUSTS (Rule 4 + Safety)
    else if (instabilityScore >= 7 || gustScore >= 20) {
      status = (gustScore >= 20) ? FlightStatus.unflyable : FlightStatus.storm;
      primaryWord = (gustScore >= 20) ? (colorBand?.label ?? 'BLOWN OUT') : 'THUNDER RISK';
      color = bandColor;
    }
    // 4. FLYABLE RANGE (Rule 1: Wind <= 20mph)
    else if (speedMph <= 20) {
      // 5. RAIN RISK (Rule 2)
      if (wd.precipitationProbability > 50) {
        status = FlightStatus.marginal;
        primaryWord = matchedBand?.label ?? 'RAIN RISK';
        color = bandColor; 
      } 
      // 6. WINDOW GOOD
      else {
        // Respect direction/gusts even within speed range
        if (dirScore >= 35 || gustScore >= 12 || rainScore >= 15) {
          status = FlightStatus.caution;
          primaryWord = matchedBand?.label ?? 'CONCERN';
          color = bandColor;
        } else {
          status = score <= 15 ? FlightStatus.prime : FlightStatus.soarable;
          primaryWord = matchedBand?.label ?? 'GOOD';
          color = bandColor;
        }
      }
    }
    // 7. OVER LIMIT
    else {
      status = FlightStatus.unflyable;
      primaryWord = matchedBand?.label ?? 'TOO STRONG';
      color = bandColor;
    }

    return FlightEvaluation(
      status: status,
      primaryWord: primaryWord,
      secondaryReason: secondaryReason,
      riskScore: score,
      notes: notes,
      color: color,
      angleDiff: isDirectionOn ? 0.0 : 180.0,
      effectiveWindMph: speedMph,
      gustFactor: gustFactor,
      cloudbaseAgl: cloudbaseAgl,
      cloudbaseMsl: cloudbaseMsl,
      dirScore: dirScore,
      speedScore: speedScore,
      gustScore: gustScore,
      rainScore: rainScore,
      cloudScore: cloudScore,
      instabilityScore: instabilityScore,
    );
  }

  // ── Timeline ─────────────────────────────────────────────────────────────
  static List<TimelineHour> calculateTimeline(
    List<WeatherData> forecast,
    Site site,
    DateTime targetDate,
  ) {
    if (forecast.isEmpty) return [];
    
    // Attempt to get solar times from the first weather data point of the day
    final dayData = forecast.where((wd) => DateTime.parse(wd.time).day == targetDate.day).firstOrNull ?? forecast.first;
    double sunriseHour, sunsetHour;
    
    if (dayData.sunrise != null && dayData.sunset != null) {
      final sunR = DateTime.parse(dayData.sunrise!);
      final sunS = DateTime.parse(dayData.sunset!);
      sunriseHour = sunR.hour + (sunR.minute / 60.0);
      sunsetHour = sunS.hour + (sunS.minute / 60.0);
    } else {
      final (estSunrise, estSunset) = estimateSunTimes(targetDate, site.latitude, site.longitude);
      sunriseHour = estSunrise;
      sunsetHour = estSunset;
    }

    final int startHour = (sunriseHour - 1.5).floor();
    final int endHour   = (sunsetHour + 1.5).ceil();

    final Map<int, WeatherData> hourlyData = {};
    for (var wd in forecast) {
      final dt = DateTime.parse(wd.time);
      if (dt.year == targetDate.year &&
          dt.month == targetDate.month &&
          dt.day == targetDate.day) {
        hourlyData[dt.hour] = wd;
      }
    }

    final List<TimelineHour> timeline = [];
    final now = DateTime.now();
    for (int h = startHour; h <= endHour; h++) {
      final wd = hourlyData[h % 24];
      Color color = Colors.transparent;
      FlightStatus status = FlightStatus.unflyable;
      bool isDirOptimal = false;
      if (wd != null) {
        final eval = evaluateCondition(wd, site);
        // Always show color for listed hours
        color  = eval.color;
        status = eval.status;
        isDirOptimal = eval.dirScore == 0;
      }
      timeline.add(TimelineHour(
        hour: h % 24,
        color: color,
        status: status,
        isDirOptimal: isDirOptimal,
        isPast: h < now.hour &&
            targetDate.year  == now.year &&
            targetDate.month == now.month &&
            targetDate.day   == now.day,
        data: wd,
      ));
    }
    return timeline;
  }

  static bool isLegalFlyingHour(DateTime time, Site site, {WeatherData? wd}) {
    double sunriseHour, sunsetHour;
    if (wd != null && wd.sunrise != null && wd.sunset != null) {
      final sunR = DateTime.parse(wd.sunrise!);
      final sunS = DateTime.parse(wd.sunset!);
      sunriseHour = sunR.hour + (sunR.minute / 60.0);
      sunsetHour = sunS.hour + (sunS.minute / 60.0);
    } else {
      final (estSunrise, estSunset) = estimateSunTimes(time, site.latitude, site.longitude);
      sunriseHour = estSunrise;
      sunsetHour = estSunset;
    }
    final h = time.hour + (time.minute / 60.0);
    // Include the +/- 1.5 hour margin
    return h >= (sunriseHour - 1.5) && h <= (sunsetHour + 1.5);
  }

  static (double, double) estimateSunTimes(
      DateTime date, double lat, double lon) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final double phi   = lat * math.pi / 180;
    final double delta = 0.409 * math.sin(2 * math.pi / 365 * (dayOfYear - 81));
    double hArgs =
        (math.sin(-0.833 * math.pi / 180) - math.sin(phi) * math.sin(delta)) /
        (math.cos(phi) * math.cos(delta));
    hArgs = hArgs.clamp(-1.0, 1.0);
    final double hourAngle = math.acos(hArgs) * 180 / math.pi;
    final double b       = 2 * math.pi * (dayOfYear - 81) / 365;
    final double eqTime  =
        9.87 * math.sin(2 * b) - 7.53 * math.cos(b) - 1.5 * math.sin(b);
    final double solarNoon = 12.0 - (lon / 15.0) - (eqTime / 60.0);
    double sunrise = solarNoon - (hourAngle / 15.0);
    double sunset  = solarNoon + (hourAngle / 15.0);
    final bool isBST =
        (date.month > 3 && date.month < 10) ||
        (date.month == 3 &&
            date.day >= (31 - (DateTime(date.year, 3, 31).weekday % 7))) ||
        (date.month == 10 &&
            date.day < (31 - (DateTime(date.year, 10, 31).weekday % 7)));
    if (isBST) { sunrise += 1; sunset += 1; }
    return (sunrise, sunset);
  }

  static WeatherData getDayWeather(
      List<WeatherData> forecast, DateTime targetDate) {
    if (forecast.isEmpty) throw Exception('No forecast data');
    final now = DateTime.now();
    final isToday = targetDate.year  == now.year &&
                    targetDate.month == now.month &&
                    targetDate.day   == now.day;
    final targetHour = isToday ? now.hour : 12;
    for (var wd in forecast) {
      final dt = DateTime.parse(wd.time);
      if (dt.year  == targetDate.year &&
          dt.month == targetDate.month &&
          dt.day   == targetDate.day &&
          dt.hour  == targetHour) { return wd; }
    }
    for (var wd in forecast) {
      final dt = DateTime.parse(wd.time);
      if (dt.year  == targetDate.year &&
          dt.month == targetDate.month &&
          dt.day   == targetDate.day) { return wd; }
    }
    return forecast.first;
  }

  static WeatherData getCurrentWeather(List<WeatherData> forecast) =>
      getDayWeather(forecast, DateTime.now());

  // ── Helpers ───────────────────────────────────────────────────────────────
  /// Returns a blue gradient color based on rain probability (0-100).
  static Color getColorForRain(int probability) {
    final double p = (probability.clamp(0, 100)) / 100.0;
    return Color.lerp(
      Colors.lightBlueAccent,
      Colors.blue.shade800,
      p,
    )!;
  }

  static bool _isWithin(double dir, double min, double max) {
    double d = (dir % 360 + 360) % 360;
    double n = (min % 360 + 360) % 360;
    double x = (max % 360 + 360) % 360;
    if (n <= x) return d >= n && d <= x;
    return d >= n || d <= x;
  }
}
