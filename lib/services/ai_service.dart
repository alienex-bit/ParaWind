import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/site.dart';
import '../models/weather_data.dart';
import '../models/pilot_report.dart';
import 'flight_logic.dart';
import '../utils/unit_converter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  static const String _apiKeyKey = 'gemini_api_key';
  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_apiKeyKey);
    if (savedKey != null && savedKey.isNotEmpty) return savedKey;
    return null;
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, key);
  }

  Future<String> getAIBriefing({
    required Map<String, List<WeatherData>> allForecasts,
    required DateTime targetDate,
    List<PilotReport>? pilotReports,
  }) async {
    final now = DateTime.now();
    final isToday =
        targetDate.year == now.year &&
        targetDate.month == now.month &&
        targetDate.day == now.day;
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final dayName = days[targetDate.weekday - 1];
    final dateStr =
        "$dayName ${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}";
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    String hiddenQuestion;
    if (isToday) {
      final isOutOfHours = now.hour < 8 || now.hour > 20;
      hiddenQuestion = isOutOfHours
          ? "Summarize today's ($dateStr) flying weather in South Wales. Since it is currently $timeStr (likely out of legal flying hours), focus on how the day was/is ending and if there were any missed windows or if things are blown out. Provide a technical 'post-flight' brief."
          : "Provide a technical 'at-a-glance' briefing for South Wales flying sites right now at $timeStr on $dateStr. Focus on current flyable windows, stability, and safety risks for the remaining part of the day.";
    } else {
      hiddenQuestion =
          "Analyze the expected flying weather for South Wales on $dateStr. Based on the forecast data, identify the best flyable windows across all sites, highlight any safety risks (gusts, rain, crosswinds), and provide a technical 'pre-flight' planning brief for the day.";
    }
    return askPilotAssistant(
      question: hiddenQuestion,
      allForecasts: allForecasts,
      targetDate: targetDate,
      pilotReports: isToday ? pilotReports : null, // Only reports for today
    );
  }

  Future<String> askPilotAssistant({
    required String question,
    required Map<String, List<WeatherData>> allForecasts,
    required DateTime targetDate,
    List<PilotReport>? pilotReports,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return "Please set your Gemini API Key in Settings to use the AI Assistant.";
    }
    try {
      final model = GenerativeModel(
        model: 'models/gemini-2.5-flash',
        apiKey: apiKey,
      );
      final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      final dayName = days[targetDate.weekday - 1];
      final formattedDate =
          "$dayName ${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}";
      final contextPrompt = _buildContextPrompt(
        allForecasts,
        targetDate,
        pilotReports,
      );
      final unitStr =
          "Speed: ${UnitSettings.unitString}, Altitude: ${UnitSettings.heightUnitString}, Pressure: ${UnitSettings.pressureUnitString}";
      final fullPrompt =
          """
You are an expert Paragliding and Hang Gliding Flight Instructor and Weather Analyst.
Your goal is to provide safety-focused, technical, yet easy-to-understand advice to pilots based on the provided weather data.
SYSTEM CONFIGURATION:
- Units to use in response: $unitStr
- Analysis Date: $formattedDate
- Current Local Time: ${DateTime.now().toString()}
CONTEXT DATA (South Wales Sites):
$contextPrompt
USER QUESTION / REQUEST:
$question
RESPONSE GUIDELINES:
1. Prioritize PILOT GROUND REPORTS over forecast data if available, as they represent live "ground truth".
2. Be technical but concise. 
3. Prioritize safety: highlight gust factor (wind vs gusts), turbulence risks, or rain.
4. Use the preferred units ($unitStr) for any values mentioned.
5. IMPORTANT: Use COMPASS DIRECTIONS (e.g., NW, NNE, S) for wind instead of degrees.
6. IMPORTANT: Always refer to the date as $formattedDate (DAY dd/mm/year).
7. Format your response using Markdown (bold text for site names, bullet points for key metrics).
8. If a status is UNFLYABLE, always label it as "probably UNFLYABLE" to reflect forecast uncertainty.
9. If there are no pilot reports mentioned in the context for a site, include the note: "There are no pilots reports via the APP although you may want to check SWWSC telegram threads for more information."
10. Explicitly mention if a site is "clagged in" (cloud base <= takeoff height + 50m) or if there is a low ceiling.
11. HIGHLIGHT atmospheric instability: if CAPE > 500 or Lifted Index < 0, warn about potential for rapid over-development, even if the current wind is good.
12. Do not include a lengthy introduction or conclusion. Get straight to the analysis.
""";
      final content = [Content.text(fullPrompt)];
      final response = await model.generateContent(content);
      return response.text ?? "I couldn't generate a response at this time.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  String _buildContextPrompt(
    Map<String, List<WeatherData>> allForecasts,
    DateTime targetDate,
    List<PilotReport>? pilotReports,
  ) {
    StringBuffer buffer = StringBuffer();
    // Add Pilot Reports first as they are "ground truth" (only relevant for Today)
    if (pilotReports != null && pilotReports.isNotEmpty) {
      buffer.writeln("PILOT GROUND REPORTS (Real-time observations today):");
      for (var report in pilotReports) {
        final site = walesSites.firstWhere(
          (s) => s.id == report.siteId,
          orElse: () => const Site(
            id: 'unknown',
            name: 'Unknown Site',
            latitude: 0,
            longitude: 0,
            elevation: 0,
            takeOffHeight: 0,
            optimalWindDirections: [],
            faceDirection: 0,
          ),
        );
        buffer.writeln(
          "- At ${site.name} (${report.timestamp.hour}:${report.timestamp.minute.toString().padLeft(2, '0')}):",
        );
        buffer.writeln(
          "  * Wind: ${report.windSpeedMin}-${report.windSpeedMax} ${UnitSettings.unitString} from ${UnitSettings.degreesToCompass(report.windDirection)}",
        );
        buffer.writeln("  * Cloud: ${report.cloudCover}");
        if (report.observations.isNotEmpty) {
          buffer.writeln("  * Observation: \"${report.observations}\"");
        }
      }
      buffer.writeln("\nWEATHER FORECAST DATA:");
    }
    for (var site in walesSites) {
      final forecast = allForecasts[site.id];
      if (forecast != null && forecast.isNotEmpty) {
        final wd = FlightLogic.getDayWeather(forecast, targetDate);
        final eval = FlightLogic.evaluateCondition(wd, site);
        buffer.writeln("- ${site.name}:");
        buffer.writeln("  * Status: ${eval.status.name}");
        buffer.writeln(
          "  * Wind: ${wd.windSpeed.toStringAsFixed(1)} ${UnitSettings.unitString} from ${UnitSettings.degreesToCompass(wd.windDirection)}",
        );
        buffer.writeln(
          "  * Gusts: ${wd.windGusts.toStringAsFixed(1)} ${UnitSettings.unitString}",
        );
        buffer.writeln(
          "  * Optimal Directions: ${site.optimalWindDirections.map((r) => '${UnitSettings.degreesToCompass(r.min.toDouble())}-${UnitSettings.degreesToCompass(r.max.toDouble())}').join(', ')}",
        );
        if (wd.precipitation > 0) {
          buffer.writeln("  * PRECIPITATION: ${wd.precipitation}mm");
        }
        final cb = FlightLogic.calculateCloudbase(wd.temperature, wd.dewPoint);
        buffer.writeln(
          "  * Cloudbase: ${cb.round()}m (Takeoff: ${site.takeOffHeight}m)",
        );
        buffer.writeln("  * CAPE: ${wd.cape.round()} J/kg");
        buffer.writeln(
          "  * Lifted Index: ${wd.liftedIndex.toStringAsFixed(1)}\n",
        );
      }
    }
    return buffer.toString();
  }
}
