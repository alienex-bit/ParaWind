# UPGRADE.md — Logic, Colours & Messages Overhaul

A ground-up review of the flight evaluation system with proposals for improvement.
Open to full replacement — nothing here is sacred.

---

## Section 1 — Problems with the Current System

### 1.1 All Sites Are Treated Identically

Every site from Rhossili (42m coastal dune) to Fan Hir (750m mountain) uses the exact same thresholds:
- Optimal: 12–18 mph
- Max: 20 mph
- Max gusts: 22 mph

In reality Rhossili is a ridge soaring site suited to lighter winds and beginners.
Fan Hir is an exposed mountain requiring experience and tolerating stronger flow.
Using one set of numbers for both produces too many false MARGINAL/OFF calls on mountains
and occasionally under-warns on easier sites.

### 1.2 Binary Escalation Loses Information

The rule "any Red factor = Red card" means a site is flagged identical Red whether:
- Wind direction is 20° off (slightly inconvenient)
- There is an active thunderstorm (life-threatening)

A pilot glancing at the home screen cannot distinguish between these.

### 1.3 Absolute Gust Value, Not Gust Factor

The current check is: gusts > 22 mph → unflyable.

But gust FACTOR (gusts ÷ mean wind) matters more than absolute gust value.
- 20 mph mean / 22 mph gusts → factor 1.1 → very smooth, just at limit
- 10 mph mean / 22 mph gusts → factor 2.2 → violently gusty, dangerous

The same 22 mph gust reads completely differently depending on mean wind.

### 1.4 Cloudbase Formula Dimensional Mismatch

Current formula:
```dart
final cloudbaseM = 125 * (temperature - dewPoint);  // gives metres AGL
if (cloudbaseM < (site.takeOffHeight + 50))          // compares to MSL height
```

`125 × (T − Td)` gives cloudbase **above the measurement point** (AGL).
`site.takeOffHeight` is **above sea level** (MSL).

These are not comparable. If Open-Meteo measures temp at the site's own elevation,
cloudbaseAGL is already the clearance above the site. The correct check is simply:
```dart
if (cloudbaseAGL < 50)   // site is in cloud
if (cloudbaseAGL < 150)  // dangerously low ceiling
```

### 1.5 Several Fetched Fields Are Completely Ignored

Fields fetched from Open-Meteo but never used in any evaluation:
- `visibility` — fog / low-vis hazard
- `cloudCover` (%) — thermal soaring potential, overcast suppression
- `relativeHumidity` — fog risk indicator
- `surfacePressure` — currently displayed but never affects status
- `uvIndex` — currently displayed, not used

### 1.6 No Trend / Trajectory Awareness

The current snapshot evaluation has no awareness of whether conditions are
improving or deteriorating. A 18 mph wind that was 12 mph an hour ago is very
different from one that was 25 mph an hour ago.

### 1.7 No XC Potential Assessment

The app evaluates "is it safe to fly" but not "how good is it for XC / distance".
Pilots want to know thermal strength, soaring potential, and whether to go local or travel.
CAPE and Lifted Index are fetched but only used as a danger signal, never as a positive signal.

### 1.8 The Kzt Factor is a Crude Heuristic

Three fixed tiers:
- < 150m → ×1.15
- 150–299m → ×1.35
- ≥ 300m → ×1.25

The non-monotonic jump (1.35 drops back to 1.25 at high altitude) is intentional but not
clearly documented. More importantly, Kzt is an opaque scalar — pilots cannot understand
why 12 mph becomes "Blown Out" without knowing this multiplier exists. Displaying it helps trust.

---

## Section 2 — Proposed New Logic

### 2.1 Site Difficulty Tiers

Add a `difficulty` field to the `Site` model:

```dart
enum SiteDifficulty { novice, intermediate, advanced }
```

Proposed site assignments:

| Site | Difficulty | Reason |
|---|---|---|
| Rhossili | novice | Coastal ridge, forgiving, long smooth slope |
| Ferryside | novice | Low coastal, short ridge |
| Newgale | novice | Beach launch, open |
| Southerndown | novice | Low coastal cliff |
| Lletty Siac | intermediate | Mid-valley, narrower window |
| Graig Fawr | intermediate | Mid-elevation |
| Bryncaws | intermediate | Easterly, valley mouth |
| Cwmafan | intermediate | Valley site |
| Cwmparc | intermediate | Sheltered valley |
| Abernant | intermediate | Exposed easterly |
| Seven Sisters | intermediate | N-facing, turbulent sector |
| Rhiw Wen | advanced | High, narrow direction window |
| Heol Senni | advanced | High mountain, NE exposed |
| Fan Gyhirych | advanced | Wide sector but 722m exposed |
| Fan Hir | advanced | 750m, strong flow |

Wind thresholds per difficulty tier (terrain-adjusted mph):

