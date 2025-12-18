import 'package:cloud_firestore/cloud_firestore.dart';

enum GoalType { daily, weekly, monthly, custom }
enum GoalStatus { pending, inProgress, completed, failed }

class GroupGoalModel {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final String createdBy; // userId
  final String createdByName;
  
  // Goal details
  final GoalType type;
  final GoalStatus status;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime endDate;
  
  // Target
  final int targetMinutes; // For study time goals
  final int targetSessions; // For session count goals
  
  // Progress
  final int completedMinutes;
  final int completedSessions;
  final List<String> completedByUserIds; // List of user IDs who completed this
  
  // Shared goal settings
  final bool isShared; // If true, all members work on same goal
  final bool isCompetitive; // If true, members compete on leaderboard
  
  GroupGoalModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdByName,
    this.type = GoalType.daily,
    this.status = GoalStatus.pending,
    required this.createdAt,
    required this.startDate,
    required this.endDate,
    this.targetMinutes = 0,
    this.targetSessions = 0,
    this.completedMinutes = 0,
    this.completedSessions = 0,
    this.completedByUserIds = const [],
    this.isShared = true,
    this.isCompetitive = false,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'type': type.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'targetMinutes': targetMinutes,
      'targetSessions': targetSessions,
      'completedMinutes': completedMinutes,
      'completedSessions': completedSessions,
      'completedByUserIds': completedByUserIds,
      'isShared': isShared,
      'isCompetitive': isCompetitive,
    };
  }

  // Create from Firestore document
  factory GroupGoalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return GroupGoalModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      type: _parseType(data['type']),
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetMinutes: data['targetMinutes'] ?? 0,
      targetSessions: data['targetSessions'] ?? 0,
      completedMinutes: data['completedMinutes'] ?? 0,
      completedSessions: data['completedSessions'] ?? 0,
      completedByUserIds: data['completedByUserIds'] != null 
          ? List<String>.from(data['completedByUserIds']) 
          : [],
      isShared: data['isShared'] ?? true,
      isCompetitive: data['isCompetitive'] ?? false,
    );
  }

  // Create from Map
  factory GroupGoalModel.fromMap(Map<String, dynamic> data, String id) {
    return GroupGoalModel(
      id: id,
      groupId: data['groupId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      type: _parseType(data['type']),
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetMinutes: data['targetMinutes'] ?? 0,
      targetSessions: data['targetSessions'] ?? 0,
      completedMinutes: data['completedMinutes'] ?? 0,
      completedSessions: data['completedSessions'] ?? 0,
      completedByUserIds: data['completedByUserIds'] != null 
          ? List<String>.from(data['completedByUserIds']) 
          : [],
      isShared: data['isShared'] ?? true,
      isCompetitive: data['isCompetitive'] ?? false,
    );
  }

  // Helper methods to parse enums
  static GoalType _parseType(dynamic typeStr) {
    if (typeStr == 'weekly') return GoalType.weekly;
    if (typeStr == 'monthly') return GoalType.monthly;
    if (typeStr == 'custom') return GoalType.custom;
    return GoalType.daily;
  }

  static GoalStatus _parseStatus(dynamic statusStr) {
    if (statusStr == 'inProgress') return GoalStatus.inProgress;
    if (statusStr == 'completed') return GoalStatus.completed;
    if (statusStr == 'failed') return GoalStatus.failed;
    return GoalStatus.pending;
  }

  // Calculate completion percentage
  double get completionPercentage {
    if (targetMinutes > 0) {
      return (completedMinutes / targetMinutes * 100).clamp(0, 100);
    }
    if (targetSessions > 0) {
      return (completedSessions / targetSessions * 100).clamp(0, 100);
    }
    return 0;
  }

  // Check if goal is active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && 
           now.isBefore(endDate) && 
           status == GoalStatus.inProgress;
  }

  // Copy with
  GroupGoalModel copyWith({
    String? id,
    String? groupId,
    String? title,
    String? description,
    String? createdBy,
    String? createdByName,
    GoalType? type,
    GoalStatus? status,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    int? targetMinutes,
    int? targetSessions,
    int? completedMinutes,
    int? completedSessions,
    List<String>? completedByUserIds,
    bool? isShared,
    bool? isCompetitive,
  }) {
    return GroupGoalModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      targetSessions: targetSessions ?? this.targetSessions,
      completedMinutes: completedMinutes ?? this.completedMinutes,
      completedSessions: completedSessions ?? this.completedSessions,
      completedByUserIds: completedByUserIds ?? this.completedByUserIds,
      isShared: isShared ?? this.isShared,
      isCompetitive: isCompetitive ?? this.isCompetitive,
    );
  }
}
