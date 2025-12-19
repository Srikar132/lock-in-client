import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/data/models/challenge_model.dart';
import 'package:lock_in/data/repositories/challenge_repository.dart';
import 'package:lock_in/presentation/providers/auth_provider.dart';
import 'package:lock_in/services/blocks_native_service.dart';

// ==================== CHALLENGE STATE ====================

/// State for challenge management
class ChallengeState {
  final SurvivalChallengeModel? activeSurvivalChallenge;
  final WorldBossModel? activeWorldBoss;
  final bool isInSurvivalMode;
  final String? error;

  const ChallengeState({
    this.activeSurvivalChallenge,
    this.activeWorldBoss,
    this.isInSurvivalMode = false,
    this.error,
  });

  ChallengeState copyWith({
    SurvivalChallengeModel? activeSurvivalChallenge,
    WorldBossModel? activeWorldBoss,
    bool? isInSurvivalMode,
    String? error,
  }) {
    return ChallengeState(
      activeSurvivalChallenge:
          activeSurvivalChallenge ?? this.activeSurvivalChallenge,
      activeWorldBoss: activeWorldBoss ?? this.activeWorldBoss,
      isInSurvivalMode: isInSurvivalMode ?? this.isInSurvivalMode,
      error: error,
    );
  }

  /// Clear active survival challenge
  ChallengeState clearSurvivalChallenge() {
    return ChallengeState(
      activeSurvivalChallenge: null,
      activeWorldBoss: activeWorldBoss,
      isInSurvivalMode: false,
      error: error,
    );
  }
}

// ==================== CHALLENGE NOTIFIER ====================

/// Notifier for managing challenge state and events
class ChallengeNotifier extends Notifier<ChallengeState> {
  ChallengeRepository get _repository => ref.read(challengeRepositoryProvider);
  String? get _userId => ref.read(currentUserProvider).value?.uid;

  @override
  ChallengeState build() {
    _initialize();
    return const ChallengeState();
  }

  void _initialize() {
    // Listen to native blocking events for survival mode failures
    _listenToBlockingEvents();
  }

  void _listenToBlockingEvents() {
    final blocksService = BlocksNativeService();

    blocksService.blockingEventsStream.listen((event) {
      final eventType = event['type'] as String?;

      // If user tries to open blocked app during survival mode
      if (eventType == 'APP_BLOCKED' && state.isInSurvivalMode) {
        _handleSurvivalModeFailure();
      }

      // Handle challenge_failed event from native service
      if (eventType == 'challenge_failed' && state.isInSurvivalMode) {
        _handleSurvivalModeFailure();
      }
    });
  }

  /// Handle survival mode failure (user knocked out)
  Future<void> _handleSurvivalModeFailure() async {
    if (state.activeSurvivalChallenge == null || _userId == null) return;

    try {
      await _repository.markUserKnockedOut(
        challengeId: state.activeSurvivalChallenge!.id,
        userId: _userId!,
      );

      // Continue in strict mode but mark as knocked out locally
      state = state.copyWith(isInSurvivalMode: false);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update survival status: $e');
    }
  }

