// lib/core/widgets/student_avatar.dart
//
// The circular avatar used in the home, history, and profile screen
// headers. Shows the student's Cloudinary picture when set, otherwise
// falls back to their initials — same treatment everywhere so the picture
// (or lack of one) reads consistently across the app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/student_avatar_provider.dart';
import '../theme/app_colors.dart';

class StudentAvatar extends ConsumerWidget {
  final double size;
  const StudentAvatar({super.key, this.size = 34});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentAvatarProvider).value;
    final avatarUrl = student?.avatarUrl;
    final initials = student != null ? _initials(student.studentName) : '';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.10),
        border: Border.all(color: AppColors.primary, width: 1.5),
        image: (avatarUrl != null && avatarUrl.isNotEmpty)
            ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
            : null,
      ),
      child: (avatarUrl == null || avatarUrl.isEmpty)
          ? Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            )
          : null,
    );
  }
}