| Threshold | Novice | Intermediate | Advanced |
|---|---|---|---|
| Min flyable | 5 mph | 5 mph | 7 mph |
| Optimal min | 8 mph | 10 mph | 12 mph |
| Optimal max | 15 mph | 18 mph | 22 mph |
| Max flyable | 18 mph | 22 mph | 26 mph |
| Max gusts (abs) | 20 mph | 24 mph | 28 mph |
| Max gust factor | 1.5 | 1.7 | 2.0 |

This correctly reflects that experts can safely fly in conditions that would be dangerous
for novices, and that mountain sites are expected to be windier.

---

### 2.2 Replace Binary Escalation with a Weighted Risk Score

Instead of "any red = red", calculate a 0–100 risk score by summing penalty points.
Hard limits still exist (thunderstorm always = OFF regardless of score).

**Scoring components:**

#### Direction penalty (0–35 pts)
```
0 pts  = within optimal range
5 pts  = 1–10° outside optimal
15 pts = 11–20° outside optimal
25 pts = 21–35° outside optimal
35 pts = >35° outside optimal
```

#### Speed penalty (0–30 pts)
```
0 pts  = optimal range (difficulty-adjusted)
5 pts  = slightly below or above optimal
15 pts = approaching min/max flyable
25 pts = at min/max flyable limit
30 pts = beyond flyable limit (hard cap)
```

#### Gust factor penalty (0–20 pts)
```
0 pts  = gust factor < 1.3
5 pts  = 1.3–1.5
12 pts = 1.5–1.8
20 pts = > 1.8
```

#### Rain penalty (0–15 pts)
```
0 pts  = no rain, prob < 10%
5 pts  = light risk (prob 10–30% or < 0.1mm)
10 pts = moderate (prob 30–50% or 0.1–0.5mm)
15 pts = certain (prob > 50% or > 0.5mm)
```

#### Cloudbase penalty (0–15 pts)
```
0 pts  = > 300m AGL clearance
5 pts  = 150–300m AGL
10 pts = 50–150m AGL (low ceiling)
15 pts = < 50m AGL (site in cloud)
```

#### Instability penalty (0–10 pts)
```
0 pts  = CAPE < 200, LI > 2
3 pts  = CAPE 200–500 or LI 0–2
7 pts  = CAPE 500–1000 or LI -3–0
10 pts = CAPE > 1000 or LI < -3
```

**Score → Status:**

| Score | Status | Colour |
|---|---|---|
| 0–15 | PRIME | Green |
| 16–30 | SOARABLE | Teal/Blue-green |
| 31–50 | MARGINAL | Amber |
| 51–70 | CAUTION | Orange |
| 71–100 | OFF | Red |

**Hard overrides (always OFF regardless of score):**
- WMO weather code 95, 96, 99 (thunderstorm)
- CAPE > 1500
- LI < -5
- Gust factor > 2.5
- Absolute gusts > difficulty-adjusted max

This system means a site can be "OFF" for a mild reason (score 75: bad direction + light rain)
vs a severe reason (hard override: thunderstorm) — the UI can differentiate these.

---

### 2.3 Gust Factor as First-Class Metric

Calculate and display gust factor everywhere wind is shown:

```dart
final gustFactor = (gustMph / speedMph).clamp(1.0, 3.0);
// Display: "12 / 18 mph  GF 1.5"
// Or colour-code the gusts value based on gust factor
```

Display convention:
- GF < 1.3: gusts shown in normal colour
- GF 1.3–1.6: gusts shown in amber
- GF > 1.6: gusts shown in red

This is immediately understandable to pilots without needing to know the thresholds.

---

### 2.4 Fix Cloudbase Comparison

```dart
// CURRENT (wrong - comparing AGL to MSL)
final cloudbaseM = 125 * (temp - dewPoint);
if (cloudbaseM < (site.takeOffHeight + 50)) → unflyable

// PROPOSED (correct - AGL clearance above site)
final cloudbaseAGL = 125 * (temp - dewPoint);
final cloudbaseMSL = cloudbaseAGL + site.elevation; // approximate
// Evaluate clearance above takeoff:
final clearance = cloudbaseMSL - site.takeOffHeight;
if (clearance < 50)  → penalty 15 (site in cloud)
if (clearance < 150) → penalty 10 (low ceiling)
if (clearance < 300) → penalty 5  (marginal ceiling)
```

Also display `cloudbaseMSL` as the primary number (more useful to pilots for flight planning)
and show clearance as the secondary value.

---

### 2.5 Use Visibility

Add a visibility check to the risk score:

```dart
// visibility is in metres from Open-Meteo
if (wd.visibility < 1000)  → penalty 15 (fog, unflyable)
if (wd.visibility < 3000)  → penalty 8  (poor vis, hill features unclear)
if (wd.visibility < 5000)  → penalty 3  (hazy)
```

