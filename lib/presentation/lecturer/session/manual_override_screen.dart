import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_database_provider.dart';
import 'session_controller.dart';

class ManualOverrideScreen extends ConsumerStatefulWidget {
  final StudentEntry student;
  // The full absent-only list this override screen is allowed to touch —
  // search below is scoped to it so a lecturer can only ever override a
  // student who is genuinely absent, never one already marked present/late.
  final List<StudentEntry> absentStudents;
  final String sessionId;
  const ManualOverrideScreen({
    super.key,
    required this.student,
    required this.absentStudents,
    required this.sessionId,
  });

  @override
  ConsumerState<ManualOverrideScreen> createState() =>
      _ManualOverrideScreenState();
}

class _ManualOverrideScreenState extends ConsumerState<ManualOverrideScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  late StudentEntry _selected = widget.student;
  String _status = 'absent';
  bool _isConfirming = false;
  String? _confirmState; // null / 'success'

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Matches against [widget.absentStudents] only — never the full roster —
  /// so search can't be used to reach a present/late student.
  List<StudentEntry> get _searchResults {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return widget.absentStudents
        .where((s) =>
            s.studentId != _selected.studentId &&
            (s.name.toLowerCase().contains(q) ||
                s.studentId.toLowerCase().contains(q)))
        .toList();
  }

  void _selectStudent(StudentEntry student) {
    HapticFeedback.selectionClick();
    setState(() {
      _selected = student;
      _searchCtrl.clear();
    });
  }

  Future<void> _onConfirmOverride() async {
    if (_isConfirming) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isConfirming = true;
      _confirmState = null;
    });

    final newStatus = _status.toUpperCase(); // PRESENT / LATE / ABSENT
    await ref.read(appDatabaseProvider).insertAttendanceRecord(
          sessionId: widget.sessionId,
          studentId: _selected.studentId,
          status: newStatus,
          submittedAt: DateTime.now().millisecondsSinceEpoch,
        );
    if (!mounted) return;

    setState(() {
      _confirmState = 'success';
    });

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    Navigator.of(context).pop((student: _selected, status: newStatus));
  }

  @override
  Widget build(BuildContext context) {
    // optional: status bar style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // background
      appBar: _ManualOverrideAppBar(),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 88),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search — scoped to widget.absentStudents only
                  _SearchField(controller: _searchCtrl),

                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _SearchResultsList(
                      results: _searchResults,
                      onSelect: _selectStudent,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Selected student card
                   _SelectedStudentCard(student: _selected),

                  const SizedBox(height: 24),

                  // Status options
                  Text(
                    'SET ATTENDANCE STATUS',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: Color(0xFF3F4944), // on-surface-variant
                    ),
                  ),
                  const SizedBox(height: 16),

                  _StatusGrid(
                    value: _status,
                    onChanged: (v) => setState(() => _status = v),
                  ),

                  const SizedBox(height: 24),

                  // Audit warning
                  const _AuditWarningCard(),
                ],
              ),
            ),
          ),

          // Fixed bottom actions
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomActions(
              isLoading: _isConfirming,
              isSuccess: _confirmState == 'success',
              onCancel: () => Navigator.of(context).pop(),
              onConfirm: _onConfirmOverride,
            ),
          ),
        ],
      ),
    );
  }
}

// AppBar ----------------------------------------------------------------------

class _ManualOverrideAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF9F9F9), // surface
      elevation: 1,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF005440)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Manual Override',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF005440), // primary
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: const [
              // logo placeholder
              Icon(Icons.school, color: Color(0xFF005440)),
              SizedBox(width: 8),
              Icon(Icons.warning_amber_rounded, color: Color(0xFFBA1A1A)),
            ],
          ),
        ),
      ],
    );
  }
}

