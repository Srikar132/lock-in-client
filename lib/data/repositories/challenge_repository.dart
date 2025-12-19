import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lock_in/data/models/challenge_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repository for managing challenges (Survival Mode and World Boss)
class ChallengeRepository {
  final FirebaseFirestore _firestore;

  ChallengeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _challengesCollection =>
      _firestore.collection('challenges');

  // ==================== SURVIVAL MODE ====================

  /// Create a new survival mode challenge for a group
  Future<String> createSurvivalChallenge({
    required String groupId,
    required String groupName,
    required List<String> participantIds,
    required int durationMinutes,
  }) async {
    final now = DateTime.now();
    final challenge = SurvivalChallengeModel(
      id: '', // Will be set by Firestore
      status: ChallengeStatus.active,
      startTime: now,
      endTime: now.add(Duration(minutes: durationMinutes)),
      createdAt: now,
      groupId: groupId,
      groupName: groupName,
      participantIds: participantIds,
      participantStatuses: {
        for (var id in participantIds) id: ParticipantStatus.active,
      },
      knockoutTimestamps: {},
      durationMinutes: durationMinutes,
      winners: [],
    );

    final doc = await _challengesCollection.add(challenge.toFirestore());
    return doc.id;
  }

  /// Mark a user as knocked out in a survival challenge
  Future<void> markUserKnockedOut({
    required String challengeId,
    required String userId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _challengesCollection.doc(challengeId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final participantStatuses = Map<String, dynamic>.from(
        data['participantStatuses'] ?? {},
      );
      final knockoutTimestamps = Map<String, dynamic>.from(
        data['knockoutTimestamps'] ?? {},
      );

      // Update status to knocked out
      participantStatuses[userId] = ParticipantStatus.knockedOut.name;
      knockoutTimestamps[userId] = Timestamp.now();

      transaction.update(docRef, {
        'participantStatuses': participantStatuses,
        'knockoutTimestamps': knockoutTimestamps,
      });
    });
  }

