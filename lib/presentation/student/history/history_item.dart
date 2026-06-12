// lib/presentation/student/history/history_item.dart
//
// A single attendance log row used in the history list.
// Stateless — all data flows in from HistoryController via the screen.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'history_controller.dart';

class HistoryItem extends StatelessWidget {
  final HistoryRecord record;

  const HistoryItem({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8E4), width: 1),
        ),
      ),
      child: Row(
        children: [
          // ── Course icon avatar ──────────────────────────────
          _CourseAvatar(courseCode: record.courseCode),
          const SizedBox(width: 14),

          // ── Course name + date ──────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.courseCode}: ${record.courseName}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDate(record.sessionDate),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Status badge ────────────────────────────────────
          _StatusBadge(record: record),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h    = d.hour > 12 ? d.hour - 12 : d.hour == 0 ? 12 : d.hour;
    final m    = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month - 1]} ${d.day}, $h:$m $ampm';
  }
}

// ── Course icon avatar ────────────────────────────────────────────────────────
class _CourseAvatar extends StatelessWidget {
  final String courseCode;
  const _CourseAvatar({required this.courseCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          _iconForCode(courseCode),
          size: 20,
          color: AppColors.tertiary,
        ),
      ),
    );
  }

  IconData _iconForCode(String code) {
    if (code.startsWith('CS')) return Icons.code_rounded;
    if (code.startsWith('MA')) return Icons.calculate_outlined;
    if (code.startsWith('PY')) return Icons.psychology_outlined;
    return Icons.menu_book_rounded;
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final HistoryRecord record;
  const _StatusBadge({required this.record});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (record.status) {
      AttendanceStatus.present => (
      'Present',
      AppColors.presentText,
      AppColors.presentBg,
      ),
      AttendanceStatus.late => (
      record.lateMinutes != null
          ? 'Late (${record.lateMinutes}m)'
          : 'Late',
      AppColors.lateText,
      AppColors.lateBg,
      ),
      AttendanceStatus.absent => (
      'Absent',
      AppColors.absentText,
      AppColors.absentBg,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}