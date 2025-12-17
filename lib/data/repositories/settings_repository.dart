

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:lock_in/data/models/pomodoro_settings.dart';
import 'package:lock_in/data/models/user_settings_model.dart';

class SettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

   // Cache settings in memory after first load
  UserSettingsModel? _cachedSettings;
  String? _cachedUserId;

  // Stream with automatic caching
  Stream<UserSettingsModel?> streamSettings(String userId) {
    return _firestore
        .collection('userSettings')
        .doc(userId)
        .snapshots(includeMetadataChanges: true) // Important for offline!
        .map((doc) {
          if (!doc.exists) return null;
          
          // Cache in memory
          final settings = UserSettingsModel.fromFirestore(doc);
          _cachedSettings = settings;
          _cachedUserId = userId;
          
          return settings;
        });
  }


  // Get cached settings instantly (for UI)
  UserSettingsModel? getCachedSettings(String userId) {
    if (_cachedUserId == userId) {
      return _cachedSettings;
    }
    return null;
  }


   // Update settings (works offline!)
  Future<void> updateSettings(String userId, UserSettingsModel settings) async {
    try {
      await _firestore
          .collection('userSettings')
          .doc(userId)
          .set(settings.toFirestore(), SetOptions(merge: true));
      
      // Update cache immediately
      _cachedSettings = settings;
      _cachedUserId = userId;
    } catch (e) {
      debugPrint('Error updating settings: $e');
      rethrow;
    }
  }


  // Initialize default settings (only once)
  Future<void> initializeDefaultSettings(String userId) async {
    final doc = await _firestore.collection('userSettings').doc(userId).get();
    
    if (!doc.exists) {
      final defaultSettings = UserSettingsModel(
        defaultDuration: 25,
        timerMode: 'timer',
        pomodoroSettings: PomodoroSettings.defaultSettings(),
        autoStartBreaks: true,
        soundEnabled: true,
        vibrationEnabled: true,
        theme: 'dark',
      );
      
      await _firestore
          .collection('userSettings')
          .doc(userId)
          .set(defaultSettings.toFirestore());
    }
  }

}