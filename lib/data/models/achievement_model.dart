import 'package:cloud_firestore/cloud_firestore.dart';

enum AchievementType { timeSaved, timeFocused, inviteFriends }

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final int targetValue;
  final String icon;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.icon,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString(),
      'targetValue': targetValue,
      'icon': icon,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
    };
  }

  factory AchievementModel.fromFirestore(Map<String, dynamic> data) {
    return AchievementModel(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: AchievementType.values.firstWhere(
            (e) => e.toString() == data['type'],
        orElse: () => AchievementType.timeFocused,
      ),
      targetValue: data['targetValue'] ?? 0,
      icon: data['icon'] ?? '🏆',
      isUnlocked: data['isUnlocked'] ?? false,
      unlockedAt: data['unlockedAt'] != null
          ? (data['unlockedAt'] as Timestamp).toDate()
          : null,
    );
  }

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    AchievementType? type,
    int? targetValue,
    String? icon,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      icon: icon ?? this.icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  // Predefined achievements
  static List<AchievementModel> getDefaultAchievements() {
    return [
      const AchievementModel(
        id: 'saved_1h',
        title: '#SAVED',
        description: '0m / 1h saved',
        type: AchievementType.timeSaved,
        targetValue: 60, // minutes
        icon: '💾',
      ),
      const AchievementModel(
        id: 'focus_2m',
        title: '#FOCUS',
        description: '2m / 1h focused',
        type: AchievementType.timeFocused,
        targetValue: 60, // minutes
        icon: '🎯',
      ),
      const AchievementModel(
        id: 'invite_1',
        title: '0 / 1 invited',
        description: 'Invite 1 friend',
        type: AchievementType.inviteFriends,
        targetValue: 1,
        icon: '👥',
      ),
    ];
  }
}