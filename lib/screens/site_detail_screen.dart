import 'package:flutter/material.dart';
import '../models/site.dart';
import '../models/weather_data.dart';
import '../services/flight_logic.dart';
import '../utils/unit_converter.dart';
import 'live_wind_screen.dart';

class SiteDetailScreen extends StatelessWidget {
  final Site site;
  final List<WeatherData> forecast;
  final DateTime selectedDate;

  const SiteDetailScreen({
    super.key,
    required this.site,
    required this.forecast,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(site.name)),
        body: const Center(child: Text("No data")),
      );
    }
    final currentData = FlightLogic.getDayWeather(forecast, selectedDate);
    final evaluation = FlightLogic.evaluateCondition(currentData, site);
    return ValueListenableBuilder<SpeedUnit>(
      valueListenable: UnitSettings.selectedUnit,
      builder: (context, unit, _) {
        final unitStr = UnitSettings.unitString;
        final isToday =
            selectedDate.year == DateTime.now().year &&
            selectedDate.month == DateTime.now().month &&
            selectedDate.day == DateTime.now().day;
        final dayName = isToday
            ? "Today"
            : [
                "Monday",
                "Tuesday",
                "Wednesday",
                "Thursday",
                "Friday",
                "Saturday",
                "Sunday",
              ][selectedDate.weekday - 1];
        return Scaffold(
          appBar: AppBar(
            title: Text(site.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.speed),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LiveWindScreen(site: site),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (evaluation.primaryWord == 'CLAGGED IN')
                    _buildCloudHazardBanner(context),
                  if (evaluation.status == FlightStatus.storm)
                    _buildThunderHazardBanner(context),
                  // Risk score clickable box
                  GestureDetector(
                    onTap: () => _showRiskBreakdown(context, evaluation),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: evaluation.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: evaluation.color.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined, size: 18, color: evaluation.color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  evaluation.primaryWord,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: evaluation.color,
                                  ),
                                ),
                                Text(
                                  'Risk score: ${evaluation.riskScore}/100  —  tap for breakdown',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: evaluation.color.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.info_outline, size: 14, color: evaluation.color),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hourly Outlook',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildHourlyGrid(context, forecast),
                  const SizedBox(height: 24),
                  _buildDetailedConditions(context, currentData, unitStr),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThunderHazardBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade900,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.bolt, color: Colors.white, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THUNDER / CONVECTIVE RISK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'High atmospheric energy detected. Watch for rapid over-development.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudHazardBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HILL IN CLOUD',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Forecast indicates the hill is clagged in as cloudbase lower than takeoff',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRiskBreakdown(BuildContext context, FlightEvaluation eval) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('RISK SCORE BREAKDOWN',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildScoreRow('Direction Penalty', eval.dirScore, 35),
            _buildScoreRow('Wind Speed Penalty', eval.speedScore, 30),
            _buildScoreRow('Gust Penalty', eval.gustScore, 20),
            _buildScoreRow('Rain/Moisture Penalty', eval.rainScore, 15),
            _buildScoreRow('Low Cloud Penalty', eval.cloudScore, 15),
            _buildScoreRow('Instability Penalty', eval.instabilityScore, 10),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL RISK SCORE', style: TextStyle(fontWeight: FontWeight.w900)),
                Text('${eval.riskScore}/100',
                    style: TextStyle(fontWeight: FontWeight.w900, color: eval.color, fontSize: 18)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, int score, int max) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text('$score',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: score > 0 ? Colors.orangeAccent : Colors.grey)),
        ],
      ),
    );
  }


  Widget _buildHourlyGrid(BuildContext context, List<WeatherData> forecast) {
    final timeline = FlightLogic.calculateTimeline(
      forecast,
      site,
      selectedDate,
    );
    final displayHours = timeline.where((h) {
      if (h.data == null) return false;
      return FlightLogic.isLegalFlyingHour(DateTime.parse(h.data!.time), site, wd: h.data);
    }).toList();

    if (displayHours.isEmpty) {
      return Card(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              "No flyable hours for this day.",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }
    
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tableHeaderColor = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : colorScheme.onSurfaceVariant;
    final tableBackgroundColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : colorScheme.surfaceContainerHigh;
    final tableBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : colorScheme.outline.withValues(alpha: 0.18);
    final rowBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : colorScheme.outline.withValues(alpha: 0.1);
    final valueTextColor = colorScheme.onSurface;
    final mutedValueColor = valueTextColor.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Hourly Forecast'.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: tableHeaderColor,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.5), width: 3),
          ),
          child: Row(
            children: [
              const SizedBox(width: 4), // Match the 4dp indicator stripe
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      const SizedBox(width: 4), // aligns with the colour bar in data rows
                      Expanded(
                        child: Text(
                          'TIME',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.purpleAccent.shade100,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'WIND / GUST',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.purpleAccent.shade100,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'DIR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.purpleAccent.shade100,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'RAIN %',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.purpleAccent.shade100,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: tableBackgroundColor,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            border: Border(
              left: BorderSide(color: tableBorderColor),
              right: BorderSide(color: tableBorderColor),
              bottom: BorderSide(color: tableBorderColor),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: (() {
              final List<Widget> items = [];
              final firstWd = displayHours.first.data!;
              DateTime? sunrise, sunset;
              if (firstWd.sunrise != null) sunrise = DateTime.parse(firstWd.sunrise!);
              if (firstWd.sunset != null) sunset = DateTime.parse(firstWd.sunset!);

              for (int i = 0; i < displayHours.length; i++) {
                final h = displayHours[i];
                final wd = h.data!;
                final time = wd.time.split('T').last.substring(0, 5);
                final hourInt = int.parse(time.split(':')[0]);
                final speed = UnitSettings.convertKmh(wd.windSpeed).round();
                final gusts = UnitSettings.convertKmh(wd.windGusts).round();
                final rainColor = FlightLogic.getColorForRain(wd.precipitationProbability);
                final dirColor = h.isDirOptimal ? Colors.greenAccent : Colors.redAccent;
                final windColor = FlightLogic.getColorForSpeed(speed);
                final gustColor = FlightLogic.getColorForSpeed(gusts);
                
                final isLast = i == displayHours.length - 1;

if (sunrise != null && hourInt == sunrise.hour) {
                  items.add(_buildSolarStrip(
                    context, 
                    'Sunrise (${sunrise.hour.toString().padLeft(2, '0')}:${sunrise.minute.toString().padLeft(2, '0')})', 
                    Icons.wb_sunny_outlined, 
                    Colors.orangeAccent,
                    rowBorderColor,
                  ));
                }

                items.add(Container(
                  decoration: BoxDecoration(
                    border: isLast && (sunset == null || sunset.hour != hourInt)
                        ? null
                        : Border(bottom: BorderSide(color: rowBorderColor)),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Container(width: 4, color: h.color),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    time,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: valueTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.air, size: 14, color: mutedValueColor),
                                      const SizedBox(width: 6),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '$speed',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: windColor,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' / ',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: mutedValueColor,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '$gusts',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: gustColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Transform.rotate(
                                        angle: (wd.windDirection + 180) * (3.14159 / 180),
                                        child: Icon(Icons.arrow_upward, size: 14, color: dirColor),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        UnitSettings.degreesToCompass(wd.windDirection),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: dirColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Icon(Icons.water_drop_rounded, size: 12, color: rainColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${wd.precipitationProbability}%',
                                        style: TextStyle(color: rainColor, fontWeight: FontWeight.w900, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ));

                if (sunset != null && hourInt == sunset.hour) {
                  items.add(_buildSolarStrip(
                    context, 
                    'Sunset (${sunset.hour.toString().padLeft(2, '0')}:${sunset.minute.toString().padLeft(2, '0')})', 
                    Icons.nights_stay_outlined, 
                    Colors.blueAccent,
                    rowBorderColor,
                  ));
                }
              }
              return items;
            })(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedConditions(
    BuildContext context,
    WeatherData wd,
    String unitStr,
  ) {
    final cbAgl = FlightLogic.calculateCloudbase(wd.temperature, wd.dewPoint);
    final cbMsl = cbAgl + site.elevation;
    final clearance = cbMsl - site.takeOffHeight;
    final cloudbaseAglDisplay = UnitSettings.convertHeight(clearance);
    final cloudbaseMslDisplay = UnitSettings.convertHeight(cbMsl);
    final toh = UnitSettings.convertHeight(site.takeOffHeight.toDouble());
    final pressure = UnitSettings.convertPressure(wd.surfacePressure);
    final pressureStr = '${pressure.toStringAsFixed(1)} ${UnitSettings.pressureUnitString}';
    String tideSection = 'N/A';
    if (site.id == 'rhossili' || site.id == 'southerndown') {
      tideSection = _getTideTimes();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Conditions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildConditionRow(context, 'Take Off Height', '${toh.round()} ${UnitSettings.heightUnitString}'),
                _buildConditionRow(context, 'Cloudbase MSL', '${cloudbaseMslDisplay.round()} ${UnitSettings.heightUnitString}'),
                _buildConditionRow(context, 'Clearance above site', '${cloudbaseAglDisplay.round()} ${UnitSettings.heightUnitString}'),
                _buildConditionRow(context, 'Pressure', pressureStr),
                _buildConditionRow(context, 'UV Index', wd.uvIndex.toStringAsFixed(1)),
                _buildConditionRow(context, 'Cloud Cover', '${wd.cloudCover}%'),
                if (site.id == 'rhossili' || site.id == 'southerndown')
                  _buildConditionRow(context, 'Tide Status', tideSection),
                Divider(color: Theme.of(context).dividerColor, height: 24),
                _buildConditionRow(context, 'Temperature', '${wd.temperature.toStringAsFixed(1)}°C'),
                _buildConditionRow(context, 'Dew Point', '${wd.dewPoint.toStringAsFixed(1)}°C'),
                _buildConditionRow(context, 'Visibility', '${(wd.visibility / 1000).toStringAsFixed(1)} km'),
                _buildConditionRow(context, 'Humidity', '${wd.relativeHumidity}%'),
                _buildConditionRow(context, 'CAPE (Energy)', '${wd.cape.round()} J/kg'),
                _buildConditionRow(context, 'Lifted Index', wd.liftedIndex.toStringAsFixed(1)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getTideTimes() {
    return 'H: 05:28, 18:03 | L: 11:54';
  }

  Widget _buildConditionRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolarStrip(BuildContext context, String label, IconData icon, Color color, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2), // More solid but still transparent
        border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.4))), // Contrasting border
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color), // High contrast icon
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color, // High contrast text
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
