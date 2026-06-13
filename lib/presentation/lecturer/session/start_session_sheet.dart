// lib/presentation/lecturer/session/start_session_sheet.dart
//
// "Select Course" modal bottom sheet for the lecturer.
// Layout rules that prevent the hasSize crash:
//   1. Return a DraggableScrollableSheet — it handles its own height correctly
//      and gives Expanded children a real bounded parent.
//   2. Never put an ElevatedButton with minimumSize:infinity inside a Row/Spacer.
//      Use SizedBox(width:…) for the button instead.
//   3. No SizedBox(height:…) wrapper around the sheet root — let the sheet
//      framework control height via DraggableScrollableSheet.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/course_model.dart';
import 'active_session_screen.dart';

// ── Public entry-point ────────────────────────────────────────────────────────

class StartSessionSheet {
  static Future<void> show(
      BuildContext context,
      WidgetRef ref, {
        CourseModel? preSelected,
      }) {
    return showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _StartSessionSheet(
        ref:         ref,
        preSelected: preSelected,
      ),
    );
  }
}

// ── Mock courses — stay in sync with CourseController._kMockCourses ───────────

const _kCourses = [
  CourseModel(
    courseCode:    'CS202',
    courseName:    'Data Structures',
    group:         'Group B',
    enrolled:      45,
    avgAttendance: 92,
    lastSessionAt: '4 hours ago',
  ),
  CourseModel(
    courseCode:    'CS405',
    courseName:    'Cloud Computing',
    group:         'Final Year',
    enrolled:      32,
    avgAttendance: 85,
    lastSessionAt: null,
  ),

  CourseModel(
    courseCode:    'CS301',
    courseName:    'Software Engineering',
    group:         'Group A',
    enrolled:      60,
    avgAttendance: 87,
    lastSessionAt: '2 days ago',
  ),
  CourseModel(
    courseCode:    'CS405',
    courseName:    'Network Security',
    group:         'Final Year',
    enrolled:      32,
    avgAttendance: 85,
    lastSessionAt: null,
  ),

];

// ── Duration options ──────────────────────────────────────────────────────────

const _kDurations = ['1 hour', '1.5 hours', '2 hours'];

// ── Sheet widget ──────────────────────────────────────────────────────────────

class _StartSessionSheet extends StatefulWidget {
  final WidgetRef    ref;
  final CourseModel? preSelected;
  const _StartSessionSheet({required this.ref, this.preSelected});

  @override
  State<_StartSessionSheet> createState() => _StartSessionSheetState();
}

class _StartSessionSheetState extends State<_StartSessionSheet> {
  late CourseModel? _selected;
  String _search       = '';
  int    _durationIdx  = 0;
  bool   _isStarting   = false;

  final _searchCtrl   = TextEditingController();
  final _roomCtrl     = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.preSelected;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  List<CourseModel> get _filtered {
    if (_search.trim().isEmpty) return _kCourses;
    final q = _search.toLowerCase();
    return _kCourses.where((c) =>
    c.courseName.toLowerCase().contains(q) ||
        c.courseCode.toLowerCase().contains(q),
    ).toList();
  }

