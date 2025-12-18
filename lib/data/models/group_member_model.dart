import 'package:cloud_firestore/cloud_firestore.dart';

enum MemberRole { admin, moderator, member }
enum MemberStatus { active, pending, banned }

class GroupMemberModel {
  final String userId;
  final String groupId;
  final String displayName;
  final String? photoURL;
  final String email;
  
  // Role & Status
  final MemberRole role;
  final MemberStatus status;
  
  // Dates
  final DateTime joinedAt;
  final DateTime? approvedAt;
  
  // Stats (within this group)
  final int goalsCompleted;
  final int studyTime; // in minutes
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  
  // Permissions
  final bool canInvite;
  final bool canPostGoals;
  
  GroupMemberModel({
    required this.userId,
    required this.groupId,
    required this.displayName,
    this.photoURL,
    required this.email,
    this.role = MemberRole.member,
    this.status = MemberStatus.active,
    required this.joinedAt,
    this.approvedAt,
    this.goalsCompleted = 0,
    this.studyTime = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.canInvite = true,
    this.canPostGoals = true,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'groupId': groupId,
      'displayName': displayName,
      'photoURL': photoURL,
      'email': email,
      'role': role.name,
      'status': status.name,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'goalsCompleted': goalsCompleted,
      'studyTime': studyTime,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate != null 
          ? Timestamp.fromDate(lastActiveDate!) 
          : null,
      'canInvite': canInvite,
      'canPostGoals': canPostGoals,
    };
  }

  // Create from Firestore document
  factory GroupMemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return GroupMemberModel(
      userId: data['userId'] ?? '',
      groupId: data['groupId'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      email: data['email'] ?? '',
      role: _parseRole(data['role']),
      status: _parseStatus(data['status']),
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      goalsCompleted: data['goalsCompleted'] ?? 0,
      studyTime: data['studyTime'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastActiveDate: data['lastActiveDate'] != null
          ? (data['lastActiveDate'] as Timestamp).toDate()
          : null,
      canInvite: data['canInvite'] ?? true,
      canPostGoals: data['canPostGoals'] ?? true,
    );
  }

  // Create from Map
  factory GroupMemberModel.fromMap(Map<String, dynamic> data) {
    return GroupMemberModel(
      userId: data['userId'] ?? '',
      groupId: data['groupId'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      email: data['email'] ?? '',
      role: _parseRole(data['role']),
      status: _parseStatus(data['status']),
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      goalsCompleted: data['goalsCompleted'] ?? 0,
      studyTime: data['studyTime'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastActiveDate: data['lastActiveDate'] != null
          ? (data['lastActiveDate'] as Timestamp).toDate()
          : null,
      canInvite: data['canInvite'] ?? true,
      canPostGoals: data['canPostGoals'] ?? true,
    );
  }

  // Helper methods to parse enums
  static MemberRole _parseRole(dynamic roleStr) {
    if (roleStr == 'admin') return MemberRole.admin;
    if (roleStr == 'moderator') return MemberRole.moderator;
    return MemberRole.member;
  }

  static MemberStatus _parseStatus(dynamic statusStr) {
    if (statusStr == 'pending') return MemberStatus.pending;
    if (statusStr == 'banned') return MemberStatus.banned;
    return MemberStatus.active;
  }

  // Copy with
  GroupMemberModel copyWith({
    String? userId,
    String? groupId,
    String? displayName,
    String? photoURL,
    String? email,
    MemberRole? role,
    MemberStatus? status,
    DateTime? joinedAt,
    DateTime? approvedAt,
    int? goalsCompleted,
    int? studyTime,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    bool? canInvite,
    bool? canPostGoals,
  }) {
    return GroupMemberModel(
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      goalsCompleted: goalsCompleted ?? this.goalsCompleted,
      studyTime: studyTime ?? this.studyTime,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      canInvite: canInvite ?? this.canInvite,
      canPostGoals: canPostGoals ?? this.canPostGoals,
    );
  }

  // Check if user is admin or moderator
  bool get canManageGroup => role == MemberRole.admin || role == MemberRole.moderator;
  
  // Check if user is creator/admin
  bool get isAdmin => role == MemberRole.admin;
}
