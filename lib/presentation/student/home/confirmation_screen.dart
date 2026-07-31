// lib/presentation/student/home/confirmation_screen.dart [UPDATED]
//
// Student confirmation screen with room code validation.
//
// NEW BEHAVIOR:
// 1. Room code input field (case-insensitive, max 6 chars)
// 2. Validation: compare entered code with session.roomCode
// 3. Error message if code is wrong
// 4. Confirm button disabled until code is entered
// 5. Success overlay after confirmation

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oromark/data/models/auth_result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_state_provider.dart';
import 'student_home_controller.dart'; // DetectedSession lives here

class ConfirmationScreen extends ConsumerStatefulWidget {
  final DetectedSession session;
  final Future<String> Function(DetectedSession session,String studentId) onSubmit;
  const ConfirmationScreen({super.key, required this.session, required this.onSubmit});

  @override
 ConsumerState<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen> {
  late final TextEditingController _roomCodeController;
  bool _submitting = false;
  bool _confirmed = false;
  String? _codeError; // Shows error message if code validation fails

  @override
  void initState() {
    super.initState();
    _roomCodeController = TextEditingController();
    _roomCodeController.addListener(() {
      if (mounted) setState(() {});
    });
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  /// ✅ NEW: Validate the room code entered by the student
  /// Returns true if code matches, false otherwise
  bool _validateRoomCode() {
    final enteredCode = _roomCodeController.text.trim().toUpperCase();
    final actualCode = widget.session.roomCode.toUpperCase();

    // Check if empty
    if (enteredCode.isEmpty) {
      setState(() => _codeError = 'Room code is required');
      return false;
    }

    // Check if matches
    if (enteredCode != actualCode) {
      setState(() => _codeError = 'Incorrect room code. Try again.');
      HapticFeedback.lightImpact(); // Haptic feedback for error
      return false;
    }

    // ✅ Valid code
    setState(() => _codeError = null);
    return true;
  }

  Future<void> _handleConfirm() async {
    // ✅ First: Validate room code
    if (!_validateRoomCode()) {
      return; // Code is invalid, stop here
    }

    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);

    // TODO: Replace with actual submission via HTTP
    // await ref.read(studentHomeControllerProvider.notifier).submitAttendance(
    //   session: widget.session,
    //   studentId: 'U-2023-8841', // [MOCK] replace with real from Supabase
    // );
    try{
      final authState  =  ref.watch(authStateNotifierProvider);
      final authResult = authState.value;

      if (authResult == null) {
        setState(() => _codeError = 'You are not logged in');
        return;
      }
      final status = await widget.onSubmit(
        widget.session,
        authResult.userId,
      );
      if (!mounted) return;

      HapticFeedback.heavyImpact();
      setState(() {
        _submitting = false;
        _confirmed = true;
      });
      // Auto-pop after the success overlay shows
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) Navigator.of(context).pop();
      });
    }catch(e){
      if (!mounted) return;
      setState(() => _submitting = false);
      HapticFeedback.lightImpact();
      setState(() => _codeError = 'Failed to record attendance: $e');
      print('Failed to record attendance: $e');
    }
    // await Future.delayed(const Duration(milliseconds: 800));





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
                          // ── Session card ──────────────────────────────
                          _SessionCard(session: widget.session),
                          const SizedBox(height: 36),

                          // ✅ NEW: Room code input field with validation
                          _RoomCodeInput(
                            controller: _roomCodeController,
                            error: _codeError,
                            enabled: !_submitting && !_confirmed,
                            onSubmitted: _handleConfirm,
                          ),
                          const SizedBox(height: 16),

                          // ── Information hint about room code ──────────
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgTertiary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Check the board or ask your lecturer for the room code.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 36),

                          // ── Question prompt ───────────────────────────
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

                          // ── Confirm button ────────────────────────────
                          // [UPDATED] Only enabled if room code is filled
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: (_submitting ||
                                  _confirmed ||
                                  _roomCodeController.text.trim().isEmpty)
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

                          // ── Cancel button ─────────────────────────────
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
// ✅ NEW: Room code input widget
// ─────────────────────────────────────────────────────────────────────────────
class _RoomCodeInput extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final bool enabled;
  final VoidCallback onSubmitted;

  const _RoomCodeInput({
    required this.controller,
    required this.error,
    required this.enabled,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: error != null ? AppColors.error : const Color(0xFFE2E8E4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'Room Code',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Input field
          TextField(
            controller: controller,
            enabled: enabled,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmitted(),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(6),
            ],
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 2.0,
            ),
            decoration: InputDecoration(
              hintText: '_ _ _ _ _ _',
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18,
                letterSpacing: 2.0,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          // Error message
          if (error != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: AppColors.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session card
// ─────────────────────────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  final DetectedSession session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final isLate = session.isLate;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: course code + status badge ──────────────
          Row(
            children: [
              Expanded(
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isLate ? AppColors.lateBg : AppColors.bgPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isLate ? '⏱  LATE' : '✓  PRESENT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isLate ? AppColors.lateText : AppColors.success,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Details: lecturer + room ──────────────────────────
          Row(
            children: [
              Expanded(
                child: _DetailCell(
                  icon: Icons.person_rounded,
                  label: 'Lecturer',
                  value: session.lecturerName,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailCell(
                  icon: Icons.location_on_rounded,
                  label: 'Room',
                  value: session.room,
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
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
    final color = session.isLate ? AppColors.warning : AppColors.success;

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