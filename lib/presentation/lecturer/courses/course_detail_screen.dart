import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oromark/presentation/lecturer/reports/session_attendace_screen.dart';
import 'package:oromark/presentation/lecturer/reports/session_attendance_controller.dart';
import 'package:oromark/data/database/app_database.dart';
import 'package:oromark/providers/app_database_provider.dart';
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
              _RecentSessionsSection(
                courseCode: widget.course.courseCode,
                courseName: widget.course.courseName,
              ),
            ],
          ),
        ),
      ),
      // bottomNavigationBar: BottomNav(
      //   selectedIndex: _navIndex,
      //   onTap: _onNavTap,
      // ),
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
class _RecentSessionsSection extends ConsumerStatefulWidget {
  final String courseCode;
  final String courseName;

  const _RecentSessionsSection({
    required this.courseCode,
    required this.courseName,
  });

  @override
  ConsumerState<_RecentSessionsSection> createState() =>
      _RecentSessionsSectionState();
}

class _RecentSessionsSectionState extends ConsumerState<_RecentSessionsSection> {
  bool _isLoading = true;
  String? _error;
  List<_SessionItem> _sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final db = ref.read(appDatabaseProvider);

      // Get all sessions for this course
      final driftSessions = await db.getSessionsForCourse(widget.courseCode);

      // For each session, compute attendance %
      final items = <_SessionItem>[];
      for (final session in driftSessions) {
        // Get who actually checked in
        final records = await db.getSessionAttendance(session.sessionId);
        // Get enrolled count
        final enrolledCount = await db.getEnrolledCount(widget.courseCode);

        final present = records.where((r) => r.status == 'PRESENT').length;
        final late = records.where((r) => r.status == 'LATE').length;
        final attendanceCount = present + late;
        final percentage = enrolledCount > 0
            ? ((attendanceCount / enrolledCount) * 100).round()
            : 0;

        // Derive display fields from session.startTime (unix ms)
        final startDt = DateTime.fromMillisecondsSinceEpoch(session.startTime);
        final month = _monthName(startDt.month);
        final day = startDt.day.toString();

        // Format time HH:MM
        final h = startDt.hour.toString().padLeft(2, '0');
        final m = startDt.minute.toString().padLeft(2, '0');
        final time = '$h:$m';

        // Color by percentage
        final color = percentage >= 85
            ? AppColors.success
            : percentage >= 75
            ? AppColors.warning
            : AppColors.error;

        items.add(_SessionItem(
          sessionId:        session.sessionId,  // Now included
          month:            month,
          day:              day,
          title:            '${widget.courseName}',
          time:             time,
          attendance:       '$percentage%',
          attendanceColor:  color,
        ));
      }

      // Sort by startTime descending (most recent first)
      items.sort((a, b) => b.day.compareTo(a.day));

      setState(() {
        _sessions = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load sessions: $e';
        _isLoading = false;
      });
    }
  }

  String _monthName(int month) => switch (month) {
    1 => 'Jan',
    2 => 'Feb',
    3 => 'Mar',
    4 => 'Apr',
    5 => 'May',
    6 => 'Jun',
    7 => 'Jul',
    8 => 'Aug',
    9 => 'Sep',
    10 => 'Oct',
    11 => 'Nov',
    12 => 'Dec',
    _ => 'Jan',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            const Text(
              'Recent Sessions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _load,
              child: Text(
                _isLoading ? 'Loading…' : 'Refresh',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (_error != null)
          Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 40, color: AppColors.textTertiary),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else if (_sessions.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.history_rounded,
                      size: 40,
                      color: AppColors.textTertiary.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'No sessions yet',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _load,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _sessions
                  .map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RecentSessionCard(
                  item: s,
                  courseCode: widget.courseCode,
                  courseName: widget.courseName,
                ),
              ))
                  .toList(),
            ),
      ],
    );
  }
}

class _SessionItem {
  final String sessionId;  // NEW: drift Sessions.sessionId
  final String month;
  final String day;
  final String title;
  final String time;
  final String attendance;
  final Color attendanceColor;

  const _SessionItem({
    required this.sessionId,
    required this.month,
    required this.day,
    required this.title,
    required this.time,
    required this.attendance,
    required this.attendanceColor,
  });
}

class _RecentSessionCard extends StatefulWidget {
  final _SessionItem item;
  final String       courseCode;
  final String       courseName;

  const _RecentSessionCard({
    required this.item,
    required this.courseCode,
    required this.courseName,
  });

  @override
  State<_RecentSessionCard> createState() => _RecentSessionCardState();
}

class _RecentSessionCardState extends State<_RecentSessionCard> {
  double _scale = 1.0;

  void _navigate() {
    // Convert local _SessionItem → PastSessionInfo that the report screen needs
    final info = PastSessionInfo(
      sessionId:       widget.item.sessionId,  // Now passed from drift
      month:           widget.item.month,
      day:             widget.item.day,
      title:           widget.item.title,
      time:            widget.item.time,
      attendance:      widget.item.attendance,
      attendanceColor: widget.item.attendanceColor,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionAttendanceScreen(
          session:    info,
          courseCode: widget.courseCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _scale = 0.975),
      onTapUp:     (_) {
        setState(() => _scale = 1.0);
        _navigate();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale:    _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        AppColors.bgPrimary,
            borderRadius: BorderRadius.circular(16),
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
              // Date block
              Container(
                width:  48,
                height: 48,
                decoration: BoxDecoration(
                  color:        AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.item.month.toUpperCase(),
                      style: const TextStyle(
                        fontSize:    10,
                        fontWeight:  FontWeight.w700,
                        color:       AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      widget.item.day,
                      style: const TextStyle(
                        fontSize:    16,
                        fontWeight:  FontWeight.w700,
                        color:       AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Title + time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      style: const TextStyle(
                        fontSize:    14,
                        fontWeight:  FontWeight.w600,
                        color:       AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          widget.item.time,
                          style: const TextStyle(
                            fontSize:   12,
                            color:      AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Attendance % + chip + chevron
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.item.attendance,
                        style: TextStyle(
                          fontSize:    14,
                          fontWeight:  FontWeight.w700,
                          color:       widget.item.attendanceColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:        AppColors.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'COMPLETED',
                          style: TextStyle(
                            fontSize:      10,
                            fontWeight:    FontWeight.w700,
                            color:         AppColors.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size:  20,
                    color: AppColors.textTertiary,
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