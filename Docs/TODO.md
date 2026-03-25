# TODO — Static Analysis Issues

Generated: 2026-03-24

---

## Priority 1 — Bugs / Incorrect Behaviour

### [P1-A] `ai_service.dart` L162–165 — Wrong unit label on AI context data
**Severity: High**
`wd.windSpeed`/`wd.windGusts` are always in km/h (Open-Meteo native) but are injected into the AI prompt alongside `UnitSettings.unitString` (e.g. "mph"). The AI receives e.g. "12.5 mph" when the value is 12.5 km/h.

**Fix:** Wrap values in `UnitSettings.convertKmh()` before building the prompt string:
```dart
buffer.writeln(
  "  * Wind: ${UnitSettings.convertKmh(wd.windSpeed).toStringAsFixed(1)} ${UnitSettings.unitString} from ${UnitSettings.degreesToCompass(wd.windDirection)}",
);
buffer.writeln(
  "  * Gusts: ${UnitSettings.convertKmh(wd.windGusts).toStringAsFixed(1)} ${UnitSettings.unitString}",
);
```

---

### [P1-B] `weather_data.dart` L82 — Unsafe `int` cast crashes on double API values
**Severity: High**
`(val as int)` throws a `TypeError` if Open-Meteo returns `12.0` instead of `12` for integer fields (`precipitationProbability`, `cloudCover`, `relativeHumidity`, `weatherCode`). Silently swallowed in `_parseHourly`, resulting in missing forecast data.

**Fix:**
```dart
static int _toInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  if (val is double) return val.toInt();
  return int.tryParse(val.toString()) ?? 0;
}
```

---

### [P1-C] `main.dart` L27 — Custom `kIsWeb` shadows Flutter's, may be wrong on Dart 3+
**Severity: High**
`const kIsWeb = bool.fromEnvironment('dart.library.js_util')` is defined locally, shadowing Flutter's built-in `kIsWeb` (from `package:flutter/foundation.dart`). On Dart 3+, Flutter uses `dart.library.js_interop`, so this custom version may return `false` on web, preventing Firebase web initialisation.

**Fix:** Delete line 27 entirely. Flutter's `kIsWeb` is already available via `package:flutter/material.dart`.

---

### [P1-D] `daily_summary_screen.dart` L23/55 — `_errorMessage` not cleared on successful retry
**Severity: Medium**
`_errorMessage` is set in the `catch` block but never cleared in the `try` success path. After a failure, pulling to refresh and succeeding still shows the error banner.

**Fix:** Add `_errorMessage = ''` at the start of `_fetchData`:
```dart
setState(() {
  _isLoading = true;
  _aiSummary = '';
  _errorMessage = '';  // add this line
});
```

---

### [P1-E] `home_screen.dart` L91 — API errors silently swallowed, no user feedback
**Severity: Medium**
`snapshot.data ?? {}` returns an empty map on error. `snapshot.hasError` is never checked, so the user sees a blank site list with no explanation.

**Fix:** Add an error branch in the FutureBuilder:
```dart
if (snapshot.hasError) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off, color: Colors.redAccent, size: 48),
        const SizedBox(height: 16),
        Text(
          'Failed to load forecasts.\nPull down to retry.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
      ],
    ),
  );
}
final forecastMap = snapshot.data ?? {};
```

---

## Priority 2 — Reliability / Edge Cases

### [P2-A] `weather_api.dart` L50 — No HTTP timeout
**Severity: Medium**
`http.get(uri)` has no timeout. On a poor mobile connection this hangs indefinitely, blocking the entire data load.

**Fix:**
```dart
final response = await http.get(uri).timeout(
  const Duration(seconds: 15),
  onTimeout: () => throw TimeoutException('Weather request timed out'),
);
```
Add `import 'dart:async';` at the top of the file.

---

### [P2-B] `weather_api.dart` L57–68 — Batch response length not validated
**Severity: Medium**
When the API returns a JSON array, the code assumes `json.length == sites.length`. If fewer items are returned, `json[s]` throws a `RangeError`.

**Fix:**
```dart
for (int s = 0; s < sites.length && s < json.length; s++) {
```

---

### [P2-C] `unit_converter.dart` L152 — `degreesToCompass` crashes on negative degrees
**Severity: Medium**
Dart's `%` operator returns negative values for negative inputs (e.g. `(-10) % 360 == -10`). A negative wind direction from bad API data produces a negative index into `compassPoints`, throwing a `RangeError`.

