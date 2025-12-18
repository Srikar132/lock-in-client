import 'package:cloud_firestore/cloud_firestore.dart';

class AppLimit {
  final String packageName;
  final int dailyLimitMinutes; // Time limit in minutes per day
  final int usedMinutesToday; // Time used today in minutes
  final bool isActive; // Can be toggled on/off

  AppLimit({
    required this.packageName,
    required this.dailyLimitMinutes,
    this.usedMinutesToday = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'dailyLimitMinutes': dailyLimitMinutes,
      'usedMinutesToday': usedMinutesToday,
      'isActive': isActive,
    };
  }

  factory AppLimit.fromMap(Map<String, dynamic> map) {
    return AppLimit(
      packageName: map['packageName'] ?? '',
      dailyLimitMinutes: map['dailyLimitMinutes'] ?? 30,
      usedMinutesToday: map['usedMinutesToday'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  // Calculate remaining time in minutes
  int get remainingMinutes {
    final remaining = dailyLimitMinutes - usedMinutesToday;
    return remaining > 0 ? remaining : 0;
  }

  // Check if limit has been exceeded
  bool get hasExceededLimit => usedMinutesToday >= dailyLimitMinutes;

  // Get usage percentage (0-100)
  int get usagePercentage {
    if (dailyLimitMinutes == 0) return 0;
    final percentage = (usedMinutesToday / dailyLimitMinutes * 100).round();
    return percentage.clamp(0, 100);
  }

  AppLimit copyWith({
    String? packageName,
    int? dailyLimitMinutes,
    int? usedMinutesToday,
    bool? isActive,
  }) {
    return AppLimit(
      packageName: packageName ?? this.packageName,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      usedMinutesToday: usedMinutesToday ?? this.usedMinutesToday,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'AppLimit(packageName: $packageName, dailyLimit: $dailyLimitMinutes min, used: $usedMinutesToday min, active: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppLimit &&
        other.packageName == packageName &&
        other.dailyLimitMinutes == dailyLimitMinutes &&
        other.usedMinutesToday == usedMinutesToday &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return packageName.hashCode ^
        dailyLimitMinutes.hashCode ^
        usedMinutesToday.hashCode ^
        isActive.hashCode;
  }
}

class BlockedWebsite {
  final String url;
  final String name;
  final bool isActive;

  BlockedWebsite({required this.url, required this.name, this.isActive = true});

  Map<String, dynamic> toMap() {
    return {'url': url, 'name': name, 'isActive': isActive};
  }

  factory BlockedWebsite.fromMap(Map<String, dynamic> map) {
    return BlockedWebsite(
      url: map['url'] ?? '',
      name: map['name'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  @override
  String toString() {
    return 'BlockedWebsite(url: $url, name: $name, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BlockedWebsite &&
        other.url == url &&
        other.name == name &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => url.hashCode ^ name.hashCode ^ isActive.hashCode;
}

class ShortFormBlock {
  final String platform; // 'youtube', 'instagram', 'snapchat', etc.
  final String feature; // 'shorts', 'reels', 'stories', etc.
  final bool isBlocked;

  ShortFormBlock({
    required this.platform,
    required this.feature,
    this.isBlocked = true,
  });

  Map<String, dynamic> toMap() {
    return {'platform': platform, 'feature': feature, 'isBlocked': isBlocked};
  }

  factory ShortFormBlock.fromMap(Map<String, dynamic> map) {
    return ShortFormBlock(
      platform: map['platform'] ?? '',
      feature: map['feature'] ?? '',
      isBlocked: map['isBlocked'] ?? true,
    );
  }

  @override
  String toString() {
    return 'ShortFormBlock(platform: $platform, feature: $feature, isBlocked: $isBlocked)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ShortFormBlock &&
        other.platform == platform &&
        other.feature == feature &&
        other.isBlocked == isBlocked;
  }

  @override
  int get hashCode => platform.hashCode ^ feature.hashCode ^ isBlocked.hashCode;
}

class BlockedContentModel {
  final Map<String, AppLimit> appLimits; // Key: packageName
  final List<BlockedWebsite> blockedWebsites;
  final Map<String, ShortFormBlock> shortFormBlocks; // Key: platform_feature
  final DateTime lastUpdated;

  BlockedContentModel({
    this.appLimits = const {},
    this.blockedWebsites = const [],
    this.shortFormBlocks = const {},
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'appLimits': appLimits.map((key, value) => MapEntry(key, value.toMap())),
      'blockedWebsites': blockedWebsites
          .map((website) => website.toMap())
          .toList(),
      'shortFormBlocks': shortFormBlocks.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // Create from Firestore document
  factory BlockedContentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    print('📋 Parsing BlockedContentModel from Firestore:');
    print('   - Document ID: ${doc.id}');
    print('   - Raw data keys: ${data.keys.toList()}');

    // Parse appLimits
    final parsedAppLimits = data['appLimits'] != null
        ? (data['appLimits'] as Map<String, dynamic>).map(
            (key, value) =>
                MapEntry(key, AppLimit.fromMap(value as Map<String, dynamic>)),
          )
        : <String, AppLimit>{};
    print('   - Parsed ${parsedAppLimits.length} app limits');

    // Parse blockedWebsites
    final parsedWebsites = data['blockedWebsites'] != null
        ? (data['blockedWebsites'] as List)
              .map(
                (website) =>
                    BlockedWebsite.fromMap(website as Map<String, dynamic>),
              )
              .toList()
        : <BlockedWebsite>[];
    print('   - Parsed ${parsedWebsites.length} blocked websites');

    // Parse shortFormBlocks with detailed logging
    Map<String, ShortFormBlock> parsedShortFormBlocks = {};

    // First, always check for flattened shortFormBlocks.* fields
    final flattenedBlocks = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.key.startsWith('shortFormBlocks.')) {
        final blockKey = entry.key.substring('shortFormBlocks.'.length);
        flattenedBlocks[blockKey] = entry.value;
        print('     * Found flattened field: ${entry.key} -> $blockKey');
      }
    }

    if (flattenedBlocks.isNotEmpty) {
      // Use flattened structure (current storage format)
      print(
        '   - Found ${flattenedBlocks.length} flattened short form blocks: ${flattenedBlocks.keys.toList()}',
      );

      parsedShortFormBlocks = flattenedBlocks.map((key, value) {
        final blockValue = value as Map<String, dynamic>;
        final block = ShortFormBlock.fromMap(blockValue);
        print('     * Parsed flattened $key: $block');
        return MapEntry(key, block);
      });
    } else if (data['shortFormBlocks'] != null) {
      // Fallback to nested structure (legacy format)
      final rawShortFormBlocks =
          data['shortFormBlocks'] as Map<String, dynamic>;
      print(
        '   - No flattened fields found, using nested shortFormBlocks: $rawShortFormBlocks',
      );

      if (rawShortFormBlocks.isNotEmpty) {
        parsedShortFormBlocks = rawShortFormBlocks.map((key, value) {
          final blockValue = value as Map<String, dynamic>;
          final block = ShortFormBlock.fromMap(blockValue);
          print('     * Parsed nested $key: $block');
          return MapEntry(key, block);
        });
      } else {
        print('   - Nested shortFormBlocks field is empty');
      }
    } else {
      print(
        '   - ❌ No shortFormBlocks data found (neither flattened nor nested)',
      );
    }
    print(
      '   - Final parsed ${parsedShortFormBlocks.length} short form blocks: ${parsedShortFormBlocks.keys.toList()}',
    );

    final result = BlockedContentModel(
      appLimits: parsedAppLimits,
      blockedWebsites: parsedWebsites,
      shortFormBlocks: parsedShortFormBlocks,
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );

    print('   - ✅ Final parsed model: ${result.shortFormBlocks}');
    return result;
  }

  // Create from Map
  factory BlockedContentModel.fromMap(Map<String, dynamic> data) {
    return BlockedContentModel(
      appLimits: data['appLimits'] != null
          ? (data['appLimits'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                AppLimit.fromMap(value as Map<String, dynamic>),
              ),
            )
          : {},
      blockedWebsites: data['blockedWebsites'] != null
          ? (data['blockedWebsites'] as List)
                .map(
                  (website) =>
                      BlockedWebsite.fromMap(website as Map<String, dynamic>),
                )
                .toList()
          : [],
      shortFormBlocks: data['shortFormBlocks'] != null
          ? (data['shortFormBlocks'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                ShortFormBlock.fromMap(value as Map<String, dynamic>),
              ),
            )
          : {},
      lastUpdated: data['lastUpdated'] is Timestamp
          ? (data['lastUpdated'] as Timestamp).toDate()
          : data['lastUpdated'] is DateTime
          ? data['lastUpdated']
          : DateTime.now(),
    );
  }

  // Create a copy with updated values
  BlockedContentModel copyWith({
    Map<String, AppLimit>? appLimits,
    List<BlockedWebsite>? blockedWebsites,
    Map<String, ShortFormBlock>? shortFormBlocks,
    DateTime? lastUpdated,
  }) {
    return BlockedContentModel(
      appLimits: appLimits ?? this.appLimits,
      blockedWebsites: blockedWebsites ?? this.blockedWebsites,
      shortFormBlocks: shortFormBlocks ?? this.shortFormBlocks,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Helper methods
  bool hasAppLimit(String packageName) {
    return appLimits.containsKey(packageName);
  }

  bool isAppLimitExceeded(String packageName) {
    final limit = appLimits[packageName];
    if (limit == null || !limit.isActive) return false;
    return limit.hasExceededLimit;
  }

  AppLimit? getAppLimit(String packageName) {
    return appLimits[packageName];
  }

  bool isWebsiteBlocked(String url) {
    return blockedWebsites.any(
      (website) => website.isActive && website.url.contains(url),
    );
  }

  bool isShortFormBlocked(String platform, String feature) {
    final key = '${platform}_$feature';
    return shortFormBlocks[key]?.isBlocked ?? false;
  }

  @override
  String toString() {
    return 'BlockedContentModel(appLimits: $appLimits, blockedWebsites: $blockedWebsites, shortFormBlocks: $shortFormBlocks, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BlockedContentModel &&
        other.appLimits.length == appLimits.length &&
        other.blockedWebsites.length == blockedWebsites.length &&
        other.shortFormBlocks.length == shortFormBlocks.length &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return appLimits.hashCode ^
        blockedWebsites.hashCode ^
        shortFormBlocks.hashCode ^
        lastUpdated.hashCode;
  }
}
