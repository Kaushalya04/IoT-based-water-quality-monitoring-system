import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/history_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run automatic water quality + valve logic only on Android/mobile.
  // This prevents duplicate history when Web and Mobile are open together.
  if (!kIsWeb) {
    HistoryService.start();
  }

  runApp(const WaterQualityApp());
}

class WaterQualityApp extends StatelessWidget {
  const WaterQualityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Water Quality Monitoring',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}