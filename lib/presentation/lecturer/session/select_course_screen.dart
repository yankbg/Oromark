// lib/presentation/lecturer/session/select_course_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oromark/core/theme/app_colors.dart';
import 'package:oromark/presentation/lecturer/courses/course_list_screen.dart'
    show BottomNav;

class SelectCourseScreen extends StatefulWidget {
  const SelectCourseScreen({super.key});

  @override
  State<SelectCourseScreen> createState() => _SelectCourseScreenState();
}

class _SelectCourseScreenState extends State<SelectCourseScreen> {
  int _navIndex = 0;

  // search + selection state
  final TextEditingController _searchController = TextEditingController();
  String _selectedCourse = 'CS301';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
    // TODO: navigate between Sessions / Analytics / Students / Settings
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Stack(
        children: [
          // Background mock content (just boxes)
          _BlurredBackground(),
          // Dark overlay + centered dialog
          _ModalOverlay(
            searchController: _searchController,
            selectedCourse: _selectedCourse,
            onCourseChanged: (value) {
              setState(() => _selectedCourse = value);
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        selectedIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _BlurredBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // background is not interactive, just visual
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: List.generate(6, (_) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBEC9C3)),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ModalOverlay extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedCourse;
  final ValueChanged<String> onCourseChanged;

  const _ModalOverlay({
    required this.searchController,
    required this.selectedCourse,
    required this.onCourseChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // full-screen overlay with blur-like effect
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 795),
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ModalHeader(searchController: searchController),
              _CourseListSection(
                searchController: searchController,
                selectedCourse: selectedCourse,
                onCourseChanged: onCourseChanged,
              ),
              const _ConfigurationSection(),
              const _ActionButtons(),
            ],
          ),
        ),
      ),
    );
  }
}

// Top “NISAMS” bar (like header in HTML)
class _ModalHeader extends StatelessWidget {
  final TextEditingController searchController;
  const _ModalHeader({required this.searchController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row: logo + avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.signal_cellular_alt_rounded,
                      color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'NISAMS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuA1YTtOYljSyUG91ZA3GZnk-b4-f4DOp8l_nJMuCZqLci3ZPsO_NKjMIAt0MQJTAkO5U-iI0X4LoWXGY7ftMdJTqBBfZy96iBRdDwJ_qF7iaZJ5ihUBnzoHIjcwH-lXzGwTQnl4DRSjO4i6IJ1lzqWF9vCTgawxLcAGtequX5S3LVPXnj5sv5jfovnDheQjoaGG_3cjl4sC-Ve5W_DtHecwQ6-8vrxd17VpexNLyd6ux7hNNFc5xODl-2vGctkCxl3ChL52j9ff0jo',
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Course',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // search bar
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textTertiary),
              hintText: 'Search courses...',
              filled: true,
              fillColor: AppColors.bgSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// Scrollable course radio list
class _CourseListSection extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedCourse;
  final ValueChanged<String> onCourseChanged;

  const _CourseListSection({
    required this.searchController,
    required this.selectedCourse,
    required this.onCourseChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Static mock list, same as HTML
    final courses = [
      _CourseRadioItem(
        code: 'CS301',
        name: 'Software Engineering',
        studentsLabel: '60 Students',
        scheduledLabel: 'Scheduled: 09:00',
      ),
      const _CourseRadioItem(
        code: 'CS202',
        name: 'Data Structures',
        studentsLabel: '45 Students',
      ),
      const _CourseRadioItem(
        code: 'CS405',
        name: 'Network Security',
        studentsLabel: '52 Students',
      ),
    ];

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ListView.separated(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          itemBuilder: (context, index) {
            final item = courses[index];
            final selected = selectedCourse == item.code;
            return _CourseRadioTile(
              item: item,
              selected: selected,
              onChanged: () => onCourseChanged(item.code),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: courses.length,
        ),
      ),
    );
  }
}

class _CourseRadioItem {
  final String code;
  final String name;
  final String studentsLabel;
  final String? scheduledLabel;

  const _CourseRadioItem({
    required this.code,
    required this.name,
    required this.studentsLabel,
    this.scheduledLabel,
  });
}

class _CourseRadioTile extends StatelessWidget {
  final _CourseRadioItem item;
  final bool selected;
  final VoidCallback onChanged;

  const _CourseRadioTile({
    required this.item,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final baseBg = selected
        ? AppColors.primary.withOpacity(0.08)
        : Colors.transparent;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onChanged,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: baseBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary.withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // text side
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.code,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.primary
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.group_rounded,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            item.studentsLabel,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (item.scheduledLabel != null) ...[
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              item.scheduledLabel!,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: item.code,
              groupValue: selected ? item.code : null,
              activeColor: AppColors.primary,
              onChanged: (_) => onChanged(),
            ),
          ],
        ),
      ),
    );
  }
}

// Room + duration section
class _ConfigurationSection extends StatelessWidget {
  const _ConfigurationSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSecondary.withOpacity(0.6),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // Room code
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Room Code (Optional)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'e.g., HALL-A',
                    filled: true,
                    fillColor: AppColors.bgPrimary,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFFBEC9C3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Duration dropdown
          Expanded(
            child: _DurationDropdown(),
          ),
        ],
      ),
    );
  }
}

class _DurationDropdown extends StatefulWidget {
  @override
  State<_DurationDropdown> createState() => _DurationDropdownState();
}

class _DurationDropdownState extends State<_DurationDropdown> {
  String _duration = '1';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _duration,
          items: const [
            DropdownMenuItem(value: '1', child: Text('1 hour')),
            DropdownMenuItem(value: '1.5', child: Text('1.5 hours')),
            DropdownMenuItem(value: '2', child: Text('2 hours')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _duration = value);
            }
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bgPrimary,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFBEC9C3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Cancel / Start Session buttons
class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 24.0).copyWith(bottom: 24),
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // TODO: start session with selected course + config
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Start Session',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}