import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/data/models/challenge_model.dart';
import 'package:lock_in/presentation/providers/challenge_provider.dart';
import 'package:lock_in/presentation/providers/auth_provider.dart';
import 'package:shimmer/shimmer.dart';

/// World Boss widget showing community challenge progress
class WorldBossWidget extends ConsumerWidget {
  const WorldBossWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worldBossAsync = ref.watch(activeWorldBossProvider);

    return worldBossAsync.when(
      data: (boss) {
        if (boss == null) {
          return const SizedBox.shrink();
        }
        return _buildWorldBossCard(context, ref, boss);
      },
      loading: () => const _WorldBossLoadingSkeleton(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildWorldBossCard(
    BuildContext context,
    WidgetRef ref,
    WorldBossModel boss,
  ) {
    final userContribution = ref.watch(userWorldBossContributionProvider);
    final qualifiesForReward = ref.watch(
      userQualifiesForWorldBossRewardProvider,
    );

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: boss.isDefeated
              ? Colors.green
              : Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: boss.isDefeated
                ? [Colors.green.shade900, Colors.green.shade700]
                : [
                    Colors.red.shade900.withOpacity(0.3),
                    Colors.purple.shade900.withOpacity(0.3),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, boss),
              const SizedBox(height: 16),

              // Boss description
              Text(
                boss.bossDescription,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 20),

              // HP Bar
              _buildHPBar(context, boss),
              const SizedBox(height: 16),

              // Stats Row
              _buildStatsRow(context, boss),
              const SizedBox(height: 16),

              // User Contribution
              _buildUserContribution(
                context,
                ref,
                boss,
                userContribution,
                qualifiesForReward,
              ),

              // Time remaining
              if (!boss.isDefeated) ...[
                const SizedBox(height: 12),
                _buildTimeRemaining(context, boss),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WorldBossModel boss) {
    return Row(
      children: [
        // Boss icon/emoji
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: boss.isDefeated
                ? Colors.green.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: boss.isDefeated ? Colors.green : Colors.red,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              boss.isDefeated ? '💀' : '👹',
              style: const TextStyle(fontSize: 32),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                boss.bossName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: boss.isDefeated ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  boss.isDefeated ? 'DEFEATED' : 'ACTIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHPBar(BuildContext context, WorldBossModel boss) {
    final hpPercentage = boss.hpPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Boss HP',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${boss.currentHP.toStringAsFixed(0)} / ${boss.maxHP}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white70,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 24,
            child: boss.isDefeated
                ? _buildDefeatedBar(context)
                : _buildActiveHPBar(context, hpPercentage),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveHPBar(BuildContext context, double hpPercentage) {
    return Shimmer.fromColors(
      baseColor: Colors.red.shade700,
      highlightColor: Colors.red.shade500,
      period: const Duration(milliseconds: 1500),
      child: Stack(
        children: [
          // Background
          Container(color: Colors.grey.shade800),
          // HP Fill
          FractionallySizedBox(
            widthFactor: hpPercentage,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade700, Colors.red.shade500],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefeatedBar(BuildContext context) {
    return Container(
      color: Colors.green,
      child: const Center(
        child: Text(
          '✓ BOSS DEFEATED',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, WorldBossModel boss) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            icon: Icons.people,
            label: 'Contributors',
            value: boss.totalContributors.toString(),
          ),
        ),
        Expanded(
          child: _buildStatItem(
            context,
            icon: Icons.health_and_safety,
            label: 'HP Left',
            value: '${(boss.hpPercentage * 100).toStringAsFixed(0)}%',
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white60),
        ),
      ],
    );
  }

  Widget _buildUserContribution(
    BuildContext context,
    WidgetRef ref,
    WorldBossModel boss,
    int userContribution,
    bool qualifiesForReward,
  ) {
    final contributionPercentage = boss.getUserContributionPercentage(
      ref.watch(currentUserProvider).value?.uid ?? '',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: qualifiesForReward ? Colors.green : Colors.white24,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Contribution',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$userContribution / ${boss.minimumContributionMinutes} min',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: qualifiesForReward ? Colors.green : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: contributionPercentage,
              minHeight: 8,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation<Color>(
                qualifiesForReward ? Colors.green : Colors.orange,
              ),
            ),
          ),
          if (qualifiesForReward) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Qualified for Focus Legend Theme!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeRemaining(BuildContext context, WorldBossModel boss) {
    final remainingTime = boss.endTime.difference(DateTime.now());
    final days = remainingTime.inDays;
    final hours = remainingTime.inHours % 24;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.timer, color: Colors.white60, size: 16),
        const SizedBox(width: 4),
        Text(
          days > 0 ? '$days days, $hours hours left' : '$hours hours left',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white60),
        ),
      ],
    );
  }
}

/// Loading skeleton for world boss widget
class _WorldBossLoadingSkeleton extends StatelessWidget {
  const _WorldBossLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade800,
        highlightColor: Colors.grey.shade700,
        child: Container(
          height: 250,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 150, height: 20, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 80, height: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(height: 40, color: Colors.white),
              const Spacer(),
              Container(height: 24, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
