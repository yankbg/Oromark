// lib/presentation/lecturer/session/session_summary_screen.dart
//
// Session summary screen shown after a session ends.
// Shows attendance stats, absent students, and export/restart options.
//
// [MOCK] — in production this will read SessionSummaryState from a provider
// that queries the attendance database for the completed session.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'session_controller.dart';
import 'session_summary_stats.dart';

class SessionSummaryScreen extends ConsumerStatefulWidget {
  final SessionSummaryState state;

  const SessionSummaryScreen({
    super.key,
    required this.state,
  });

  @override
  ConsumerState<SessionSummaryScreen> createState() =>
      _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends ConsumerState<SessionSummaryScreen> {
  late SessionSummaryState state = widget.state;

  void _handleOverride(StudentEntry student, String newStatus) {
    setState(() {
      state = state.copyWith(
        presentCount: newStatus == 'PRESENT'
            ? state.presentCount + 1
            : state.presentCount,
        lateCount: newStatus == 'LATE'
            ? state.lateCount + 1
            : state.lateCount,
        absentStudents: newStatus == 'ABSENT'
            ? state.absentStudents
            : state.absentStudents
                .where((s) => s.studentId != student.studentId)
                .toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: _AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
        children: [
          // ── Header ───────────────────────────────────────────────
          SessionSummaryHeader(
            state:   state,
            onShare: () => _handleShare(context),
            onPrint: () => _handlePrint(context),
          ),
          const SizedBox(height: 28),

          // ── Stats grid ───────────────────────────────────────────
          GridView.count(
            crossAxisCount:
            MediaQuery.of(context).size.width > 600 ? 4 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap:      true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StatCard(
                label:      'Present',
                count:      state.presentCount,
                total:      state.enrolled,
                percentage: state.presentPercentage,
                color:      AppColors.success,
              ),
              StatCard(
                label:      'Late',
                count:      state.lateCount,
                percentage: state.latePercentage,
                color:      AppColors.warning,
              ),
              StatCard(
                label:      'Absent',
                count:      state.absentCount,
                percentage: state.absentPercentage,
                color:      AppColors.error,
              ),
              StatCard(
                label:      'Total',
                count:      state.enrolled,
                percentage: 1.0,
                color:      AppColors.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Absent students section ───────────────────────────────
          AbsentStudentsSection(
            sessionId:      state.sessionId,
            absentStudents: state.absentStudents,
            totalAbsent:    state.absentCount,
            onOverride:     _handleOverride,
          ),
        ],
      ),
      // ── Bottom action bar ─────────────────────────────────────────
      bottomSheet: _BottomActionBar(
        onExportPDF: () => _handleExportPDF(context),
        onExportCSV: () => _handleExportCSV(context),
        onNewSession: () => _handleNewSession(context, ref),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _handleShare(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share functionality coming soon'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handlePrint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Print Report functionality coming soon'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleExportPDF(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exporting PDF...'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleExportCSV(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exporting CSV...'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleNewSession(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pushReplacementNamed('/lecturer/courses');
  }
}

// ── Top app bar ───────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPrimary,
      child: SafeArea(
        bottom: false,
        child: Container(
          height:  preferredSize.height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8E4))),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.arrow_back_rounded,
                      size: 22, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Attendance Manager',
                style: TextStyle(
                  fontSize:    18,
                  fontWeight:  FontWeight.w700,
                  color:       AppColors.primary,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Container(
                width:  36,
                height: 36,
                decoration: BoxDecoration(
                  shape:  BoxShape.circle,
                  color:  AppColors.primary.withOpacity(0.10),
                  border: Border.all(
                      color: AppColors.primary, width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    'DN',
                    style: TextStyle(
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
      ),
    );
  }
}

// ── Bottom action bar ─────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final VoidCallback onExportPDF;
  final VoidCallback onExportCSV;
  final VoidCallback onNewSession;

  const _BottomActionBar({
    required this.onExportPDF,
    required this.onExportCSV,
    required this.onNewSession,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Material(
      color: AppColors.bgSecondary,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        maintainBottomViewPadding: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: screenWidth < 600
              ? _MobileLayout(
            onExportPDF: onExportPDF,
            onExportCSV: onExportCSV,
            onNewSession: onNewSession,
          )
              : screenWidth < 1024
              ? _TabletLayout(
            onExportPDF: onExportPDF,
            onExportCSV: onExportCSV,
            onNewSession: onNewSession,
          )
              : _DesktopLayout(
            onExportPDF: onExportPDF,
            onExportCSV: onExportCSV,
            onNewSession: onNewSession,
          ),
        ),
      ),
    );
  }
}
class _MobileLayout extends StatelessWidget {
  final VoidCallback onExportPDF;
  final VoidCallback onExportCSV;
  final VoidCallback onNewSession;

  const _MobileLayout({
    required this.onExportPDF,
    required this.onExportCSV,
    required this.onNewSession,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Export buttons row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onExportPDF,
                icon:      const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label:     const Text('Export PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: Color(0xFFBEC9C3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onExportCSV,
                icon: const Icon(Icons.table_chart_rounded, size: 18),
                label: const Text('Export CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: Color(0xFFBEC9C3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Start New Session button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:     onNewSession,
            icon:          const Icon(Icons.add_rounded, size: 18),
            label:         const Text('End Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation:       4,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabletLayout extends StatelessWidget {
  final VoidCallback onExportPDF;
  final VoidCallback onExportCSV;
  final VoidCallback onNewSession;

  const _TabletLayout({
    required this.onExportPDF,
    required this.onExportCSV,
    required this.onNewSession,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onExportPDF,
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text('Export PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: Color(0xFFBEC9C3)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onExportCSV,
            icon: const Icon(Icons.table_chart_rounded, size: 18),
            label: const Text('Export CSV'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: Color(0xFFBEC9C3)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onNewSession,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('End New Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final VoidCallback onExportPDF;
  final VoidCallback onExportCSV;
  final VoidCallback onNewSession;

  const _DesktopLayout({
    required this.onExportPDF,
    required this.onExportCSV,
    required this.onNewSession,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: onExportPDF,
          icon:      const Icon(Icons.picture_as_pdf_rounded, size: 18),
          label:     const Text('Export PDF'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: Color(0xFFBEC9C3)),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onExportCSV,
          icon: const Icon(Icons.table_chart_rounded, size: 18),
          label: const Text('Export CSV'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: Color(0xFFBEC9C3)),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed:     onNewSession,
          icon:          const Icon(Icons.add_rounded, size: 18),
          label:         const Text('End Session'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation:       4,
            padding: const EdgeInsets.symmetric(
                horizontal: 28, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}