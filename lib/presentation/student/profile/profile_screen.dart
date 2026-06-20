// lib/presentation/student/profile/profile_screen.dart
//
// Student profile screen.
// Reads real data from drift via StudentProfileController.
// Made a ConsumerStatefulWidget so it can obtain appDatabaseProvider
// from Riverpod without touching Supabase.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/app_database_provider.dart';
import '../history/history_screen.dart';
import '../home/student_home_screen.dart';
import 'student_profile_controller.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final StudentProfileController _ctrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    // Obtain the database from Riverpod and hand it to the controller.
    // ConsumerState.ref is safe to use in initState.
    _ctrl = StudentProfileController(db: ref.read(appDatabaseProvider))
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        top:    true,
        bottom: false,
        child: Column(
          children: [
            _TopBar(profile: _ctrl.profile),
            Expanded(
              child: _Body(
                isLoading: _ctrl.isLoading,
                error:     _ctrl.error,
                profile:   _ctrl.profile,
                onRefresh: _ctrl.refresh,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: 2,
        onTap: (i) {
          if (i == 0) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
            );
          } else if (i == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
          }
        },
      ),
    );
  }
}

// ── Body dispatcher ───────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final bool                  isLoading;
  final String?               error;
  final StudentProfileViewModel? profile;
  final Future<void> Function() onRefresh;

  const _Body({
    required this.isLoading,
    required this.error,
    required this.profile,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Loading skeleton
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Error state
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize:   14,
                  color:      AppColors.textSecondary,
                  height:     1.5,
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

    // Main content — always non-null here because isLoading is false
    final p = profile!;
    return RefreshIndicator(
      color:     AppColors.primary,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(profile: p),
            const SizedBox(height: 16),
            _InfoGrid(profile: p),
            const SizedBox(height: 16),
            _EnrollmentCard(profile: p),
            const SizedBox(height: 16),
            const _SignOutTile(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final StudentProfileViewModel? profile;
  const _TopBar({this.profile});

  @override
  Widget build(BuildContext context) {
    final initials = profile?.initials ?? '…';
    return Container(
      color: AppColors.bgPrimary,
      child: Container(
        height:  60,
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
                fontSize:   19,
                fontWeight: FontWeight.w700,
                color:      AppColors.primary,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            // Avatar with real initials from drift
            Container(
              width:  34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.10),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w700,
                    color:      AppColors.primary,
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

// ── Profile header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final StudentProfileViewModel profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color:        AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: const Color(0xFFE2E8E4)),
        boxShadow: [
          BoxShadow(
            color:     Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset:    const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar — network image if avatarUrl is set, else initials circle
          _Avatar(profile: profile),
          const SizedBox(height: 16),

          // Full name from drift
          Text(
            profile.fullName,
            style: const TextStyle(
              fontSize:   24,
              fontWeight: FontWeight.w700,
              color:      AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Student ID badge from drift
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color:        AppColors.secondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              profile.studentId,
              style: const TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                color:      AppColors.secondary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),


        ],
      ),
    );
  }
}

// Avatar widget — shows network image when available, initials fallback otherwise
class _Avatar extends StatelessWidget {
  final StudentProfileViewModel profile;
  const _Avatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width:  112,
          height: 112,
          decoration: BoxDecoration(
            shape:  BoxShape.circle,
            color:  AppColors.primary.withOpacity(0.10),
            border: Border.all(color: AppColors.primary, width: 3),
            boxShadow: [
              BoxShadow(
                color:     Colors.black.withOpacity(0.10),
                blurRadius: 14,
                offset:    const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAGiOLpDF7nqbe0DWr8i2FEKQtuQIxqb-s3f-uiX8Hntp74m1HL9bqAYnvBsySobMtmS3czjwzclikbWY5FlU71IeZiqpms62lwKLFQT72kf9cmAfUoCz70TV-B5Q1FAGMjwER6MDELDdAJkVjHrztwJ5VKFNHs7VgR0-RIEDtUse2jHSUsQdMPJV9dJWIjkm97eGOGrBrw2oRskCHxBzwMWgNydX6XZNLx2wYXzFItuVhYDUdksw2wJoNlU6oGuxyahm7fH-wbzlo',
            fit: BoxFit.cover,
          ),

        ),

        // Edit button — TODO: launch image picker + Supabase Storage upload
        Positioned(
          bottom: 2,
          right:  2,
          child: Material(
            color:     AppColors.primary,
            shape:     const CircleBorder(),
            elevation: 3,
            child: InkWell(
              onTap:       () {},
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.edit_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InitialsFallback extends StatelessWidget {
  final String initials;
  const _InitialsFallback({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize:   36,
          fontWeight: FontWeight.w700,
          color:      AppColors.primary,
        ),
      ),
    );
  }
}

// ── Info grid ─────────────────────────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  final StudentProfileViewModel profile;
  const _InfoGrid({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoCard(
          icon:  Icons.person_outline_rounded,
          title: 'Personal Information',
          items: [
            // TODO: populated from Supabase users table after auth is wired
            _InfoItem(
              label: 'Email',
              value: profile.email.isNotEmpty ? profile.email : '—',
            ),
            _InfoItem(
              label: 'Phone Number',
              value: profile.phone.isNotEmpty ? profile.phone : '—',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          icon:  Icons.school_rounded,
          title: 'Academic Info',
          items: [
            _InfoItem(
              label: 'Year',
              value: profile.yearLabel.isNotEmpty ? profile.yearLabel : '—',
            ),
            _InfoItem(
              label: 'Department',
              value: profile.department.isNotEmpty ? profile.department : '—',
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData        icon;
  final String          title;
  final List<_InfoItem> items;
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: const Color(0xFFE2E8E4)),
        boxShadow: [
          BoxShadow(
            color:     Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset:    const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize:   16,
                  fontWeight: FontWeight.w600,
                  color:      AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map(
                (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color:    AppColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.value,
                    style: const TextStyle(
                      fontSize:   15,
                      color:      AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});
}

// ── Enrollment summary card ───────────────────────────────────────────────────
// Shows how many courses the student is enrolled in — pulled directly from drift.

class _EnrollmentCard extends StatelessWidget {
  final StudentProfileViewModel profile;
  const _EnrollmentCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: const Color(0xFFE2E8E4)),
        boxShadow: [
          BoxShadow(
            color:     Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset:    const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width:  46,
            height: 46,
            decoration: BoxDecoration(
              color:        AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.library_books_rounded,
              color: AppColors.primary,
              size:  22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enrolled Courses',
                  style: TextStyle(
                    fontSize: 13,
                    color:    AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${profile.enrolledCourseCount} course${profile.enrolledCourseCount == 1 ? '' : 's'} this semester',
                  style: const TextStyle(
                    fontSize:   15,
                    fontWeight: FontWeight.w600,
                    color:      AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Source badge — reassures the reader this number comes from drift
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:        AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'LOCAL DB',
              style: TextStyle(
                fontSize:      9,
                fontWeight:    FontWeight.w700,
                color:         AppColors.primary,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sign out tile ─────────────────────────────────────────────────────────────

class _SignOutTile extends StatelessWidget {
  const _SignOutTile();

  @override
  Widget build(BuildContext context) {
    final color = AppColors.error;
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: const Color(0xFFE2E8E4)),
        boxShadow: [
          BoxShadow(
            color:     Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset:    const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // TODO: supabase.auth.signOut() then navigate to /login
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.logout_rounded, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize:   15,
                      fontWeight: FontWeight.w500,
                      color:      color,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: color.withOpacity(0.4), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom navigation ─────────────────────────────────────────────────────────
// Identical structure to StudentHomeScreen and HistoryScreen.

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selectedIndex, required this.onTap});

  static const _items = [
    (icon: Icons.home_rounded,    label: 'Home'),
    (icon: Icons.history_rounded, label: 'History'),
    (icon: Icons.person_rounded,  label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color:  AppColors.bgPrimary,
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
                onTap:    () => onTap(i),
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
                          size:  23,
                          color: active
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize:   11,
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