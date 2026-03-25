import 'package:flutter/material.dart';
import 'screens/disclaimer_screen.dart';
import 'utils/unit_converter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await UnitSettings.init();
  await ThemeSettings.init();
  await WeatherSettings.init();
  await WindBandSettings.init();
  runApp(const WeatherApp());
}


class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeSettings.selectedTheme,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          title: 'ParaWind',
          debugShowCheckedModeBanner: false,
          themeMode: currentThemeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blueAccent,
              brightness: Brightness.light,
              surface: const Color(0xFFF5F7FA), // Light surface
            ),
            scaffoldBackgroundColor: const Color(0xFFEef2F6),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blueAccent,
              brightness: Brightness.dark,
              surface: const Color(0xFF242835),
              surfaceContainerLowest:
                  Colors.black, // Background for pure black enthusiasts
            ),
            scaffoldBackgroundColor: Colors.black,
            useMaterial3: true,
          ),
          home: const DisclaimerScreen(),
        );
      },
    );
  }
}
