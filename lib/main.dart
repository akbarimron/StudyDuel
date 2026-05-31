import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'app.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    await NotificationService().initialize();
    FirebaseService().initializeDataIfNeeded();
  } catch (e) {
    debugPrint("Firebase default init error: $e. Attempting fallback with explicit options...");
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyDBTVx1HVeO_oTVLtjT032C_C89LmuPwEc',
          appId: '1:395482754229:android:7edaab8edf74e5330b62fc',
          messagingSenderId: '395482754229',
          projectId: 'study-duel',
          databaseURL: 'https://study-duel-default-rtdb.firebaseio.com',
          storageBucket: 'study-duel.firebasestorage.app',
        ),
      );
      await NotificationService().initialize();
      await FirebaseService().initializeDataIfNeeded();
      debugPrint("Firebase successfully initialized via explicit options fallback.");
    } catch (fallbackError) {
      debugPrint("Firebase fallback initialization also failed: $fallbackError");
    }
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const StudyDuelApp());
}
