import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

// ============================================================================
// STATE MODEL
// ============================================================================

class OverlayState {
  final Map<String, dynamic> overlayData;
  final Map<String, dynamic> sessionData;
  final bool isLoading;
  final String? error;

  const OverlayState({
    this.overlayData = const {},
    this.sessionData = const {},
    this.isLoading = false,
    this.error,
  });

  OverlayState copyWith({
    Map<String, dynamic>? overlayData,
    Map<String, dynamic>? sessionData,
    bool? isLoading,
    String? error,
  }) {
    return OverlayState(
      overlayData: overlayData ?? this.overlayData,
      sessionData: sessionData ?? this.sessionData,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  // Convenience getters
  String get overlayType => overlayData['overlayType'] as String? ?? 'blocked_app';
  String get appName => overlayData['appName'] as String? ?? 'Unknown App';
  String get packageName => overlayData['packageName'] as String? ?? '';
  int get focusTimeMinutes => overlayData['focusTimeMinutes'] as int? ?? 0;
  String get sessionType => overlayData['sessionType'] as String? ?? 'timer';
  bool get isSessionActive => sessionData['isActive'] as bool? ?? false;
  bool get isSessionPaused => sessionData['isPaused'] as bool? ?? false;
  int get elapsedMinutes => sessionData['elapsedMinutes'] as int? ?? 0;
}

// ============================================================================
// SERVICE (For Stream)
// ============================================================================

class OverlayService {
  static const EventChannel _eventChannel =
  EventChannel('com.lockin.focus/overlay_events');

  Stream<Map<String, dynamic>> get eventStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map));
  }
}

// ============================================================================
// NOTIFIER (Riverpod 3.0)
// ============================================================================

class OverlayDataNotifier extends Notifier<OverlayState> {
  static const MethodChannel _methodChannel =
  MethodChannel('com.lockin.focus/overlay_actions');

  @override
  OverlayState build() {
    // Load initial data asynchronously without blocking UI
    Future.microtask(() => _loadInitialData());

    ref.listen(overlayEventsProvider, (previous, next) {
      next.whenData((event) {
        if (event['event'] == 'session_data') {
          updateSessionData(Map<String, dynamic>.from(event['data']));
        } else if (event['event'] == 'session_ended') {
          closeOverlay(); // Auto-close if session finishes
        }
      });
    });

    return const OverlayState();
  }

  Future<void> _loadInitialData() async {
    try {
      final overlayData = await _methodChannel.invokeMethod('getOverlayData');
      final sessionData = await _methodChannel.invokeMethod('getSessionData');

      state = state.copyWith(
        overlayData: Map<String, dynamic>.from(overlayData ?? {}),
        sessionData: Map<String, dynamic>.from(sessionData ?? {}),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load overlay data: $e',
      );
    }
  }

  // Action methods
  Future<bool> goHome() async {
    try {
      await _reportInteraction('go_home');
      final result = await _methodChannel.invokeMethod('goHome');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> goBack() async {
    try {
      await _reportInteraction('go_back');
      final result = await _methodChannel.invokeMethod('goBack');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> endFocusSession() async {
    try {
      await _reportInteraction('end_session');
      final result = await _methodChannel.invokeMethod('endFocusSession');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> pauseFocusSession() async {
    try {
      await _reportInteraction('pause_session');
      final result = await _methodChannel.invokeMethod('pauseFocusSession');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resumeFocusSession() async {
    try {
      await _reportInteraction('resume_session');
      final result = await _methodChannel.invokeMethod('resumeFocusSession');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> overrideAppLimit({
    required String packageName,
    required int overrideDurationMinutes,
  }) async {
    try {
      await _reportInteraction('override_limit', {
        'packageName': packageName,
        'duration': overrideDurationMinutes,
      });

      final result = await _methodChannel.invokeMethod('overrideAppLimit', {
        'packageName': packageName,
        'overrideDurationMinutes': overrideDurationMinutes,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> vibrate([String pattern = 'single']) async {
    try {
      await _methodChannel.invokeMethod('vibrate', pattern);
    } catch (e) {
      // Ignore vibration errors
    }
  }

  Future<void> showEducationalContent(String contentType) async {
    try {
      await _reportInteraction('show_education');
      await _methodChannel.invokeMethod('showEducationalContent', {
        'contentType': contentType,
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> closeOverlay() async {
    try {
      await _reportInteraction('close_overlay');
      await _methodChannel.invokeMethod('closeOverlay');
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _reportInteraction(String type,
      [Map<String, dynamic>? data]) async {
    try {
      await _methodChannel.invokeMethod('reportInteraction', {
        'type': type,
        'data': data ?? {},
      });
    } catch (e) {
      // Ignore reporting errors
    }
  }

  void updateSessionData(Map<String, dynamic> data) {
    state = state.copyWith(sessionData: data);
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

// Overlay data provider
final overlayDataProvider = NotifierProvider<OverlayDataNotifier, OverlayState>(() {
  return OverlayDataNotifier();
});

// Session data provider (Simple Provider for data)
final sessionDataProvider = Provider<Map<String, dynamic>>((ref) {
  // If you want this to be reactive based on the notifier state:
  return ref.watch(overlayDataProvider.select((s) => s.sessionData));
});

// Real-time updates provider
final overlayEventsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return OverlayService().eventStream;
});