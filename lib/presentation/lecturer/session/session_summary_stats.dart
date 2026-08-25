// lib/presentation/lecturer/session/session_summary_stats.dart
//
// Display widgets for the session summary screen.
// Kept separate per the project brief's file structure.

import 'package:flutter/material.dart';
import 'package:oromark/presentation/lecturer/session/manual_override_screen.dart';
import '../../../core/theme/app_colors.dart';
import 'session_controller.dart';

// ── Session header ────────────────────────────────────────────────────────────

class SessionSummaryHeader extends StatelessWidget {
  final SessionSummaryState state;
  final VoidCallback        onShare;
  final VoidCallback        onPrint;

  const SessionSummaryHeader({
    super.key,
    required this.state,
    required this.onShare,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final h    = state.endedAt.hour > 12
        ? state.endedAt.hour - 12
        : state.endedAt.hour == 0
        ? 12
        : state.endedAt.hour;
    final m    = state.endedAt.minute.toString().padLeft(2, '0');
    final ampm = state.endedAt.hour >= 12 ? 'PM' : 'AM';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb
        Text(
          'SESSION SUMMARY',
          style: TextStyle(
            fontFamily:    'Inter',
            fontSize:      12,
            fontWeight:    FontWeight.w600,
            color:         AppColors.primary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),

        // Title
        Text(
          'Session Ended - ${state.courseCode}',
          style: const TextStyle(
            fontFamily:  'Inter',
            fontSize:    28,
            fontWeight:  FontWeight.w700,
            color:       AppColors.textPrimary,
            height:      1.2,
          ),
        ),
        const SizedBox(height: 12),

        // Meta: Duration + Closed time
        Row(
          children: [
            _MetaItem(
              icon:  Icons.schedule_rounded,
              label: 'Duration: ${state.durationMinutes} minutes',
            ),
            const SizedBox(width: 20),
            _MetaItem(
              icon:  Icons.timer_off_rounded,
              label: 'Closed at: $h:$m $ampm',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Share + Print buttons
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onShare,
              icon:      const Icon(Icons.share_rounded, size: 18),
              label:     const Text('Share'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: Color(0xFFBEC9C3)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onPrint,
              icon:      const Icon(Icons.print_rounded, size: 18),
              label:     const Text('Print Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation:       0,
                minimumSize:     Size.zero,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize:   14,
            color:      AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Stats card ────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String label;
  final int    count;
  final int?   total;  // null = no denominator
  final double percentage; // 0.0 to 1.0
  final Color  color;

  const StatCard({
    super.key,
    required this.label,
    required this.count,
    this.total,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:     const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: const Color(0xFFE2E8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily:    'Inter',
              fontSize:      10,
              fontWeight:    FontWeight.w600,
              color:         AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
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
              if (total != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '/ $total',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize:   12,
                      color:      AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value:           percentage,
              minHeight:       4,
              backgroundColor: AppColors.bgSecondary,
              valueColor:      AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Absent students expandable section ─────────────────────────────────────────

class AbsentStudentsSection extends StatefulWidget {
  final String              sessionId;
  final List<StudentEntry>  absentStudents;
  final int                 totalAbsent;
  final void Function(StudentEntry student, String newStatus) onOverride;

  const AbsentStudentsSection({
    super.key,
    required this.sessionId,
    required this.absentStudents,
    required this.totalAbsent,
    required this.onOverride,
  });

  @override
  State<AbsentStudentsSection> createState() =>
      _AbsentStudentsSectionState();
}

class _AbsentStudentsSectionState extends State<AbsentStudentsSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    const visibleCount = 3;
    final displayedStudents = widget.absentStudents.take(visibleCount).toList();
    final remaining = widget.totalAbsent - visibleCount;

    return Container(
      decoration: BoxDecoration(
        color:        AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: const Color(0xFFE2E8E4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header / Summary
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _expanded
                    ? AppColors.bgSecondary
                    : AppColors.bgPrimary,
                border: _expanded
                    ? const Border(
                    bottom: BorderSide(
                        color: Color(0xFFE2E8E4)))
                    : null,
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_off_rounded,
                      size: 20, color: AppColors.error),
                  const SizedBox(width: 12),
                  Text(
                    'Absent Students (${widget.totalAbsent})',
                    style: const TextStyle(
                      fontFamily:  'Inter',
                      fontSize:    18,
                      fontWeight:  FontWeight.w600,
                      color:       AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // Expandable list
          if (_expanded) ...[
            ...displayedStudents.map((s) => _AbsentStudentRow(
              student: s,
              sessionId: widget.sessionId,
              onOverride: widget.onOverride,
            )),
            if (remaining > 0)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color:   AppColors.bgSecondary,
                child: Center(
                  child: Text(
                    '+$remaining more students in this list',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize:   12,
                      color:      AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AbsentStudentRow extends StatelessWidget {
  final StudentEntry student;
  final String       sessionId;
  final void Function(StudentEntry student, String newStatus) onOverride;

  const _AbsentStudentRow({
    required this.student,
    required this.sessionId,
    required this.onOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:     const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Color(0xFFF5F5F5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontFamily:  'Inter',
                    fontSize:    14,
                    fontWeight:  FontWeight.w600,
                    color:       AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${student.studentId} • Last Seen: --',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize:   13,
                    color:      AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              final newStatus = await Navigator.of(context).push<String>(
                MaterialPageRoute(
                  builder: (_) => ManualOverrideScreen(
                    student: student,
                    sessionId: sessionId,
                  ),
                ),
              );
              if (newStatus != null) {
                onOverride(student, newStatus);
              }
            },
            icon: const Icon(Icons.check_circle_rounded,
                size: 18, color: AppColors.primary),
            label: const Text(
              'Mark Manually',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      AppColors.primary,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}