Particularly important for coastal sites and winter flying.

---

### 2.6 Trend Indicators

Compare current hour with ±1 and ±2 hours to detect trajectory:

```dart
enum WindTrend { rapidlyIncreasing, increasing, steady, decreasing, rapidlyDecreasing }

WindTrend calculateWindTrend(List<WeatherData> forecast, DateTime targetHour) {
  // Compare current hour to +2 hours
  final deltaSpeed = futureSpeed - currentSpeed;  // terrain-adjusted mph
  if (deltaSpeed > 5)  return WindTrend.rapidlyIncreasing;
  if (deltaSpeed > 2)  return WindTrend.increasing;
  if (deltaSpeed < -5) return WindTrend.rapidlyDecreasing;
  if (deltaSpeed < -2) return WindTrend.decreasing;
  return WindTrend.steady;
}
```

Display as ↑↑ ↑ → ↓ ↓↓ arrows next to the wind speed on cards and detail screens.
A 19 mph → with a ↑↑ is much more alarming than 19 mph ↓↓.

---

### 2.7 XC / Soaring Potential Score

Separate from safety (which tells you if you CAN fly), this tells you HOW GOOD it will be:

```dart
int xcPotential = 0; // 0–10

// Thermal triggers
if (temp > 12 && cloudCover < 60) xcPotential += 2;
if (temp > 16 && cloudCover < 40) xcPotential += 1;
if (liftedIndex < -1 && liftedIndex > -3) xcPotential += 2; // unstable but not dangerous
if (cape > 100 && cape < 500) xcPotential += 1;             // some energy, not overdeveloping

// Wind strength for ridge soaring
if (speedMph >= 12 && speedMph <= 20 && isDirectionOn) xcPotential += 2;

// Penalise over-development risk
if (cape > 500 || liftedIndex < -3) xcPotential = min(xcPotential, 3);
// Penalise overcast (kills thermals)
if (cloudCover > 85) xcPotential -= 2;
```

Display as a badge: `XC ★★★☆☆` or `XC: GOOD` / `XC: RIDGE ONLY` / `XC: POOR`

This is additive information — a site can be CAUTION (borderline safe) but XC POOR,
or SOARABLE and XC EXCELLENT.

---

## Section 3 — Proposed New Colour System

### Replace 3-state with 5-state

| State | Colour | Hex suggestion | Meaning |
|---|---|---|---|
| PRIME | **Bright green** | `#00E676` | Textbook conditions, all factors optimal |
| SOARABLE | **Teal** | `#00BCD4` | Flyable, one factor slightly off ideal |
| MARGINAL | **Amber** | `#FFB300` | Multiple factors borderline, experience needed |
| CAUTION | **Deep orange** | `#FF6D00` | Significant issue, think carefully |
| OFF | **Red** | `#FF1744` | Do not fly |
| STORM | **Purple** | `#AA00FF` | Active thunderstorm risk — separate from OFF for clarity |

**Why purple for storm?**
Red currently means everything from "wind's a bit off" to "lightning likely".
Purple as a distinct storm warning cannot be ignored or normalised by seeing it daily.
It signals "this is categorically different — not just bad weather, it's dangerous weather."

### Card Background Tint

Keep the current approach of `color.withOpacity(0.12)` for the card background,
but also add a **left edge accent bar** (3px wide, full height) in the status colour.
This is readable in both light and dark themes without being garish.

---

## Section 4 — Proposed New Message System

### Replace Single Verdict String with Two-Part Display

**Part 1 — Primary status word** (large, bold, one word):

| Score/State | Word |
|---|---|
| PRIME | `PRIME` |
| SOARABLE | `SOARABLE` |
| MARGINAL | `MARGINAL` |
| CAUTION | `CAUTION` |
| OFF (direction) | `CROSSED` |
| OFF (too strong) | `BLOWN` |
| OFF (too light) | `CALM` |
| OFF (rain) | `WET` |
| OFF (cloud) | `CLAGGED` |
| STORM | `STORM` |

**Part 2 — Secondary reason** (smaller, sentence case, describes the dominant factor):

Examples: `"Direction perfect"`, `"Slight crosswind"`, `"Gusty"`, `"Strong gusts"`,
`"Light but soarable"`, `"Rain likely"`, `"Hill in cloud"`, `"Unstable air"`,
`"Thunderstorm risk"`, `"Good XC window"`, `"Thermal trigger likely"`

Displayed together: **BLOWN** · *Strong gusts*

This is scannable at a glance on the home screen but gives detail without tapping in.

### Remove `\n` From Verdict Strings

Currently `"FLYABLE\nOPTIMAL"` is a string with a literal newline, forcing two-line
rendering. This should be two separate text widgets with proper typography control.

---

## Section 5 — Site Detail Screen Upgrades

