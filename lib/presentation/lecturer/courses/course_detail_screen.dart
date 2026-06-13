import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'course_controller.dart';
import 'package:oromark/core/theme/app_colors.dart';
import 'package:oromark/data/models/course_model.dart';
import 'package:oromark/presentation/lecturer/session/select_course_screen.dart';
import 'package:oromark/presentation/lecturer/session/start_session_sheet.dart';
import 'course_list_screen.dart' show BottomNav; // import your lecturer bottom nav

class CourseDetailScreen extends ConsumerStatefulWidget {
  final CourseModel course;
  const CourseDetailScreen({super.key,required this.course});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  int _navIndex = 0; // same pattern as CourseListScreen

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
    // TODO: navigate to Sessions / Analytics / Students / Settings
  }
  void _startSession() {
    // same logic as in CourseListScreen, but using widget.course
    final courses = ref.read(courseControllerProvider).courses;
    final course = courses.firstWhere(
          (c) => c.courseCode == widget.course.courseCode,
      orElse: () => widget.course,
    );

    StartSessionSheet.show(context, ref, preSelected: course);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary, // maps to background/surface
      appBar: _CourseDetailAppBar(),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              _HeaderCard(
                  course: widget.course,
                onStartSession: _startSession,
              ),
              const SizedBox(height: 24),
              const _RecentSessionsSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNav(
        selectedIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
class _CourseDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgPrimary,
      elevation: 1,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Course Details',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.transparent,
            backgroundImage: NetworkImage(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuD-UH5VKz-IQM0qTKqtqaB06du_EFxpxFZnKcZiXOFM3NihLrLudfnJDqAXqFPy0ebHlNRzdkerBm4QGXmp5bNvBFdig6saq1xxbVYi6qhXtWxAJ32Cj_y3BrZrRB3rFZkO3jEZatowR3EShmlcdKg8uZD7ZCt3RvYJVKLA1VfLQgTr71lAtR8BxnMi3oMiIikNyXW487gFnsWa3nrq8qikTM-tTEpjP143s_vMkGtqXDf_8u5m8AtrxfAXymONIuzCn91d28XxfEc',
            ),
          ),
        ),
      ],
    );
  }
}
class _HeaderCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onStartSession;
  const _HeaderCard({
    required this.course,
    required this.onStartSession,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // big blurred circle like HTML absolute blob
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CS301 chip
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  course.courseCode,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                course.courseName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.groups_rounded,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${course.enrolled} students',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('•',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      )),
                  const SizedBox(width: 8),
                  const Icon(Icons.location_on_rounded,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    course.group.isNotEmpty
                        ? course.group
                        : 'Room A204',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:  onStartSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    shadowColor: AppColors.primary.withOpacity(0.25),
                  ),
                  icon: const Icon(Icons.sensors_rounded),
                  label: const Text(
                    'Start Session',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _RecentSessionsSection extends StatelessWidget {
  const _RecentSessionsSection();

  @override
  Widget build(BuildContext context) {
    // In real code, this would come from a model/controller
    final sessions = [
      _SessionItem(
        month: 'Oct',
        day: '21',
        title: 'Lecture: Agile Methodology',
        time: '10:15 AM',
        attendance: '92%',
        attendanceColor: AppColors.primary,
      ),
      _SessionItem(
        month: 'Oct',
        day: '18',
        title: 'Session: Sprint Review',
        time: '02:30 PM',
        attendance: '84%',
        attendanceColor: AppColors.secondary,
      ),
      _SessionItem(
        month: 'Oct',
        day: '14',
        title: 'Lab: Git Workflows',
        time: '09:00 AM',
        attendance: '72%',
        attendanceColor: AppColors.error,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            const Text(
              'Recent Sessions',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // TODO: navigate to full sessions history
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: sessions
              .map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RecentSessionCard(item: s),
          ))
              .toList(),
        ),
      ],
    );
  }
}

class _SessionItem {
  final String month;
  final String day;
  final String title;
  final String time;
  final String attendance;
  final Color attendanceColor;

  const _SessionItem({
    required this.month,
    required this.day,
    required this.title,
    required this.time,
    required this.attendance,
    required this.attendanceColor,
  });
}

class _RecentSessionCard extends StatelessWidget {
  final _SessionItem item;
  const _RecentSessionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33000000)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // date block
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.month.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  item.day,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // title + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      item.time,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // attendance percentage and chip
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.attendance,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: item.attendanceColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'COMPLETED',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}