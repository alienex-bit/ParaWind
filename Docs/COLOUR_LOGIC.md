# SWWSC Weather App — Colours, Calculations & Outputs

## 1. Flight Status States

Six states drive all colours and labels throughout the app, in order from best to worst:

| State | Colour | Meaning |
|---|---|---|
| `prime` | Bright green `#00E676` | Optimal conditions |
| `soarable` | (band colour) | Good but not perfect |
| `marginal` | (band colour) | Flyable with caution |
| `caution` | (band colour) | Concerns present |
| `unflyable` | Red / band colour | Do not fly |
| `storm` | Red | Thunder/extreme risk — do not fly |

> **Note:** The exact colour displayed is always taken from the matching **Wind Band** (see §3), not hardcoded per status. The status determines _which_ band is relevant.

---

## 2. Terrain Adjustment (KZT)

All flight evaluation uses **terrain-adjusted wind speeds**, not raw forecast values.

```
Adjusted speed = Raw forecast speed (km/h) × KZT
```

| Takeoff height | KZT | Terrain type |
|---|---|---|
| < 150 m | **1.15** | Coastal / dune — some shelter |
| 150–499 m | **1.35** | Valley / low hill — most exposed |
| ≥ 500 m | **1.25** | High mountain — laminar flow |

Cards show **both**:
- **Forecast winds** — raw Open-Meteo value, unit-converted
- **Take off winds** — terrain-adjusted value, unit-converted

---

## 3. Wind Bands (Colour System)

Wind bands are user-configurable (Settings → Wind Bands). The defaults are:

| Band | Speed range | Label | Colour |
|---|---|---|---|
| 1 | 0–20 mph | PRIME | `#00E676` bright green |
| 2 | 20–99 mph | BLOWN | `#FF1744` bright red |

Custom bands can be set to any range/colour/label in Settings.

**How colour is selected:**
1. Terrain-adjusted speed (and gusts) are rounded to the nearest mph
2. If gusts exceed max-gusts limit, OR speed exceeds max-fly limit, OR rain > 50% → use `max(speed, gusts)` for lookup
3. Otherwise use speed alone
4. The **last matching band** (highest range) wins — so 20 mph hits "20–99" not "0–20"
5. Falls back to `white70` if no band matches

---

## 4. Per-Difficulty Wind Thresholds

Thresholds are applied using **terrain-adjusted mph**.

| Threshold | Novice | Intermediate | Advanced |
|---|---|---|---|
| Min flyable | 5 mph | 5 mph | 7 mph |
| Optimal min | 8 mph | 10 mph | 12 mph |
| Optimal max | 15 mph | 18 mph | 22 mph |
| Max flyable | 18 mph | 22 mph | 26 mph |
| Max gusts | 20 mph | 24 mph | 28 mph |
| Max gust factor | 1.5× | 1.7× | 2.0× |

**Gust factor** = gusts ÷ speed (clamped 1.0–3.0). A factor above the limit means turbulent, unpredictable conditions.

---

## 5. Cloudbase Calculation

```
Cloudbase AGL (m)  = 125 × (temperature °C − dew point °C)
Cloudbase MSL (m)  = Cloudbase AGL + site elevation (m)
Clearance (m)      = Cloudbase MSL − takeoff height (m)
```

- **Clearance < 0** → site is in cloud → `CLAGGED IN` (unflyable override)
- Clearance penalties: < 50 m = −15 pts; < 150 m = −10 pts; < 300 m = −5 pts

---

## 6. Instability (CAPE & Lifted Index)

| Condition | CAPE | Lifted Index | Risk penalty |
|---|---|---|---|
| Extreme | > 1500 OR | < −5 | **STORM override** |
| High | > 1000 AND | < −3 | −10 pts |
| Moderate | > 500 OR | < 0 | −7 pts |
| Some | > 200 | — | −3 pts |
| Stable | ≤ 200 AND | ≥ 0 | 0 |

Storm override also triggers if `weatherCode` ∈ {95, 96, 99} (thunderstorm codes from Open-Meteo).

---

## 7. Risk Score (0–100)

Each flight evaluation produces a **risk score** — lower is better. Components:

