# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter weather forecasting app (**ParaWind**) for paragliding sites in South Wales. It fetches forecasts from Open-Meteo and evaluates flight conditions. Android only. Package ID: `com.alienexbit.parawind`.

## Common Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter analyze          # Static analysis
flutter test             # Run all tests
flutter build apk        # Build Android APK
flutter format lib/      # Format Dart code
```

To run a single test file:
```bash
flutter test test/some_test.dart
```

## Architecture

**Entry point:** `lib/main.dart` loads user settings, and routes to `DisclaimerScreen` before `HomeScreen`.

**Data flow:**
1. `WeatherApi` fetches hourly forecasts from Open-Meteo (10-minute cache) for each site in `SitesData`
2. `FlightLogic` evaluates conditions using wind speed, gusts, direction, CAPE, lifted index, and cloudbase; produces a risk score 0–100
3. `HomeScreen` displays all sites via `SiteCard` widgets with a 5-day date picker at the top; tapping a card opens `SiteDetailScreen`
4. `SiteDetailScreen` shows a risk score box (tap for breakdown), hourly forecast table, and wind compass

**Key service responsibilities:**
- `FlightLogic`: Wind safety (5–20 mph optimal, max 22 mph gusts), cloudbase = `125 × (temp − dewpoint)`, instability warnings (CAPE > 500 or Lifted Index < 0), site wind-direction matching. `calculateKzt(takeoffHeight)` returns a terrain exposure factor (1.15 coastal / 1.35 lower valleys / 1.25 high mountain); `terrainAdjustedKmh(windKmh, takeoffHeight)` applies it for display. All flight evaluation uses terrain-adjusted speeds internally.
- `UnitConverter`: Manages unit preferences (mph/kph/knots, ft/m, etc.) and weather model selection (UKV / ECMWF / ICON) via SharedPreferences; also provides degree-to-compass conversion

**Wind speed display convention:** Cards and detail screens show raw forecast speed (from Open-Meteo) alongside terrain-adjusted speed. Always pass raw `windSpeed`/`windGusts` (km/h) through `UnitSettings.convertKmh()` for display; use `FlightLogic.terrainAdjustedKmh()` then `UnitSettings.convertKmh()` for the terrain-adjusted value.

**Sites:** 16 hardcoded Welsh paragliding sites in `lib/data/sites_data.dart` with coordinates, elevations, and optimal wind direction ranges.

## External Dependencies

- **Open-Meteo** – free weather API, no key required


## Settings & State

User preferences (units, weather model, theme, wind bands) are persisted via `SharedPreferences` and accessed throughout the app through `UnitConverter`. Changing the weather model clears the weather cache.

## Reference docs

See `Docs/` folder for: `COLOUR_LOGIC.md` (flight status colours and risk scoring), `SiteDataSheet.pdf`, `TODO.md`, `UPGRADE.md`.
