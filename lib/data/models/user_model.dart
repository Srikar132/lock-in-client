import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool hasCompletedOnboarding;
  final bool hasGrantedPermissions;
  
  // Onboarding data
  final String? procrastinationLevel; // "struggle" | "few_bad_days" | "consistent"
  final List<String>? distractions; // ["reels", "notifications", "texting", "games"]
  final String? preferredStudyTime; // "morning" | "afternoon" | "evening" | "night"

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.lastLoginAt,
    this.hasCompletedOnboarding = false,
    this.hasGrantedPermissions = false,
    this.procrastinationLevel,
    this.distractions,
    this.preferredStudyTime,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'hasGrantedPermissions': hasGrantedPermissions,
      'procrastinationLevel': procrastinationLevel,
      'distractions': distractions,
      'preferredStudyTime': preferredStudyTime,
    };
  }

  // Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hasCompletedOnboarding: data['hasCompletedOnboarding'] ?? false,
      hasGrantedPermissions: data['hasGrantedPermissions'] ?? false,
      procrastinationLevel: data['procrastinationLevel'],
      distractions: data['distractions'] != null 
          ? List<String>.from(data['distractions']) 
          : null,
      preferredStudyTime: data['preferredStudyTime'],
    );
  }

  // Copy with method for immutability
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? hasCompletedOnboarding,
    bool? hasGrantedPermissions,
    String? procrastinationLevel,
    List<String>? distractions,
    String? preferredStudyTime,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasGrantedPermissions: hasGrantedPermissions ?? this.hasGrantedPermissions,
      procrastinationLevel: procrastinationLevel ?? this.procrastinationLevel,
      distractions: distractions ?? this.distractions,
      preferredStudyTime: preferredStudyTime ?? this.preferredStudyTime,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