**Fix:**
```dart
static String degreesToCompass(double degrees) {
  final normalized = ((degrees % 360) + 360) % 360;
  return compassPoints[(normalized / 22.5).round() % 16];
}
```

---

### [P2-D] `unit_converter.dart` — Listeners accumulate on repeated `init()` calls
**Severity: Low**
Each call to `UnitSettings.init()` adds a new listener to the static `ValueNotifier` without removing the previous one. During hot restart in debug mode, listeners multiply, causing redundant `SharedPreferences` writes.

**Fix:** Guard with a `_initialized` flag:
```dart
static bool _initialized = false;
static Future<void> init() async {
  if (_initialized) return;
  _initialized = true;
  // ... rest of init
}
```
Apply the same pattern to `ThemeSettings`, `WeatherSettings`, and `LayoutSettings`.

---

### [P2-E] `flight_logic.dart` L443–445 — Silent fallback to wrong date's data
**Severity: Low**
`getDayWeather` returns `forecast.first` when no entry matches the target date. If the forecast starts tomorrow, today's cards silently display tomorrow's data.

**Fix:** Throw a descriptive exception instead:
```dart
throw Exception('No forecast data available for ${targetDate.toIso8601String()}');
```
Or change return type to `WeatherData?` and guard at call sites.

---

## Priority 3 — Security

### [P3-A] `ai_service.dart` L114 — Exception detail exposed in UI
**Severity: Low**
`return "Error: ${e.toString()}"` can expose internal SDK details, endpoint URLs, or stack info to the user's screen.

**Fix:**
```dart
} catch (e) {
  debugPrint('AI service error: $e');
  return "Unable to generate briefing. Please check your API key and connection.";
}
```

---

### [P3-B] `ai_service.dart` — Gemini API key stored in plaintext (`SharedPreferences`)
**Severity: Low**
`SharedPreferences` writes plaintext to disk. Readable by backup tools and device owners.

**Optional improvement:** Replace with `flutter_secure_storage` (Android Keystore / iOS Keychain).

---

## Priority 4 — Performance / Optimisations

### [P4-A] `daily_summary_screen.dart` — Re-fetches all 16 sites unnecessarily
`HomeScreen` already holds fresh forecast data but `DailySummaryScreen` opens a new `WeatherApi` instance and re-fetches everything. This doubles Open-Meteo traffic and risks 429 rate-limiting.

**Improvement:** Accept `Map<String, List<WeatherData>> forecasts` as a constructor parameter (same pattern as `SiteDetailScreen`).

---

### [P4-B] `home_screen.dart` L38 — Cache cleared on every refresh
`WeatherApi.clearCache()` is called before every fetch, making the 10-minute TTL in `WeatherApi` ineffective against rapid user refreshes.

**Improvement:** Remove `clearCache()` from `_fetchData`. Pass a `forceRefresh: true` flag from pull-to-refresh only, and let the TTL govern background/auto refreshes.

---

### [P4-C] `ai_service.dart` — `GenerativeModel` recreated on every call
A new `GenerativeModel` instance is created on each `askPilotAssistant` call. Should be cached as a field and recreated only when the API key changes.

---

## Summary

| ID | File | Issue | Severity |
|----|------|-------|----------|
| P1-A | `ai_service.dart` | Wind speed units mismatch in AI prompt | High |
| P1-B | `weather_data.dart` | Unsafe `int` cast crashes on `double` from API | High |
| P1-C | `main.dart` | Custom `kIsWeb` shadows Flutter's, wrong on Dart 3+ | High |
| P1-D | `daily_summary_screen.dart` | Error message not cleared on successful retry | Medium |
| P1-E | `home_screen.dart` | API errors silently swallowed, no user feedback | Medium |
| P2-A | `weather_api.dart` | No HTTP timeout | Medium |
| P2-B | `weather_api.dart` | Batch response length not validated | Medium |
| P2-C | `unit_converter.dart` | `degreesToCompass` crashes on negative degrees | Medium |
| P2-D | `unit_converter.dart` | Listeners accumulate on repeated `init()` | Low |
| P2-E | `flight_logic.dart` | Silent fallback to wrong date's data | Low |
| P3-A | `ai_service.dart` | Exception detail exposed in UI | Low |
| P3-B | `ai_service.dart` | API key stored in plaintext | Low |
| P4-A | `daily_summary_screen.dart` | Re-fetches all weather data unnecessarily | Optimisation |
| P4-B | `home_screen.dart` | Cache cleared on every refresh | Optimisation |
| P4-C | `ai_service.dart` | `GenerativeModel` recreated every call | Optimisation |
