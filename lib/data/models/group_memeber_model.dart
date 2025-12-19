import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a member within a group
class GroupMemberModel {
  final String userId;
  final String groupId;
  final String displayName;
  final String? photoUrl;
  final int focusTime; // Total focus time in minutes
  final DateTime joinedAt;
  final bool isAdmin;
  final int rank; // Position in leaderboard (1 = first place)

  const GroupMemberModel({
    required this.userId,
    required this.groupId,
    required this.displayName,
    this.photoUrl,
    this.focusTime = 0,
    required this.joinedAt,
    this.isAdmin = false,
    this.rank = 0,
  });

  /// Convert GroupMemberModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'groupId': groupId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'focusTime': focusTime,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isAdmin': isAdmin,
      'rank': rank,
    };
  }

  /// Create GroupMemberModel from Firestore document
  factory GroupMemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GroupMemberModel(
      userId: data['userId'] ?? '',
      groupId: data['groupId'] ?? '',
      displayName: data['displayName'] ?? 'Unknown',
      photoUrl: data['photoUrl'],
      focusTime: data['focusTime'] ?? 0,
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      isAdmin: data['isAdmin'] ?? false,
      rank: data['rank'] ?? 0,
    );
  }

  /// Get formatted focus time for display
  String getFormattedFocusTime() {
    if (focusTime < 60) return '${focusTime}m';
    final hours = focusTime ~/ 60;
    final minutes = focusTime % 60;
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }

  /// Create a copy with updated fields
  GroupMemberModel copyWith({
    String? userId,
    String? groupId,
    String? displayName,
    String? photoUrl,
    int? focusTime,
    DateTime? joinedAt,
    bool? isAdmin,
    int? rank,
  }) {
    return GroupMemberModel(
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      focusTime: focusTime ?? this.focusTime,
      joinedAt: joinedAt ?? this.joinedAt,
      isAdmin: isAdmin ?? this.isAdmin,
      rank: rank ?? this.rank,
    );
  }

  /// Get medal emoji for top 3 ranks
  String? getMedalEmoji() {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return null;
    }
  }
}