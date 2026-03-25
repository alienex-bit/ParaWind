import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: "REPLACED_BY_YOUR_KEY",
        appId: "1:839225060770:web:f53500698d01c0e156d6fb",
        messagingSenderId: "839225060770",
        projectId: "swwsc-weather",
        authDomain: "swwsc-weather.firebaseapp.com",
        storageBucket: "swwsc-weather.firebasestorage.app",
      );
    }
    // For Android and iOS, Firebase will use the google-services.json and GoogleService-Info.plist files
    // so we don't strictly need to provide them here if using standard initialization,
    // but we can provide placeholders or actual values if needed.
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }
}
