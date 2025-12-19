import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/data/models/challenge_model.dart';
import 'package:lock_in/data/models/user_model.dart';
import 'package:lock_in/data/repositories/user_repository.dart';
import 'package:lock_in/presentation/providers/challenge_provider.dart';
import 'dart:async';

/// Survival Lobby Screen showing real-time participant status
class SurvivalLobbyScreen extends ConsumerStatefulWidget {
  final String challengeId;

  const SurvivalLobbyScreen({super.key, required this.challengeId});

  @override
  ConsumerState<SurvivalLobbyScreen> createState() =>
      _SurvivalLobbyScreenState();
}

class _SurvivalLobbyScreenState extends ConsumerState<SurvivalLobbyScreen> {
  Timer? _countdownTimer;
  Duration? _remainingTime;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime endTime) {
    _countdownTimer?.cancel();
    _updateRemainingTime(endTime);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime(endTime);

      if (_remainingTime != null && _remainingTime!.isNegative) {
        timer.cancel();
        // Challenge ended
        ref
            .read(challengeProvider.notifier)
            .completeSurvivalChallenge(widget.challengeId);
      }
    });
  }

  void _updateRemainingTime(DateTime endTime) {
    setState(() {
      _remainingTime = endTime.difference(DateTime.now());
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return "00:00:00";
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final challengeAsync = ref.watch(
      survivalChallengeProvider(widget.challengeId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Survival Mode'),
        centerTitle: true,
        elevation: 0,
      ),
      body: challengeAsync.when(
        data: (challenge) {
          if (challenge == null) {
            return const Center(child: Text('Challenge not found'));
          }

          // Start countdown if not already started
          if (_remainingTime == null) {
            _startCountdown(challenge.endTime);
          }

          return _buildChallengeContent(challenge);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildChallengeContent(SurvivalChallengeModel challenge) {
    final survivorCount = challenge.survivorCount;
    final totalParticipants = challenge.participantIds.length;
    final knockoutPercentage = challenge.knockoutPercentage;

    return CustomScrollView(
      slivers: [
        // Timer Header
        SliverToBoxAdapter(child: _buildTimerHeader(challenge)),

        // Stats Section
        SliverToBoxAdapter(
          child: _buildStatsSection(
            survivorCount,
            totalParticipants,
            knockoutPercentage,
          ),
        ),

        // Participants Grid
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: _buildParticipantsGrid(challenge),
        ),
      ],
    );
  }

  Widget _buildTimerHeader(SurvivalChallengeModel challenge) {
    final isActive = challenge.status == ChallengeStatus.active;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ]
              : [Colors.grey.shade800, Colors.grey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade700,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            challenge.groupName,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _remainingTime != null
                ? _formatDuration(_remainingTime!)
                : "00:00:00",
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontFeatures: [const FontFeature.tabularFigures()],
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isActive ? 'Time Remaining' : 'Challenge Ended',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    int survivorCount,
    int totalParticipants,
    double knockoutPercentage,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.people,
              label: 'Survivors',
              value: '$survivorCount/$totalParticipants',
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.close,
              label: 'Knocked Out',
              value: '${(knockoutPercentage * 100).toStringAsFixed(0)}%',
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsGrid(SurvivalChallengeModel challenge) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final userId = challenge.participantIds[index];
        final status = challenge.participantStatuses[userId];
        return _ParticipantCard(
          userId: userId,
          status: status ?? ParticipantStatus.active,
        );
      }, childCount: challenge.participantIds.length),
    );
  }
}

/// Individual participant card showing status
class _ParticipantCard extends ConsumerWidget {
  final String userId;
  final ParticipantStatus status;

  const _ParticipantCard({required this.userId, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRepository = ref.watch(userRepositoryProvider);

    return FutureBuilder<UserModel?>(
      future: userRepository.getUserById(userId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isKnockedOut = status == ParticipantStatus.knockedOut;

        return Card(
          elevation: isKnockedOut ? 0 : 2,
          child: ColorFiltered(
            colorFilter: isKnockedOut
                ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                : const ColorFilter.mode(
                    Colors.transparent,
                    BlendMode.multiply,
                  ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: isKnockedOut
                            ? Colors.grey.shade800
                            : Theme.of(context).colorScheme.primary,
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? Text(
                                user?.displayName
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
                                    '?',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      // Name
                      Text(
                        user?.displayName ?? 'User',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isKnockedOut
                              ? Colors.grey.shade600
                              : Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status, context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Knocked out overlay
                if (isKnockedOut)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.close, color: Colors.red, size: 48),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(ParticipantStatus status, BuildContext context) {
    switch (status) {
      case ParticipantStatus.active:
        return Colors.green;
      case ParticipantStatus.knockedOut:
        return Colors.red;
      case ParticipantStatus.completed:
        return Colors.blue;
    }
  }

  String _getStatusText(ParticipantStatus status) {
    switch (status) {
      case ParticipantStatus.active:
        return 'ALIVE';
      case ParticipantStatus.knockedOut:
        return 'OUT';
      case ParticipantStatus.completed:
        return 'WON';
    }
  }
}