// Search field ----------------------------------------------------------------

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search student by name or ID',
        prefixIcon: const Icon(Icons.search_rounded,
            color: Color(0xFF6F7A74)), // outline
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFBEC9C3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF005440), width: 2),
        ),
      ),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        color: Color(0xFF1A1C1C),
      ),
    );
  }
}

// Search results (absent students only) ----------------------------------------

class _SearchResultsList extends StatelessWidget {
  final List<StudentEntry> results;
  final ValueChanged<StudentEntry> onSelect;
  const _SearchResultsList({required this.results, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBEC9C3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: results
            .map((s) => InkWell(
                  onTap: () => onSelect(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1C1C),
                                ),
                              ),
                              Text(
                                s.studentId,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xFF3F4944),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFF6F7A74)),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// Selected student card -------------------------------------------------------

class _SelectedStudentCard extends StatelessWidget {
  final StudentEntry student;
  const _SelectedStudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // surface-container-lowest
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFBEC9C3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0F6E56), // primary-container
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuBPQctMCm5Idb1uMQ4GfLCjug3l6rQXbkd0vBrucqZZmM81TJNB-yHnv71QcYu_Of1ZyDv3mKQoISIerH25zw2jSqBqRb6nidw1F90xziAxmn5eXKInaXHv6hyFfG6H_NW7mBhV7FHhixThxtGaU5ebaSp8HA8ZecZRjzMei6RX4OugO838MGp5Gw1zWkZINwKasThikFUBC4ZEh8UOhWSyuUabms_1lUW9zqpTIhHxaEvG0940uK8u3Zi-9gF-lfKpur6lyt4rLvM',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          // name + id
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  student.studentId,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3F4944),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // absent pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDAD6), // error-container
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.error_rounded,
                    size: 16, color: Color(0xFF93000A)),
                SizedBox(width: 4),
                Text(
                  'ABSENT',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF93000A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Status grid -----------------------------------------------------------------

class _StatusGrid extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusGrid({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 96,
      ),
      children: [
        _StatusCard(
          label: 'PRESENT',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF005440), // primary
          groupValue: value,
          value: 'present',
          onChanged: onChanged,
        ),
        _StatusCard(
          label: 'LATE',
          icon: Icons.schedule_rounded,
          color: const Color(0xFF885200), // secondary
          groupValue: value,
          value: 'late',
          onChanged: onChanged,
        ),
        _StatusCard(
          label: 'ABSENT',
          icon: Icons.cancel_rounded,
          color: const Color(0xFFBA1A1A), // error
          groupValue: value,
          value: 'absent',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String groupValue;
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.groupValue,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = groupValue == value;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color : const Color(0xFFBEC9C3),
            width: isActive ? 1.8 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color:
                    isActive ? color : const Color(0xFF3F4944),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                      isActive ? color : const Color(0xFF3F4944),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? color : const Color(0xFFBEC9C3),
                    width: 2,
                  ),
                  color: isActive ? color : Colors.transparent,
                ),
                child: isActive
                    ? const Icon(Icons.check,
                    size: 12, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Audit warning ---------------------------------------------------------------

class _AuditWarningCard extends StatelessWidget {
  const _AuditWarningCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDCBB).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDAD4E).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.history_edu_rounded,
              size: 24, color: Color(0xFF704200)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action will be logged in the audit trail.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF704200),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Timestamp and your name (Dr. Sarah Jenkins) will be recorded.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF704200),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom actions --------------------------------------------------------------

class _BottomActions extends StatelessWidget {
  final bool isLoading;
  final bool isSuccess;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _BottomActions({
    required this.isLoading,
    required this.isSuccess,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEEEEE),
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isLoading ? null : onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A1C1C),
                side: const BorderSide(color: Color(0xFF6F7A74)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: isLoading ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005440),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              child: Builder(
                builder: (_) {
                  if (isLoading) {
                    return const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    );
                  }
                  if (isSuccess) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_rounded, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Success',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  }
                  return const Text(
                    'Confirm Override',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}