// lib/presentation/student/history/history_screen.dart
//
// Student attendance history screen.
// Reached from the bottom nav (History tab) on StudentHomeScreen.
// Split per project brief: history_screen / history_item / history_controller.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oromark/presentation/student/home/student_home_screen.dart';
import 'package:oromark/presentation/student/profile/profile_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/student_avatar.dart';
import 'history_controller.dart';
import 'history_item.dart';
import '../../../providers/app_database_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late final HistoryController _ctrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    final db = ref.read(appDatabaseProvider);
    _ctrl = HistoryController(db, ref)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Column(
        children: [
          _TopBar(),
          Expanded(
            child: _ctrl.isLoading
                ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
                : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _ctrl.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                children: [
                  const SizedBox(height: 20),

                  // ── Title ───────────────────────────────
                  _SectionTitle(),
                  const SizedBox(height: 20),

                  // ── Attendance overview chart ──────────
                  _AttendanceChartCard(records: _ctrl.all),
                  const SizedBox(height: 20),

                  // ── Summary bento card ─────────────────
                  _SummaryCard(controller: _ctrl),
                  const SizedBox(height: 24),

                  // ── Recent logs header + filter chips ──
                  const Text(
                    'Recent Logs',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FilterChips(
                    active: _ctrl.activeFilter,
                    onSelect: _ctrl.setFilter,
                  ),
                  const SizedBox(height: 12),

                  // ── Log list ───────────────────────────
                  if (_ctrl.filtered.isEmpty)
                    _EmptyState(filter: _ctrl.activeFilter)
                  else
                    ..._ctrl.filtered.map(
                          (r) => HistoryItem(key: ValueKey(r.id), record: r),
                    ),

                  // ── Load more ──────────────────────────
                  if (_ctrl.filtered.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () {
                            // TODO: paginate
                          },
                          icon: const Icon(Icons.expand_more_rounded,
                              size: 18),
                          label: const Text('View More History'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            backgroundColor:
                            AppColors.primary.withOpacity(0.08),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(99),
                            ),
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
      // Bottom nav — History tab is active
      bottomNavigationBar: BottomNav(
        selectedIndex: 1, // History is index 1
        onTap: (i) {
          if (i == 0) {
            // back to Home
            Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StudentHomeScreen(),
                ));
          }
          else if(i == 2){
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
              )
            );
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPrimary,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8E4), width: 1),
            ),
          ),
          child: Row(
            children: [
              Image.asset('assets/icon/logo_mark_primary.png', height: 26, fit: BoxFit.contain),
              const SizedBox(width: 8),
              const Text(
                'OROmark',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              const StudentAvatar(size: 34),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen title
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'Attendance History',
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chips
// ─────────────────────────────────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  final HistoryFilter active;
  final ValueChanged<HistoryFilter> onSelect;

  const _FilterChips({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: HistoryFilter.values.map((f) {
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
                      : AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  f.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

// ─────────────────────────────────────────────────────────────────────────────
// Summary bento card  (glass-style)
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final HistoryController controller;
  const _SummaryCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final rate    = controller.attendanceRate;
    final pct     = (rate * 100).round();
    final c       = controller;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8E4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SEMESTER AVERAGE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$pct%',
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            height: 1,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: controller.standingColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              c.standingLabel,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c.standingColor,
                              ),
                            ),
                          ),
                        ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.analytics_rounded,
                  size: 36, color: AppColors.primary),
            ],
          ),

          const SizedBox(height: 16),

          // ── Progress bar ────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 7,
              backgroundColor: AppColors.bgTertiary,
              valueColor:
              const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),

          const SizedBox(height: 14),

          // ── Stat pills row ──────────────────────────────────
          Row(
            children: [
              _StatPill(
                count: c.totalPresent,
                label: 'Present',
                color: AppColors.presentText,
                bg:    AppColors.presentBg,
              ),
              const SizedBox(width: 8),
              _StatPill(
                count: c.totalLate,
                label: 'Late',
                color: AppColors.lateText,
                bg:    AppColors.lateBg,
              ),
              const SizedBox(width: 8),
              _StatPill(
                count: c.totalAbsent,
                label: 'Absent',
                color: AppColors.absentText,
                bg:    AppColors.absentBg,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final Color bg;

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
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attendance overview chart — one column per session, oldest → newest.
// Height encodes attendance credit (present=full, late=half, absent=none —
// same weighting as HistoryController.attendanceRate), color encodes status.
// Height is a second, non-color cue on top of the status color so present
// and late (closest hues in the app's status palette) stay tellable apart
// even under color-vision deficiency.
// ─────────────────────────────────────────────────────────────────────────────
class _AttendanceChartCard extends StatelessWidget {
  final List<HistoryRecord> records;
  const _AttendanceChartCard({required this.records});

  static const _maxBars = 20;
  static const _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime d) => '${d.day} ${_monthAbbr[d.month - 1]}';

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    // records is most-recent-first; the chart reads left→right as oldest→
    // newest, so reverse it, then keep only the most recent _maxBars.
    final chronological = records.reversed.toList();
    final windowed = chronological.length > _maxBars
        ? chronological.sublist(chronological.length - _maxBars)
        : chronological;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8E4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ATTENDANCE OVERVIEW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Last ${windowed.length} session${windowed.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 18),

          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final r in windowed)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: _AttendanceBar(status: r.status),
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
              Text(
                _formatDate(windowed.first.sessionDate),
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
              Text(
                _formatDate(windowed.last.sessionDate),
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
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

class _AttendanceBar extends StatelessWidget {
  final AttendanceStatus status;
  const _AttendanceBar({required this.status});

  // Present = full credit, Late = half credit, Absent = none — mirrors
  // HistoryController.attendanceRate's weighting, so the bar height means
  // the same thing the percentage above already does.
  double get _heightFactor => switch (status) {
    AttendanceStatus.present => 1.0,
    AttendanceStatus.late    => 0.55,
    AttendanceStatus.absent  => 0.22,
  };

  Color get _color => switch (status) {
    AttendanceStatus.present => AppColors.presentText,
    AttendanceStatus.late    => AppColors.lateText,
    AttendanceStatus.absent  => AppColors.absentText,
  };

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.bottomCenter,
      heightFactor: _heightFactor,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
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
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final HistoryFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 52, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            filter == HistoryFilter.all
                ? 'No attendance records yet'
                : 'No ${filter.label.toLowerCase()} records',
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom nav — shared with StudentHomeScreen
// ─────────────────────────────────────────────────────────────────────────────
class BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const BottomNav({required this.selectedIndex, required this.onTap});

  static const _items = [
    (icon: Icons.home_rounded,    label: 'Home'),
    (icon: Icons.history_rounded, label: 'History'),
    (icon: Icons.person_rounded,  label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(top: BorderSide(color: Color(0xFFE2E8E4), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final active = selectedIndex == i;
              final item   = _items[i];
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 80,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary.withOpacity(0.10)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Icon(
                          item.icon,
                          size: 23,
                          color: active
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: active
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}