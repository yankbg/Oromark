// lib/presentation/lecturer/session/session_stats.dart
//
// All small stat/display widgets used by ActiveSessionScreen.
// Kept in a separate file per the project brief's structure:
//   presentation/lecturer/session/session_stats.dart

import 'package:flutter/material.dart';
import 'package:oromark/data/models/course_model.dart';
import '../../../core/theme/app_colors.dart';
import 'session_controller.dart';

// ── Course header card ────────────────────────────────────────────────────────

class CourseHeaderCard extends StatelessWidget {
  final CourseModel course;
  final String room;
  final DateTime startedAt;

  const CourseHeaderCard({
    super.key,
    required this.course,
    required this.room,
    required this.startedAt,
  });

  @override
  Widget build(BuildContext context) {
    final h = startedAt.hour > 12
        ? startedAt.hour - 12
        : startedAt.hour == 0
        ? 12
        : startedAt.hour;
    final m    = startedAt.minute.toString().padLeft(2, '0');
    final ampm = startedAt.hour >= 12 ? 'PM' : 'AM';

    return Container(
      padding:     const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: const Color(0xFFE2E8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${course.courseCode} · ${course.courseName}',
            style: const TextStyle(
              fontFamily:  'Inter',
              fontSize:    20,
              fontWeight:  FontWeight.w700,
              color:       AppColors.primary,
              height:      1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MetaChip(
                icon:  Icons.meeting_room_rounded,
                label: 'Room $room',
              ),
              const SizedBox(width: 16),
              _MetaChip(
                icon:  Icons.schedule_rounded,
                label: 'Started $h:$m $ampm',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Cloud sync badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:        AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.20)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_done_rounded,
                    size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'Cloud Sync Active',
                  style: TextStyle(
                    fontFamily:  'Inter',
                    fontSize:    11,
                    fontWeight:  FontWeight.w600,
                    color:       AppColors.primary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize:   12,
            color:      AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Live status card (teal hero) ──────────────────────────────────────────────

class LiveStatusCard extends StatefulWidget {
  final ActiveSessionState state;
  final VoidCallback       onStartLateWindow;

  const LiveStatusCard({
    super.key,
    required this.state,
    required this.onStartLateWindow,
  });

  @override
  State<LiveStatusCard> createState() => _LiveStatusCardState();
}

class _LiveStatusCardState extends State<LiveStatusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync:    this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s        = widget.state;
    final remaining = s.remaining;
    final mins     = remaining.inMinutes;
    final secs     = remaining.inSeconds % 60;
    final isEnded  = s.window == SessionWindow.ended;
    final isLate   = s.window == SessionWindow.late;

    return Container(
      padding:     const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Live indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Opacity(
                  opacity: 0.5 + _pulse.value * 0.5,
                  child: Transform.scale(
                    scale: 1.0 + _pulse.value * 0.12,
                    child: const Icon(Icons.sensors_rounded,
                        size: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE SESSION STATUS',
                style: TextStyle(
                  fontFamily:    'Inter',
                  fontSize:      11,
                  fontWeight:    FontWeight.w600,
                  color:         Colors.white.withOpacity(0.80),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Window label
          Text(
            isEnded
                ? 'SESSION ENDED'
                : isLate
                ? 'LATE WINDOW'
                : 'PRESENT WINDOW',
            style: const TextStyle(
              fontFamily:    'Inter',
              fontSize:      22,
              fontWeight:    FontWeight.w900,
              color:         Colors.white,
              letterSpacing: 2.0,
            ),
          ),

          const SizedBox(height: 16),

          // Countdown
          if (!isEnded) ...[
            Text(
              '$mins:${secs.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontFamily:  'Inter',
                fontSize:    64,
                fontWeight:  FontWeight.w900,
                color:       Colors.white,
                height:      1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'minutes remaining',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize:   12,
                color:      Colors.white.withOpacity(0.70),
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            const SizedBox(height: 12),
            Icon(Icons.check_circle_rounded,
                size: 64, color: Colors.white.withOpacity(0.90)),
            const SizedBox(height: 20),
          ],

          // Action button
          if (s.window == SessionWindow.present)
            _ActionButton(
              icon:    Icons.history_rounded,
              label:   'Start Late Window',
              onTap:   widget.onStartLateWindow,
              bgColor: AppColors.secondary.withOpacity(0.18),
              fgColor: Colors.white,
            ),

          if (s.window == SessionWindow.late)
            _ActionButton(
              icon:    Icons.hourglass_bottom_rounded,
              label:   'Late Window Active',
              onTap:   () {},
              bgColor: Colors.white.withOpacity(0.12),
              fgColor: Colors.white.withOpacity(0.70),
            ),

          if (s.window == SessionWindow.ended)
            _ActionButton(
              icon:    Icons.bar_chart_rounded,
              label:   'View Summary',
              onTap:   () {},
              bgColor: Colors.white.withOpacity(0.15),
              fgColor: Colors.white,
            ),

          const SizedBox(height: 10),

          Text(
            isEnded
                ? 'Session has been closed'
                : 'Updates status for new check-ins',
            style: TextStyle(
              fontFamily:    'Inter',
              fontSize:      10,
              color:         Colors.white.withOpacity(0.60),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;
  final Color    bgColor;
  final Color    fgColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:        bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: fgColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily:  'Inter',
                fontSize:    14,
                fontWeight:  FontWeight.w700,
                color:       fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Metric cards (Present / Late) ─────────────────────────────────────────────

class MetricRow extends StatelessWidget {
  final int presentCount;
  final int lateCount;

  const MetricRow({
    super.key,
    required this.presentCount,
    required this.lateCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label:    'Present',
            count:    presentCount,
            subLabel: 'Students',
            color:    AppColors.primary,
            bgColor:  AppColors.presentBg,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            label:    'Late',
            count:    lateCount,
            subLabel: 'Flagged',
            color:    AppColors.secondary,
            bgColor:  AppColors.lateBg,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final int    count;
  final String subLabel;
  final Color  color;
  final Color  bgColor;

  const _MetricCard({
    required this.label,
    required this.count,
    required this.subLabel,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:     const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color:        AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: const Color(0xFFE2E8E4)),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily:    'Inter',
              fontSize:      11,
              fontWeight:    FontWeight.w600,
              color:         AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontFamily:  'Inter',
                  fontSize:    40,
                  fontWeight:  FontWeight.w800,
                  color:       color,
                  height:      1.0,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  subLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize:   11,
                    color:      AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Coverage footer ───────────────────────────────────────────────────────────

class CoverageFooter extends StatelessWidget {
  final ActiveSessionState state;
  const CoverageFooter({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final pct       = (state.coverageRate * 100).round();
    final remaining = state.notCheckedIn;

    return Container(
      padding:     const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration:  const BoxDecoration(
        color: AppColors.bgSecondary,
      ),
      child: Row(
        children: [
          Text(
            '$pct% coverage · $remaining remaining',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize:   12,
              color:      AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          // Pagination placeholders — wire to real pagination later
          _NavBtn(icon: Icons.chevron_left_rounded,  onTap: () {}),
          _NavBtn(icon: Icons.chevron_right_rounded, onTap: () {}),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}