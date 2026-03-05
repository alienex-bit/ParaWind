import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/disclaimer_screen.dart';
import 'utils/unit_converter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Firebase configuration from google-services.json
    // These values are from your Firebase project: swwsc-weather
    if (kIsWeb) {
      // Web Firebase initialization
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: "REPLACED_BY_YOUR_KEY",
          appId: "1:839225060770:web:f53500698d01c0e156d6fb",
          messagingSenderId: "839225060770",
          projectId: "swwsc-weather",
          authDomain: "swwsc-weather.firebaseapp.com",
          storageBucket: "swwsc-weather.firebasestorage.app",
        ),
      );
    } else {
      // Android/iOS Firebase initialization (uses google-services.json)
      await Firebase.initializeApp();
    }
    debugPrint("Firebase initialized successfully");
    // Auto-login anonymously to satisfy firestore rules for submitting reports
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
        debugPrint("Anonymous sign-in successful");
      } catch (e) {
        debugPrint("Anonymous sign-in failed: $e. Falling back to email auth.");
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: "guest@swwsc.com",
            password: "guestuser123!",
          );
          debugPrint("Guest email sign-in successful");
        } catch (e) {
          try {
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: "guest@swwsc.com",
              password: "guestuser123!",
            );
            debugPrint("Guest email sign-up successful");
          } catch (e) {
            debugPrint("All auto-auth fallbacks failed: $e");
          }
        }
      }
    }
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
    debugPrint(
      "This may happen if google-services.json is missing or misconfigured.",
    );
    // Show error screen if Firebase fails
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF12141C),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Firebase Initialization Error',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    e.toString(),
                    style: const TextStyle(color: Colors.yellow, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return;
  }
  await UnitSettings.init();
  await ThemeSettings.init();
  await WeatherSettings.init();
  runApp(const WeatherApp());
}

// Check if running on web
const kIsWeb = bool.fromEnvironment('dart.library.js_util');

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeSettings.selectedTheme,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          title: 'SWWSC Weather',
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
