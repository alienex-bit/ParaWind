import 'package:flutter/material.dart';
import '../models/site.dart';
import '../models/weather_data.dart';
import '../models/pilot_report.dart';
import '../services/pilot_report_service.dart';
import '../services/flight_logic.dart';
import '../utils/unit_converter.dart';
import '../screens/site_detail_screen.dart';
import 'wind_compass.dart';

class SiteCard extends StatelessWidget {
  final Site site;
  final List<WeatherData>? forecast;
  final DateTime selectedDate;
  const SiteCard({
    super.key,
    required this.site,
    this.forecast,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    if (forecast == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final currentData = FlightLogic.getDayWeather(forecast!, selectedDate);
    final evaluation = FlightLogic.evaluateCondition(currentData, site);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => SiteDetailScreen(
              site: site,
              forecast: forecast!,
              selectedDate: selectedDate,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: _buildStandardLayout(context, currentData, evaluation),
      ),
    );
  }

  Widget _buildStandardLayout(
    BuildContext context,
    WeatherData currentData,
    FlightEvaluation evaluation,
  ) {
    final takeoffHeight = site.takeOffHeight.toDouble();
    final adjSpeed = UnitSettings.convertKmh(
        FlightLogic.terrainAdjustedKmh(currentData.windSpeed, takeoffHeight)).round();
    final adjGusts = UnitSettings.convertKmh(
        FlightLogic.terrainAdjustedKmh(currentData.windGusts, takeoffHeight)).round();
    final foreSpeed = UnitSettings.convertKmh(currentData.windSpeed).round();
    final foreGusts = UnitSettings.convertKmh(currentData.windGusts).round();
    final unit = UnitSettings.unitString;
    final subtleColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: site name + status + two wind rows
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  site.name.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  evaluation.primaryWord,
                  style: TextStyle(
                    color: evaluation.color,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _buildWindRow(context, Icons.air, foreSpeed, foreGusts, unit, subtleColor),
                const SizedBox(height: 2),
                _buildWindRow(context, Icons.flight_takeoff, adjSpeed, adjGusts, unit, subtleColor),
              ],
            ),
          ),
          // Center: compass
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              width: 56,
              height: 56,
              child: WindCompass(
                currentWind: currentData.windDirection,
                faceDirection: site.faceDirection,
                optimalRanges: site.optimalWindDirections,
                arrowColor: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          // Right: BHPA + cloud hazard + reports + rain — right-aligned chips
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBhpaBadge(context),
              const SizedBox(height: 4),
              if (evaluation.primaryWord == 'CLAGGED IN') ...[
                _buildCloudHazardBadge(context),
                const SizedBox(height: 4),
              ],
              StreamBuilder<List<PilotReport>>(
                stream: PilotReportService().getRecentReports(site.id),
                builder: (context, snapshot) {
                  final count = snapshot.data?.length ?? 0;
                  if (count == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _buildReportBadge(context, count),
                  );
                },
              ),
              _buildRainBadge(context, currentData.precipitationProbability),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWindRow(BuildContext context, IconData icon,
      int speed, int gusts, String unit, Color subtleColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: subtleColor),
        const SizedBox(width: 3),
        Text(
          '$speed / $gusts $unit',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildBhpaBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Text(
        site.bhpaRating,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildRainBadge(BuildContext context, int probability) {
    final color = FlightLogic.getColorForRain(probability);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.water_drop_rounded, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            '$probability%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudHazardBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.onSurface, size: 10),
          const SizedBox(width: 3),
          Text(
            'HILL IN CLOUD',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportBadge(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.comment, color: Colors.purpleAccent, size: 10),
          const SizedBox(width: 3),
          Text(
            '$count ${count == 1 ? 'REPORT' : 'REPORTS'}',
            style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.w900, color: Colors.purpleAccent),
          ),
        ],
      ),
    );
  }
}
