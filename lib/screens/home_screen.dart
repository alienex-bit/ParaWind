import 'package:flutter/material.dart';
import '../utils/unit_converter.dart';
import '../models/weather_data.dart';
import '../services/weather_api.dart';
import '../data/sites_data.dart';
import '../widgets/daily_summary_card.dart';
import '../widgets/status_header.dart';
import '../widgets/site_card.dart';
import '../widgets/settings_drawer.dart';

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
          'PARAWIND',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      drawer: SettingsDrawer(onWeatherModelChanged: _fetchData),
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
                      StatusHeader(lastRefreshed: _lastRefreshed),
                      DailySummaryCard(
                        selectedDate: _selectedDate,
                        onDateSelected: (date) {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                      ),
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
}
