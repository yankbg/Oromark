// lib/presentation/lecturer/courses/course_list_screen.dart [FIXED]
//
// [FIXED] Corrected type issues:
// - state now accepts CourseListState (not List<CourseModel>)
// - onRefresh now returns Future<void> (RefreshCallback signature)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oromark/data/models/course_model.dart';
import 'package:oromark/presentation/lecturer/courses/course_detail_screen.dart';
import 'package:oromark/presentation/lecturer/session/select_course_screen.dart';
import 'package:oromark/presentation/lecturer/session/start_session_sheet.dart';
import 'package:oromark/providers/auth_state_provider.dart';
import 'package:oromark/data/models/auth_result.dart';
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
    // Find the full CourseModel so the sheet can pre-select it
    final courses = ref.read(courseControllerProvider).courses;
    final course  = courses.firstWhere(
          (c) => c.courseCode == courseCode,
      orElse: () => CourseModel(
        courseCode: courseCode,
        courseName: courseName,
      ),
    );
    StartSessionSheet.show(context, ref, preSelected: course);
  }

  // ── View details ────────────────────────────────────────────────────────

  void _viewDetails(CourseModel course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseDetailScreen(course: course),
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

    //  courseState is now CourseListState (not List)
    final courseState = ref.watch(courseControllerProvider);
    //  Watch auth state to get lecturer's name
    final authState = ref.watch(authStateNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Column(
        children: [
          //  Pass auth state to top bar
          _TopBar(
            searchController: _searchController,
            authState: authState,
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
              //  Pass entire CourseListState, not just List
              state:          courseState,
              authState:      authState,
              //  onRefresh must return Future<void> (RefreshCallback)
              onRefresh:      () async =>
              await ref.read(courseControllerProvider.notifier).loadCourses(),
              onStartSession: _startSession,
              onViewDetails:  _viewDetails,
            ),
          ),
        ],
      ),
      // bottomNavigationBar: BottomNav(
      //   selectedIndex: _navIndex,
      //   onTap:         _onNavTap,
      // ),
    );
  }
}

// ── Top App Bar ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final TextEditingController searchController;
  final AsyncValue<AuthResult?> authState;
  final ValueChanged<String>  onSearchChanged;
  final VoidCallback          onClearSearch;

  const _TopBar({
    required this.searchController,
    required this.authState,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  //  Helper to get initials from lecturer name
  String _getInitials(String fullname) {
    final parts = fullname.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return fullname.substring(0, 2).toUpperCase();
  }

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
                  // GestureDetector(
                  //   onTap: () {},
                  //   child: const Padding(
                  //     padding: EdgeInsets.all(4),
                  //     child: Icon(
                  //       Icons.menu_rounded,
                  //       size:  22,
                  //       color: AppColors.primary,
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(width: 12),
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

                  //  Dynamic avatar with initials from logged-in lecturer
                  GestureDetector(
                    onTap: () {},
                    child: authState.when(
                      data: (authResult) {
                        if (authResult == null) {
                          // No user logged in
                          return CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary.withOpacity(0.12),
                            child: const Icon(Icons.person_rounded, size: 18),
                          );
                        }

                        // Show initials from lecturer's actual name
                        final initials = _getInitials(authResult.fullname);
                        return CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary.withOpacity(0.12),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontFamily:  'Inter',
                              fontSize:    12,
                              fontWeight:  FontWeight.w700,
                              color:       AppColors.primary,
                            ),
                          ),
                        );
                      },
                      loading: () => CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                          ),
                        ),
                      ),
                      error: (e, st) => CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.error.withOpacity(0.12),
                        child: const Icon(Icons.error_rounded, size: 18),
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
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB), width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
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

// ── Course body ────────────────────────────────────────────────────────────────

class _CourseBody extends StatelessWidget {
  //  state is CourseListState (not List<CourseModel>)
  final CourseListState state;
  final AsyncValue<AuthResult?> authState;
  // onRefresh signature is Future<void> Function() (RefreshCallback)
  final Future<void> Function() onRefresh;
  final Function(String, String) onStartSession;
  final Function(CourseModel) onViewDetails;

  const _CourseBody({
    required this.state,
    required this.authState,
    required this.onRefresh,
    required this.onStartSession,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    //  Access filtered courses from state
    final courses = state.filtered;
    final isLoading = state.isLoading;

    if (courses.isEmpty && !isLoading) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 48, color: AppColors.textTertiary),
              SizedBox(height: 12),
              Text(
                'No courses match your search',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize:   14,
                  color:      AppColors.textSecondary,
                ),
              ),
            ],
          ),
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

          //  Welcome header with actual lecturer name
          _WelcomeHeader(
            courseCount: courses.length,
            authState: authState,
          ),
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
                onViewDetails:  () => onViewDetails(course),
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
  final AsyncValue<AuthResult?> authState;

  const _WelcomeHeader({
    required this.courseCount,
    required this.authState,
  });

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
        //  Show actual lecturer name from auth state
        authState.when(
          data: (authResult) {
            final lecturerName = authResult?.fullname ?? 'Guest';
            return Text(
              '${_greeting()}, $lecturerName',
              style: const TextStyle(
                fontFamily:  'Inter',
                fontSize:    22,
                fontWeight:  FontWeight.w700,
                color:       AppColors.textPrimary,
                height:      1.2,
              ),
            );
          },
          loading: () => Text(
            '${_greeting()}...',
            style: const TextStyle(
              fontFamily:  'Inter',
              fontSize:    22,
              fontWeight:  FontWeight.w700,
              color:       AppColors.textSecondary,
              height:      1.2,
            ),
          ),
          error: (e, st) => Text(
            '${_greeting()}, User',
            style: const TextStyle(
              fontFamily:  'Inter',
              fontSize:    22,
              fontWeight:  FontWeight.w700,
              color:       AppColors.textPrimary,
              height:      1.2,
            ),
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

class BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const BottomNav({required this.selectedIndex, required this.onTap});

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