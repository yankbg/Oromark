// lib/presentation/student/home/confirmation_screen.dart
//
// Simple confirm-or-cancel attendance screen.
// No biometric, no PIN — just a session summary and two action buttons.
// On confirm → success overlay → auto-pop back to home.
// On cancel  → immediately pops back.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import 'student_home_controller.dart'; // DetectedSession lives here

class ConfirmationScreen extends StatefulWidget {
  final DetectedSession session;
  const ConfirmationScreen({super.key, required this.session});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  bool _submitting = false;
  bool _confirmed  = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<void> _handleConfirm() async {
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);

    // TODO: replace with ConfirmAttendanceUseCase → HTTP POST + DB insert
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _submitting = false;
      _confirmed  = true;
    });

    // Auto-pop after the success overlay shows
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _handleCancel() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end:   Alignment.bottomCenter,
            stops: [0.0, 0.42],
            colors: [AppColors.primary, AppColors.bgSecondary],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Main content ──────────────────────────────────────────────
              Column(
                children: [
                  _AppBar(onBack: _handleCancel),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                      child: Column(
                        children: [
                          // ── Session card ──────────────────────────────────
                          _SessionCard(session: widget.session),
                          const SizedBox(height: 36),

                          // ── Question prompt ───────────────────────────────
                          Text(
                            'Are you physically present\nin this lecture hall?',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your submission is tied to this device.\nOnly confirm if you are in the room.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Confirm button ────────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: (_submitting || _confirmed)
                                  ? null
                                  : _handleConfirm,
                              icon: _submitting
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                              ),
                              label: Text(
                                _submitting
                                    ? 'Recording...'
                                    : 'Yes, I\'m Present',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // ── Cancel button ─────────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton.icon(
                              onPressed: (_submitting || _confirmed)
                                  ? null
                                  : _handleCancel,
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 20,
                              ),
                              label: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Success overlay ───────────────────────────────────────────
              if (_confirmed)
                _SuccessOverlay(isLate: widget.session.isLate),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar
// ─────────────────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final VoidCallback onBack;
  const _AppBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Confirm Attendance',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48), // balance the back button
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session summary card  (frosted-glass style)
// ─────────────────────────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  final DetectedSession session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final now     = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    final isLate  = session.isLate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFBEC9C3).withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Course ─────────────────────────────────────────
          const Text(
            'COURSE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            session.courseCode,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            session.courseName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFE2E8E4)),
          ),

          // ── Lecturer + room row ────────────────────────────
          Row(
            children: [
              _DetailCell(
                icon: Icons.person_rounded,
                label: 'Lecturer',
                value: session.lecturerName,
              ),
              const SizedBox(width: 24),
              _DetailCell(
                icon: Icons.location_on_rounded,
                label: 'Room',
                value: session.room,
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFE2E8E4)),
          ),

          // ── Time + status row ──────────────────────────────
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '$timeStr · Today',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Window status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isLate ? AppColors.lateBg : AppColors.primary,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  isLate ? '⏱  LATE' : '✓  PRESENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isLate ? AppColors.lateText : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          // ── Remaining time bar ─────────────────────────────
          const SizedBox(height: 16),
          _RemainingBar(session: session),
        ],
      ),
    );
  }
}

class _DetailCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 1),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }
}

// Thin time-remaining progress bar inside the card
class _RemainingBar extends StatelessWidget {
  final DetectedSession session;
  const _RemainingBar({required this.session});

  @override
  Widget build(BuildContext context) {
    final remaining = session.remaining;
    final total = session.isLate
        ? session.lateCutoff.difference(session.presentCutoff)
        : session.presentCutoff.difference(
        session.presentCutoff.subtract(const Duration(minutes: 20)));
    final progress = (remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0);
    final color    = session.isLate ? AppColors.warning : AppColors.success;

    final m = remaining.inMinutes;
    final s = remaining.inSeconds % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Window closes in',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
            Text(
              '$m:${s.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppColors.bgTertiary,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Success overlay
// ─────────────────────────────────────────────────────────────────────────────
class _SuccessOverlay extends StatefulWidget {
  final bool isLate;
  const _SuccessOverlay({required this.isLate});

  @override
  State<_SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<_SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>    _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: AppColors.primary,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Elastic bounce checkmark orb
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1.0),
                duration: const Duration(milliseconds: 550),
                curve: Curves.elasticOut,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    size: 70,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Confirmed!',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your attendance has been recorded.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.80),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  widget.isLate ? '⏱  LATE' : '✓  PRESENT',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.0,
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