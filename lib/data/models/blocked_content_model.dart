import 'package:cloud_firestore/cloud_firestore.dart';

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
  final List<String> permanentlyBlockedApps;
  final List<BlockedWebsite> blockedWebsites;
  final Map<String, ShortFormBlock> shortFormBlocks; // Key: platform_feature
  final DateTime lastUpdated;

  BlockedContentModel({
    this.permanentlyBlockedApps = const [],
    this.blockedWebsites = const [],
    this.shortFormBlocks = const {},
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'permanentlyBlockedApps': permanentlyBlockedApps,
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

    return BlockedContentModel(
      permanentlyBlockedApps: data['permanentlyBlockedApps'] != null
          ? List<String>.from(data['permanentlyBlockedApps'])
          : [],
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
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create from Map
  factory BlockedContentModel.fromMap(Map<String, dynamic> data) {
    return BlockedContentModel(
      permanentlyBlockedApps: data['permanentlyBlockedApps'] != null
          ? List<String>.from(data['permanentlyBlockedApps'])
          : [],
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
    List<String>? permanentlyBlockedApps,
    List<BlockedWebsite>? blockedWebsites,
    Map<String, ShortFormBlock>? shortFormBlocks,
    DateTime? lastUpdated,
  }) {
    return BlockedContentModel(
      permanentlyBlockedApps:
          permanentlyBlockedApps ?? this.permanentlyBlockedApps,
      blockedWebsites: blockedWebsites ?? this.blockedWebsites,
      shortFormBlocks: shortFormBlocks ?? this.shortFormBlocks,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Helper methods
  bool isAppBlocked(String packageName) {
    return permanentlyBlockedApps.contains(packageName);
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

  // Get all blocked app count
  int get blockedAppsCount => permanentlyBlockedApps.length;

  // Get all blocked websites count
  int get blockedWebsitesCount =>
      blockedWebsites.where((w) => w.isActive).length;

  // Get all blocked short forms count
  int get blockedShortFormsCount =>
      shortFormBlocks.values.where((b) => b.isBlocked).length;

  @override
  String toString() {
    return 'BlockedContentModel(permanentlyBlockedApps: $permanentlyBlockedApps, blockedWebsites: $blockedWebsites, shortFormBlocks: $shortFormBlocks, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BlockedContentModel &&
        other.permanentlyBlockedApps.length == permanentlyBlockedApps.length &&
        other.blockedWebsites.length == blockedWebsites.length &&
        other.shortFormBlocks.length == shortFormBlocks.length &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return permanentlyBlockedApps.hashCode ^
        blockedWebsites.hashCode ^
        shortFormBlocks.hashCode ^
        lastUpdated.hashCode;
  }
}