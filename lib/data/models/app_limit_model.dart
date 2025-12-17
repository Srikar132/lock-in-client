import 'package:cloud_firestore/cloud_firestore.dart';

class AppLimitModel {
  final String packageName;
  final String appName;
  final int dailyLimit; // in minutes
  final int weeklyLimit; // in minutes
  final bool isActive;
  final String actionOnExceed; // 'block', 'warn', 'redirect'

  AppLimitModel({
    required this.packageName,
    required this.appName,
    required this.dailyLimit,
    required this.weeklyLimit,
    this.isActive = true,
    this.actionOnExceed = 'warn',
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'packageName': packageName,
      'appName': appName,
      'dailyLimit': dailyLimit,
      'weeklyLimit': weeklyLimit,
      'isActive': isActive,
      'actionOnExceed': actionOnExceed,
    };
  }

  // Create from Firestore document
  factory AppLimitModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AppLimitModel(
      packageName: data['packageName'] ?? '',
      appName: data['appName'] ?? '',
      dailyLimit: data['dailyLimit'] ?? 0,
      weeklyLimit: data['weeklyLimit'] ?? 0,
      isActive: data['isActive'] ?? true,
      actionOnExceed: data['actionOnExceed'] ?? 'warn',
    );
  }

  // Create from Map (for subcollection queries)
  factory AppLimitModel.fromMap(Map<String, dynamic> data) {
    return AppLimitModel(
      packageName: data['packageName'] ?? '',
      appName: data['appName'] ?? '',
      dailyLimit: data['dailyLimit'] ?? 0,
      weeklyLimit: data['weeklyLimit'] ?? 0,
      isActive: data['isActive'] ?? true,
      actionOnExceed: data['actionOnExceed'] ?? 'warn',
    );
  }

  // Create a copy with updated values
  AppLimitModel copyWith({
    String? packageName,
    String? appName,
    int? dailyLimit,
    int? weeklyLimit,
    bool? isActive,
    String? actionOnExceed,
  }) {
    return AppLimitModel(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      weeklyLimit: weeklyLimit ?? this.weeklyLimit,
      isActive: isActive ?? this.isActive,
      actionOnExceed: actionOnExceed ?? this.actionOnExceed,
    );
  }

  @override
  String toString() {
    return 'AppLimitModel(packageName: $packageName, appName: $appName, dailyLimit: $dailyLimit, weeklyLimit: $weeklyLimit, isActive: $isActive, actionOnExceed: $actionOnExceed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppLimitModel &&
        other.packageName == packageName &&
        other.appName == appName &&
        other.dailyLimit == dailyLimit &&
        other.weeklyLimit == weeklyLimit &&
        other.isActive == isActive &&
        other.actionOnExceed == actionOnExceed;
  }

  @override
  int get hashCode {
    return packageName.hashCode ^
        appName.hashCode ^
        dailyLimit.hashCode ^
        weeklyLimit.hashCode ^
        isActive.hashCode ^
        actionOnExceed.hashCode;
  }
}
