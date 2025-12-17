/// Data model representing an installed app on the device.
class InstalledApp {
  /// Display name of the app
  final String appName;

  /// Unique package name (e.g., com.example.app)
  final String packageName;

  /// Version name of the app (e.g., "1.0.0")
  final String versionName;

  /// Timestamp when the app was first installed
  final int installTime;

  /// Timestamp when the app was last updated
  final int updateTime;

  /// Whether this is a system app
  final bool isSystemApp;

  /// App category (e.g., "Social", "Games", "Productivity")
  final String category;

  /// Whether the app can be launched (has a launcher activity)
  final bool canLaunch;

  InstalledApp({
    required this.appName,
    required this.packageName,
    required this.versionName,
    required this.installTime,
    required this.updateTime,
    required this.isSystemApp,
    required this.category,
    required this.canLaunch,
  });

  /// Create an [InstalledApp] from a map received from native code
  factory InstalledApp.fromMap(Map<String, dynamic> map) {
    return InstalledApp(
      appName: map['appName'] as String? ?? 'Unknown',
      packageName: map['packageName'] as String? ?? '',
      versionName: map['versionName'] as String? ?? 'Unknown',
      installTime: map['installTime'] as int? ?? 0,
      updateTime: map['updateTime'] as int? ?? 0,
      isSystemApp: map['isSystemApp'] as bool? ?? false,
      category: map['category'] as String? ?? 'Other',
      canLaunch: map['canLaunch'] as bool? ?? false,
    );
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'packageName': packageName,
      'versionName': versionName,
      'installTime': installTime,
      'updateTime': updateTime,
      'isSystemApp': isSystemApp,
      'category': category,
      'canLaunch': canLaunch,
    };
  }

  /// Get install date as DateTime
  DateTime get installDate => DateTime.fromMillisecondsSinceEpoch(installTime);

  /// Get update date as DateTime
  DateTime get updateDate => DateTime.fromMillisecondsSinceEpoch(updateTime);

  @override
  String toString() {
    return 'InstalledApp(appName: $appName, packageName: $packageName, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is InstalledApp && other.packageName == packageName;
  }

  @override
  int get hashCode => packageName.hashCode;
}

/// Extension methods for working with lists of installed apps
extension InstalledAppListExtensions on List<InstalledApp> {
  /// Filter apps by category
  List<InstalledApp> byCategory(String category) {
    return where((app) => app.category == category).toList();
  }

  /// Get only user-installed apps (exclude system apps)
  List<InstalledApp> get userAppsOnly {
    return where((app) => !app.isSystemApp).toList();
  }

  /// Get only launchable apps
  List<InstalledApp> get launchableOnly {
    return where((app) => app.canLaunch).toList();
  }

  /// Get all unique categories
  List<String> get allCategories {
    return map((app) => app.category).toSet().toList()..sort();
  }

  /// Group apps by category
  Map<String, List<InstalledApp>> groupByCategory() {
    final Map<String, List<InstalledApp>> grouped = {};
    for (final app in this) {
      grouped.putIfAbsent(app.category, () => []).add(app);
    }
    return grouped;
  }
}