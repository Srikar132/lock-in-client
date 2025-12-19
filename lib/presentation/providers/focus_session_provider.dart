import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lock_in/data/models/focus_session_model.dart';
import 'package:lock_in/services/native_service.dart';
import 'package:lock_in/presentation/providers/auth_provider.dart';
import 'package:lock_in/data/repositories/focus_session_repository.dart';

final sessionRepositoryProvider = Provider<FocusSessionRepository>((ref) {
  return FocusSessionRepository();
});

final todaySessionsProvider =
    StreamProvider.family<List<FocusSessionModel>, String>((ref, userId) {
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
  endingWithSave,
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
      status == FocusSessionStatus.active ||
      status == FocusSessionStatus.paused;
  int get elapsedMinutes => (elapsedSeconds ?? 0) ~/ 60;
  int get remainingMinutes => (remainingSeconds ?? 0) ~/ 60;
}

// ============================================================================
// FOCUS SESSION NOTIFIER (Fixed Type Casting)
// ============================================================================

class FocusSessionNotifier extends Notifier<FocusSessionState> {
  StreamSubscription? _eventSubscription;
  Timer? _localTimer;
  bool _isEndingForSave = false;

  @override
  FocusSessionState build() {
    _listenToNativeEvents();
    ref.onDispose(() {
      _eventSubscription?.cancel();
      _stopLocalTimer();
    });
    return FocusSessionState();
  }

  void _listenToNativeEvents() {
    _eventSubscription = NativeService.focusEventStream.listen(
      (event) {
        try {
          final eventType = event['event'] as String?;
          // FIX: Safe cast with proper error handling
          final data = _safeConvertToMap(event['data']);

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
        } catch (e, stack) {
          debugPrint('❌ Error processing native event: $e');
          debugPrint('Stack trace: $stack');
        }
      },
      onError: (error) {
        debugPrint('❌ Error in native event stream: $error');
      },
    );
  }

  /// FIX: Safely convert dynamic map to Map<String, dynamic>
  Map<String, dynamic>? _safeConvertToMap(dynamic data) {
    if (data == null) return null;

    try {
      if (data is Map<String, dynamic>) {
        return data;
      } else if (data is Map) {
        // Convert Map<Object?, Object?> to Map<String, dynamic>
        return Map<String, dynamic>.from(
          data.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error converting map: $e');
    }

    return null;
  }

  void _handleSessionStarted(Map<String, dynamic>? data) {
    if (data == null) return;

    state = state.copyWith(
      status: FocusSessionStatus.active,
      sessionId: data['sessionId'] as String?,
      sessionType: data['sessionType'] as String?,
      plannedDuration: _safeInt(data['plannedDuration']),
      isPaused: false,
      nativeSessionData: data,
    );

    _startLocalTimer();
  }

  void _handleSessionPaused(Map<String, dynamic>? data) {
    state = state.copyWith(status: FocusSessionStatus.paused, isPaused: true);
    _stopLocalTimer();
  }

  void _handleSessionResumed(Map<String, dynamic>? data) {
    state = state.copyWith(status: FocusSessionStatus.active, isPaused: false);
    _startLocalTimer();
  }

  void _handleSessionCompleted(Map<String, dynamic>? data) {
    debugPrint(
      '🔄 _handleSessionCompleted called. Current status: ${state.status}, _isEndingForSave: $_isEndingForSave',
    );

    // CRITICAL FIX: If we're ending for save screen, ignore ALL native completion events
    if (_isEndingForSave ||
        state.status == FocusSessionStatus.endingWithSave ||
        state.status == FocusSessionStatus.ending) {
      debugPrint(
        '🔄 Ignoring auto-completion - session is being ended for save screen',
      );
      return;
    }

    debugPrint('🔄 Setting status to completed from _handleSessionCompleted');
    state = state.copyWith(
      status: FocusSessionStatus.completed,
      isPaused: false,
    );
    _stopLocalTimer();

    if (data != null) {
      _saveCompletedSession(data);
    }
  }

  void _handleTimerUpdate(Map<String, dynamic>? data) {
    if (data == null) return;

    final elapsedMs = _safeInt(data['elapsed']);
    final remainingMs = _safeInt(data['remaining']);

    state = state.copyWith(
      elapsedSeconds: elapsedMs != null ? elapsedMs ~/ 1000 : null,
      remainingSeconds: remainingMs != null ? remainingMs ~/ 1000 : null,
    );
  }

  void _handleInterruptionDetected(Map<String, dynamic>? data) {
    if (data == null) return;
    debugPrint('⚠️ Interruption detected: ${data['appName']}');
  }

  /// Helper to safely extract integers from dynamic data
  int? _safeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

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

  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ============================================================================
  // SESSION CONTROL (Fixed Navigation Issue)
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

      final nativeSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final todayDate = _getTodayDateString();

      // Start Native Session
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

      final sessionModel = FocusSessionModel(
        sessionId: nativeSessionId,
        userId: user.uid,
        startTime: DateTime.now(),
        plannedDuration: plannedDuration,
        sessionType: sessionType,
        status: 'active',
        date: todayDate,
      );

      final firestoreId = await ref
          .read(sessionRepositoryProvider)
          .createSession(sessionModel);

      state = state.copyWith(
        status: FocusSessionStatus.active,
        sessionId: firestoreId,
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
      state = state.copyWith(status: FocusSessionStatus.paused, isPaused: true);
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

  // FIX: Proper error handling to prevent navigation crashes
  Future<void> endSession() async {
    if (!state.isActive) {
      debugPrint('⚠️ No active session to end');
      return;
    }

    // Set flag to indicate we're ending for save screen
    _isEndingForSave = true;
    debugPrint('🔄 Setting flag _isEndingForSave = true');

    debugPrint('🔄 Setting status to ending...');
    state = state.copyWith(status: FocusSessionStatus.ending);

    try {
      debugPrint('🔄 Calling native endFocusSession...');
      final success = await NativeService.endFocusSession();

      if (success) {
        // CRITICAL FIX: Add a small delay to ensure the listener catches this state change
        await Future.delayed(const Duration(milliseconds: 100));

        // Set state to endingWithSave to trigger navigation to save screen
        debugPrint('🔄 Setting status to endingWithSave...');
        state = state.copyWith(status: FocusSessionStatus.endingWithSave);
        _stopLocalTimer();

        debugPrint(
          '✅ Session ended, ready for save screen. Status: ${state.status}',
        );
      } else {
        throw Exception('Failed to end native session');
      }
    } catch (e) {
      debugPrint('❌ Error ending session: $e');
      // Even if there's an error, reset to idle to prevent stuck state
      _isEndingForSave = false;
      state = FocusSessionState(
        status: FocusSessionStatus.error,
        error: e.toString(),
      );
      _stopLocalTimer();
    }
  }

  Future<void> refreshSessionFromNative() async {
    try {
      final status = await NativeService.getCurrentSessionStatus();

      if (status != null && status['isActive'] == true) {
        final mappedData = _safeConvertToMap(status);
        _handleSessionStarted(mappedData);
        debugPrint('🔄 Focus session synchronized from Native');
      } else if (state.isActive) {
        // Reset to idle if native layer confirms no active session
        state = FocusSessionState(status: FocusSessionStatus.idle);
        _stopLocalTimer();
      }
    } catch (e) {
      debugPrint('❌ Sync Error: $e');
    }
  }

  Future<void> _saveCompletedSession(Map<String, dynamic> data) async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null || state.sessionId == null) return;

      final actualDuration = state.elapsedMinutes;
      final todayDate = _getTodayDateString();

      await ref
          .read(sessionRepositoryProvider)
          .completeSession(
            sessionId: state.sessionId!,
            userId: user.uid,
            actualDuration: actualDuration,
            date: todayDate,
          );

      debugPrint('✅ Session saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving completed session: $e');
    }
  }

  // Get session data for save screen
  Map<String, dynamic> getCurrentSessionData() {
    return {
      'sessionId': state.sessionId,
      'elapsedSeconds': state.elapsedSeconds ?? 0,
      'plannedDuration': state.plannedDuration,
      'sessionType': state.sessionType,
      'startTime': DateTime.now().subtract(
        Duration(seconds: state.elapsedSeconds ?? 0),
      ),
    };
  }

  // Complete session with additional notes and tag
  Future<void> completeSessionWithNotes({String? notes, String? tag}) async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null || state.sessionId == null) return;

      final actualDuration = state.elapsedMinutes;
      final todayDate = _getTodayDateString();

      // Update session with notes and tag
      await ref
          .read(sessionRepositoryProvider)
          .updateSession(state.sessionId!, {
            'actualDuration': actualDuration,
            'endTime': Timestamp.now(),
            'status': 'completed',
            'notes': notes ?? '',
            'tag': tag ?? 'untagged',
            'completedAt': todayDate,
          });

      // IMPORTANT: Reset flag BEFORE changing status
      _isEndingForSave = false;

      // Now set to completed
      state = FocusSessionState(status: FocusSessionStatus.completed);
      _stopLocalTimer();

      debugPrint('✅ Session completed and saved with notes');
    } catch (e) {
      debugPrint('❌ Error completing session with notes: $e');
      // Reset flag even on error
      _isEndingForSave = false;
      throw e;
    }
  }

  void discardSession() {
    try {
      // IMPORTANT: Reset flag BEFORE changing status
      _isEndingForSave = false;

      // Now set to idle
      state = FocusSessionState(status: FocusSessionStatus.idle);
      _stopLocalTimer();

      debugPrint('✅ Session discarded without saving');
    } catch (e) {
      debugPrint('❌ Error discarding session: $e');
      // Reset flag even on error
      _isEndingForSave = false;
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

final isSessionActiveProvider = Provider<bool>((ref) {
  return ref.watch(focusSessionProvider.select((s) => s.isActive));
});

final sessionElapsedTimeProvider = Provider<String>((ref) {
  final elapsed = ref.watch(
    focusSessionProvider.select((s) => s.elapsedSeconds ?? 0),
  );
  final minutes = elapsed ~/ 60;
  final seconds = elapsed % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
});

final sessionRemainingTimeProvider = Provider<String>((ref) {
  final remaining = ref.watch(
    focusSessionProvider.select((s) => s.remainingSeconds ?? 0),
  );
  final minutes = remaining ~/ 60;
  final seconds = remaining % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
});
