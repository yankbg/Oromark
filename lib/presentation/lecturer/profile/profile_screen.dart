// lib/presentation/lecturer/profile/profile_screen.dart
//
// Lecturer profile screen. Unlike the student one, this doesn't need its
// own controller/drift stream — everything it shows (name, email,
// department, lecturer id) is already sitting in authStateNotifierProvider
// from login, and lecturers have no avatar photo or phone number column
// to load (see tables.dart's Lecturers table).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/radar_loading_indicator.dart';
import '../../../data/models/auth_result.dart';
import '../../../providers/auth_state_provider.dart';

class LecturerProfileScreen extends ConsumerWidget {
  const LecturerProfileScreen({super.key});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _signOut(BuildContext context, WidgetRef ref) {
    ref.read(authStateNotifierProvider.notifier).clearUser();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);

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
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: authState.when(
        data: (lecturer) {
          if (lecturer == null) {
            return const Center(
              child: Text(
                'Not signed in',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(lecturer: lecturer, initials: _initials(lecturer.fullname)),
                const SizedBox(height: 16),
                _InfoCard(
                  icon: Icons.person_outline_rounded,
                  title: 'Personal Information',
                  items: [
                    _InfoItem(
                      label: 'Email',
                      value: lecturer.email.isNotEmpty ? lecturer.email : '—',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: Icons.school_rounded,
                  title: 'Work Info',
                  items: [
                    _InfoItem(
                      label: 'Department',
                      value: lecturer.department?.isNotEmpty == true
                          ? lecturer.department!
                          : '—',
                    ),
                    _InfoItem(label: 'Lecturer ID', value: lecturer.userId),
                  ],
                ),
                const SizedBox(height: 16),
                _SignOutTile(onSignOut: () => _signOut(context, ref)),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: RadarLoadingIndicator(),
        ),
        error: (e, st) => Center(
          child: Text(
            'Could not load profile: $e',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AuthResult lecturer;
  final String initials;
  const _Header({required this.lecturer, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.10),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            lecturer.fullname,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              lecturer.userId,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info card ───────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_InfoItem> items;
  const _InfoCard({required this.icon, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8E4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
                      color: AppColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.value,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
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

// ── Sign out tile ─────────────────────────────────────────────────────────────

class _SignOutTile extends StatelessWidget {
  final VoidCallback onSignOut;
  const _SignOutTile({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.error;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8E4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onSignOut,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: color,
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
