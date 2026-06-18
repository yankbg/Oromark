// lib/presentation/lecturer/reports/session_attendance_screen.dart
//
// Shows every student's attendance record for one completed session.
// Reached by tapping a session card in CourseDetailScreen.
// Shell only — all state lives in SessionAttendanceController.
// Per project brief: presentation/lecturer/reports/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oromark/core/theme/app_colors.dart';
import 'session_attendance_controller.dart';

class SessionAttendanceScreen extends StatefulWidget {
  final PastSessionInfo session;
  final String          courseCode;
  final String          courseName;

  const SessionAttendanceScreen({
    super.key,
    required this.session,
    required this.courseCode,
    required this.courseName,
  });

  @override
  State<SessionAttendanceScreen> createState() =>
      _SessionAttendanceScreenState();
}

class _SessionAttendanceScreenState extends State<SessionAttendanceScreen> {
  late final SessionAttendanceController _ctrl;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _ctrl = SessionAttendanceController(session: widget.session)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Column(
        children: [
          _TopBar(
            courseCode: widget.courseCode,
            courseName: widget.courseName,
          ),
          Expanded(
            child: _ctrl.isLoading
                ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
                : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                const SizedBox(height: 20),

                // ── Session meta card ──────────────────────────
                _SessionMetaCard(
                  session:    widget.session,
                  controller: _ctrl,
                ),
                const SizedBox(height: 16),

                // ── Stat pills ─────────────────────────────────
                _StatRow(controller: _ctrl),
                const SizedBox(height: 20),

                // ── Search bar ─────────────────────────────────
                _SearchBar(
                  controller: _searchCtrl,
                  onChanged: (q) => _ctrl.setSearch(q),
                  onClear: () {
                    _searchCtrl.clear();
                    _ctrl.setSearch('');
                  },
                ),
                const SizedBox(height: 12),

                // ── Filter chips ───────────────────────────────
                _FilterChips(
                  active:   _ctrl.activeFilter,
                  onSelect: _ctrl.setFilter,
                  ctrl:     _ctrl,
                ),
                const SizedBox(height: 16),

                // ── Student list header ────────────────────────
                _ListHeader(count: _ctrl.filtered.length),
                const SizedBox(height: 8),

                // ── Student rows ───────────────────────────────
                if (_ctrl.filtered.isEmpty)
                  _EmptyState(filter: _ctrl.activeFilter)
                else
                  _StudentList(records: _ctrl.filtered),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String courseCode;
  final String courseName;

  const _TopBar({required this.courseCode, required this.courseName});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPrimary,
      child: SafeArea(
        bottom: false,
        child: Container(
          height:  60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8E4)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:  MainAxisAlignment.center,
                  children: [
                    Text(
                      courseCode,
                      style: const TextStyle(
                        fontFamily:    'Inter',
                        fontSize:      11,
                        fontWeight:    FontWeight.w600,
                        color:         AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Session Attendance',
                      style: const TextStyle(
                        fontFamily:  'Inter',
                        fontSize:    16,
                        fontWeight:  FontWeight.w700,
                        color:       AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Export button
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Export coming soon'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.file_download_outlined,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Session meta card (date · title · time · attendance %) ────────────────────

class _SessionMetaCard extends StatelessWidget {
  final PastSessionInfo            session;
  final SessionAttendanceController controller;

  const _SessionMetaCard({
    required this.session,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Date block
          Container(
            width:  56,
            height: 56,
            decoration: BoxDecoration(
              color:        Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  session.month.toUpperCase(),
                  style: TextStyle(
                    fontFamily:  'Inter',
                    fontSize:    10,
                    fontWeight:  FontWeight.w700,
                    color:       Colors.white.withOpacity(0.75),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  session.day,
                  style: const TextStyle(
                    fontFamily:  'Inter',
                    fontSize:    22,
                    fontWeight:  FontWeight.w800,
                    color:       Colors.white,
                    height:      1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Title + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: const TextStyle(
                    fontFamily:  'Inter',
                    fontSize:    16,
                    fontWeight:  FontWeight.w700,
                    color:       Colors.white,
                    height:      1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 13,
                        color: Colors.white.withOpacity(0.70)),
                    const SizedBox(width: 4),
                    Text(
                      session.time,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize:   12,
                        color:      Colors.white.withOpacity(0.70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Attendance % badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                session.attendance,
                style: const TextStyle(
                  fontFamily:  'Inter',
                  fontSize:    28,
                  fontWeight:  FontWeight.w800,
                  color:       Colors.white,
                  height:      1.0,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'COMPLETED',
                  style: TextStyle(
                    fontFamily:    'Inter',
                    fontSize:      9,
                    fontWeight:    FontWeight.w700,
                    color:         Colors.white,
                    letterSpacing: 0.6,
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

// ── Stat pills row ────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final SessionAttendanceController controller;
  const _StatRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatPill(
          count: controller.totalPresent,
          label: 'Present',
          color: AppColors.presentText,
          bg:    AppColors.presentBg,
        ),
        const SizedBox(width: 8),
        _StatPill(
          count: controller.totalLate,
          label: 'Late',
          color: AppColors.lateText,
          bg:    AppColors.lateBg,
        ),
        const SizedBox(width: 8),
        _StatPill(
          count: controller.totalAbsent,
          label: 'Absent',
          color: AppColors.absentText,
          bg:    AppColors.absentBg,
        ),
        const Spacer(),
        // Enrolled total
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:        AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            children: [
              const Icon(Icons.groups_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                '${controller.totalEnrolled} enrolled',
                style: const TextStyle(
                  fontFamily:  'Inter',
                  fontSize:    12,
                  fontWeight:  FontWeight.w600,
                  color:       AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final int    count;
  final String label;
  final Color  color;
  final Color  bg;

  const _StatPill({
    required this.count,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontFamily:  'Inter',
              fontSize:    14,
              fontWeight:  FontWeight.w700,
              color:       color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily:  'Inter',
              fontSize:    12,
              fontWeight:  FontWeight.w500,
              color:       color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>  onChanged;
  final VoidCallback          onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged:  onChanged,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize:   14,
        color:      AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText:  'Search by name or student ID…',
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize:   14,
          color:      AppColors.textTertiary,
        ),
        filled:    true,
        fillColor: AppColors.bgPrimary,
        prefixIcon: const Icon(
          Icons.search_rounded,
          size:  20,
          color: AppColors.textSecondary,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? GestureDetector(
          onTap: onClear,
          child: const Icon(
            Icons.close_rounded,
            size:  18,
            color: AppColors.textSecondary,
          ),
        )
            : null,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   const BorderSide(color: Color(0xFFE2E8E4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   const BorderSide(color: Color(0xFFE2E8E4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final AttendanceFilter            active;
  final ValueChanged<AttendanceFilter> onSelect;
  final SessionAttendanceController ctrl;

  const _FilterChips({
    required this.active,
    required this.onSelect,
    required this.ctrl,
  });

  int _countFor(AttendanceFilter f) => switch (f) {
    AttendanceFilter.all     => ctrl.totalEnrolled,
    AttendanceFilter.present => ctrl.totalPresent,
    AttendanceFilter.late    => ctrl.totalLate,
    AttendanceFilter.absent  => ctrl.totalAbsent,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AttendanceFilter.values.map((f) {
          final isActive = f == active;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.bgPrimary,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary
                        : const Color(0xFFBEC9C3),
                  ),
                ),
                child: Text(
                  '${f.label} (${_countFor(f)})',
                  style: TextStyle(
                    fontFamily:  'Inter',
                    fontSize:    13,
                    fontWeight:  FontWeight.w600,
                    color: isActive
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── List header ───────────────────────────────────────────────────────────────

class _ListHeader extends StatelessWidget {
  final int count;
  const _ListHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Students',
          style: TextStyle(
            fontFamily:  'Inter',
            fontSize:    17,
            fontWeight:  FontWeight.w700,
            color:       AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          '$count result${count == 1 ? '' : 's'}',
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

// ── Student list ──────────────────────────────────────────────────────────────

class _StudentList extends StatelessWidget {
  final List<SessionAttendanceRecord> records;
  const _StudentList({required this.records});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: const Color(0xFFE2E8E4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table header
          Container(
            color:   AppColors.bgSecondary,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: const Row(
              children: [
                SizedBox(width: 18), // dot column
                SizedBox(width: 10),
                Expanded(
                  flex: 5,
                  child: Text(
                    'NAME',
                    style: TextStyle(
                      fontFamily:    'Inter',
                      fontSize:      10,
                      fontWeight:    FontWeight.w600,
                      color:         AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'TIME',
                    style: TextStyle(
                      fontFamily:    'Inter',
                      fontSize:      10,
                      fontWeight:    FontWeight.w600,
                      color:         AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                SizedBox(
                  width: 68,
                  child: Text(
                    'STATUS',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily:    'Inter',
                      fontSize:      10,
                      fontWeight:    FontWeight.w600,
                      color:         AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rows
          ...records.map((r) => _StudentRow(record: r)),
        ],
      ),
    );
  }
}

// ── Single student row ────────────────────────────────────────────────────────

class _StudentRow extends StatelessWidget {
  final SessionAttendanceRecord record;
  const _StudentRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final (dotColor, badgeColor, badgeBg, badgeLabel) = switch (record.status) {
      AttendanceStatus.present => (
      AppColors.success,
      AppColors.presentText,
      AppColors.presentBg,
      'Present',
      ),
      AttendanceStatus.late => (
      AppColors.warning,
      AppColors.lateText,
      AppColors.lateBg,
      'Late',
      ),
      AttendanceStatus.absent => (
      AppColors.error,
      AppColors.absentText,
      AppColors.absentBg,
      'Absent',
      ),
    };

    final isAbsent = record.status == AttendanceStatus.absent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0)),
        ),
      ),
      child: Row(
        children: [
          // Status dot
          Container(
            width:  10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 10),

          // Name + student ID
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.name,
                  style: TextStyle(
                    fontFamily:  'Inter',
                    fontSize:    14,
                    fontWeight:  FontWeight.w600,
                    color: isAbsent
                        ? AppColors.textPrimary.withOpacity(0.45)
                        : AppColors.textPrimary,
                    fontStyle: isAbsent
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  record.studentId,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize:   11,
                    color: isAbsent
                        ? AppColors.textTertiary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Check-in time
          SizedBox(
            width: 80,
            child: Text(
              _formatTime(record.checkInTime),
              style: TextStyle(
                fontFamily:  'Inter',
                fontSize:    13,
                fontWeight:  record.status == AttendanceStatus.late
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: record.status == AttendanceStatus.late
                    ? AppColors.secondary
                    : isAbsent
                    ? AppColors.textTertiary
                    : AppColors.textSecondary,
              ),
            ),
          ),

          // Status badge
          SizedBox(
            width: 68,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:        badgeBg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontFamily:  'Inter',
                    fontSize:    10,
                    fontWeight:  FontWeight.w700,
                    color:       badgeColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    final h    = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final m    = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AttendanceFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size:  52,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            filter == AttendanceFilter.all
                ? 'No records found'
                : 'No ${filter.label.toLowerCase()} students',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize:   15,
              color:      AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}