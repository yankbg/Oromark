// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
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

  // Lock to portrait — attendance app does not need landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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