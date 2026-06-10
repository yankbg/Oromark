//a pure dart representing a sessions
// lib/domain/entities/session_state.dart

class SessionState {
  final String? sessionId;
  final String? courseCode;
  final String? roomCode;
  final DateTime? presentCutoff;
  final DateTime? lateCutoff;
  final SessionStatus status;

  const SessionState._({
    required this.status,
    this.sessionId,
    this.courseCode,
    this.roomCode,
    this.presentCutoff,
    this.lateCutoff,
  });

  // Factory constructors — these are what you call in the notifier
  factory SessionState.idle() => const SessionState._(
    status: SessionStatus.idle,
  );

  factory SessionState.active({
    required String sessionId,
    required String courseCode,
    required String roomCode,
    required DateTime presentCutoff,
    required DateTime lateCutoff,
  }) =>
      SessionState._(
        status: SessionStatus.active,
        sessionId: sessionId,
        courseCode: courseCode,
        roomCode: roomCode,
        presentCutoff: presentCutoff,
        lateCutoff: lateCutoff,
      );

  factory SessionState.ended() => const SessionState._(
    status: SessionStatus.ended,
  );

  // Helpers your UI will use
  bool get isIdle    => status == SessionStatus.idle;
  bool get isActive  => status == SessionStatus.active;
  bool get isEnded   => status == SessionStatus.ended;
  bool get isPresent =>
      isActive && DateTime.now().isBefore(presentCutoff!);
  bool get isLate    =>
      isActive && DateTime.now().isAfter(presentCutoff!);
}

enum SessionStatus { idle, active, ended }