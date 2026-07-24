// lib/presentation/student/home/confirmation_screen.dart
//
// UPDATED VERSION: Real HTTP submission to lecturer's server.
// Handles network errors, timeouts, and displays appropriate feedback.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oromark/data/services/attendace_submission_service.dart';
import '../../../core/theme/app_colors.dart';
import 'student_home_controller.dart';
import '../../../providers/app_database_provider.dart';


class ConfirmationScreen extends ConsumerStatefulWidget {
  final DetectedSession session;
  final String studentId;
  final Future<String> Function({
  required DetectedSession session,
  required String studentId,
  })? onSubmit;

  const ConfirmationScreen({
    super.key,
    required this.session,
    this.studentId = 'U-2023-8841', // [MOCK] — will be replaced with real auth
    this.onSubmit,
  });

  @override
  ConsumerState<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen> {
  bool _submitting = false;
  bool _confirmed = false;
  String? _error;
  String? _status; // PRESENT, LATE, ABSENT

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<void> _handleConfirm() async {
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);

    try {
      String status;

      if (widget.onSubmit != null) {
        // Use provided callback (for testing/custom behavior)
        status = await widget.onSubmit!(
          session: widget.session,
          studentId: widget.studentId,
        );
      } else {
        // Real HTTP submission to lecturer's server
        status = await _submitToServer();
      }

      if (!mounted) return;

      HapticFeedback.heavyImpact();
      setState(() {
        _submitting = false;
        _confirmed = true;
        _status = status;
        _error = null;
      });

      // Auto-pop after success overlay shows
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) Navigator.of(context).pop();
      });
    } catch (e) {
      if (!mounted) return;

      HapticFeedback.lightImpact();
      setState(() {
        _submitting = false;
        _error = _formatErrorMessage(e);
      });

      print('[ConfirmationScreen] Error: $e');
    }
  }

  /// Real HTTP submission to lecturer's server
  Future<String> _submitToServer() async {
    print('[ConfirmationScreen] Submitting to ${widget.session.lecturerIP}:${widget.session.lecturerPort}');

    // TODO: Get database from Riverpod provider
    final db = ref.read(appDatabaseProvider);
    final service = AttendanceSubmissionService(db);

    final status = await service.submitAttendance(
      session: widget.session,
      studentId: widget.studentId,
    );

    return status;
  }

  String _formatErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'Connection timeout. Check WiFi and try again.';
    } else if (error is NetworkException) {
      return error.message;
    } else if (error is BadRequestException) {
      return error.message;
    } else if (error is DuplicateSubmissionException) {
      return 'Already submitted. No duplicate entries allowed.';
    } else if (error is NotFoundException) {
      return 'Session not found. Try again.';
    } else {
      return error.toString();
    }
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
            end: Alignment.bottomCenter,
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

                          // ── Error message ─────────────────────────────────
                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.error.withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: AppColors.error,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.error,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

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
              if (_confirmed && _status != null)
                _SuccessOverlay(
                  isLate: widget.session.isLate,
                  status: _status!,
                ),
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
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session card (same as before)
// ─────────────────────────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  final DetectedSession session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.courseCode,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            session.courseName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _DetailCell(
            icon: Icons.person_rounded,
            label: 'Lecturer',
            value: session.lecturerName,
          ),
          const SizedBox(height: 12),
          _DetailCell(
            icon: Icons.location_on_rounded,
            label: 'Room',
            value: session.room,
          ),
          const SizedBox(height: 12),
          _DetailCell(
            icon: Icons.vpn_key_rounded,
            label: 'Room Code',
            value: session.roomCode,
          ),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RemainingBar extends StatelessWidget {
  final DetectedSession session;
  const _RemainingBar({required this.session});

  @override
  Widget build(BuildContext context) {
    final remaining = session.remaining;
    final isLate = session.isLate;
    final color = isLate ? AppColors.warning : AppColors.success;

    final m = remaining.inMinutes;
    final s = remaining.inSeconds % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isLate ? 'Late window closes in' : 'Present window closes in',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
            value: remaining.inSeconds > 0
                ? (remaining.inSeconds / (20 * 60)).clamp(0.0, 1.0)
                : 0.0,
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
  final String status;

  const _SuccessOverlay({required this.isLate, required this.status});

  @override
  State<_SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<_SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

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
    final statusText = widget.status == 'LATE' ? '⏱ LATE' : '✓ PRESENT';

    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: AppColors.primary,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  statusText,
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