### 5.1 Risk Score Breakdown

The `riskScore` field already exists on `FlightEvaluation` but is never displayed.
Show a breakdown card on the detail screen:

```
RISK BREAKDOWN          Total: 23/100 → SOARABLE
Direction       ░░░░░░░░░░  0 pts
Wind Speed      ██░░░░░░░░  8 pts
Gust Factor     ████░░░░░░ 12 pts
Rain            ░░░░░░░░░░  0 pts
Cloudbase       ██░░░░░░░░  3 pts
Instability     ░░░░░░░░░░  0 pts
```

A pilot can immediately see why a site is marginal and decide whether that factor
matters for their flying.

### 5.2 Hourly Grid — Add Trend Column

Show ↑↓ trend for each hour in the hourly grid so pilots can see the window shape:
- 09:00 🟢 PRIME ↑
- 10:00 🟢 PRIME →
- 11:00 🟡 MARGINAL ↑↑
- 12:00 🔴 BLOWN

### 5.3 Show Both Cloudbase Numbers

Currently only one cloudbase figure is shown. Show:
- `Cloudbase AGL: 450 ft` — height above the site
- `Cloudbase MSL: 2,950 ft` — absolute altitude (useful for XC planning)

### 5.4 Three-Model Confidence Indicator

The app supports UKV, ECMWF, ICON. If all three were fetched and compared,
disagreement between models signals lower forecast confidence.

A simple badge: `MODEL CONFIDENCE: HIGH / MED / LOW` based on spread between model outputs.
This is particularly valuable for South Wales where Atlantic fronts move fast.

Realistically this requires fetching from all three and comparing — a bigger change,
but very valuable as a unique feature.

---

## Section 6 — Home Screen Upgrades

### 6.1 Sort Order Options

Currently sites are hardcoded in `sites_data.dart` order.
Allow sorting by:
- Best conditions first (score ascending)
- Alphabetical
- Distance from user location

### 6.2 "Best Site Now" Banner

A pinned card at the top showing the single highest-scoring flyable site right now,
with the key stats and a one-tap navigation. Saves scrolling 15 cards looking for green.

### 6.3 "Window Opening" Alert Style

Sites that are currently OFF but will be PRIME within 2 hours get a distinctive indicator:
a small clock icon or "OPENS 14:00" label on the card.
Pilots can see at a glance which sites are worth driving to.

---

## Section 7 — Implementation Priority

| Priority | Change | Complexity | Impact |
|---|---|---|---|
| 1 | Fix cloudbase AGL/MSL mismatch | Low | High (correctness) |
| 2 | Add gust factor display | Low | High (pilot insight) |
| 3 | Two-part message system (word + reason) | Low | High (readability) |
| 4 | 5-colour status system | Medium | High (nuance) |
| 5 | Add difficulty tiers to Site model | Medium | High (relevance) |
| 6 | Weighted risk score | Medium | High (replaces binary) |
| 7 | Trend indicators (↑↓) | Medium | Medium |
| 8 | Use visibility field | Low | Medium |
| 9 | XC potential score | Medium | Medium |
| 10 | Risk breakdown card on detail screen | Low | Medium |
| 11 | "Best site now" banner | Low | Medium |
| 12 | "Window opening" indicator | Medium | High (pilot planning) |
| 13 | Sort by conditions | Low | Low |
| 14 | Three-model confidence | High | High (unique feature) |

---

## Section 8 — What to Keep

- The terrain-adjusted wind display (raw + adjusted rows) — good addition, keep it
- The timeline bar (colour per hour) — valuable, extend with trend arrows
- The Kzt system — keep but document clearly and make Kzt visible to pilots
- The CAPE / LI instability checks — keep, just reclassify into the new score
- Pilot reports — keep, they're a differentiating feature vs generic weather apps
- AI briefing — keep, just fix the units bug (P1-A in TODO.md)
- The three weather model options — keep, build model confidence on top of it

---

## Appendix — New FlightEvaluation Fields Needed

```dart
class FlightEvaluation {
  // Existing
  final FlightStatus status;          // keep but extend to 5 values
  final String verdict;               // replace with primaryWord + secondaryReason
  final int riskScore;                // keep and display
  final List<String> notes;           // keep
  final Color color;                  // keep

  // New
  final String primaryWord;           // e.g. "BLOWN", "PRIME", "MARGINAL"
  final String secondaryReason;       // e.g. "Strong gusts", "Direction perfect"
  final double gustFactor;            // gusts / mean wind
  final WindTrend windTrend;          // ↑↑ ↑ → ↓ ↓↓
  final int xcPotential;              // 0–10
  final double cloudbaseMsl;          // metres MSL
  final double cloudbaseAgl;          // metres AGL (clearance above site)
  final Map<String, int> scoreBreakdown; // penalty pts per category for UI display
}
```
