// lib/presentation/lecturer/courses/course_list_screen.dart
//
// The lecturer's home screen — shows all their enrolled courses.
// Reads state from CourseController (Riverpod StateNotifier).
// CourseCard is a separate widget in course_card.dart per the brief's structure.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'course_card.dart';
import 'course_controller.dart';

class CourseListScreen extends ConsumerStatefulWidget {
  const CourseListScreen({super.key});

  @override
  ConsumerState<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends ConsumerState<CourseListScreen> {
  int _navIndex = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
    // TODO: navigate to History / Reports / Profile screens
  }

  // ── Session start ───────────────────────────────────────────────────────

  void _startSession(String courseCode, String courseName) {
    // TODO: ref.read(sessionNotifierProvider.notifier)
    //           .startSession(courseCode, courseName);
    //       Navigator.pushNamed(context, '/lecturer/session');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting session for $courseName…'),
        backgroundColor: AppColors.primary,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── View details ────────────────────────────────────────────────────────

  void _viewDetails(String courseCode) {
    // TODO: Navigator.pushNamed(context, '/lecturer/reports',
    //           arguments: courseCode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$courseCode details — coming soon'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep status bar icons dark (light scaffold)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final courseState = ref.watch(courseControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Column(
        children: [
          _TopBar(
            searchController: _searchController,
            onSearchChanged: (query) {
              ref.read(courseControllerProvider.notifier).updateSearch(query);
            },
            onClearSearch: () {
              _searchController.clear();
              ref.read(courseControllerProvider.notifier).clearSearch();
            },
          ),
          Expanded(
            child: _CourseBody(
              state:          courseState,
              onRefresh:      () => ref.read(courseControllerProvider.notifier).loadCourses(),
              onStartSession: _startSession,
              onViewDetails:  _viewDetails,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _navIndex,
        onTap:         _onNavTap,
      ),
    );
  }
}

// ── Top App Bar ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String>  onSearchChanged;
  final VoidCallback          onClearSearch;

  const _TopBar({
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPrimary,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Brand row ─────────────────────────────────────────────
            Container(
              height:  64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: AppColors.bgPrimary,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                children: [
                  // Hamburger — wire up Drawer later
                  GestureDetector(
                    onTap: () {},
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.menu_rounded,
                        size:  22,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'OROmark',
                    style: TextStyle(
                      fontFamily:  'Inter',
                      fontSize:    18,
                      fontWeight:  FontWeight.w700,
                      color:       AppColors.primary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(),
                  // Avatar / profile
                  GestureDetector(
                    onTap: () {},
                    child: CircleAvatar(
                      radius:          18,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      child: const Text(
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

            // ── Search bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: TextField(
                controller:    searchController,
                onChanged:     onSearchChanged,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize:   14,
                  color:      AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText:  'Search courses…',
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize:   14,
                    color:      AppColors.textTertiary,
                  ),
                  filled:    true,
                  fillColor: AppColors.bgSecondary,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size:  20,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? GestureDetector(
                    onTap: onClearSearch,
                    child: const Icon(
                      Icons.close_rounded,
                      size:  18,
                      color: AppColors.textSecondary,
                    ),
                  )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical:   10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:  const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:  const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:  const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _CourseBody extends StatelessWidget {
  final CourseListState state;
  final Future<void> Function() onRefresh;
  final void Function(String code, String name) onStartSession;
  final void Function(String code)              onViewDetails;

  const _CourseBody({
    required this.state,
    required this.onRefresh,
    required this.onStartSession,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    // ── Loading ────────────────────────────────────────────────────────
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      );
    }

    // ── Error ──────────────────────────────────────────────────────────
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize:   14,
                  color:      AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRefresh,
                child: const Text(
                  'Retry',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final courses = state.filtered;

    // ── Empty (no search match) ────────────────────────────────────────
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            const Text(
              'No courses match your search',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize:   14,
                color:      AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // ── Course list ────────────────────────────────────────────────────
    return RefreshIndicator(
      onRefresh: onRefresh,
      color:     AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [

          // Welcome / greeting
          _WelcomeHeader(courseCount: courses.length),
          const SizedBox(height: 20),

          // Section label
          Row(
            children: [
              const Text(
                'My Courses',
                style: TextStyle(
                  fontFamily:  'Inter',
                  fontSize:    18,
                  fontWeight:  FontWeight.w700,
                  color:       AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${courses.length} course${courses.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize:   12,
                  color:      AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Cards — one per course
          ...courses.asMap().entries.map((entry) {
            final index  = entry.key;
            final course = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CourseCard(
                course:         course,
                index:          index,
                onStartSession: () => onStartSession(
                    course.courseCode, course.courseName),
                onViewDetails:  () => onViewDetails(course.courseCode),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Welcome header ────────────────────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  final int courseCount;
  const _WelcomeHeader({required this.courseCount});

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String _dateLabel() {
    final now = DateTime.now();
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[now.weekday - 1]}, '
        '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_greeting()}, Dr. Nzabanita',
          style: const TextStyle(
            fontFamily:  'Inter',
            fontSize:    22,
            fontWeight:  FontWeight.w700,
            color:       AppColors.textPrimary,
            height:      1.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              _dateLabel(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize:   13,
                color:      AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            // "3 classes today" amber chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:        AppColors.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$courseCount classes today',
                style: const TextStyle(
                  fontFamily:  'Inter',
                  fontSize:    12,
                  fontWeight:  FontWeight.w600,
                  color:       AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Bottom navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  static const _items = [
    (icon: Icons.home_rounded,           label: 'Home'),
    (icon: Icons.history_rounded,        label: 'History'),
    (icon: Icons.bar_chart_rounded,      label: 'Reports'),
    (icon: Icons.account_circle_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: _items.asMap().entries.map((entry) {
              final i       = entry.key;
              final item    = entry.value;
              final selected = i == selectedIndex;

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
                          horizontal: 16, vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.secondary.withOpacity(0.14)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Icon(
                          item.icon,
                          size:  22,
                          color: selected
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
                          fontWeight:  selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
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