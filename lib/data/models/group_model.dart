import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a focus group with members and settings
class GroupModel {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final List<String> memberIds;
  final List<String> adminIds;
  final String? imageUrl;
  final DateTime createdAt;
  final int totalFocusTime; // Combined focus time of all members (minutes)
  final Map<String, int> memberFocusTime; // Per member focus tracking
  final GroupSettings settings;

  const GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.memberIds,
    required this.adminIds,
    this.imageUrl,
    required this.createdAt,
    this.totalFocusTime = 0,
    this.memberFocusTime = const {},
    required this.settings,
  });

  /// Convert GroupModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'totalFocusTime': totalFocusTime,
      'memberFocusTime': memberFocusTime,
      'settings': settings.toMap(),
    };
  }

  /// Create GroupModel from Firestore document
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      creatorId: data['creatorId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      adminIds: List<String>.from(data['adminIds'] ?? []),
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      totalFocusTime: data['totalFocusTime'] ?? 0,
      memberFocusTime: Map<String, int>.from(data['memberFocusTime'] ?? {}),
      settings: GroupSettings.fromMap(data['settings'] ?? {}),
    );
  }

  /// Create a copy with updated fields
  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    List<String>? memberIds,
    List<String>? adminIds,
    String? imageUrl,
    DateTime? createdAt,
    int? totalFocusTime,
    Map<String, int>? memberFocusTime,
    GroupSettings? settings,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      totalFocusTime: totalFocusTime ?? this.totalFocusTime,
      memberFocusTime: memberFocusTime ?? this.memberFocusTime,
      settings: settings ?? this.settings,
    );
  }

  /// Check if user is a member of this group
  bool isMember(String userId) => memberIds.contains(userId);

  /// Check if user is an admin of this group
  bool isAdmin(String userId) => adminIds.contains(userId);

  /// Check if user is the creator of this group
  bool isCreator(String userId) => creatorId == userId;

  /// Get formatted focus time (e.g., "2h 30m" or "45m")
  String getFormattedFocusTime() {
    if (totalFocusTime < 60) return '${totalFocusTime}m';
    final hours = totalFocusTime ~/ 60;
    final minutes = totalFocusTime % 60;
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }
}

/// Settings for a group
class GroupSettings {
  final bool isPublic;
  final bool allowMemberInvites;
  final int focusGoalMinutes;
  final bool showLeaderboard;

  const GroupSettings({
    this.isPublic = false,
    this.allowMemberInvites = true,
    this.focusGoalMinutes = 0,
    this.showLeaderboard = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'isPublic': isPublic,
      'allowMemberInvites': allowMemberInvites,
      'focusGoalMinutes': focusGoalMinutes,
      'showLeaderboard': showLeaderboard,
    };
  }

  factory GroupSettings.fromMap(Map<String, dynamic> map) {
    return GroupSettings(
      isPublic: map['isPublic'] ?? false,
      allowMemberInvites: map['allowMemberInvites'] ?? true,
      focusGoalMinutes: map['focusGoalMinutes'] ?? 0,
      showLeaderboard: map['showLeaderboard'] ?? true,
    );
  }

  GroupSettings copyWith({
    bool? isPublic,
    bool? allowMemberInvites,
    int? focusGoalMinutes,
    bool? showLeaderboard,
  }) {
    return GroupSettings(
      isPublic: isPublic ?? this.isPublic,
      allowMemberInvites: allowMemberInvites ?? this.allowMemberInvites,
      focusGoalMinutes: focusGoalMinutes ?? this.focusGoalMinutes,
      showLeaderboard: showLeaderboard ?? this.showLeaderboard,
    );
  }
}