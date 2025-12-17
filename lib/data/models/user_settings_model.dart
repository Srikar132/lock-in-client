import 'package:cloud_firestore/cloud_firestore.dart';
import 'pomodoro_settings.dart';

class UserSettingsModel {
  final int defaultDuration; // in minutes (e.g., 25 for timer)
  final String timerMode; // 'timer', 'stopwatch', 'pomodoro'
  final PomodoroSettings pomodoroSettings;
  final int numberOfBreaks; // Number of breaks during session
  final bool blockPhoneHomeScreen; // Block access to home screen
  final bool strictMode; // Prevent ending session early
  final bool autoStartBreaks;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String theme;

  UserSettingsModel({
    required this.defaultDuration,
    required this.timerMode,
    required this.pomodoroSettings,
    required this.numberOfBreaks,
    required this.blockPhoneHomeScreen,
    required this.strictMode,
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
      numberOfBreaks: data['numberOfBreaks'] ?? 1,
      blockPhoneHomeScreen: data['blockPhoneHomeScreen'] ?? false,
      strictMode: data['strictMode'] ?? false,
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
      'numberOfBreaks': numberOfBreaks,
      'blockPhoneHomeScreen': blockPhoneHomeScreen,
      'strictMode': strictMode,
      'autoStartBreaks': autoStartBreaks,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'theme': theme,
    };
  }

  // Convenience method to copy with changes
  UserSettingsModel copyWith({
    int? defaultDuration,
    String? timerMode,
    PomodoroSettings? pomodoroSettings,
    int? numberOfBreaks,
    bool? blockPhoneHomeScreen,
    bool? strictMode,
    bool? autoStartBreaks,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? theme,
  }) {
    return UserSettingsModel(
      defaultDuration: defaultDuration ?? this.defaultDuration,
      timerMode: timerMode ?? this.timerMode,
      pomodoroSettings: pomodoroSettings ?? this.pomodoroSettings,
      numberOfBreaks: numberOfBreaks ?? this.numberOfBreaks,
      blockPhoneHomeScreen: blockPhoneHomeScreen ?? this.blockPhoneHomeScreen,
      strictMode: strictMode ?? this.strictMode,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      theme: theme ?? this.theme,
    );
  }
}