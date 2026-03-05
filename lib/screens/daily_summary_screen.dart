import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/site.dart';
import '../models/weather_data.dart';
import '../services/weather_api.dart';
import '../services/ai_service.dart';
import '../services/pilot_report_service.dart';

class DailySummaryScreen extends StatefulWidget {
  final DateTime selectedDate;
  const DailySummaryScreen({super.key, required this.selectedDate});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  final WeatherApi _weatherApi = WeatherApi();
  final AIService _aiService = AIService();
  final Map<String, List<WeatherData>> _siteForecasts = {};
  bool _isLoading = true;
  bool _isAiLoading = false;
  String _errorMessage = '';
  String _aiSummary = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _aiSummary = '';
    });
    try {
      final forecastMap = await _weatherApi.fetchForecastBatch(walesSites);
      if (mounted) {
        setState(() {
          _siteForecasts.clear();
          _siteForecasts.addAll(forecastMap);
          _isLoading = false;
        });
        // Auto-trigger AI summary once data is ready
        _fetchAiSummary();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load summary: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAiSummary() async {
    if (!mounted) return;
    setState(() => _isAiLoading = true);
    try {
      final reports = await PilotReportService().getAllRecentReportsFuture();
      final summary = await _aiService.getAIBriefing(
        allForecasts: _siteForecasts,
        targetDate: widget.selectedDate,
        pilotReports: reports,
      );
      if (mounted) {
        setState(() {
          _aiSummary = summary;
          _isAiLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiSummary = "Error generating AI summary: $e";
          _isAiLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'AI SUMMARY',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.redAccent),
              ),
            )
          : _buildBriefingView(),
    );
  }

  Widget _buildBriefingView() {
    final now = DateTime.now();
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildAiSummarySection(),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Last updated: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: Theme.of(context).dividerColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 18),
            const SizedBox(width: 8),
            Text(
              'AI PILOT BRIEFING',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            if (_isAiLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blueAccent,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.blueAccent.withValues(alpha: 0.15),
            ),
          ),
          child: _isAiLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "AI is analyzing weather data...",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _aiSummary.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          size: 48,
                          color: Colors.blueAccent.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Briefing data ready for analysis",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchAiSummary,
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: const Text("GENERATE AI BRIEFING"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent.withValues(
                              alpha: 0.1,
                            ),
                            foregroundColor: Colors.blueAccent,
                            elevation: 0,
                            side: BorderSide(
                              color: Colors.blueAccent.withValues(alpha: 0.4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : MarkdownBody(
                  data: _aiSummary,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.7,
                      fontWeight: FontWeight.w400,
                    ),
                    h1: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      height: 2.0,
                    ),
                    h2: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      height: 1.8,
                    ),
                    h3: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      height: 1.6,
                    ),
                    strong: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w900,
                    ),
                    listBullet: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 15,
                    ),
                    listIndent: 24,
                    blockSpacing: 16,
                  ),
                ),
        ),
      ],
    );
  }
}
