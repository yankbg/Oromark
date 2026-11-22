// lib/presentation/lecturer/reports/reports_screen.dart
//
// Lecturer Reports screen — built from this device's own ENDED sessions
// (see reports_controller.dart). Two charts:
//   1. Attendance Over Time — one column per session, oldest -> newest,
//      segments stacked present/late/absent as a % of that session's
//      records (so sessions with different class sizes stay comparable).
//   2. Course Ranking — one horizontal bar per course, sorted by
//      attendance rate, colored by the same present/fair/at-risk
//      thresholds StudentHistory already uses for "standing", so a
//      lecturer can see at a glance which course needs attention.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/radar_loading_indicator.dart';
import '../../../providers/app_database_provider.dart';
import 'reports_controller.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late final ReportsController _ctrl;

  @override
  void initState() {
    super.initState();
    final db = ref.read(appDatabaseProvider);
    _ctrl = ReportsController(db, ref)..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _ctrl.state;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 1,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Reports',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: RadarLoadingIndicator())
          : state.error != null
              ? _ErrorState(message: state.error!, onRetry: _ctrl.refresh)
              : state.sessions.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _ctrl.refresh,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        children: [
                          _KpiRow(state: state),
                          const SizedBox(height: 20),
                          _AttendanceOverTimeCard(sessions: state.sessions),
                          const SizedBox(height: 20),
                          _CourseRankingCard(courses: state.courseRanking),
                        ],
                      ),
                    ),
    );
  }
}

// ── KPI row ───────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final ReportsState state;
  const _KpiRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final pct = (state.overallRate * 100).round();
    return Row(
      children: [
        Expanded(
          child: _KpiTile(
            label: 'OVERALL ATTENDANCE',
            value: '$pct%',
            valueColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiTile(
            label: 'SESSIONS',
            value: '${state.totalSessions}',
            valueColor: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _KpiTile({required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Attendance over time (stacked bar chart) ───────────────────────────────────

class _AttendanceOverTimeCard extends StatelessWidget {
  final List<SessionReportEntry> sessions;
  const _AttendanceOverTimeCard({required this.sessions});

  static const _maxBars = 20;
  static const _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime d) => '${d.day} ${_monthAbbr[d.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final windowed = sessions.length > _maxBars
        ? sessions.sublist(sessions.length - _maxBars)
        : sessions;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8E4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ATTENDANCE OVER TIME',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Last ${windowed.length} session${windowed.length == 1 ? '' : 's'} — share of present / late / absent',
            style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final s in windowed)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: _SessionStackedBar(entry: s),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: const Color(0xFFE2E8E4)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDate(windowed.first.date),
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              Text(_formatDate(windowed.last.date),
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _LegendDot(color: AppColors.presentText, label: 'Present'),
              _LegendDot(color: AppColors.lateText, label: 'Late'),
              _LegendDot(color: AppColors.absentText, label: 'Absent'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionStackedBar extends StatelessWidget {
  final SessionReportEntry entry;
  const _SessionStackedBar({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry.total == 0) {
      // No attendance data for this session — render a flat placeholder
      // instead of a divide-by-zero bar, so the bar count still matches
      // the date range shown below. SizedBox.expand forces it to fill the
      // slot's full height — a bare DecoratedBox with no child sizes to
      // zero under the loose constraints this Row hands its children.
      return SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      child: Column(
        children: [
          if (entry.absent > 0) Expanded(flex: entry.absent, child: const ColoredBox(color: AppColors.absentText)),
          if (entry.absent > 0 && (entry.late > 0 || entry.present > 0)) const SizedBox(height: 2),
          if (entry.late > 0) Expanded(flex: entry.late, child: const ColoredBox(color: AppColors.lateText)),
          if (entry.late > 0 && entry.present > 0) const SizedBox(height: 2),
          if (entry.present > 0) Expanded(flex: entry.present, child: const ColoredBox(color: AppColors.presentText)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Course ranking (ranked horizontal bars) ────────────────────────────────────

class _CourseRankingCard extends StatelessWidget {
  final List<CourseAttendance> courses;
  const _CourseRankingCard({required this.courses});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8E4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COURSES BY ATTENDANCE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ranked highest to lowest',
            style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 18),
          if (courses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No ended sessions with attendance data yet.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            )
          else
            ...courses.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _CourseRankBar(course: c),
                )),
        ],
      ),
    );
  }
}

class _CourseRankBar extends StatelessWidget {
  final CourseAttendance course;
  const _CourseRankBar({required this.course});

  // Same thresholds as HistoryController.standingColor on the student
  // side, so "good / fair / at-risk" means the same thing app-wide.
  Color get _color {
    if (course.rate >= 0.85) return AppColors.primary;
    if (course.rate >= 0.70) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (course.rate * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${course.courseCode} · ${course.courseName}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$pct%',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: course.rate,
            minHeight: 8,
            backgroundColor: AppColors.bgTertiary,
            valueColor: AlwaysStoppedAnimation(_color),
          ),
        ),
      ],
    );
  }
}

// ── Empty / error states ───────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, size: 52, color: AppColors.textTertiary),
            SizedBox(height: 12),
            Text(
              'No ended sessions yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            SizedBox(height: 4),
            Text(
              'Reports fill in once you\'ve run and ended at least one session.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}
