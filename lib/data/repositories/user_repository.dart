import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:lock_in/data/models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Update user onboarding status
  Future<void> updateOnboardingStatus(String uid, bool completed) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'hasCompletedOnboarding': completed,
      });
    } catch (e) {
      debugPrint('Error updating onboarding status: $e');
      rethrow;
    }
  }

  // Update permission status
  Future<void> updatePermissionStatus(String uid, bool granted) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'hasGrantedPermissions': granted,
      });
    } catch (e) {
      debugPrint('Error updating permission status: $e');
      rethrow;
    }
  }

  // Update onboarding answers
  Future<void> updateOnboardingAnswers({
    required String uid,
    String? procrastinationLevel,
    List<String>? distractions,
    String? preferredStudyTime,
  }) async {
    try {
      final defaultSettings = {
        'hasCompletedOnboarding': true,
        'focusSettings': {
          'defaultDuration': 25, // in minutes (default: 25)
          'timerMode': 'timer', // "timer" | "stopwatch" | "pomodoro"
          'pomodoroSettings': {
            'workDuration': 25, // 25 min
            'shortBreak': 5, // 5 min
            'longBreak': 15, // 15 min
            'sessionsBeforeLongBreak': 4,
          },
          'autoStartBreaks': true,
          'soundEnabled': true,
          'vibrationEnabled': true,
        },
        'stats': {
          "totalFocusTime": 0, // milliseconds
          "totalSessions": 0,
          "currentStreak": 0,
          "longestStreak": 0,
          "lastActiveDate": FieldValue.serverTimestamp(),
          "todayScreenTime": 0,
          "todayFocusTime": 0,
        },
      };

      if (procrastinationLevel != null) {
        defaultSettings['procrastinationLevel'] = procrastinationLevel;
      }
      if (distractions != null) {
        defaultSettings['distractions'] = distractions;
      }

      if (procrastinationLevel != null) {
        defaultSettings['procrastinationLevel'] = procrastinationLevel;
      }
      if (distractions != null) {
        defaultSettings['distractions'] = distractions;
      }
      if (preferredStudyTime != null) {
        defaultSettings['preferredStudyTime'] = preferredStudyTime;
      }

      await _firestore.collection('users').doc(uid).update(defaultSettings);
    } catch (e) {
      debugPrint('Error updating onboarding answers: $e');
      rethrow;
    }
  }

  // Stream user data
  Stream<UserModel?> streamUserData(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<void> updateUserStatsAfterSession({
    required String userId,
    required int sessionDurationMinutes, // e.g., 25
    required int todayDurationMinutes, // Tracked locally
  }) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    // Convert minutes to milliseconds if your schema uses ms, or keep as minutes
    final sessionTimeToAdd = sessionDurationMinutes;

    try {
      await userRef.update({
        // 1. ATOMIC INCREMENTS (Safe & Fast)
        // This adds to the existing value, it doesn't overwrite it.
        'stats.totalFocusTime': FieldValue.increment(sessionTimeToAdd),
        'stats.totalSessions': FieldValue.increment(1),

        // 2. SIMPLE UPDATES
        'stats.lastActiveDate': FieldValue.serverTimestamp(),

        // 3. UPDATING "TODAY" STATS
        // Note: "Today" logic is tricky in DBs.
        // It's usually better to just set the new calculated value from the client
        // or handle the reset logic separately.
        'stats.todayFocusTime': FieldValue.increment(sessionTimeToAdd),
      });

      debugPrint("User stats updated successfully!");
    } catch (e) {
      debugPrint("Error updating stats: $e");
    }
  }

  Future<void> updateAppLimit(
    String userId,
    String packageName,
    int limitMinutes,
  ) async {
    // 1. Sanitize package name for Firestore keys (cannot contain dots if used directly,
    // but usually fine in map values. If used as a key, replace '.' with '_')
    try {
      final safeKey = packageName.replaceAll('.', '_');

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        // Update specifically the entry for this app inside the 'appLimits' map
        'appLimits.$safeKey': {
          'dailyLimit': limitMinutes,
          'actionOnExceed': 'block',
          'isActive': true,
        },
      });
    } catch (e) {
      debugPrint('Error updating app limit: $e');
      rethrow;
    }
  }
}
