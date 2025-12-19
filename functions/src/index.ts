/**
 * Firebase Cloud Functions for LockIn Challenge System
 * 
 * This file contains Cloud Functions for:
 * 1. World Boss damage aggregation
 * 2. Survival Mode badge awards
 * 3. Theme unlocking rewards
 * 4. Challenge completion handlers
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

const db = admin.firestore();

// ==================== WORLD BOSS FUNCTIONS ====================

/**
 * Triggered when a focus session is completed
 * Deals damage to the active World Boss
 */
export const onFocusSessionComplete = functions.firestore
  .document('users/{userId}/sessions/{sessionId}')
  .onCreate(async (snap, context) => {
    const session = snap.data();
    const userId = context.params.userId;

    // Only process completed sessions
    if (!session || session.status !== 'completed') {
      return null;
    }

    // Calculate damage (1 minute = 1 HP)
    const durationMinutes = Math.floor(session.actualDuration / 60000);

    try {
      // Get active world boss
      const activeBossQuery = await db
        .collection('challenges')
        .where('type', '==', 'worldBoss')
        .where('status', '==', 'active')
        .limit(1)
        .get();

      if (activeBossQuery.empty) {
        console.log('No active world boss found');
        return null;
      }

      const bossDoc = activeBossQuery.docs[0];
      const bossRef = bossDoc.ref;
      const bossData = bossDoc.data();

      // Update boss HP and user contributions using transaction
      await db.runTransaction(async (transaction) => {
        const boss = await transaction.get(bossRef);
        if (!boss.exists) return;

        const currentHP = boss.data()?.currentHP || 0;
        const maxHP = boss.data()?.maxHP || 100000;
        const userContributions = boss.data()?.userContributions || {};
        let totalContributors = boss.data()?.totalContributors || 0;

        // Add user contribution
        const previousContribution = userContributions[userId] || 0;
        userContributions[userId] = previousContribution + durationMinutes;

        // Increment contributor count if first contribution
        if (previousContribution === 0) {
          totalContributors++;
        }

        // Calculate new HP (can't go below 0)
        const newHP = Math.max(0, currentHP - durationMinutes);

        const updates: any = {
          currentHP: newHP,
          userContributions,
          totalContributors,
        };

        // Check if boss is defeated
        if (newHP <= 0 && boss.data()?.status !== 'completed') {
          updates.status = 'completed';
          console.log(`🎉 World Boss defeated! Awarding rewards...`);

          // Award rewards in the same transaction
          await awardWorldBossRewards(transaction, bossDoc.id, bossData);
        }

        transaction.update(bossRef, updates);
      });

      console.log(
        `✅ User ${userId} dealt ${durationMinutes} damage to World Boss`
      );
      return null;
    } catch (error) {
      console.error('Error processing world boss damage:', error);
      return null;
    }
  });

/**
 * Award Focus Legend theme to all qualified participants
 */
async function awardWorldBossRewards(
  transaction: FirebaseFirestore.Transaction,
  bossId: string,
  bossData: any
) {
  const userContributions = bossData.userContributions || {};
  const minimumContribution = bossData.minimumContributionMinutes || 300;

  const qualifiedUsers = Object.entries(userContributions)
    .filter(([_, contribution]) => (contribution as number) >= minimumContribution)
    .map(([userId, _]) => userId);

  console.log(`Awarding theme to ${qualifiedUsers.length} qualified users`);

  // Award theme to all qualified users
  for (const userId of qualifiedUsers) {
    const userRef = db.collection('users').doc(userId);
    transaction.update(userRef, {
      unlockedThemes: admin.firestore.FieldValue.arrayUnion('focusLegend'),
    });
  }
}

// ==================== SURVIVAL MODE FUNCTIONS ====================

/**
 * Triggered when a survival challenge is completed
 * Awards Unbreakable badge to winners
 */
