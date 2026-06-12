// lib/presentation/student/home/student_home_screen.dart
//
// Shell only — no business logic, no state of its own.
// All logic lives in StudentHomeController.
// Widgets live in session_card.dart and shared/widgets/.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import 'student_home_controller.dart';
import 'session_card.dart';
import 'confirmation_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen>
    with TickerProviderStateMixin {
  late final StudentHomeController _controller;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _controller = StudentHomeController(vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          const _TopBar(userName: 'Alex'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 96),
              child: Column(
                children: [
                  _ScanningHero(
                    wave1: _controller.wave1,
                    wave2: _controller.wave2,
                    compact: _controller.session != null,
                  ),
                  if (_controller.session != null) ...[
                    const SizedBox(height: 28),
                    SessionCard(
                      session: _controller.session!,
                      confirmed: _controller.confirmed,
                      onConfirm: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ConfirmationScreen(session: _controller.session!),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _controller.navIndex,
        onTap: _controller.setNavIndex,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String userName;
  const _TopBar({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPrimary,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8E4), width: 1),
            ),
          ),
          child: Row(
            children: [
              Image.asset('assets/oromark.jpg', height: 26, fit: BoxFit.contain),
              const SizedBox(width: 8),
              const Text(
                'OROmark',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              // Avatar
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.10),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scanning hero — pulsing orb with WIDE wave rings
// ─────────────────────────────────────────────────────────────────────────────
class _ScanningHero extends StatelessWidget {
  final AnimationController wave1;
  final AnimationController wave2;
  final bool compact;

  const _ScanningHero({
    required this.wave1,
    required this.wave2,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    // Orb sits at the centre; waves expand to near full screen width
    final orbSize   = compact ? 100.0  : 160.0;
    final iconSize  = compact ? 34.0   : 56.0;

    // baseRingSize is what the ring starts at (inner edge); it grows to
    // baseRingSize * maxScale via animation. Making it ~50% of screen width
    // gives rings that feel like real radio waves, not tight bubbles.
    final baseRingSize = compact
        ? screenW * 0.28   // compact: starts at ~28% screen width
        : screenW * 0.42;  // full: starts at ~42% screen width

    return Column(
      children: [
        SizedBox(
          // Container must be big enough for the fully expanded ring.
          // max scale is 2.4 (see _WaveRing), so we need baseRingSize * 2.4.
          // Add a little headroom.
          width:  compact ? screenW * 0.7 : screenW,
          height: compact ? screenW * 0.5 : screenW * 0.75,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: wave1,
                builder: (_, __) => _WaveRing(
                  progress: wave1.value,
                  baseSize: baseRingSize,
                ),
              ),
              AnimatedBuilder(
                animation: wave2,
                builder: (_, __) => _WaveRing(
                  progress: wave2.value,
                  baseSize: baseRingSize,
                ),
              ),
              // Core orb
              Container(
                width: orbSize,
                height: orbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.30),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.sensors_rounded,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            ],
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 16),
          const Text(
            'Searching for session...',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep screen active to detect\nsessions nearby via signal.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ],
    );
  }
}

// Ring widget: starts at baseSize and expands outward as progress → 1.0
class _WaveRing extends StatelessWidget {
  final double progress;
  final double baseSize;

  const _WaveRing({required this.progress, required this.baseSize});

  @override
  Widget build(BuildContext context) {
    // Scale from 1.0 → 2.4 so rings travel far from the orb
    final scale   = 1.0 + progress * 1.4;
    // Fade out completely by the time the ring reaches its max size
    final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.45;
    final size    = baseSize * scale;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withOpacity(opacity),
          width: 1.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom navigation bar
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  static const _items = [
    (icon: Icons.home_rounded,    label: 'Home'),
    (icon: Icons.history_rounded, label: 'History'),
    (icon: Icons.person_rounded,  label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(top: BorderSide(color: Color(0xFFE2E8E4), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final active = selectedIndex == i;
              final item   = _items[i];
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 80,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary.withOpacity(0.10)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Icon(
                          item.icon,
                          size: 23,
                          color: active
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                          active ? FontWeight.w600 : FontWeight.w400,
                          color: active
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}