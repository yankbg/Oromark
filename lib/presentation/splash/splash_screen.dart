// lib/presentation/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late final AnimationController _logoController;
  late final AnimationController _taglineController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset>  _taglineSlide;

  @override
  void initState() {
    super.initState();

    // White background so logo looks natural — no status bar tint
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _logoController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve:  Curves.easeOutBack,
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve:  const Interval(0.0, 0.65, curve: Curves.easeIn),
      ),
    );

    _taglineController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 500),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _taglineController,
        curve:  Curves.easeIn,
      ),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end:   Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _taglineController,
        curve:  Curves.easeOut,
      ),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    FlutterNativeSplash.remove();

    await Future.delayed(const Duration(milliseconds: 250));
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    await _taglineController.forward();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) _navigate();
  }

  void _navigate() {
    // ── MOCK navigation ───────────────────────────────────
    // Goes straight to login for now.
    // When Supabase is connected, your friend replaces this
    // with a real session check.
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // White background — matches the logo's own background
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            // ── Main content ──────────────────────────────
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // ── Logo image ──────────────────────
                      ScaleTransition(
                        scale: _logoScale,
                        child: FadeTransition(
                          opacity: _logoOpacity,
                          child: Image.asset(
                            'assets/oromark.jpg',
                            // Wide enough to show the full wordmark
                            width: double.infinity,
                            fit:   BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Tagline ─────────────────────────
                      SlideTransition(
                        position: _taglineSlide,
                        child: FadeTransition(
                          opacity: _taglineOpacity,
                          child: const Text(
                            'Mark your presence',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize:      16,
                              fontWeight:    FontWeight.w400,
                              color:         Color(0xFF6B7280),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Loading indicator ─────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: FadeTransition(
                opacity: _taglineOpacity,
                child: Column(
                  children: [
                    // Thin teal progress indicator — matches brand
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth:  2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF0F9E8A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'IUEA · Kampala, Uganda',
                      style: TextStyle(
                        fontSize:      12,
                        color:         Color(0xFFADB5BD),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}