export const onSurvivalChallengeComplete = functions.firestore
  .document('challenges/{challengeId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const challengeId = context.params.challengeId;

    // Check if challenge just completed
    if (
      beforeData.type === 'survivalMode' &&
      beforeData.status !== 'completed' &&
      afterData.status === 'completed'
    ) {
      const winners = afterData.winners || [];

      console.log(
        `🏆 Survival challenge completed! ${winners.length} winners`
      );

      // Award badge to all winners
      const badgeDuration = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
      const badgeExpiry = new Date(Date.now() + badgeDuration);

      const batch = db.batch();

      for (const userId of winners) {
        const userRef = db.collection('users').doc(userId);
        batch.update(userRef, {
          unbreakableBadgeExpiry: admin.firestore.Timestamp.fromDate(badgeExpiry),
        });
      }

      await batch.commit();

      console.log(`✅ Awarded Unbreakable badge to ${winners.length} winners`);
      return null;
    }

    return null;
  });

// ==================== SCHEDULED FUNCTIONS ====================

/**
 * Create a new weekly World Boss challenge
 * Runs every Monday at 00:00 UTC
 */
export const createWeeklyWorldBoss = functions.pubsub
  .schedule('0 0 * * 1') // Every Monday at midnight
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      // Check if there's already an active boss
      const activeBossQuery = await db
        .collection('challenges')
        .where('type', '==', 'worldBoss')
        .where('status', '==', 'active')
        .get();

      if (!activeBossQuery.empty) {
        console.log('Active World Boss already exists');
        return null;
      }

      const now = new Date();
      const endDate = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000); // 7 days

      const newBoss = {
        type: 'worldBoss',
        status: 'active',
        startTime: admin.firestore.Timestamp.fromDate(now),
        endTime: admin.firestore.Timestamp.fromDate(endDate),
        createdAt: admin.firestore.Timestamp.fromDate(now),
        bossName: 'Distraction Demon',
        bossDescription:
          'A corrupted manifestation of digital distraction. Defeat it through collective focus!',
        maxHP: 100000,
        currentHP: 100000,
        totalContributors: 0,
        userContributions: {},
        minimumContributionMinutes: 300, // 5 hours
      };

      await db.collection('challenges').add(newBoss);

      console.log('✅ Created new weekly World Boss challenge');
      return null;
    } catch (error) {
      console.error('Error creating weekly world boss:', error);
      return null;
    }
  });

/**
 * Clean up expired badges
 * Runs daily at 00:00 UTC
 */
export const cleanupExpiredBadges = functions.pubsub
  .schedule('0 0 * * *') // Daily at midnight
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      const now = admin.firestore.Timestamp.now();

      // Find users with expired badges
      const expiredBadgesQuery = await db
        .collection('users')
        .where('unbreakableBadgeExpiry', '<=', now)
        .get();

      if (expiredBadgesQuery.empty) {
        console.log('No expired badges to clean up');
        return null;
      }

      const batch = db.batch();

      expiredBadgesQuery.docs.forEach((doc) => {
        batch.update(doc.ref, {
          unbreakableBadgeExpiry: admin.firestore.FieldValue.delete(),
        });
      });

      await batch.commit();

      console.log(
        `✅ Cleaned up ${expiredBadgesQuery.size} expired badges`
      );
      return null;
    } catch (error) {
      console.error('Error cleaning up expired badges:', error);
      return null;
    }
  });

// ==================== CALLABLE FUNCTIONS ====================

/**
 * Manually trigger World Boss reward distribution
 * Can be called by admins or when boss is defeated
 */
export const distributeWorldBossRewards = functions.https.onCall(
  async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Must be authenticated to call this function'
      );
    }

    const { challengeId } = data;

    if (!challengeId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Challenge ID is required'
      );
    }

    try {
      const bossRef = db.collection('challenges').doc(challengeId);
      const bossDoc = await bossRef.get();

      if (!bossDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Challenge not found'
        );
      }

      const bossData = bossDoc.data()!;

      if (bossData.type !== 'worldBoss') {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Not a World Boss challenge'
        );
      }

      if (!bossData.isDefeated && bossData.currentHP > 0) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Boss is not yet defeated'
        );
      }

      await db.runTransaction(async (transaction) => {
        await awardWorldBossRewards(transaction, challengeId, bossData);
      });

      return { success: true, message: 'Rewards distributed successfully' };
    } catch (error) {
      console.error('Error distributing rewards:', error);
      throw new functions.https.HttpsError('internal', 'Failed to distribute rewards');
    }
  }
);
