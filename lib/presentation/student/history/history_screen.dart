// lib/presentation/student/history/history_screen.dart
//
// Student attendance history screen.
// Reached from the bottom nav (History tab) on StudentHomeScreen.
// Split per project brief: history_screen / history_item / history_controller.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oromark/presentation/student/home/student_home_screen.dart';
import 'package:oromark/presentation/student/profile/profile_screen.dart';
import '../../../core/theme/app_colors.dart';
import 'history_controller.dart';
import 'history_item.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
    _ctrl = HistoryController()..addListener(() => setState(() {}));
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
              onRefresh: () async {
                // TODO: re-fetch from drift / Supabase
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                children: [
                  const SizedBox(height: 20),

                  // ── Title + filter chips ───────────────
                  _SectionTitle(),
                  const SizedBox(height: 14),
                  _FilterChips(
                    active: _ctrl.activeFilter,
                    onSelect: _ctrl.setFilter,
                  ),
                  const SizedBox(height: 20),

                  // ── Summary bento card ─────────────────
                  _SummaryCard(controller: _ctrl),
                  const SizedBox(height: 24),

                  // ── Recent logs header ─────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Logs',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      // Export button
                      GestureDetector(
                        onTap: () {
                          // TODO: export CSV / PDF
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Export coming soon'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.file_download_outlined,
                                size: 16, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'Export',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

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
              Image.asset('assets/oromark.jpg', height: 26, fit: BoxFit.contain),
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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.10),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    'A',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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
                        Padding(
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
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c.standingColor,
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