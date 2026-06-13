// lib/presentation/lecturer/courses/course_card.dart
//
// Self-contained card widget for a single course.
// Receives a CourseModel + callbacks — owns no state of its own.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/course_model.dart';

// Badge colour pairs cycling through the three brand accents.
// Index 0 = amber, 1 = mint-green, 2 = sage — matches the HTML design.
const _kBadgeColors = [
  _BadgeColor(bg: Color(0xFFFFDCBB), fg: Color(0xFF2B1700)), // amber
  _BadgeColor(bg: Color(0xFFA0F3D4), fg: Color(0xFF002117)), // mint
  _BadgeColor(bg: Color(0xFFD2E7E0), fg: Color(0xFF0C1F1B)), // sage
];

class _BadgeColor {
  final Color bg;
  final Color fg;
  const _BadgeColor({required this.bg, required this.fg});
}

class CourseCard extends StatefulWidget {
  final CourseModel course;
  final int index; // used to pick badge colour
  final VoidCallback onStartSession;
  final VoidCallback onViewDetails;

  const CourseCard({
    super.key,
    required this.course,
    required this.index,
    required this.onStartSession,
    required this.onViewDetails,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final badge = _kBadgeColors[widget.index % _kBadgeColors.length];
    final c = widget.course;

    return GestureDetector(
      onTapDown:  (_) => setState(() => _scale = 0.975),
      onTapUp:    (_) => setState(() => _scale = 1.0),
      onTapCancel:()  => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale:    _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color:        AppColors.bgPrimary,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header: code badge + name + overflow menu ─────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CodeBadge(
                          code:  c.courseCode,
                          bg:    badge.bg,
                          fg:    badge.fg,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c.courseName,
                          style: const TextStyle(
                            fontFamily:  'Inter',
                            fontSize:    16,
                            fontWeight:  FontWeight.w700,
                            color:       AppColors.textPrimary,
                            height:      1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Overflow — placeholder; wire to bottom sheet later
                  GestureDetector(
                    onTap: () {},
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.more_vert_rounded,
                        size:  20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Meta info: group · students · last session ────────────
              Wrap(
                spacing:    16,
                runSpacing: 6,
                children: [
                  _MetaChip(
                    icon:  Icons.groups_rounded,
                    label: c.group,
                  ),
                  _MetaChip(
                    icon:  Icons.person_pin_rounded,
                    label: '${c.enrolled} Students',
                  ),
                  if (c.lastSessionAt != null)
                    _MetaChip(
                      icon:  Icons.history_rounded,
                      label: 'Last: ${c.lastSessionAt}',
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Average attendance bar ────────────────────────────────
              Row(
                children: [
                  const Text(
                    'Avg. Attendance',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize:   12,
                      color:      AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${c.avgAttendance}%',
                    style: const TextStyle(
                      fontFamily:  'Inter',
                      fontSize:    12,
                      fontWeight:  FontWeight.w700,
                      color:       AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value:          c.avgAttendance / 100,
                  minHeight:      7,
                  backgroundColor: AppColors.bgTertiary,
                  valueColor:     const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),

              const SizedBox(height: 14),

              // ── Action buttons ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label:       'Start Session',
                      filled:      true,
                      onTap:       widget.onStartSession,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label:       'View Details',
                      filled:      false,
                      onTap:       widget.onViewDetails,
                    ),
                  ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _CodeBadge extends StatelessWidget {
  final String code;
  final Color  bg;
  final Color  fg;
  const _CodeBadge({required this.code, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        code.toUpperCase(),
        style: TextStyle(
          fontFamily:    'Inter',
          fontSize:      10,
          fontWeight:    FontWeight.w700,
          color:         fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          label,
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

class _ActionButton extends StatelessWidget {
  final String   label;
  final bool     filled;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height:    40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:        filled ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: filled
              ? null
              : Border.all(color: const Color(0xFFBEC9C3), width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily:  'Inter',
            fontSize:    13,
            fontWeight:  FontWeight.w600,
            color:       filled ? Colors.white : AppColors.primary,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}