| Factor | Max penalty | Triggers |
|---|---|---|
| **Wind direction** | 35 pts | Off optimal range: +35 |
| **Wind speed** | 30 pts | Too light: +30 / light: +8 / strong: +12 / too strong: +30 |
| **Gusts** | 20 pts | Dangerous (over limit or factor): +20 / gusty: +10 / some: +5 |
| **Rain** | 15 pts | > 0.5 mm or > 50%: +15 / > 0.1 mm or > 30%: +10 / > 10%: +5 |
| **Cloudbase** | 15 pts | < 50 m clearance: +15 / < 150 m: +10 / < 300 m: +5 |
| **Instability** | 10 pts | See §6 |
| **Visibility** | 15 pts | < 1 km: +15 / < 3 km: +8 / < 5 km: +3 |
| **Total max** | **100** (clamped) | |

The risk score is displayed on the site detail screen as **Risk score: X/100**.

---

## 8. Status Decision Tree

Evaluated in order — first match wins:

```
1. STORM override
   → weatherCode is thunderstorm, OR CAPE > 1500, OR Lifted Index < −5
   → Status: storm | primaryWord: "THUNDER RISK"

2. CLAGGED IN
   → Cloudbase MSL ≤ takeoff height (site is in cloud)
   → Status: unflyable | primaryWord: "CLAGGED IN"

3. BLOWN OUT / THUNDER RISK (gusts/instability severe)
   → gustScore ≥ 20 → Status: unflyable | primaryWord: "BLOWN OUT"
   → instabilityScore ≥ 7 → Status: storm | primaryWord: "THUNDER RISK"

4. Within flyable speed (terrain-adjusted ≤ max flyable)
   a. Rain > 50% probability
      → Status: marginal | primaryWord: band label or "RAIN RISK"
   b. Direction off, gust concerns, or heavy rain
      → Status: caution | primaryWord: band label or "CONCERN"
   c. riskScore ≤ 15
      → Status: prime | primaryWord: band label or "GOOD"
   d. Otherwise
      → Status: soarable | primaryWord: band label or "GOOD"

5. Over speed limit
   → Status: unflyable | primaryWord: band label or "TOO STRONG"
```

**`primaryWord`** is always the **wind band label** for the matched speed band (e.g., "PRIME", "BLOWN"), falling back to the decision-tree word if no band matches.

---

## 9. Rain Colour

Linear interpolation between two colours based on precipitation probability:

| Probability | Colour |
|---|---|
| 0% | Light blue (`lightBlueAccent`) |
| 50% | Mid blue |
| 100% | Dark blue (`blue.shade800`) |

---

## 10. Direction Colours (Hourly Table)

In the hourly forecast table on the site detail screen:

| Direction status | Colour |
|---|---|
| Optimal (within site's wind range) | `greenAccent` |
| Off optimal | `redAccent` |

---

## 11. Card Border & Background

Card border and background use the **band colour** of the current evaluation:

| Property | Alpha |
|---|---|
| Background fill | 10% opacity |
| Border | 50% opacity, 2.0 px |

This means a green-banded site has a subtle green tint; a red-banded site has a subtle red tint.

---

## 12. Flyable Hours Window

Calculated from the hourly timeline for the selected day:

```
Optimal hours  = hours where status is prime OR soarable
Marginal hours = hours where status is marginal OR caution
Total flyable  = optimal + marginal
```

Displayed on the card as `XH WINDOW` or `NO WINDOW`.

---

## 13. Weather Model Options

Selectable in Settings. Affects which Open-Meteo model is queried:

| Option | Model |
|---|---|
| UKV | UK Met Office UKV (highest resolution for Wales) |
| ECMWF | ECMWF IFS (global, good medium-range) |
| ICON | DWD ICON (good for Atlantic systems) |

Changing the model clears the 10-minute weather cache.

---

## 14. Units

All user-facing wind speeds are converted from the internal **km/h** (Open-Meteo native) via `UnitSettings.convertKmh()`:

| Setting | Conversion |
|---|---|
| mph | ÷ 1.60934 |
| kph | × 1.0 (no conversion) |
| knots | ÷ 1.852 |

Elevations are shown in **ft** (`takeoffHeightFt` field on each site).
