import 'package:cloud_firestore/cloud_firestore.dart';

/// Base challenge type enum
enum ChallengeType { survivalMode, worldBoss }

/// Challenge status enum
enum ChallengeStatus { upcoming, active, completed, failed }

/// Participant status in survival challenge
enum ParticipantStatus { active, knockedOut, completed }

/// Base challenge model
abstract class ChallengeModel {
  final String id;
  final ChallengeType type;
  final ChallengeStatus status;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime createdAt;

  const ChallengeModel({
    required this.id,
    required this.type,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore();

  factory ChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final type = ChallengeType.values.byName(data['type'] ?? 'survivalMode');

    switch (type) {
      case ChallengeType.survivalMode:
        return SurvivalChallengeModel.fromFirestore(doc);
      case ChallengeType.worldBoss:
        return WorldBossModel.fromFirestore(doc);
    }
  }
}

/// Survival Mode Challenge Model
class SurvivalChallengeModel extends ChallengeModel {
  final String groupId;
  final String groupName;
  final List<String> participantIds;
  final Map<String, ParticipantStatus> participantStatuses;
  final Map<String, DateTime> knockoutTimestamps;
  final int durationMinutes;
  final List<String> winners; // Those who survived

  const SurvivalChallengeModel({
    required super.id,
    required super.status,
    required super.startTime,
    required super.endTime,
    required super.createdAt,
    required this.groupId,
    required this.groupName,
    required this.participantIds,
    required this.participantStatuses,
    required this.knockoutTimestamps,
    required this.durationMinutes,
    required this.winners,
  }) : super(type: ChallengeType.survivalMode);

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'status': status.name,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'createdAt': Timestamp.fromDate(createdAt),
      'groupId': groupId,
      'groupName': groupName,
      'participantIds': participantIds,
      'participantStatuses': participantStatuses.map(
        (key, value) => MapEntry(key, value.name),
      ),
      'knockoutTimestamps': knockoutTimestamps.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
      'durationMinutes': durationMinutes,
      'winners': winners,
    };
  }

  factory SurvivalChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SurvivalChallengeModel(
      id: doc.id,
      status: ChallengeStatus.values.byName(data['status'] ?? 'upcoming'),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      groupId: data['groupId'] ?? '',
      groupName: data['groupName'] ?? '',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantStatuses:
          (data['participantStatuses'] as Map<String, dynamic>?)?.map(
            (key, value) =>
                MapEntry(key, ParticipantStatus.values.byName(value as String)),
          ) ??
          {},
      knockoutTimestamps:
          (data['knockoutTimestamps'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as Timestamp).toDate()),
          ) ??
          {},
      durationMinutes: data['durationMinutes'] ?? 120,
      winners: List<String>.from(data['winners'] ?? []),
    );
  }

  SurvivalChallengeModel copyWith({
    String? id,
    ChallengeStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
    String? groupId,
    String? groupName,
    List<String>? participantIds,
    Map<String, ParticipantStatus>? participantStatuses,
    Map<String, DateTime>? knockoutTimestamps,
    int? durationMinutes,
    List<String>? winners,
  }) {
    return SurvivalChallengeModel(
      id: id ?? this.id,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      participantIds: participantIds ?? this.participantIds,
      participantStatuses: participantStatuses ?? this.participantStatuses,
      knockoutTimestamps: knockoutTimestamps ?? this.knockoutTimestamps,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      winners: winners ?? this.winners,
    );
  }

  /// Check if a user is still active in the challenge
  bool isUserActive(String userId) {
    return participantStatuses[userId] == ParticipantStatus.active;
  }

  /// Get number of survivors
  int get survivorCount {
    return participantStatuses.values
        .where((status) => status == ParticipantStatus.active)
        .length;
  }

  /// Get knockout percentage
  double get knockoutPercentage {
    if (participantIds.isEmpty) return 0;
    final knockedOut = participantStatuses.values
        .where((status) => status == ParticipantStatus.knockedOut)
        .length;
    return knockedOut / participantIds.length;
  }
}

/// World Boss Challenge Model
class WorldBossModel extends ChallengeModel {
  final String bossName;
  final String bossDescription;
  final int maxHP;
  final int currentHP;
  final int totalContributors;
  final Map<String, int> userContributions; // userId -> minutes contributed
  final int minimumContributionMinutes;

  const WorldBossModel({
    required super.id,
    required super.status,
    required super.startTime,
    required super.endTime,
    required super.createdAt,
    required this.bossName,
    required this.bossDescription,
    required this.maxHP,
    required this.currentHP,
    required this.totalContributors,
    required this.userContributions,
    required this.minimumContributionMinutes,
  }) : super(type: ChallengeType.worldBoss);

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'status': status.name,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'createdAt': Timestamp.fromDate(createdAt),
      'bossName': bossName,
      'bossDescription': bossDescription,
      'maxHP': maxHP,
      'currentHP': currentHP,
      'totalContributors': totalContributors,
      'userContributions': userContributions,
      'minimumContributionMinutes': minimumContributionMinutes,
    };
  }

  factory WorldBossModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return WorldBossModel(
      id: doc.id,
      status: ChallengeStatus.values.byName(data['status'] ?? 'upcoming'),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      bossName: data['bossName'] ?? 'Distraction Boss',
      bossDescription:
          data['bossDescription'] ??
          'A corrupted version of Lumo representing digital distraction',
      maxHP: data['maxHP'] ?? 100000,
      currentHP: data['currentHP'] ?? 100000,
      totalContributors: data['totalContributors'] ?? 0,
      userContributions: Map<String, int>.from(data['userContributions'] ?? {}),
      minimumContributionMinutes:
          data['minimumContributionMinutes'] ?? 300, // 5 hours
    );
  }

  WorldBossModel copyWith({
    String? id,
    ChallengeStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
    String? bossName,
    String? bossDescription,
    int? maxHP,
    int? currentHP,
    int? totalContributors,
    Map<String, int>? userContributions,
    int? minimumContributionMinutes,
  }) {
    return WorldBossModel(
      id: id ?? this.id,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      bossName: bossName ?? this.bossName,
      bossDescription: bossDescription ?? this.bossDescription,
      maxHP: maxHP ?? this.maxHP,
      currentHP: currentHP ?? this.currentHP,
      totalContributors: totalContributors ?? this.totalContributors,
      userContributions: userContributions ?? this.userContributions,
      minimumContributionMinutes:
          minimumContributionMinutes ?? this.minimumContributionMinutes,
    );
  }

  /// Get HP percentage remaining
  double get hpPercentage {
    if (maxHP == 0) return 0;
    return (currentHP / maxHP).clamp(0.0, 1.0);
  }

  /// Check if boss is defeated
  bool get isDefeated => currentHP <= 0;

  /// Check if user qualifies for reward
  bool userQualifiesForReward(String userId) {
    final contribution = userContributions[userId] ?? 0;
    return isDefeated && contribution >= minimumContributionMinutes;
  }

  /// Get user's contribution
  int getUserContribution(String userId) {
    return userContributions[userId] ?? 0;
  }

  /// Get user's contribution percentage towards minimum
  double getUserContributionPercentage(String userId) {
    final contribution = getUserContribution(userId);
    return (contribution / minimumContributionMinutes).clamp(0.0, 1.0);
  }

  /// Calculate damage dealt by a duration
  int calculateDamage(int minutes) {
    // 1 minute = 1 HP damage (can be adjusted)
    return minutes;
  }
}
