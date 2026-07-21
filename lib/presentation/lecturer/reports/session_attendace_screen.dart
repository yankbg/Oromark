// lib/presentation/lecturer/reports/session_attendace_screen.dart
//
// Attendance detail view for a completed session.
// Shows per-student check-in status (PRESENT/LATE/ABSENT) in a filterable,
// searchable table.
//
// DATA WIRING CHANGE
//   Previously: StatefulWidget receiving a controller with hardcoded mock data.
//   Now: ConsumerStatefulWidget that injects the real AppDatabase into the
//   controller via ref.read(appDatabaseProvider), so all queries run against
//   the real drift tables (Sessions, EnrolledStudents, AttendanceRecords).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oromark/providers/app_database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/app_database.dart';
import 'session_attendance_controller.dart';

class SessionAttendanceScreen extends ConsumerStatefulWidget {
  final PastSessionInfo session;
  final String courseCode;

  const SessionAttendanceScreen({
    required this.session,
    required this.courseCode,
  });

  @override
  ConsumerState<SessionAttendanceScreen> createState() =>
      _SessionAttendanceScreenState();
}

class _SessionAttendanceScreenState
    extends ConsumerState<SessionAttendanceScreen> {
  late SessionAttendanceController _controller;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inject the real AppDatabase into the controller.
    // ref is available in initState via ConsumerStatefulWidget.
    final db = ref.read(appDatabaseProvider);
    _controller = SessionAttendanceController(
      db: db,
      session: widget.session,
      courseCode: widget.courseCode,
    );
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.session.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.session.month} ${widget.session.day} · ${widget.session.time}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.session.attendanceColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.session.attendance,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.session.attendanceColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _controller.isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : _controller.error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            _controller.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _controller.refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Content: filter bar + table ────────────────────────────────────────────

  Widget _buildContent() {
    final stats = [
      ('Present', _controller.totalPresent, AppColors.success),
      ('Late', _controller.totalLate, AppColors.warning),
      ('Absent', _controller.totalAbsent, AppColors.error),
    ];

    return Column(
      children: [
        // ── Stats pills ─────────────────────────────────────────────────
        Container(
          color: AppColors.bgSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < stats.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _StatPill(
                    label: stats[i].$1,
                    count: stats[i].$2,
                    color: stats[i].$3,
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── Search bar ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => _controller.setSearch(v),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search student…',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
              filled: true,
              fillColor: AppColors.bgSecondary,
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 20, color: AppColors.textSecondary),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  _controller.setSearch('');
                },
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textSecondary),
              )
                  : null,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                const BorderSide(color: Color(0xFFE2E8E4), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                const BorderSide(color: Color(0xFFE2E8E4), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ),

        // ── Filter tabs ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (final filter in AttendanceFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter.label),
                    selected: _controller.activeFilter == filter,
                    onSelected: (_) => _controller.setFilter(filter),
                    backgroundColor: AppColors.bgSecondary,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _controller.activeFilter == filter
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _controller.activeFilter == filter
                            ? AppColors.primary
                            : const Color(0xFFE2E8E4),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Table ───────────────────────────────────────────────────────
        Expanded(
          child: _controller.filtered.isEmpty
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_rounded,
                    size: 40,
                    color: AppColors.textTertiary.withOpacity(0.6)),
                const SizedBox(height: 12),
                Text(
                  'No students match',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          )
              : ListView.separated(
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: _controller.filtered.length,
            separatorBuilder: (_, __) => const Divider(
              color: Color(0xFFE2E8E4),
              height: 0.5,
            ),
            itemBuilder: (_, i) {
              final record = _controller.filtered[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    // Status badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor(record.status)
                            .withOpacity(0.15),
                      ),
                      child: Center(
                        child: Icon(
                          _statusIcon(record.status),
                          size: 18,
                          color: _statusColor(record.status),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name + ID
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            record.studentId,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Status + time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _statusLabel(record.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(record.status),
                          ),
                        ),
                        if (record.checkInTime != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(record.checkInTime!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _statusColor(AttendanceStatus status) => switch (status) {
    AttendanceStatus.present => AppColors.success,
    AttendanceStatus.late => AppColors.warning,
    AttendanceStatus.absent => AppColors.error,
  };

  IconData _statusIcon(AttendanceStatus status) => switch (status) {
    AttendanceStatus.present => Icons.check_circle_rounded,
    AttendanceStatus.late => Icons.schedule_rounded,
    AttendanceStatus.absent => Icons.cancel_rounded,
  };

  String _statusLabel(AttendanceStatus status) => switch (status) {
    AttendanceStatus.present => 'Present',
    AttendanceStatus.late => 'Late',
    AttendanceStatus.absent => 'Absent',
  };

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Stat pill ──────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatPill({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}