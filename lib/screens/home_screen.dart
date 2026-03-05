import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/site.dart';
import '../models/weather_data.dart';
import '../models/pilot_report.dart';
import '../services/pilot_report_service.dart';
import '../services/weather_api.dart';
import '../services/flight_logic.dart';
import 'site_detail_screen.dart';
import 'about_screen.dart';
import 'daily_summary_screen.dart';
import 'disclaimer_screen.dart';
import 'admin_reports_screen.dart';
import '../utils/unit_converter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherApi _api = WeatherApi();
  Future<Map<String, List<WeatherData>>>? _forecastsFuture;
  DateTime? _lastRefreshed;
  DateTime _selectedDate = DateTime.now();
  @override
  void initState() {
    super.initState();
    _fetchData();
    WeatherSettings.selectedModel.addListener(_fetchData);
  }

  @override
  void dispose() {
    WeatherSettings.selectedModel.removeListener(_fetchData);
    super.dispose();
  }

  void _fetchData() {
    setState(() {
      WeatherApi.clearCache();
      _forecastsFuture = _api.fetchForecastBatch(walesSites);
      _lastRefreshed = DateTime.now();
    });
    // Cleanup old pilot reports on launch/refresh
    PilotReportService().cleanupOldReports();
  }

  Future<void> _handleRefresh() async {
    _fetchData();
    if (_forecastsFuture != null) {
      try {
        await _forecastsFuture;
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'SWWSC FORECASTS',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: FutureBuilder<Map<String, List<WeatherData>>>(
          future: _forecastsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.blueAccent),
                    const SizedBox(height: 16),
                    Text(
                      'Analyzing Airflow...',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              );
            }
            final forecastMap = snapshot.data ?? {};
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount:
                  walesSites.length + 2, // +1 for header, +1 for bottom spacer
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    children: [
                      if (_lastRefreshed != null) _buildStatusHeader(),
                      _buildDailySummaryCard(context),
                      const SizedBox(height: 12),
                    ],
                  );
                }
                if (index == walesSites.length + 1) {
                  // Bottom spacer to prevent navigation bar clipping
                  return const SizedBox(height: 120);
                }
                final site = walesSites[index - 1];
                return SiteCard(
                  site: site,
                  forecast: forecastMap[site.id],
                  selectedDate: _selectedDate,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 120,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Color(0xFF1E88E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.only(left: 20, bottom: 20),
            alignment: Alignment.bottomLeft,
            child: Text(
              'SETTINGS',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _buildDrawerSection('UNITS'),
          _buildUnitTile(
            icon: Icons.speed,
            title: 'Wind Speed',
            listenable: UnitSettings.selectedUnit,
            options: SpeedUnit.values.map((v) => v.name.toUpperCase()).toList(),
            onChanged: (idx) =>
                UnitSettings.selectedUnit.value = SpeedUnit.values[idx],
            currentIdx: UnitSettings.selectedUnit.value.index,
          ),
          _buildUnitTile(
            icon: Icons.straighten,
            title: 'Distance',
            listenable: UnitSettings.selectedDistanceUnit,
            options: ['KM', 'MILES'],
            onChanged: (idx) => UnitSettings.selectedDistanceUnit.value =
                DistanceUnit.values[idx],
            currentIdx: UnitSettings.selectedDistanceUnit.value.index,
          ),
          _buildUnitTile(
            icon: Icons.height,
            title: 'Height',
            listenable: UnitSettings.selectedHeightUnit,
            options: ['METERS', 'FEET'],
            onChanged: (idx) =>
                UnitSettings.selectedHeightUnit.value = HeightUnit.values[idx],
            currentIdx: UnitSettings.selectedHeightUnit.value.index,
          ),
          _buildUnitTile(
            icon: Icons.compress,
            title: 'Pressure',
            listenable: UnitSettings.selectedPressureUnit,
            options: ['HPA', 'MBAR'],
            onChanged: (idx) => UnitSettings.selectedPressureUnit.value =
                PressureUnit.values[idx],
            currentIdx: UnitSettings.selectedPressureUnit.value.index,
          ),
          Divider(color: Theme.of(context).dividerColor, height: 32),
          _buildDrawerSection('SYSTEM'),
          _buildUnitTile(
            icon: Icons.brightness_medium,
            title: 'Theme',
            listenable: ThemeSettings.selectedTheme,
            options: ['AUTO', 'LIGHT', 'DARK'],
            onChanged: (idx) =>
                ThemeSettings.selectedTheme.value = ThemeMode.values[idx],
            currentIdx: ThemeSettings.selectedTheme.value.index,
          ),
          ListTile(
            leading: const Icon(Icons.cloud_queue, color: Colors.blueAccent),
            title: Text(
              'Weather Model',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: ValueListenableBuilder<WeatherModel>(
              valueListenable: WeatherSettings.selectedModel,
              builder: (context, m, _) => Text(
                m.displayName,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: _showModelPicker,
          ),
          ListTile(
            leading: const Icon(Icons.gavel, color: Colors.orangeAccent),
            title: Text(
              'Disclaimer',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const DisclaimerScreen()),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            title: Text(
              'About',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const AboutScreen()),
            ),
          ),
          Divider(color: Theme.of(context).dividerColor, height: 32),
          _buildDrawerSection('DEVELOPMENT'),
          ListTile(
            leading: const Icon(Icons.bug_report, color: Colors.purpleAccent),
            title: Text(
              'Admin / Debug Reports',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => AdminReportsScreen()),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.blueAccent.withValues(alpha: 0.8),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildUnitTile({
    required IconData icon,
    required String title,
    required ValueNotifier listenable,
    required List<String> options,
    required Function(int) onChanged,
    required int currentIdx,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).textTheme.bodyMedium?.color,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 15,
        ),
      ),
      trailing: ValueListenableBuilder(
        valueListenable: listenable,
        builder: (context, _, _) {
          return DropdownButton<int>(
            value: currentIdx,
            dropdownColor: Theme.of(context).colorScheme.surface,
            underline: const SizedBox(),
            items: List.generate(
              options.length,
              (i) => DropdownMenuItem(
                value: i,
                child: Text(
                  options[i],
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            onChanged: (val) => val != null ? onChanged(val) : null,
          );
        },
      ),
    );
  }

  void _showModelPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Select Model',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: WeatherModel.values.map((m) {
              return ValueListenableBuilder<WeatherModel>(
                valueListenable: WeatherSettings.selectedModel,
                builder: (context, currentModel, child) {
                  return RadioListTile<WeatherModel>(
                    title: Text(
                      m.displayName,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 14,
                      ),
                    ),
                    value: m,
                    // ignore: deprecated_member_use
                    groupValue: currentModel,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      if (val != null) {
                        WeatherSettings.selectedModel.value = val;
                        Navigator.pop(context);
                      }
                    },
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDailySummaryCard(BuildContext context) {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            // Top part: Clickable AI Summary header
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) =>
                        DailySummaryScreen(selectedDate: _selectedDate),
                  ),
                );
              },
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI PILOT BRIEFING',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.blueAccent,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Tap for detailed forecast analysis',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.history,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.15),
            ),
            // Middle part: Day Selector
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: List.generate(5, (i) {
                  final date = now.add(Duration(days: i));
                  final isSelected =
                      date.year == _selectedDate.year &&
                      date.month == _selectedDate.month &&
                      date.day == _selectedDate.day;
                  final weekdays = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];
                  String dayName = '';
                  if (i == 0) {
                    dayName = 'TODAY';
                  } else if (i == 1) {
                    dayName = 'TOMORR';
                  } else {
                    dayName = weekdays[date.weekday - 1].toUpperCase();
                  }
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          height: 52,
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blueAccent.withValues(alpha: 0.2)
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blueAccent
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayName,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected
                                      ? Colors.blueAccent
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                date.day.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return ValueListenableBuilder<WeatherModel>(
      valueListenable: WeatherSettings.selectedModel,
      builder: (context, model, _) {
        final timeStr =
            "${_lastRefreshed!.hour.toString().padLeft(2, '0')}:${_lastRefreshed!.minute.toString().padLeft(2, '0')}";
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "MODEL: ${model.shortName}",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                "UPDATED: $timeStr",
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
    final timeline = FlightLogic.calculateTimeline(
      forecast!,
      site,
      selectedDate,
    );
    final optimalHours = timeline
        .where((h) => h.color == Colors.greenAccent)
        .length;
    final marginalHours = timeline
        .where((h) => h.color == Colors.orange)
        .length;
    final totalFlyableHours = optimalHours + marginalHours;
    final badgeColor = optimalHours > 0
        ? Colors.greenAccent
        : (marginalHours > 0
              ? Colors.orange
              : Theme.of(context).colorScheme.outline);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: evaluation.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: evaluation.color.withValues(alpha: 0.5),
          width: 1.5,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Section: Site Info & Wind Stats
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            site.name.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      evaluation.verdict.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${UnitSettings.convertKmh(currentData.windSpeed).round()} / ${UnitSettings.convertKmh(currentData.windGusts).round()} ${UnitSettings.unitString}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Center Section: Compass (Centered in available width)
              Expanded(
                flex: 2,
                child: Center(
                  child: WindCompass(
                    currentWind: currentData.windDirection,
                    faceDirection: site.faceDirection,
                    optimalRanges: site.optimalWindDirections,
                    arrowColor: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              // Right Section: Badges (Pushed to the edge)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (evaluation.notes.contains("Hill in cloud"))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _buildCloudHazardBadge(context),
                      ),
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
                    _buildWindowBadge(totalFlyableHours, badgeColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWindowBadge(int hours, Color color) {
    return Container(
      width: 85,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(
          hours > 0 ? "${hours}H WINDOW" : "NO WINDOW",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildCloudHazardBadge(BuildContext context) {
    return Container(
      width: 85,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.onSurface,
            size: 10,
          ),
          const SizedBox(width: 4),
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
      width: 85,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.comment, color: Colors.purpleAccent, size: 10),
          const SizedBox(width: 4),
          Text(
            '$count ${count == 1 ? 'REPORT' : 'REPORTS'}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.purpleAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class WindCompass extends StatefulWidget {
  final double currentWind;
  final double faceDirection;
  final List<WindDirectionRange> optimalRanges;
  final Color arrowColor;
  const WindCompass({
    super.key,
    required this.currentWind,
    required this.faceDirection,
    required this.optimalRanges,
    required this.arrowColor,
  });
  @override
  State<WindCompass> createState() => _WindCompassState();
}

class _WindCompassState extends State<WindCompass>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: WindDirectionPainter(
              currentWind: widget.currentWind,
              faceDirection: widget.faceDirection,
              optimalRanges: widget.optimalRanges,
              arrowColor: widget.arrowColor,
              dividerColor: Theme.of(
                context,
              ).dividerColor.withValues(alpha: 0.2),
              textColor: Colors.transparent,
              flowProgress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class WindDirectionPainter extends CustomPainter {
  final double currentWind;
  final double faceDirection;
  final List<WindDirectionRange> optimalRanges;
  final Color arrowColor;
  final Color dividerColor;
  final Color textColor;
  final double flowProgress;
  WindDirectionPainter({
    required this.currentWind,
    required this.faceDirection,
    required this.optimalRanges,
    required this.arrowColor,
    required this.dividerColor,
    required this.textColor,
    this.flowProgress = 0,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    // Background circle
    final bgPaint = Paint()
      ..color = dividerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);
    // Border
    final borderPaint = Paint()
      ..color = dividerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, borderPaint);
    // Compass labels removed as per request
    // Optimal Ranges
    final rangePaint = Paint()
      ..color = Colors.greenAccent
          .withValues(alpha: 0.8) // High opacity for "same green" look
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    for (var range in optimalRanges) {
      double startAngle = (range.min - 90) * (math.pi / 180);
      double sweepAngle = (range.max - range.min) * (math.pi / 180);
      if (range.max < range.min) {
        sweepAngle = (360 - range.min + range.max) * (math.pi / 180);
      }
      canvas.drawArc(
        rect.inflate(-3),
        startAngle,
        sweepAngle,
        false,
        rangePaint,
      );
    }
    // Draw Flowing Arrows
    // parrowPaint is used inside the loop for each moving arrow
    // windRad is direction wind is BLOWING TO
    double windRad = (currentWind + 90) * (math.pi / 180);
    // Number of arrows in the flow
    const arrowCount = 3;
    final totalLen = radius * 1.5; // Flow line length
    for (int i = 0; i < arrowCount; i++) {
      // Each arrow has an individual offset that cycles
      double individualProgress = (flowProgress + (i / arrowCount)) % 1.0;
      // Calculate position along the flow line centered on the compass
      double dist = (individualProgress - 0.5) * totalLen;
      double posX = center.dx + dist * math.cos(windRad);
      double posY = center.dy + dist * math.sin(windRad);
      // Fade in at start, fade out at end
      double opacity = 1.0;
      if (individualProgress < 0.2) opacity = individualProgress / 0.2;
      if (individualProgress > 0.8) opacity = (1.0 - individualProgress) / 0.2;
      final parrowPaint = Paint()
        ..color = arrowColor.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      // Small arrow head
      double headLen = 4.0;
      double headAngle = math.pi / 6;
      // Only draw if within (or mostly within) the circle to keep it clean
      double distFromCenter = math.sqrt(
        math.pow(posX - center.dx, 2) + math.pow(posY - center.dy, 2),
      );
      if (distFromCenter < radius - 2) {
        // Draw small arrowhead pointing in wind direction
        canvas.drawLine(
          Offset(posX, posY),
          Offset(
            posX - headLen * math.cos(windRad - headAngle),
            posY - headLen * math.sin(windRad - headAngle),
          ),
          parrowPaint,
        );
        canvas.drawLine(
          Offset(posX, posY),
          Offset(
            posX - headLen * math.cos(windRad + headAngle),
            posY - headLen * math.sin(windRad + headAngle),
          ),
          parrowPaint,
        );
        // Small tail line
        canvas.drawLine(
          Offset(posX, posY),
          Offset(
            posX - headLen * 1.5 * math.cos(windRad),
            posY - headLen * 1.5 * math.sin(windRad),
          ),
          parrowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant WindDirectionPainter oldDelegate) {
    return oldDelegate.flowProgress != flowProgress ||
        oldDelegate.currentWind != currentWind ||
        oldDelegate.arrowColor != arrowColor;
  }
}