  /// Complete a survival challenge and determine winners
  Future<void> completeSurvivalChallenge(String challengeId) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _challengesCollection.doc(challengeId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final participantStatuses = Map<String, dynamic>.from(
        data['participantStatuses'] ?? {},
      );

      // Find survivors (those still active)
      final winners = participantStatuses.entries
          .where((entry) => entry.value == ParticipantStatus.active.name)
          .map((entry) => entry.key)
          .toList();

      // Update all active participants to completed
      for (var userId in winners) {
        participantStatuses[userId] = ParticipantStatus.completed.name;
      }

      transaction.update(docRef, {
        'status': ChallengeStatus.completed.name,
        'participantStatuses': participantStatuses,
        'winners': winners,
      });
    });
  }

  /// Get a survival challenge by ID
  Future<SurvivalChallengeModel?> getSurvivalChallenge(
    String challengeId,
  ) async {
    final doc = await _challengesCollection.doc(challengeId).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    if (data['type'] != ChallengeType.survivalMode.name) return null;

    return SurvivalChallengeModel.fromFirestore(doc);
  }

  /// Stream a survival challenge in real-time
  Stream<SurvivalChallengeModel?> watchSurvivalChallenge(String challengeId) {
    return _challengesCollection.doc(challengeId).snapshots().map((doc) {
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      if (data['type'] != ChallengeType.survivalMode.name) return null;

      return SurvivalChallengeModel.fromFirestore(doc);
    });
  }

  /// Get active survival challenge for a group
  Future<SurvivalChallengeModel?> getActiveSurvivalChallengeForGroup(
    String groupId,
  ) async {
    final query = await _challengesCollection
        .where('type', isEqualTo: ChallengeType.survivalMode.name)
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: ChallengeStatus.active.name)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return SurvivalChallengeModel.fromFirestore(query.docs.first);
  }

  /// Stream active survival challenges for a user
  Stream<List<SurvivalChallengeModel>> watchUserSurvivalChallenges(
    String userId,
  ) {
    return _challengesCollection
        .where('type', isEqualTo: ChallengeType.survivalMode.name)
        .where('participantIds', arrayContains: userId)
        .where('status', isEqualTo: ChallengeStatus.active.name)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SurvivalChallengeModel.fromFirestore(doc))
              .toList();
        });
  }

  // ==================== WORLD BOSS ====================

  /// Create a new world boss challenge
  Future<String> createWorldBoss({
    required String bossName,
    required String bossDescription,
    required int maxHP,
    required DateTime startTime,
    required DateTime endTime,
    int minimumContributionMinutes = 300, // 5 hours default
  }) async {
    final challenge = WorldBossModel(
      id: '', // Will be set by Firestore
      status: ChallengeStatus.active,
      startTime: startTime,
      endTime: endTime,
      createdAt: DateTime.now(),
      bossName: bossName,
      bossDescription: bossDescription,
      maxHP: maxHP,
      currentHP: maxHP,
      totalContributors: 0,
      userContributions: {},
      minimumContributionMinutes: minimumContributionMinutes,
    );

    final doc = await _challengesCollection.add(challenge.toFirestore());
    return doc.id;
  }

  /// Deal damage to the world boss (called after focus session)
  Future<void> dealDamageToWorldBoss({
    required String challengeId,
    required String userId,
    required int damageAmount, // minutes of focus
  }) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _challengesCollection.doc(challengeId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final currentHP = data['currentHP'] ?? 0;
      final userContributions = Map<String, dynamic>.from(
        data['userContributions'] ?? {},
      );
      var totalContributors = data['totalContributors'] ?? 0;

      // Add user contribution
      final previousContribution = userContributions[userId] ?? 0;
      userContributions[userId] = previousContribution + damageAmount;

      // Increment contributor count if this is user's first contribution
      if (previousContribution == 0) {
        totalContributors++;
      }

      // Calculate new HP (can't go below 0)
      final newHP = (currentHP - damageAmount).clamp(0, data['maxHP']);

      // Check if boss is defeated
      final updates = {
        'currentHP': newHP,
        'userContributions': userContributions,
        'totalContributors': totalContributors,
      };

      if (newHP <= 0 && data['status'] != ChallengeStatus.completed.name) {
        updates['status'] = ChallengeStatus.completed.name;
      }

      transaction.update(docRef, updates);
    });
  }

  /// Get the active world boss challenge
  Future<WorldBossModel?> getActiveWorldBoss() async {
    final query = await _challengesCollection
        .where('type', isEqualTo: ChallengeType.worldBoss.name)
        .where('status', isEqualTo: ChallengeStatus.active.name)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return WorldBossModel.fromFirestore(query.docs.first);
  }

  /// Stream the active world boss in real-time
  Stream<WorldBossModel?> watchActiveWorldBoss() {
    return _challengesCollection
        .where('type', isEqualTo: ChallengeType.worldBoss.name)
        .where('status', isEqualTo: ChallengeStatus.active.name)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return WorldBossModel.fromFirestore(snapshot.docs.first);
        });
  }

  /// Get world boss by ID
  Future<WorldBossModel?> getWorldBoss(String challengeId) async {
    final doc = await _challengesCollection.doc(challengeId).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    if (data['type'] != ChallengeType.worldBoss.name) return null;

    return WorldBossModel.fromFirestore(doc);
  }

  /// Get all world boss challenges (for history)
  Future<List<WorldBossModel>> getAllWorldBosses({int limit = 10}) async {
    final query = await _challengesCollection
        .where('type', isEqualTo: ChallengeType.worldBoss.name)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return query.docs.map((doc) => WorldBossModel.fromFirestore(doc)).toList();
  }

  // ==================== REWARDS ====================

  /// Award "Unbreakable" badge to survival challenge winners
  Future<void> awardUnbreakableBadge({
    required String userId,
    Duration badgeDuration = const Duration(hours: 24),
  }) async {
    final expiry = DateTime.now().add(badgeDuration);

    await _firestore.collection('users').doc(userId).update({
      'unbreakableBadgeExpiry': Timestamp.fromDate(expiry),
    });
  }

  /// Unlock "Focus Legend" theme for world boss participants
  Future<void> unlockFocusLegendTheme(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'unlockedThemes': FieldValue.arrayUnion(['focusLegend']),
    });
  }

  /// Check and award rewards for completed world boss
  Future<void> checkAndAwardWorldBossRewards(String challengeId) async {
    final boss = await getWorldBoss(challengeId);
    if (boss == null || !boss.isDefeated) return;

    // Award theme to all qualified users
    for (var entry in boss.userContributions.entries) {
      if (entry.value >= boss.minimumContributionMinutes) {
        await unlockFocusLegendTheme(entry.key);
      }
    }
  }

  // ==================== DELETE METHODS ====================

  /// Delete a world boss challenge
  Future<void> deleteWorldBoss(String challengeId) async {
    await _challengesCollection.doc(challengeId).delete();
  }

  /// Delete a survival challenge
  Future<void> deleteSurvivalChallenge(String challengeId) async {
    await _challengesCollection.doc(challengeId).delete();
  }

  /// Delete all completed challenges older than specified days
  Future<void> deleteOldChallenges({int olderThanDays = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));

    final query = await _challengesCollection
        .where('status', isEqualTo: ChallengeStatus.completed.name)
        .where('endTime', isLessThan: Timestamp.fromDate(cutoffDate))
        .get();

    final batch = _firestore.batch();
    for (var doc in query.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}

/// Provider for ChallengeRepository
final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository();
});
