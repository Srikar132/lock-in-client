import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/data/models/focus_session_model.dart';
import 'package:lock_in/services/native_service.dart';
import 'package:lock_in/presentation/providers/auth_provider.dart';
import 'package:lock_in/data/repositories/focus_session_repository.dart';

final sessionRepositoryProvider = Provider<FocusSessionRepository>((ref) {
  return FocusSessionRepository();
});

// Today's sessions stream
final todaySessionsProvider = StreamProvider.family<List<FocusSessionModel>, String>((ref, userId) {
  return ref.watch(sessionRepositoryProvider).streamTodaySessions(userId);
});


// ============================================================================
// FOCUS SESSION STATE
// ============================================================================

enum FocusSessionStatus {
  idle,
  starting,
  active,
  paused,
  ending,
  completed,
  error,
}

class FocusSessionState {
  final FocusSessionStatus status;
  final String? sessionId;
  final int? elapsedSeconds;
  final int? remainingSeconds;
  final int? plannedDuration;
  final String? sessionType;
  final bool isPaused;
  final String? error;
  final Map<String, dynamic>? nativeSessionData;

  FocusSessionState({
    this.status = FocusSessionStatus.idle,
    this.sessionId,
    this.elapsedSeconds,
    this.remainingSeconds,
    this.plannedDuration,
    this.sessionType,
    this.isPaused = false,
    this.error,
    this.nativeSessionData,
  });

  FocusSessionState copyWith({
    FocusSessionStatus? status,
    String? sessionId,
    int? elapsedSeconds,
    int? remainingSeconds,
    int? plannedDuration,
    String? sessionType,
    bool? isPaused,
    String? error,
    Map<String, dynamic>? nativeSessionData,
  }) {
    return FocusSessionState(
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      sessionType: sessionType ?? this.sessionType,
      isPaused: isPaused ?? this.isPaused,
      error: error,
      nativeSessionData: nativeSessionData ?? this.nativeSessionData,
    );
  }

  bool get isActive =>
      status == FocusSessionStatus.active || status == FocusSessionStatus.paused;
  int get elapsedMinutes => (elapsedSeconds ?? 0) ~/ 60;
  int get remainingMinutes => (remainingSeconds ?? 0) ~/ 60;
}

// ============================================================================
// FOCUS SESSION NOTIFIER (Riverpod 3.0)
// ============================================================================

class FocusSessionNotifier extends Notifier<FocusSessionState> {
  StreamSubscription? _eventSubscription;
  Timer? _localTimer;

  // With Notifier, we initialize state in build()
  @override
  FocusSessionState build() {
    // Start listening to native events immediately when the provider is built
    _listenToNativeEvents();

    // Clean up subscription when the provider is destroyed
    ref.onDispose(() {
      _eventSubscription?.cancel();
      _stopLocalTimer();
    });

    return FocusSessionState();
  }

  // ============================================================================
  // EVENT LISTENING
  // ============================================================================

  void _listenToNativeEvents() {
    _eventSubscription = NativeService.focusEventStream.listen(
          (event) {
        final eventType = event['event'] as String?;
        final data = event['data'] as Map<String, dynamic>?;

        debugPrint('📡 Received native event: $eventType');

        switch (eventType) {
          case 'session_started':
            _handleSessionStarted(data);
            break;
          case 'session_paused':
            _handleSessionPaused(data);
            break;
          case 'session_resumed':
            _handleSessionResumed(data);
            break;
          case 'session_completed':
          case 'session_auto_completed':
            _handleSessionCompleted(data);
            break;
          case 'timer_update':
            _handleTimerUpdate(data);
            break;
          case 'interruption_detected':
            _handleInterruptionDetected(data);
            break;
        }
      },
      onError: (error) {
        debugPrint('❌ Error in native event stream: $error');
      },
    );
  }

  void _handleSessionStarted(Map<String, dynamic>? data) {
    if (data == null) return;

    state = state.copyWith(
      status: FocusSessionStatus.active,
      sessionId: data['sessionId'] as String?,
      sessionType: data['sessionType'] as String?,
      plannedDuration: data['plannedDuration'] as int?,
      isPaused: false,
      nativeSessionData: data,
    );

    _startLocalTimer();
  }

  void _handleSessionPaused(Map<String, dynamic>? data) {
    state = state.copyWith(
      status: FocusSessionStatus.paused,
      isPaused: true,
    );
    _stopLocalTimer();
  }

  void _handleSessionResumed(Map<String, dynamic>? data) {
    state = state.copyWith(
      status: FocusSessionStatus.active,
      isPaused: false,
    );
    _startLocalTimer();
  }

  void _handleSessionCompleted(Map<String, dynamic>? data) {
    state = state.copyWith(
      status: FocusSessionStatus.completed,
      isPaused: false,
    );
    _stopLocalTimer();

    // Save to Firestore
    if (data != null) {
      _saveCompletedSession(data);
    }
  }

  void _handleTimerUpdate(Map<String, dynamic>? data) {
    if (data == null) return;

    state = state.copyWith(
      elapsedSeconds: (data['elapsed'] as int?) != null
          ? (data['elapsed'] as int) ~/ 1000
          : null,
      remainingSeconds: (data['remaining'] as int?) != null
          ? (data['remaining'] as int) ~/ 1000
          : null,
    );
  }

  void _handleInterruptionDetected(Map<String, dynamic>? data) {
    debugPrint('⚠️ Interruption detected: ${data?['appName']}');
    // Could show UI notification or update stats

  }

