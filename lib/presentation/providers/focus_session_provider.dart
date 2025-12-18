import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/services/focus_session_service.dart';

/// State for the active focus session
class ActiveFocusSession {
  final bool isActive;
  final String? sessionId;
  final List<String> blockedApps;
  final int duration;
  final bool strictMode;
  final int elapsedMinutes;
  final bool isLoading;
  final String? error;

  const ActiveFocusSession({
    this.isActive = false,
    this.sessionId,
    this.blockedApps = const [],
    this.duration = 0,
    this.strictMode = false,
    this.elapsedMinutes = 0,
    this.isLoading = false,
    this.error,
  });

  ActiveFocusSession copyWith({
    bool? isActive,
    String? sessionId,
    List<String>? blockedApps,
    int? duration,
    bool? strictMode,
    int? elapsedMinutes,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ActiveFocusSession(
      isActive: isActive ?? this.isActive,
      sessionId: sessionId ?? this.sessionId,
      blockedApps: blockedApps ?? this.blockedApps,
      duration: duration ?? this.duration,
      strictMode: strictMode ?? this.strictMode,
      elapsedMinutes: elapsedMinutes ?? this.elapsedMinutes,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  int get remainingMinutes => duration - elapsedMinutes;
  double get progress => duration > 0 ? elapsedMinutes / duration : 0.0;
}

/// Notifier for managing focus sessions
class FocusSessionNotifier extends Notifier<ActiveFocusSession> {
  @override
  ActiveFocusSession build() {
    // Listen to focus events
    FocusSessionService.focusEvents.listen((event) {
      _handleFocusEvent(event);
    });

    // Load initial state
    _loadSessionInfo();

    return const ActiveFocusSession();
  }

  /// Load current session info from native
  Future<void> _loadSessionInfo() async {
    final info = await FocusSessionService.getSessionInfo();
    if (info != null) {
      state = state.copyWith(
        isActive: info.isActive,
        sessionId: info.sessionId,
        blockedApps: await FocusSessionService.getBlockedApps(),
        duration: info.plannedDuration,
        strictMode: info.strictMode,
        elapsedMinutes: info.elapsedMinutes,
      );
    }
  }

  /// Handle focus events from native
  void _handleFocusEvent(FocusEvent event) {
    if (event.isFocusStarted) {
      debugPrint('Focus session started: ${event.sessionId}');
      _loadSessionInfo();
    } else if (event.isFocusStopped) {
      debugPrint('Focus session stopped');
      state = const ActiveFocusSession();
    } else if (event.isAppBlocked) {
      debugPrint('App blocked: ${event.data}');
    }
  }

  /// Start a new focus session
  Future<bool> startSession({
    required String sessionId,
    required List<String> blockedApps,
    required int durationMinutes,
    bool strictMode = false,
    bool blockHomeScreen = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final success = await FocusSessionService.startFocusSession(
        sessionId: sessionId,
        blockedApps: blockedApps,
        duration: durationMinutes,
        strictMode: strictMode,
        blockHomeScreen: blockHomeScreen,
      );

      if (success) {
        state = state.copyWith(
          isActive: true,
          sessionId: sessionId,
          blockedApps: blockedApps,
          duration: durationMinutes,
          strictMode: strictMode,
          elapsedMinutes: 0,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to start focus session',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error starting focus session: $e');
      state = state.copyWith(isLoading: false, error: 'Error: $e');
      return false;
    }
  }

  /// Stop the current focus session
  Future<bool> stopSession({bool force = false}) async {
    if (!state.isActive) {
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final success = await FocusSessionService.stopFocusSession(force: force);

      if (success) {
        state = const ActiveFocusSession();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: state.strictMode
              ? 'Cannot stop session in strict mode'
              : 'Failed to stop focus session',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error stopping focus session: $e');
      state = state.copyWith(isLoading: false, error: 'Error: $e');
      return false;
    }
  }

  /// Refresh session info
  Future<void> refresh() async {
    await _loadSessionInfo();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for active focus session
final activeFocusSessionProvider =
    NotifierProvider<FocusSessionNotifier, ActiveFocusSession>(
      FocusSessionNotifier.new,
    );

/// Stream provider for focus events
final focusEventsProvider = StreamProvider<FocusEvent>((ref) {
  return FocusSessionService.focusEvents;
});
