import 'package:cloud_firestore/cloud_firestore.dart';
import 'pomodoro_settings.dart';

class UserSettingsModel {
  final int defaultDuration;
  final String timerMode;
  final PomodoroSettings pomodoroSettings;
  final bool autoStartBreaks;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String theme;

  UserSettingsModel({
    required this.defaultDuration,
    required this.timerMode,
    required this.pomodoroSettings,
    required this.autoStartBreaks,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.theme,
  });

  factory UserSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserSettingsModel(
      defaultDuration: data['defaultDuration'] ?? 25,
      timerMode: data['timerMode'] ?? 'timer',
      pomodoroSettings: PomodoroSettings.fromMap(data['pomodoroSettings']),
      autoStartBreaks: data['autoStartBreaks'] ?? true,
      soundEnabled: data['soundEnabled'] ?? true,
      vibrationEnabled: data['vibrationEnabled'] ?? true,
      theme: data['theme'] ?? 'dark',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'defaultDuration': defaultDuration,
      'timerMode': timerMode,
      'pomodoroSettings': pomodoroSettings.toMap(),
      'autoStartBreaks': autoStartBreaks,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'theme': theme,
    };
  }
}
