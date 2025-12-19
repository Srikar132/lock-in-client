import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for parental control settings
class ParentalControl {
  final String userId;
  final bool isEnabled;
  final String? passwordHash;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> blockedApps;
  final List<String> blockedWebsites;
  final bool blockYoutubeShorts;
  final bool blockInstagramReels;
  final bool blockWebsites;
  final bool blockAppCategories;

  ParentalControl({
    required this.userId,
    required this.isEnabled,
    this.passwordHash,
    this.createdAt,
    this.updatedAt,
    this.blockedApps = const [],
    this.blockedWebsites = const [],
    this.blockYoutubeShorts = false,
    this.blockInstagramReels = false,
    this.blockWebsites = false,
    this.blockAppCategories = false,
  });

  factory ParentalControl.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      return ParentalControl.empty(doc.id);
    }

    return ParentalControl(
      userId: doc.id,
      isEnabled: data['isEnabled'] ?? false,
      passwordHash: data['passwordHash'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      blockedApps: List<String>.from(data['blockedApps'] ?? []),
      blockedWebsites: List<String>.from(data['blockedWebsites'] ?? []),
      blockYoutubeShorts: data['blockYoutubeShorts'] ?? false,
      blockInstagramReels: data['blockInstagramReels'] ?? false,
      blockWebsites: data['blockWebsites'] ?? false,
      blockAppCategories: data['blockAppCategories'] ?? false,
    );
  }

  factory ParentalControl.empty(String userId) {
    return ParentalControl(userId: userId, isEnabled: false);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isEnabled': isEnabled,
      'passwordHash': passwordHash,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': Timestamp.now(),
      'blockedApps': blockedApps,
      'blockedWebsites': blockedWebsites,
      'blockYoutubeShorts': blockYoutubeShorts,
      'blockInstagramReels': blockInstagramReels,
      'blockWebsites': blockWebsites,
      'blockAppCategories': blockAppCategories,
    };
  }

  ParentalControl copyWith({
    bool? isEnabled,
    String? passwordHash,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? blockedApps,
    List<String>? blockedWebsites,
    bool? blockYoutubeShorts,
    bool? blockInstagramReels,
    bool? blockWebsites,
    bool? blockAppCategories,
  }) {
    return ParentalControl(
      userId: userId,
      isEnabled: isEnabled ?? this.isEnabled,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      blockedApps: blockedApps ?? this.blockedApps,
      blockedWebsites: blockedWebsites ?? this.blockedWebsites,
      blockYoutubeShorts: blockYoutubeShorts ?? this.blockYoutubeShorts,
      blockInstagramReels: blockInstagramReels ?? this.blockInstagramReels,
      blockWebsites: blockWebsites ?? this.blockWebsites,
      blockAppCategories: blockAppCategories ?? this.blockAppCategories,
    );
  }
}
