// lib/presentation/student/home/session_card.dart
//
// The card that appears when a session broadcast is detected.
// Stateless — all data flows in from StudentHomeController via the screen.
// Split out per project brief: presentation/student/home/session_card.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'student_home_controller.dart';

class SessionCard extends StatelessWidget {
  final DetectedSession session;
  final bool confirmed;
  final VoidCallback onConfirm;

  const SessionCard({
    super.key,
    required this.session,
    required this.confirmed,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(session: session),
          _CardDetails(session: session),
          _TimeStrip(session: session),
          _CardFooter(confirmed: confirmed, onConfirm: onConfirm),
        ],
      ),
    );
  }
}

// ── Header: badge + course title ──────────────────────────────────────────────
class _CardHeader extends StatelessWidget {
  final DetectedSession session;
  const _CardHeader({required this.session});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Signal detected badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sensors_rounded, size: 13, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  'SIGNAL DETECTED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Course code chip
          Text(
            session.courseCode,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          // Course name
          Text(
            session.courseName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Details row: lecturer + room ──────────────────────────────────────────────
class _CardDetails extends StatelessWidget {
  final DetectedSession session;
  const _CardDetails({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFFE2E8E4), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _InfoCell(
              icon: Icons.person_rounded,
              label: 'Lecturer',
              value: session.lecturerName,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _InfoCell(
              icon: Icons.location_on_rounded,
              label: 'Room',
              value: session.room,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
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
                  fontSize: 14,
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

// ── Time window strip ─────────────────────────────────────────────────────────
class _TimeStrip extends StatelessWidget {
  final DetectedSession session;
  const _TimeStrip({required this.session});

  @override
  Widget build(BuildContext context) {
    final color = session.isLate ? AppColors.warning : AppColors.secondary;
    final label = session.isLate ? 'LATE window' : 'PRESENT window';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule_rounded, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              _formatRemaining(session.remaining),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '($label)',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            const Text(
              'Confirm\nrequired',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textTertiary,
                height: 1.35,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRemaining(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')} left';
  }
}

// ── Footer: confirm button or confirmed badge ─────────────────────────────────
class _CardFooter extends StatelessWidget {
  final bool confirmed;
  final VoidCallback onConfirm;

  const _CardFooter({required this.confirmed, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: confirmed ? const _ConfirmedBadge() : _ConfirmButton(onTap: onConfirm),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ConfirmButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.check_circle_rounded, size: 20),
        label: const Text(
          'Confirm Attendance',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ConfirmedBadge extends StatelessWidget {
  const _ConfirmedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.presentBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.4)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
          SizedBox(width: 8),
          Text(
            'Attendance Confirmed',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.presentText,
            ),
          ),
        ],
      ),
    );
  }
}