// lib/presentation/lecturer/session/active_session_screen.dart
//
// Live session dashboard for the lecturer.
// Shell only — all logic lives in SessionController.
// Stat/display widgets live in session_stats.dart.
// Follows the same pattern as student_home_screen.dart.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'session_controller.dart';
import 'session_stats.dart';
import '../../../data/models/course_model.dart';

class ActiveSessionScreen extends ConsumerStatefulWidget {
  final CourseModel course;
  final Duration duration;
  final String? room;
  const ActiveSessionScreen({
    super.key,
    required this.course,
    required this.duration,
    this.room,
  });

  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  final _searchCtrl = TextEditingController();
  int _navIndex     = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── End session ─────────────────────────────────────────────────────────

  Future<void> _confirmEndSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'End Session?',
          style: TextStyle(
            fontFamily:  'Inter',
            fontWeight:  FontWeight.w700,
            color:       AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'This will stop the UDP broadcast, close the HTTP server, '
              'and auto-mark absent students. This cannot be undone.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize:   14,
            color:      AppColors.textSecondary,
            height:     1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.primary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize:     Size.zero,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('End Session',
                style: TextStyle(fontFamily: 'Inter',
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(sessionControllerProvider.notifier)
          .endSession(() {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final state = ref.watch(sessionControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Column(
        children: [
          _TopBar(),
          Expanded(
            child: _Body(
              state:          state,
              searchCtrl:     _searchCtrl,
              onSearch: (q) => ref
                  .read(sessionControllerProvider.notifier)
                  .updateSearch(q),
              onFilter: (s) => ref
                  .read(sessionControllerProvider.notifier)
                  .setFilter(s),
              onStartLate: () => ref
                  .read(sessionControllerProvider.notifier)
                  .startLateWindow(),
              course: widget.course,
              roomOverride: widget.room,
            ),
          ),
        ],
      ),
      // "End Session" FAB — red, bottom-right, above nav bar
      floatingActionButton: FloatingActionButton.extended(
        onPressed:        _confirmEndSession,
        backgroundColor:  AppColors.error,
        foregroundColor:  Colors.white,
        elevation:        4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(99)),
        icon:  const Icon(Icons.power_settings_new_rounded),
        label: const Text(
          'End Session',
          style: TextStyle(
            fontFamily:  'Inter',
            fontSize:    14,
            fontWeight:  FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: _BottomNav(
        selectedIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPrimary,
      child: SafeArea(
        bottom: false,
        child: Container(
          height:  60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8E4))),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {},
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.menu_rounded,
                      size: 22, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Attendance Manager',
                style: TextStyle(
                  fontFamily:  'Inter',
                  fontSize:    18,
                  fontWeight:  FontWeight.w700,
                  color:       AppColors.primary,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Container(
                width:  34,
                height: 34,
                decoration: BoxDecoration(
                  shape:  BoxShape.circle,
                  color:  AppColors.primary.withOpacity(0.10),
                  border: Border.all(
                      color: AppColors.primary, width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    'DN',
                    style: TextStyle(
                      fontFamily:  'Inter',
                      fontSize:    12,
                      fontWeight:  FontWeight.w700,
                      color:       AppColors.primary,
                    ),
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

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final ActiveSessionState          state;
  final TextEditingController       searchCtrl;
  final ValueChanged<String>        onSearch;
  final ValueChanged<CheckInStatus?> onFilter;
  final VoidCallback                onStartLate;
  final CourseModel                 course;
  final String?                     roomOverride;

  const _Body({
    required this.state,
    required this.searchCtrl,
    required this.onSearch,
    required this.onFilter,
    required this.onStartLate,
    required this.course,
    this.roomOverride,
  });

  @override
  Widget build(BuildContext context) {
    final startedAt = state.startedAt ?? DateTime.now();
    final room      = roomOverride ?? state.room ?? 'Room A204';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [

        // ── Course header ─────────────────────────────────────
        CourseHeaderCard(
          course: course,
          room: room,
          startedAt: startedAt,
        ),
        const SizedBox(height: 12),

        // ── Live status (teal hero) ───────────────────────────
        LiveStatusCard(
          state:             state,
          onStartLateWindow: onStartLate,
        ),
        const SizedBox(height: 12),

        // ── Metric pills: Present · Late ──────────────────────
        MetricRow(
          presentCount: state.presentCount,
          lateCount:    state.lateCount,
        ),
        const SizedBox(height: 12),

        // ── Student list card ─────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color:        AppColors.bgPrimary,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: const Color(0xFFE2E8E4)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Search + filter chips
              _SearchAndFilter(
                searchCtrl:   searchCtrl,
                onSearch:     onSearch,
                onFilter:     onFilter,
                activeFilter: state.filterStatus,
                enrolled:     state.enrolled,
                presentCount: state.presentCount,
                lateCount:    state.lateCount,
                notCheckedIn: state.notCheckedIn,
              ),

              // Table header
              Container(
                color:   AppColors.bgSecondary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        'STUDENT NAME',
                        style: TextStyle(
                          fontFamily:    'Inter',
                          fontSize:      10,
                          fontWeight:    FontWeight.w600,
                          color:         AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'ID',
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
                      width: 72,
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
                  ],
                ),
              ),

              // Student rows
              if (state.filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No students match',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize:   14,
                        color:      AppColors.textTertiary,
                      ),
                    ),
                  ),
                )
              else
                ...state.filtered.map(
                      (s) => _StudentRow(student: s),
                ),

              // Coverage footer
              CoverageFooter(state: state),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Search + filter chips ─────────────────────────────────────────────────────

class _SearchAndFilter extends StatelessWidget {
  final TextEditingController        searchCtrl;
  final ValueChanged<String>         onSearch;
  final ValueChanged<CheckInStatus?> onFilter;
  final CheckInStatus?               activeFilter;
  final int                          enrolled;
  final int                          presentCount;
  final int                          lateCount;
  final int                          notCheckedIn;

  const _SearchAndFilter({
    required this.searchCtrl,
    required this.onSearch,
    required this.onFilter,
    required this.activeFilter,
    required this.enrolled,
    required this.presentCount,
    required this.lateCount,
    required this.notCheckedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: searchCtrl,
            onChanged:  onSearch,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize:   14,
              color:      AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText:  'Search students…',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize:   14,
                color:      AppColors.textTertiary,
              ),
              filled:    true,
              fillColor: AppColors.bgSecondary,
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 20, color: AppColors.textSecondary),
              suffixIcon: searchCtrl.text.isNotEmpty
                  ? GestureDetector(
                onTap: () {
                  searchCtrl.clear();
                  onSearch('');
                },
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textSecondary),
              )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
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
          ),
          const SizedBox(height: 12),

          // Filter chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label:    'All ($enrolled)',
                  isActive: activeFilter == null,
                  onTap:    () => onFilter(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label:    'Present ($presentCount)',
                  isActive: activeFilter == CheckInStatus.present,
                  onTap: () =>
                      onFilter(CheckInStatus.present),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label:    'Late ($lateCount)',
                  isActive: activeFilter == CheckInStatus.late,
                  onTap: () =>
                      onFilter(CheckInStatus.late),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label:    'Not Checked In ($notCheckedIn)',
                  isActive:
                  activeFilter == CheckInStatus.notCheckedIn,
                  onTap: () =>
                      onFilter(CheckInStatus.notCheckedIn),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String       label;
  final bool         isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:  const EdgeInsets.symmetric(
            horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : const Color(0xFFBEC9C3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily:  'Inter',
            fontSize:    12,
            fontWeight:  FontWeight.w600,
            color: isActive
                ? Colors.white
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Student row ───────────────────────────────────────────────────────────────

class _StudentRow extends StatelessWidget {
  final StudentEntry student;
  const _StudentRow({required this.student});

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(student.checkInTime);

    // Colour coding from the HTML:
    // present  → normal text
    // late     → secondary/amber
    // not yet  → dimmed + italic
    final nameStyle = switch (student.status) {
      CheckInStatus.notCheckedIn => const TextStyle(
        fontFamily:  'Inter',
        fontSize:    14,
        fontWeight:  FontWeight.w500,
        color:       AppColors.textPrimary,
        fontStyle:   FontStyle.italic,
      ),
      _ => const TextStyle(
        fontFamily:  'Inter',
        fontSize:    14,
        fontWeight:  FontWeight.w600,
        color:       AppColors.textPrimary,
      ),
    };

    final timeColor = switch (student.status) {
      CheckInStatus.late         => AppColors.secondary,
      CheckInStatus.notCheckedIn => AppColors.textTertiary,
      _                          => AppColors.textSecondary,
    };

    return Container(
      padding:     const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          // Status dot
          Container(
            width:  8,
            height: 8,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: switch (student.status) {
                CheckInStatus.present      => AppColors.success,
                CheckInStatus.late         => AppColors.warning,
                CheckInStatus.notCheckedIn =>
                AppColors.textTertiary,
              },
            ),
          ),

          // Name
          Expanded(
            flex: 5,
            child: Text(
              student.name,
              style: nameStyle.copyWith(
                color: student.status == CheckInStatus.notCheckedIn
                    ? AppColors.textPrimary.withOpacity(0.45)
                    : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Student ID
          Expanded(
            flex: 4,
            child: Text(
              student.studentId,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize:   13,
                color:      AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Check-in time
          SizedBox(
            width: 64,
            child: Text(
              timeStr,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize:   13,
                color:      timeColor,
                fontWeight: student.status == CheckInStatus.late
                    ? FontWeight.w600
                    : FontWeight.w400,
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

// ── Bottom navigation ─────────────────────────────────────────────────────────
// Uses amber secondary for active — matches lecturer nav in course_list_screen

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  static const _items = [
    (icon: Icons.event_available_rounded, label: 'Sessions'),
    (icon: Icons.query_stats_rounded,     label: 'Analytics'),
    (icon: Icons.group_rounded,           label: 'Students'),
    (icon: Icons.settings_rounded,        label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color:  AppColors.bgPrimary,
        border: Border(top: BorderSide(color: Color(0xFFE2E8E4))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: _items.asMap().entries.map((e) {
              final i      = e.key;
              final item   = e.value;
              final active = i == selectedIndex;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap:    () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.secondary.withOpacity(0.13)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Icon(
                          item.icon,
                          size:  22,
                          color: active
                              ? AppColors.secondary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily:  'Inter',
                          fontSize:    11,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: active
                              ? AppColors.secondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}