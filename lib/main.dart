  // lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/services/sync_service.dart';
import 'presentation/lecturer/courses/course_list_screen.dart';
import 'presentation/login_screen.dart';
import 'presentation/splash/splash_screen.dart';
import 'presentation/student/home/student_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //This must be first
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  //Keep native splash visible until we say so
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Cloud name + upload preset for profile picture uploads — not secrets,
  // safe to bundle (unsigned upload preset, no API secret used).
  // .env is gitignored, so a fresh checkout without one must not crash the
  // whole app at startup — just leave profile-picture upload unavailable.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[main] .env not found — profile picture upload will be unavailable: $e');
  }

  // Lock to portrait — attendance app does not need landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Best-effort push of whatever's unsynced to the Neon-backed dashboard.
  // Fire-and-forget: must never block startup or affect the live
  // UDP/HTTP attendance flow, which stays entirely local and offline.
  // No-ops silently if SYNC_API_URL isn't configured or there's no internet.
  unawaited(SyncService(AppDatabase()).syncNow());

  runApp(
    // ProviderScope is required — wraps the entire app for Riverpod
    const ProviderScope(
      child: OROmarkApp(),
    ),
  );
}

class OROmarkApp extends StatelessWidget {
  const OROmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OROmark',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Splash is the first screen — it handles routing
      home: const SplashScreen(),
      routes: {
        '/login':            (_) => const LoginScreen(),
        '/student/home':     (_) => const StudentHomeScreen(),
        '/lecturer/courses': (_) => const CourseListScreen(),
      },
    );
  }
}