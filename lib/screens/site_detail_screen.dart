import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/site.dart';
import '../models/weather_data.dart';
import '../models/pilot_report.dart';
import '../services/flight_logic.dart';
import '../services/pilot_report_service.dart';
import '../utils/unit_converter.dart';
import 'live_wind_screen.dart';

class SiteDetailScreen extends StatelessWidget {
  final Site site;
  final List<WeatherData> forecast;
  final DateTime selectedDate;
  final _reportService = PilotReportService();
  SiteDetailScreen({
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showReportDialog(context),
            label: const Text('Add Report'),
            icon: const Icon(Icons.add_comment),
            backgroundColor: Colors.blueAccent,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (evaluation.notes.contains("Hill in cloud"))
                    _buildCloudHazardBanner(context),
                  if (evaluation.notes.any(
                    (n) => n.contains("thunder") || n.contains("Storm"),
                  ))
                    _buildThunderHazardBanner(context),
                  _buildCurrentConditionsCard(context, currentData, evaluation),
                  const SizedBox(height: 24),
                  _buildPilotReportsSection(context),
                  const SizedBox(height: 24),
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
                          color: Colors.grey.shade400,
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

  Widget _buildCurrentConditionsCard(
    BuildContext context,
    WeatherData wd,
    FlightEvaluation evaluation,
  ) {
    final now = DateTime.now();
    final direction = UnitSettings.degreesToCompass(wd.windDirection);
    final speed = UnitSettings.convertKmh(wd.windSpeed).round();
    final gusts = UnitSettings.convertKmh(wd.windGusts).round();
    final boxColor = evaluation.color;
    final speedUnit = UnitSettings.unitString;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: boxColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: boxColor.withValues(alpha: 0.5), width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT CONDITIONS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  evaluation.verdict.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}\n$speed $speedUnit\nG $gusts $speedUnit',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Transform.rotate(
                angle: (wd.windDirection + 180) * (3.14159 / 180),
                child: const Icon(
                  Icons.arrow_upward,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                direction,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPilotReportsSection(BuildContext context) {
    return StreamBuilder<List<PilotReport>>(
      stream: _reportService.getRecentReports(
        site.id,
        targetDate: selectedDate,
      ),
      builder: (context, snapshot) {
        final reports = snapshot.data ?? [];
        final count = reports.length;
        final boxColor = count > 0 ? Colors.purpleAccent : Colors.white10;
        final textColor = count > 0 ? Colors.white : Colors.white38;
        return InkWell(
          onTap: count > 0
              ? () => _showDetailedReportsDialog(context, reports)
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: boxColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: boxColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  count > 0 ? Icons.comment : Icons.comment_outlined,
                  color: boxColor,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    count == 0
                        ? 'No site reports for ${site.name}'
                        : '$count ${count == 1 ? 'report' : 'reports'} for ${site.name}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: count > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (count > 0)
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).dividerColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetailedReportsDialog(
    BuildContext context,
    List<PilotReport> reports,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PILOT REPORTS',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: reports.length,
                itemBuilder: (context, index) =>
                    _buildReportCard(context, reports[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, PilotReport report) {
    final timeStr =
        '${report.timestamp.hour.toString().padLeft(2, '0')}:${report.timestamp.minute.toString().padLeft(2, '0')}';
    final directionStr = UnitSettings.degreesToCompass(report.windDirection);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                report.userName,
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                timeStr,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.explore_outlined,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '$directionStr (${report.windDirection.round()})\n${report.windSpeedMin.round()}-${report.windSpeedMax.round()} ${UnitSettings.unitString}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.wb_sunny_outlined,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Cloud: ${report.cloudCover}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (report.observations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              report.observations,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    String selectedDirectionPoint = 'N';
    int selectedMin = 10;
    int selectedMax = 15;
    String selectedCloudCover = UnitSettings.cloudCoverOctas[0];
    final observationsController = TextEditingController();
    bool isSubmitting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SUBMIT PILOT REPORT',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'WIND DIRECTION',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(
                              height: 120,
                              child: CupertinoPicker(
                                itemExtent: 40,
                                scrollController: FixedExtentScrollController(
                                  initialItem: 0,
                                ),
                                onSelectedItemChanged: (index) => setModalState(
                                  () => selectedDirectionPoint =
                                      UnitSettings.compassPoints[index],
                                ),
                                children: UnitSettings.compassPoints
                                    .map(
                                      (p) => Center(
                                        child: Text(
                                          p,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CLOUD COVER',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(
                              height: 120,
                              child: CupertinoPicker(
                                itemExtent: 40,
                                scrollController: FixedExtentScrollController(
                                  initialItem: 0,
                                ),
                                onSelectedItemChanged: (index) => setModalState(
                                  () => selectedCloudCover =
                                      UnitSettings.cloudCoverOctas[index],
                                ),
                                children: UnitSettings.cloudCoverOctas
                                    .map(
                                      (c) => Center(
                                        child: Text(
                                          c.split(' - ').first,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MIN SPEED',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(
                              height: 120,
                              child: CupertinoPicker(
                                itemExtent: 40,
                                scrollController: FixedExtentScrollController(
                                  initialItem: 10,
                                ),
                                onSelectedItemChanged: (index) =>
                                    setModalState(() => selectedMin = index),
                                children: List.generate(
                                  100,
                                  (i) => Center(
                                    child: Text(
                                      '$i',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MAX SPEED',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(
                              height: 120,
                              child: CupertinoPicker(
                                itemExtent: 40,
                                scrollController: FixedExtentScrollController(
                                  initialItem: 15,
                                ),
                                onSelectedItemChanged: (index) =>
                                    setModalState(() => selectedMax = index),
                                children: List.generate(
                                  100,
                                  (i) => Center(
                                    child: Text(
                                      '$i',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'OBSERVATIONS (OPTIONAL)',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: observationsController,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Smooth, bumpy, busy take-off...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).dividerColor,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).dividerColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              final user = FirebaseAuth.instance.currentUser;
                              final report = PilotReport(
                                siteId: site.id,
                                userId: user?.uid ?? 'anonymous',
                                userName:
                                    user?.email?.split('@').first ??
                                    'Guest Pilot',
                                windDirection: UnitSettings.compassToDegrees(
                                  selectedDirectionPoint,
                                ),
                                windSpeedMin: selectedMin.toDouble(),
                                windSpeedMax: selectedMax.toDouble(),
                                cloudCover: selectedCloudCover,
                                observations: observationsController.text,
                                timestamp: DateTime.now(),
                              );
                              // Pop immediately to return to site detail page
                              Navigator.pop(context);
                              // Save in background and show notification
                              _reportService
                                  .saveReport(report)
                                  .then((_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Report submitted successfully!',
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  })
                                  .catchError((e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to submit: $e'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'SUBMIT REPORT',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                ],
              ),
            ),
          ),
        ),
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
      return FlightLogic.isLegalFlyingHour(DateTime.parse(h.data!.time), site);
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
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
          child: Row(
            children: [
              const SizedBox(width: 4), // Space for status line
              Expanded(
                flex: 2,
                child: Text(
                  'TIME',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.4),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'WIND & GUSTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.4),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'DIRECTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.4),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'RAIN %',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.4),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: displayHours.map((h) {
              final wd = h.data!;
              final time = wd.time.split('T').last.substring(0, 5);
              final eval = FlightLogic.evaluateCondition(wd, site);
              final speed = UnitSettings.convertKmh(wd.windSpeed).round();
              final gusts = UnitSettings.convertKmh(wd.windGusts).round();
              final rainColor = wd.precipitationProbability > 30
                  ? Colors.blueAccent
                  : Colors.white;
              final isLast = displayHours.last == h;
              return Container(
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Vertical status indicator
                      Container(width: 4, color: eval.color),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              // Time
                              Expanded(
                                flex: 2,
                                child: Text(
                                  time,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              // Wind
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.air,
                                      size: 14,
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                        children: [
                                          TextSpan(text: '$speed'),
                                          TextSpan(
                                            text: ' / $gusts',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.5,
                                              ),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Direction
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    Transform.rotate(
                                      angle:
                                          (wd.windDirection + 180) *
                                          (3.14159 / 180),
                                      child: const Icon(
                                        Icons.navigation_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      UnitSettings.degreesToCompass(
                                        wd.windDirection,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Rain
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(
                                      Icons.water_drop_rounded,
                                      size: 12,
                                      color: rainColor.withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${wd.precipitationProbability}%',
                                      style: TextStyle(
                                        color: rainColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
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
              );
            }).toList(),
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
    final cbMeters = FlightLogic.calculateCloudbase(
      wd.temperature,
      wd.dewPoint,
    );
    final cloudbase = UnitSettings.convertHeight(cbMeters);
    final toh = UnitSettings.convertHeight(site.takeOffHeight.toDouble());
    final pressure = UnitSettings.convertPressure(wd.surfacePressure);
    final pressureStr =
        '${pressure.toStringAsFixed(1)} ${UnitSettings.pressureUnitString}';
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
                _buildConditionRow(
                  context,
                  'Take Off Height',
                  '${toh.round()} ${UnitSettings.heightUnitString}',
                ),
                _buildConditionRow(
                  context,
                  'Cloud Base',
                  '${cloudbase.round()} ${UnitSettings.heightUnitString}',
                ),
                _buildConditionRow(context, 'Pressure', pressureStr),
                _buildConditionRow(
                  context,
                  'UV Index',
                  wd.uvIndex.toStringAsFixed(1),
                ),
                _buildConditionRow(context, 'Cloud Cover', '${wd.cloudCover}%'),
                if (site.id == 'rhossili' || site.id == 'southerndown')
                  _buildConditionRow(context, 'Tide Status', tideSection),
                Divider(color: Theme.of(context).dividerColor, height: 24),
                _buildConditionRow(
                  context,
                  'Temperature',
                  '${wd.temperature.toStringAsFixed(1)}°C',
                ),
                _buildConditionRow(
                  context,
                  'Dew Point',
                  '${wd.dewPoint.toStringAsFixed(1)}°C',
                ),
                _buildConditionRow(
                  context,
                  'Visibility',
                  '${(wd.visibility / 1000).toStringAsFixed(1)} km',
                ),
                _buildConditionRow(
                  context,
                  'Humidity',
                  '${wd.relativeHumidity}%',
                ),
                _buildConditionRow(
                  context,
                  'CAPE (Energy)',
                  '${wd.cape.round()} J/kg',
                ),
                _buildConditionRow(
                  context,
                  'Lifted Index',
                  wd.liftedIndex.toStringAsFixed(1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getTideTimes() {
    // Rhossili/Southerdown Tide Times for March 2, 2026
    // High: 05:28 & 18:03
    // Low: 11:54
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
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}