  // ============================================================================
  // LOCAL TIMER (Backup)
  //============================================================================

  void _startLocalTimer() {
    _stopLocalTimer();
    _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isPaused && state.isActive) {
        final newElapsed = (state.elapsedSeconds ?? 0) + 1;
        final newRemaining = state.remainingSeconds != null
            ? (state.remainingSeconds! - 1).clamp(0, double.infinity).toInt()
            : null;

        state = state.copyWith(
          elapsedSeconds: newElapsed,
          remainingSeconds: newRemaining,
        );
      }
    });
  }

  void _stopLocalTimer() {
    _localTimer?.cancel();
    _localTimer = null;
  }

// Helper to get formatted date string for Repo
  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ============================================================================
  // SESSION CONTROL
  // ============================================================================

  Future<void> startSession({
    required int plannedDuration,
    required String sessionType,
    required List<String> blockedApps,
    List<Map<String, dynamic>>? blockedWebsites,
    bool shortFormBlocked = false,
    bool notificationsBlocked = false,
  }) async {
    state = state.copyWith(status: FocusSessionStatus.starting);

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception('User not logged in');

      // 1. Generate ID for Native use
      final nativeSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final todayDate = _getTodayDateString();

      // 2. Start Native Session
      final success = await NativeService.startFocusSession(
        sessionId: nativeSessionId,
        userId: user.uid,
        plannedDuration: plannedDuration,
        sessionType: sessionType,
        blockedApps: blockedApps,
        blockedWebsites: blockedWebsites,
        shortFormBlocked: shortFormBlocked,
        notificationsBlocked: notificationsBlocked,
      );

      if (!success) throw Exception('Failed to start native session');

      // 3. Create Model for Repository
      final sessionModel = FocusSessionModel(
        sessionId: nativeSessionId, // This might be ignored by .add() in repo
        userId: user.uid,
        startTime: DateTime.now(),
        plannedDuration: plannedDuration,
        sessionType: sessionType,
        status: 'active',
        date: todayDate,
      );

      // 4. Call Repository (CORRECTED)
      // The repo uses .add(), so it generates a NEW Firestore Document ID.
      // We must capture this ID to update the session later.
      final firestoreId = await ref.read(sessionRepositoryProvider).createSession(sessionModel);

      state = state.copyWith(
        status: FocusSessionStatus.active,
        sessionId: firestoreId, // Important: Use Firestore ID for state so completeSession works
        plannedDuration: plannedDuration,
        sessionType: sessionType,
        elapsedSeconds: 0,
        remainingSeconds: plannedDuration * 60,
        isPaused: false,
      );

      _startLocalTimer();
    } catch (e) {
      debugPrint('❌ Error starting session: $e');
      state = state.copyWith(
        status: FocusSessionStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> pauseSession() async {
    if (!state.isActive || state.isPaused) return;

    final success = await NativeService.pauseFocusSession();
    if (success) {
      state = state.copyWith(
        status: FocusSessionStatus.paused,
        isPaused: true,
      );
      _stopLocalTimer();
    }
  }

  Future<void> resumeSession() async {
    if (!state.isActive || !state.isPaused) return;

    final success = await NativeService.resumeFocusSession();
    if (success) {
      state = state.copyWith(
        status: FocusSessionStatus.active,
        isPaused: false,
      );
      _startLocalTimer();
    }
  }

  Future<void> endSession() async {
    if (!state.isActive) return;

    state = state.copyWith(status: FocusSessionStatus.ending);

    final success = await NativeService.endFocusSession();
    if (success) {
      // Get final session data
      final nativeData = await NativeService.getCurrentSessionStatus();

      if (nativeData != null && state.sessionId != null) {
        await _saveCompletedSession(nativeData);
      }

      state = FocusSessionState(status: FocusSessionStatus.idle);
      _stopLocalTimer();
    }
  }

  Future<void> _saveCompletedSession(Map<String, dynamic> data) async {
    try {
      final user = ref.read(currentUserProvider).value;
      // We need the sessionId that matches the Firestore Document ID
      if (user == null || state.sessionId == null) return;

      final actualDuration = state.elapsedMinutes;
      final todayDate = _getTodayDateString();

      // CORRECTION: Matching the Repo signature
      // Repo expects: completeSession({required String sessionId, required String userId, required int actualDuration, required String date})
      await ref.read(sessionRepositoryProvider).completeSession(
        sessionId: state.sessionId!,
        userId: user.uid,
        actualDuration: actualDuration,
        date: todayDate, // Added this
        // Removed completionRate (repo doesn't take it as arg)
      );
    } catch (e) {
      debugPrint('❌ Error saving completed session: $e');
    }
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

final focusSessionProvider =
NotifierProvider<FocusSessionNotifier, FocusSessionState>(() {
  return FocusSessionNotifier();
});

// Derived providers
final isSessionActiveProvider = Provider<bool>((ref) {
  return ref.watch(focusSessionProvider.select((s) => s.isActive));
});

final sessionElapsedTimeProvider = Provider<String>((ref) {
  final elapsed =
  ref.watch(focusSessionProvider.select((s) => s.elapsedSeconds ?? 0));
  final minutes = elapsed ~/ 60;
  final seconds = elapsed % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
});

final sessionRemainingTimeProvider = Provider<String>((ref) {
  final remaining =
  ref.watch(focusSessionProvider.select((s) => s.remainingSeconds ?? 0));
  final minutes = remaining ~/ 60;
  final seconds = remaining % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
});