class PomodoroSettings {
  final int workDuration; // minutes
  final int shortBreak; // minutes
  final int longBreak; // minutes
  final int sessionsBeforeLongBreak;

  PomodoroSettings({
    required this.workDuration,
    required this.shortBreak,
    required this.longBreak,
    required this.sessionsBeforeLongBreak,
  });

  // Default settings
  factory PomodoroSettings.defaultSettings() {
    return PomodoroSettings(
      workDuration: 25,
      shortBreak: 5,
      longBreak: 15,
      sessionsBeforeLongBreak: 4,
    );
  }

  // From Firestore map
  factory PomodoroSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return PomodoroSettings.defaultSettings();
    
    return PomodoroSettings(
      workDuration: map['workDuration'] ?? 25,
      shortBreak: map['shortBreak'] ?? 5,
      longBreak: map['longBreak'] ?? 15,
      sessionsBeforeLongBreak: map['sessionsBeforeLongBreak'] ?? 4,
    );
  }

  // To Firestore map
  Map<String, dynamic> toMap() {
    return {
      'workDuration': workDuration,
      'shortBreak': shortBreak,
      'longBreak': longBreak,
      'sessionsBeforeLongBreak': sessionsBeforeLongBreak,
    };
  }

  // Copy with
  PomodoroSettings copyWith({
    int? workDuration,
    int? shortBreak,
    int? longBreak,
    int? sessionsBeforeLongBreak,
  }) {
    return PomodoroSettings(
      workDuration: workDuration ?? this.workDuration,
      shortBreak: shortBreak ?? this.shortBreak,
      longBreak: longBreak ?? this.longBreak,
      sessionsBeforeLongBreak: sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
    );
  }

  @override
  String toString() {
    return 'PomodoroSettings(work: $workDuration min, short: $shortBreak min, long: $longBreak min, cycles: $sessionsBeforeLongBreak)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PomodoroSettings &&
        other.workDuration == workDuration &&
        other.shortBreak == shortBreak &&
        other.longBreak == longBreak &&
        other.sessionsBeforeLongBreak == sessionsBeforeLongBreak;
  }

  @override
  int get hashCode {
    return Object.hash(
      workDuration,
      shortBreak,
      longBreak,
      sessionsBeforeLongBreak,
    );
  }
}