import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  // User status
  final bool hasCompletedOnboarding;
  final bool hasGrantedPermissions;

  // Onboarding data
  final String? procrastinationLevel;
  final List<String>? distractions;
  final String? preferredStudyTime;

  // === QUICK STATS (for dashboard) ===
  final int totalFocusTime; // milliseconds
  final int totalSessions;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;

  // === GAMIFICATION (Challenges) ===
  final DateTime? unbreakableBadgeExpiry; // 24-hour badge from survival mode
  final List<String> unlockedThemes; // Unlocked theme IDs (e.g., 'focusLegend')

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
    this.totalFocusTime = 0,
    this.totalSessions = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.unbreakableBadgeExpiry,
    this.unlockedThemes = const [],
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
      'totalFocusTime': totalFocusTime,
      'totalSessions': totalSessions,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate != null
          ? Timestamp.fromDate(lastActiveDate!)
          : null,
      'unbreakableBadgeExpiry': unbreakableBadgeExpiry != null
          ? Timestamp.fromDate(unbreakableBadgeExpiry!)
          : null,
      'unlockedThemes': unlockedThemes,
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
      lastLoginAt:
          (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hasCompletedOnboarding: data['hasCompletedOnboarding'] ?? false,
      hasGrantedPermissions: data['hasGrantedPermissions'] ?? false,
      procrastinationLevel: data['procrastinationLevel'],
      distractions: data['distractions'] != null
          ? List<String>.from(data['distractions'])
          : null,
      preferredStudyTime: data['preferredStudyTime'],
      totalFocusTime: data['totalFocusTime'] ?? 0,
      totalSessions: data['totalSessions'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      unbreakableBadgeExpiry: data['unbreakableBadgeExpiry'] != null
          ? (data['unbreakableBadgeExpiry'] as Timestamp).toDate()
          : null,
      unlockedThemes: data['unlockedThemes'] != null
          ? List<String>.from(data['unlockedThemes'])
          : [],
      longestStreak: data['longestStreak'] ?? 0,
      lastActiveDate: data['lastActiveDate'] != null
          ? (data['lastActiveDate'] as Timestamp).toDate()
          : null,
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
    DateTime? unbreakableBadgeExpiry,
    List<String>? unlockedThemes,
    String? preferredStudyTime,
    int? totalFocusTime,
    int? totalSessions,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasGrantedPermissions:
          hasGrantedPermissions ?? this.hasGrantedPermissions,
      unbreakableBadgeExpiry:
          unbreakableBadgeExpiry ?? this.unbreakableBadgeExpiry,
      unlockedThemes: unlockedThemes ?? this.unlockedThemes,
      procrastinationLevel: procrastinationLevel ?? this.procrastinationLevel,
      distractions: distractions ?? this.distractions,
      preferredStudyTime: preferredStudyTime ?? this.preferredStudyTime,
      totalFocusTime: totalFocusTime ?? this.totalFocusTime,
      totalSessions: totalSessions ?? this.totalSessions,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  // Helper methods

  /// Check if user has active "Unbreakable" badge
  bool get hasUnbreakableBadge {
    if (unbreakableBadgeExpiry == null) return false;
    return DateTime.now().isBefore(unbreakableBadgeExpiry!);
  }

  /// Check if user has unlocked a specific theme
  bool hasTheme(String themeId) => unlockedThemes.contains(themeId);

  // Helper methods
  String get firstName => displayName?.split(' ').first ?? 'User';

  bool get isOnboardingComplete => hasCompletedOnboarding;
  bool get isPermissionsGranted => hasGrantedPermissions;
  bool get isSetupComplete => hasCompletedOnboarding && hasGrantedPermissions;

  // Format total focus time
  String get formattedTotalFocusTime {
    final hours = totalFocusTime ~/ (1000 * 60 * 60);
    final minutes = (totalFocusTime % (1000 * 60 * 60)) ~/ (1000 * 60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, sessions: $totalSessions)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