  /// Create a survival challenge (wrapper for startSurvivalChallenge)
  Future<String> createSurvivalChallenge({
    required String groupId,
    required Duration duration,
  }) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) throw Exception('User not authenticated');

    // Get group data to get participant IDs
    // For now, just use groupId as a single participant
    final challengeId = await startSurvivalChallenge(
      groupId: groupId,
      groupName: 'Group Challenge',
      participantIds: [user.uid],
      durationMinutes: duration.inMinutes,
    );

    if (challengeId == null) {
      throw Exception('Failed to create survival challenge');
    }

    return challengeId;
  }

  /// Start a survival challenge
  Future<String?> startSurvivalChallenge({
    required String groupId,
    required String groupName,
    required List<String> participantIds,
    int durationMinutes = 120,
  }) async {
    try {
      final challengeId = await _repository.createSurvivalChallenge(
        groupId: groupId,
        groupName: groupName,
        participantIds: participantIds,
        durationMinutes: durationMinutes,
      );

      state = state.copyWith(isInSurvivalMode: true);
      return challengeId;
    } catch (e) {
      state = state.copyWith(error: 'Failed to start survival challenge: $e');
      return null;
    }
  }

  /// Mark user as knocked out
  Future<void> knockoutUser(String challengeId, String userId) async {
    try {
      await _repository.markUserKnockedOut(
        challengeId: challengeId,
        userId: userId,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to knockout user: $e');
    }
  }

  /// Complete survival challenge
  Future<void> completeSurvivalChallenge(String challengeId) async {
    try {
      await _repository.completeSurvivalChallenge(challengeId);
      state = state.clearSurvivalChallenge();

      // Award badges to winners
      final challenge = await _repository.getSurvivalChallenge(challengeId);
      if (challenge != null && _userId != null) {
        if (challenge.winners.contains(_userId)) {
          await _repository.awardUnbreakableBadge(userId: _userId!);
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to complete challenge: $e');
    }
  }

  /// Deal damage to world boss after focus session
  Future<void> contributeToWorldBoss(int focusMinutes) async {
    if (state.activeWorldBoss == null || _userId == null) return;

    try {
      await _repository.dealDamageToWorldBoss(
        challengeId: state.activeWorldBoss!.id,
        userId: _userId!,
        damageAmount: focusMinutes,
      );

      // Check if boss is defeated and award rewards
      final boss = await _repository.getWorldBoss(state.activeWorldBoss!.id);
      if (boss != null && boss.isDefeated) {
        await _repository.checkAndAwardWorldBossRewards(boss.id);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to contribute to world boss: $e');
    }
  }

  /// Update active survival challenge
  void updateSurvivalChallenge(SurvivalChallengeModel? challenge) {
    state = state.copyWith(activeSurvivalChallenge: challenge);
  }

  /// Update active world boss
  void updateWorldBoss(WorldBossModel? boss) {
    state = state.copyWith(activeWorldBoss: boss);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Exit survival mode
  void exitSurvivalMode() {
    state = state.copyWith(isInSurvivalMode: false);
  }

  // ==================== DELETE METHODS ====================

  /// Delete a world boss challenge
  Future<void> deleteWorldBoss(String challengeId) async {
    try {
      await _repository.deleteWorldBoss(challengeId);

      // Clear from state if it's the active one
      if (state.activeWorldBoss?.id == challengeId) {
        state = state.copyWith(activeWorldBoss: null);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete world boss: $e');
      rethrow;
    }
  }

  /// Delete a survival challenge
  Future<void> deleteSurvivalChallenge(String challengeId) async {
    try {
      await _repository.deleteSurvivalChallenge(challengeId);

      // Clear from state if it's the active one
      if (state.activeSurvivalChallenge?.id == challengeId) {
        state = state.clearSurvivalChallenge();
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete survival challenge: $e');
      rethrow;
    }
  }

  /// Delete old completed challenges
  Future<void> deleteOldChallenges({int olderThanDays = 30}) async {
    try {
      await _repository.deleteOldChallenges(olderThanDays: olderThanDays);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete old challenges: $e');
      rethrow;
    }
  }
}

// ==================== PROVIDERS ====================

/// Main challenge provider
final challengeProvider = NotifierProvider<ChallengeNotifier, ChallengeState>(
  ChallengeNotifier.new,
);

/// Stream provider for user's active survival challenges
final userSurvivalChallengesProvider =
    StreamProvider<List<SurvivalChallengeModel>>((ref) {
      final userId = ref.watch(currentUserProvider).value?.uid;
      if (userId == null) {
        return Stream.value([]);
      }

      final repository = ref.watch(challengeRepositoryProvider);
      return repository.watchUserSurvivalChallenges(userId);
    });

/// Stream provider for a specific survival challenge
final survivalChallengeProvider =
    StreamProvider.family<SurvivalChallengeModel?, String>((ref, challengeId) {
      final repository = ref.watch(challengeRepositoryProvider);
      return repository.watchSurvivalChallenge(challengeId);
    });

/// Stream provider for active world boss
final activeWorldBossProvider = StreamProvider<WorldBossModel?>((ref) {
  final repository = ref.watch(challengeRepositoryProvider);
  return repository.watchActiveWorldBoss();
});

/// Provider to get user's contribution to current world boss
final userWorldBossContributionProvider = Provider<int>((ref) {
  final userId = ref.watch(currentUserProvider).value?.uid;
  final worldBoss = ref.watch(activeWorldBossProvider).value;

  if (userId == null || worldBoss == null) return 0;

  return worldBoss.getUserContribution(userId);
});

/// Provider to check if user qualifies for world boss reward
final userQualifiesForWorldBossRewardProvider = Provider<bool>((ref) {
  final userId = ref.watch(currentUserProvider).value?.uid;
  final worldBoss = ref.watch(activeWorldBossProvider).value;

  if (userId == null || worldBoss == null) return false;

  return worldBoss.userQualifiesForReward(userId);
});

/// Provider to check if user has unbreakable badge
final hasUnbreakableBadgeProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return user?.hasUnbreakableBadge ?? false;
});

/// Provider to get user's unlocked themes
final unlockedThemesProvider = Provider<List<String>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return user?.unlockedThemes ?? [];
});

/// Provider to check if a specific theme is unlocked
final hasThemeUnlockedProvider = Provider.family<bool, String>((ref, themeId) {
  final unlockedThemes = ref.watch(unlockedThemesProvider);
  return unlockedThemes.contains(themeId);
});
