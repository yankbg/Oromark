// lib/presentation/student/home/session_discovery_screen.dart
//
// Modal sheet that displays available session broadcasts.
// Student can view sessions and tap one to join.
// Uses Riverpod to listen for UDP broadcasts in real-time.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oromark/providers/session_discovery_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'student_home_controller.dart';
import 'confirmation_screen.dart';

class SessionDiscoverySheet extends ConsumerWidget {
  final Function(DetectedSession) onSessionSelected;

  const SessionDiscoverySheet({
    super.key,
    required this.onSessionSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // [MOCK] — Will be replaced with:
    // final discoveredSessions = ref.watch(discoveredSessionsProvider);

    // For now, use the mock sessions from controller
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ───────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          // ── Header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.sensors_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Sessions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tap a session to join',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.bgSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFFE2E8E4), height: 1),

          // ── Session list ─────────────────────────────────────
          Expanded(
            child: _SessionList(
              onSessionSelected: (session) {
                Navigator.pop(context);
                onSessionSelected(session);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Session list implementation ───────────────────────────────────────────────
class _SessionList extends ConsumerWidget {
  final Function(DetectedSession) onSessionSelected;

  const _SessionList({required this.onSessionSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveredSessionsAsync = ref.watch(discoveredSessionsProvider);
    // [MOCK] For testing, return 2 mock sessions
    // After UDP is integrated, this will come from Riverpod provider

    // final mockSessions = [
    //   DetectedSession(
    //     sessionId: 'mock-uuid-001',
    //     courseCode: 'CS301',
    //     courseName: 'Software Engineering',
    //     lecturerName: 'Dr. John Doe',
    //     room: 'A204',
    //     roomCode: 'A3K9',
    //     presentCutoff: DateTime.now().add(const Duration(minutes: 8)),
    //     lateCutoff: DateTime.now().add(const Duration(minutes: 18)),
    //     lecturerIP: '192.168.1.100', // [MOCK]
    //     lecturerPort: 3000,
    //   ),
    //   DetectedSession(
    //     sessionId: 'mock-uuid-002',
    //     courseCode: 'CS202',
    //     courseName: 'Data Structures',
    //     lecturerName: 'Dr. Sarah Smith',
    //     room: 'B105',
    //     roomCode: 'B2M7',
    //     presentCutoff: DateTime.now().add(const Duration(minutes: 12)),
    //     lateCutoff: DateTime.now().add(const Duration(minutes: 22)),
    //     lecturerIP: '192.168.1.101', // [MOCK]
    //     lecturerPort: 3000,
    //   ),
    // ];
    //
    // if (mockSessions.isEmpty) {
    //   return _EmptyState();
    // }

    return discoveredSessionsAsync.when(
      // ✅ Loading state: Show spinner
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Listening for broadcasts...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),

      // ✅ Success: Show list of discovered sessions
      data: (sessions) {
        if (sessions.isEmpty) {
          return _EmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: sessions.length,
          itemBuilder: (context, index) => _SessionTile(
            session: sessions[index],
            onTap: onSessionSelected,
          ),
        );
      },

      // ❌ Error: Show error message
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Discovery Error',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sensors_off_rounded,
              color: AppColors.textSecondary,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No sessions available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Waiting for lecturer to start a session.\nKeep this screen open.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Refresh button to retry discovery
          ElevatedButton.icon(
            onPressed: () {
              // Refresh the provider to restart discovery
              // User can tap if they know a session should be available
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Session tile ───────────────────────────────────────────────────────────────
class _SessionTile extends StatelessWidget {
  final DetectedSession session;
  final Function(DetectedSession) onTap;

  const _SessionTile({
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLate = session.isLate;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8E4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(session),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: course code + time window ──────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.courseCode,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            session.courseName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isLate ? AppColors.warning : AppColors.bgPrimary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isLate ? 'LATE' : 'PRESENT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isLate ? AppColors.warning : AppColors.success,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Details row: lecturer + room ───────────────
                Row(
                  children: [
                    Expanded(
                      child: _DetailChip(
                        icon: Icons.person_rounded,
                        label: session.lecturerName,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DetailChip(
                        icon: Icons.location_on_rounded,
                        label: session.room,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Room code display ──────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.vpn_key_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Code: ${session.roomCode}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatRemaining(session.remaining),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isLate ? AppColors.warning : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRemaining(Duration d) {
    if (d.isNegative) return 'Expired';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')} left';
  }
}

// ── Detail chip (lecturer/room) ───────────────────────────────────────────────
class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}