  Future<void> _handleStart() async {
    if (_selected == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _isStarting = true);

    // Map the dropdown index to a real Duration
    final duration = switch (_durationIdx) {
      0 => const Duration(hours: 1),
      1 => const Duration(minutes: 90),
      2 => const Duration(hours: 2),
      _ => const Duration(hours: 1),
    };
    final room = _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim();

    // [MOCK] — replace with sessionNotifier.startSession()
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    HapticFeedback.heavyImpact();

    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) =>  ActiveSessionScreen(
        course: _selected!,   // full CourseModel from list/detail
        duration: duration,
        room: room,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    // DraggableScrollableSheet is the correct way to do a tall bottom sheet
    // on both phones and tablets — the framework controls height, so we never
    // need to hardcode a pixel height or fight Expanded constraints.
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      expand:           false,  // IMPORTANT: don't expand to fill the overlay
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color:        AppColors.bgPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          // Use a Column where only the list is scrollable via the
          // DraggableScrollableSheet controller.  The header and footer
          // are fixed (non-scrolling) children of the outer Column.
          child: Column(
            children: [

              // ── Drag handle ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width:  40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:        const Color(0xFFBEC9C3),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),

              // ── Title + search (fixed) ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Course',
                      style: TextStyle(
                        fontFamily:  'Inter',
                        fontSize:    20,
                        fontWeight:  FontWeight.w700,
                        color:       AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchCtrl,
                      onChanged:  (v) => setState(() => _search = v),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize:   14,
                        color:      AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText:  'Search courses…',
                        hintStyle: const TextStyle(
                          fontSize:   14,
                          color:      AppColors.textTertiary,
                        ),
                        filled:    true,
                        fillColor: AppColors.bgSecondary,
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 20, color: AppColors.textSecondary),
                        suffixIcon: _search.isNotEmpty
                            ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          },
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textSecondary),
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
                    ),
                  ],
                ),
              ),

              // ── Scrollable course list (Expanded so it fills remaining
              //    space between header and footer) ──────────────────────
              Expanded(
                child: ListView.separated(
                  controller:  scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  itemCount:       _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final course     = _filtered[i];
                    final isSelected =
                        _selected?.courseCode == course.courseCode;
                    return _CourseItem(
                      course:     course,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selected = course),
                    );
                  },
                ),
              ),

              // ── Config row: room code + duration (fixed footer) ───────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:        AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8E4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Room code
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ROOM CODE (OPTIONAL)',
                              style: TextStyle(
                                fontSize:      10,
                                fontWeight:    FontWeight.w600,
                                color:         AppColors.textSecondary,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller:         _roomCtrl,
                              textCapitalization: TextCapitalization.characters,
                              maxLength:          8,
                              style: const TextStyle(
                                fontSize:    14,
                                fontWeight:  FontWeight.w600,
                                color:       AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText:    'e.g. HALL-A',
                                counterText: '',
                                hintStyle: const TextStyle(
                                  fontSize:   13,
                                  color:      AppColors.textTertiary,
                                ),
                                filled:      true,
                                fillColor:   AppColors.bgPrimary,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE2E8E4)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE2E8E4)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: AppColors.primary, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Duration dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DURATION',
                              style: TextStyle(
                                fontFamily:    'Inter',
                                fontSize:      10,
                                fontWeight:    FontWeight.w600,
                                color:         AppColors.textSecondary,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height:  44,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color:        AppColors.bgPrimary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: const Color(0xFFE2E8E4)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value:      _durationIdx,
                                  isExpanded: true,
                                  icon: const Icon(Icons.expand_more_rounded,
                                      size: 18,
                                      color: AppColors.textSecondary),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize:   14,
                                    color:      AppColors.textPrimary,
                                  ),
                                  onChanged: (v) =>
                                      setState(() => _durationIdx = v!),
                                  items: _kDurations.asMap().entries.map((e) =>
                                      DropdownMenuItem(
                                        value: e.key,
                                        child: Text(e.value),
                                      ),
                                  ).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Action buttons (fixed footer) ─────────────────────────
              // KEY FIX: never put ElevatedButton(minimumSize: infinity)
              // inside a Row with Spacer — give it an explicit width instead.
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20, 12, 20,
                  20 + MediaQuery.of(context).padding.bottom,
                ),
                child: Row(
                  children: [
                    // Cancel — intrinsic width, no Spacer needed
                    TextButton(
                      onPressed: _isStarting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily:  'Inter',
                          fontSize:    14,
                          fontWeight:  FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Start Session — Expanded so it fills the rest of the row.
                    // Expanded in a Row is safe; double.infinity width is NOT.
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: (_selected == null || _isStarting)
                              ? null
                              : _handleStart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:        AppColors.primary,
                            disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.45),
                            foregroundColor: Colors.white,
                            elevation:       0,
                            // DO NOT set minimumSize with infinity here —
                            // the Expanded parent already handles width.
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isStarting
                              ? const SizedBox(
                            width:  18,
                            height: 18,
                            child:  CircularProgressIndicator(
                              strokeWidth: 2,
                              color:       Colors.white,
                            ),
                          )
                              : const Text(
                            'Start Session',
                            style: TextStyle(
                              fontFamily:    'Inter',
                              fontSize:      14,
                              fontWeight:    FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        );
      },
    );
  }
}

// ── Course item ───────────────────────────────────────────────────────────────

class _CourseItem extends StatelessWidget {
  final CourseModel  course;
  final bool         isSelected;
  final VoidCallback onTap;

  const _CourseItem({
    required this.course,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:  const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.10)
              : AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8E4),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Code + name
                  Row(
                    children: [
                      Text(
                        course.courseCode,
                        style: const TextStyle(
                          fontSize:      13,
                          fontWeight:    FontWeight.w700,
                          color:         AppColors.primary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          course.courseName,
                          style: const TextStyle(
                            fontSize:    14,
                            fontWeight:  FontWeight.w500,
                            color:       AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Meta: students · last session
                  Row(
                    children: [
                      Icon(Icons.group_rounded,
                          size: 14,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${course.enrolled} Students',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize:   12,
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.8)
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (course.lastSessionAt != null) ...[
                        const SizedBox(width: 14),
                        Icon(Icons.schedule_rounded,
                            size: 14,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Last: ${course.lastSessionAt}',
                          style: TextStyle(
                            fontSize:   12,
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.8)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width:  22,
              height: 22,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                color:  isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFBEC9C3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                  size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}