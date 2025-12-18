import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupPrivacy { public, private }

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String? photoURL;
  final String creatorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Privacy & Settings
  final GroupPrivacy privacy;
  final bool requiresApproval; // For joining
  final int maxMembers;
  
  // Stats
  final int memberCount;
  final int totalGoalsCompleted;
  final int totalStudyTime; // in minutes
  
  // Invite link
  final String inviteCode;
  
  // Categories
  final List<String> categories; // e.g., 'study', 'fitness', 'productivity'
  
  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    this.photoURL,
    required this.creatorId,
    required this.createdAt,
    required this.updatedAt,
    this.privacy = GroupPrivacy.public,
    this.requiresApproval = false,
    this.maxMembers = 50,
    this.memberCount = 1,
    this.totalGoalsCompleted = 0,
    this.totalStudyTime = 0,
    required this.inviteCode,
    this.categories = const [],
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'photoURL': photoURL,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'privacy': privacy.name,
      'requiresApproval': requiresApproval,
      'maxMembers': maxMembers,
      'memberCount': memberCount,
      'totalGoalsCompleted': totalGoalsCompleted,
      'totalStudyTime': totalStudyTime,
      'inviteCode': inviteCode,
      'categories': categories,
    };
  }

  // Create from Firestore document
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      photoURL: data['photoURL'],
      creatorId: data['creatorId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      privacy: data['privacy'] == 'private' 
          ? GroupPrivacy.private 
          : GroupPrivacy.public,
      requiresApproval: data['requiresApproval'] ?? false,
      maxMembers: data['maxMembers'] ?? 50,
      memberCount: data['memberCount'] ?? 1,
      totalGoalsCompleted: data['totalGoalsCompleted'] ?? 0,
      totalStudyTime: data['totalStudyTime'] ?? 0,
      inviteCode: data['inviteCode'] ?? '',
      categories: data['categories'] != null 
          ? List<String>.from(data['categories']) 
          : [],
    );
  }

  // Create from Map
  factory GroupModel.fromMap(Map<String, dynamic> data, String id) {
    return GroupModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      photoURL: data['photoURL'],
      creatorId: data['creatorId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      privacy: data['privacy'] == 'private' 
          ? GroupPrivacy.private 
          : GroupPrivacy.public,
      requiresApproval: data['requiresApproval'] ?? false,
      maxMembers: data['maxMembers'] ?? 50,
      memberCount: data['memberCount'] ?? 1,
      totalGoalsCompleted: data['totalGoalsCompleted'] ?? 0,
      totalStudyTime: data['totalStudyTime'] ?? 0,
      inviteCode: data['inviteCode'] ?? '',
      categories: data['categories'] != null 
          ? List<String>.from(data['categories']) 
          : [],
    );
  }

  // Copy with
  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? photoURL,
    String? creatorId,
    DateTime? createdAt,
    DateTime? updatedAt,
    GroupPrivacy? privacy,
    bool? requiresApproval,
    int? maxMembers,
    int? memberCount,
    int? totalGoalsCompleted,
    int? totalStudyTime,
    String? inviteCode,
    List<String>? categories,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      photoURL: photoURL ?? this.photoURL,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      privacy: privacy ?? this.privacy,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      maxMembers: maxMembers ?? this.maxMembers,
      memberCount: memberCount ?? this.memberCount,
      totalGoalsCompleted: totalGoalsCompleted ?? this.totalGoalsCompleted,
      totalStudyTime: totalStudyTime ?? this.totalStudyTime,
      inviteCode: inviteCode ?? this.inviteCode,
      categories: categories ?? this.categories,
    );
  }
}
