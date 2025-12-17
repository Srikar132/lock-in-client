import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/data/models/focus_session_model.dart';
import 'package:lock_in/data/repositories/focus_session_repository.dart';


final sessionRepositoryProvider = Provider<FocusSessionRepository>((ref) {
  return FocusSessionRepository();
});

// Today's sessions stream
final todaySessionsProvider = StreamProvider.family<List<FocusSessionModel>, String>((ref, userId) {
  return ref.watch(sessionRepositoryProvider).streamTodaySessions(userId);
});


// Session state notifier for active session
class ActiveSessionNotifier extends Notifier<FocusSessionModel?> {
  late final FocusSessionRepository _repository;

  @override
  FocusSessionModel? build() {
    _repository = ref.watch(sessionRepositoryProvider);
    return null;
  }

  Future<void> startSession({
    required String userId,
    required int plannedDuration,
    required String sessionType,
  }) async {
    final now = DateTime.now();
    final dateString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final session = FocusSessionModel(
      sessionId: '', // Will be set by Firestore
      userId: userId,
      startTime: now,
      plannedDuration: plannedDuration,
      sessionType: sessionType,
      status: 'active',
      date: dateString,
    );

    try {
      final sessionId = await _repository.createSession(session);
      state = session.copyWith(sessionId: sessionId);
    } catch (e) {
      debugPrint('Error starting session: $e');
      rethrow;
    }
  }

  Future<void> completeSession(int actualDuration) async {
    if (state == null) return;

    try {
      await _repository.completeSession(
        sessionId: state!.sessionId,
        userId: state!.userId,
        actualDuration: actualDuration,
        date: state!.date,
      );

      state = null; // Clear active session
    } catch (e) {
      debugPrint('Error completing session: $e');
      rethrow;
    }
  }

  void cancelSession() {
    state = null;
  }
}

final activeSessionProvider = NotifierProvider<ActiveSessionNotifier, FocusSessionModel?>(() {
  return ActiveSessionNotifier();
});
