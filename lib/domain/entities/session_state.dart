// lib/domain/entities/session_state.dart

/// Represents the state of a lecturer's active attendance session
///
/// States:
/// - Idle: No session running
/// - Active: Session in progress (can be in present or late window)
/// - Ended: Session finished

sealed class SessionState {
  const SessionState();

  /// Idle state — no session
  factory SessionState.idle() => const _IdleState();

  /// Active session
  factory SessionState.active({
    required String sessionId,
    required String courseCode,
    required String roomCode,
    required DateTime presentCutoff,
    required DateTime lateCutoff,
    bool isLate = false,
  }) =>
      _ActiveState(
        sessionId: sessionId,
        courseCode: courseCode,
        roomCode: roomCode,
        presentCutoff: presentCutoff,
        lateCutoff: lateCutoff,
        isLate: isLate,
      );

  /// Ended state
  factory SessionState.ended() => const _EndedState();

  /// Getter: Is this idle?
  bool get isIdle => this is _IdleState;

  /// Getter: Is this active?
  bool get isActive => this is _ActiveState;

  /// Getter: Is this ended?
  bool get isEnded => this is _EndedState;

  /// Getter: Get active session data (null if not active)
  _ActiveState? get active => this is _ActiveState ? this as _ActiveState : null;

  /// Getter: Session ID (null if not active)
  String? get sessionId => active?.sessionId;

  /// Getter: Course code (null if not active)
  String? get courseCode => active?.courseCode;

  /// Getter: Getter for copyWith pattern
  SessionState copyWith({
    String? sessionId,
    String? courseCode,
    String? roomCode,
    DateTime? presentCutoff,
    DateTime? lateCutoff,
    bool? isLate,
  }) {
    if (this is _ActiveState) {
      final current = this as _ActiveState;
      return SessionState.active(
        sessionId: sessionId ?? current.sessionId,
        courseCode: courseCode ?? current.courseCode,
        roomCode: roomCode ?? current.roomCode,
        presentCutoff: presentCutoff ?? current.presentCutoff,
        lateCutoff: lateCutoff ?? current.lateCutoff,
        isLate: isLate ?? current.isLate,
      );
    }
    return this;
  }

  @override
  String toString() => switch (this) {
    _IdleState() => 'SessionState.idle()',
    _ActiveState(:final sessionId, :final courseCode, :final isLate) =>
    'SessionState.active(id=$sessionId, course=$courseCode, late=$isLate)',
    _EndedState() => 'SessionState.ended()',
  };
}

/// Idle state
class _IdleState extends SessionState {
  const _IdleState();
}

/// Active session state
class _ActiveState extends SessionState {
  final String sessionId;
  final String courseCode;
  final String roomCode;
  final DateTime presentCutoff;
  final DateTime lateCutoff;
  final bool isLate; // ✅ Track whether in late window

  const _ActiveState({
    required this.sessionId,
    required this.courseCode,
    required this.roomCode,
    required this.presentCutoff,
    required this.lateCutoff,
    this.isLate = false,
  });
}

/// Ended state
class _EndedState extends SessionState {
  const _EndedState();
}