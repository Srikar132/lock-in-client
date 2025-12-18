import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:lock_in/data/models/blocked_content_model.dart';

class BlockedContentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Document reference for blocked content
  DocumentReference _getBlockedContentDoc(String userId) {
    return _firestore.collection('blockedContent').doc(userId);
  }

  // Get blocked content for a user
  Future<BlockedContentModel?> getBlockedContent(String userId) async {
    try {
      final doc = await _getBlockedContentDoc(userId).get();

      if (!doc.exists) {
        // Return default empty model if document doesn't exist
        return BlockedContentModel();
      }

      return BlockedContentModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting blocked content: $e');
      rethrow;
    }
  }

  // Get blocked content as stream for real-time updates
  Stream<BlockedContentModel> getBlockedContentStream(String userId) {
    return _getBlockedContentDoc(
      userId,
    ).snapshots(includeMetadataChanges: true).map((doc) {
      debugPrint('📡 Firestore stream update for user: $userId');
      debugPrint('   - Document exists: ${doc.exists}');

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        debugPrint('   - Has data: ${data != null}');

        if (data != null) {
          // Debug appLimits
          if (data.containsKey('appLimits')) {
            final appLimits = data['appLimits'] as Map<String, dynamic>?;
            debugPrint('   - App limits count: ${appLimits?.length ?? 0}');
            debugPrint('   - App limits keys: ${appLimits?.keys.toList()}');
          } else {
            debugPrint('   - No appLimits field in document');
          }

          // Debug shortFormBlocks
          if (data.containsKey('shortFormBlocks')) {
            final shortFormBlocks =
                data['shortFormBlocks'] as Map<String, dynamic>?;
            debugPrint(
              '   - Short form blocks count: ${shortFormBlocks?.length ?? 0}',
            );
            debugPrint(
              '   - Short form blocks keys: ${shortFormBlocks?.keys.toList()}',
            );
            if (shortFormBlocks != null) {
              shortFormBlocks.forEach((key, value) {
                final blockData = value as Map<String, dynamic>;
                debugPrint(
                  '     * $key: ${blockData['platform']}_${blockData['feature']} = ${blockData['isBlocked']}',
                );
              });
            }
          } else {
            debugPrint('   - ❌ No shortFormBlocks field in document');
          }

          // Debug all fields
          debugPrint('   - All document fields: ${data.keys.toList()}');
        }

        return BlockedContentModel.fromFirestore(doc);
      }

      debugPrint('   - Returning empty model (doc does not exist)');
      return BlockedContentModel();
    });
  }

  // Set or update blocked content
  Future<void> setBlockedContent(
    String userId,
    BlockedContentModel blockedContent,
  ) async {
    try {
      await _getBlockedContentDoc(
        userId,
      ).set(blockedContent.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error setting blocked content: $e');
      rethrow;
    }
  }

  // Update specific fields
  Future<void> updateBlockedContent(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Always update the lastUpdated field
      updates['lastUpdated'] = Timestamp.fromDate(DateTime.now());

      await _getBlockedContentDoc(userId).update(updates);
    } catch (e) {
      debugPrint('Error updating blocked content: $e');
      rethrow;
    }
  }

  // === APP LIMITS ===

  // Add or update app limit
  Future<void> setAppLimit(String userId, AppLimit appLimit) async {
    try {
      await _getBlockedContentDoc(userId).set({
        'appLimits.${appLimit.packageName}': appLimit.toMap(),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error setting app limit: $e');
      rethrow;
    }
  }

  // Remove app limit
  Future<void> removeAppLimit(String userId, String packageName) async {
    try {
      await _getBlockedContentDoc(userId).update({
        'appLimits.$packageName': FieldValue.delete(),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error removing app limit: $e');
      rethrow;
    }
  }

  // Update app usage time
  Future<void> updateAppUsage(
    String userId,
    String packageName,
    int usedMinutesToday,
  ) async {
    try {
      await _getBlockedContentDoc(userId).update({
        'appLimits.$packageName.usedMinutesToday': usedMinutesToday,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error updating app usage: $e');
      rethrow;
    }
  }

  // Reset all app usage times (call this daily at midnight)
  Future<void> resetDailyUsage(String userId) async {
    try {
      final currentData = await getBlockedContent(userId);
      final appLimits = currentData?.appLimits ?? {};

      // Reset usage for each app
      final updates = <String, dynamic>{
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      };

      for (final packageName in appLimits.keys) {
        updates['appLimits.$packageName.usedMinutesToday'] = 0;
      }

      if (updates.length > 1) {
        await _getBlockedContentDoc(userId).update(updates);
      }
    } catch (e) {
      debugPrint('Error resetting daily usage: $e');
      rethrow;
    }
  }

  // Toggle app limit active status
  Future<void> toggleAppLimitStatus(
    String userId,
    String packageName,
    bool isActive,
  ) async {
    try {
      await _getBlockedContentDoc(userId).update({
        'appLimits.$packageName.isActive': isActive,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error toggling app limit status: $e');
      rethrow;
    }
  }

  // === BLOCKED WEBSITES ===

  // Add blocked website
  Future<void> addBlockedWebsite(String userId, BlockedWebsite website) async {
    try {
      final currentData = await getBlockedContent(userId);
      final currentWebsites = currentData?.blockedWebsites ?? [];

      // Check if website already exists
      final existingIndex = currentWebsites.indexWhere(
        (w) => w.url == website.url,
      );

      List<BlockedWebsite> updatedWebsites;
      if (existingIndex != -1) {
        // Update existing website
        updatedWebsites = List.from(currentWebsites);
        updatedWebsites[existingIndex] = website;
      } else {
        // Add new website
        updatedWebsites = [...currentWebsites, website];
      }

      await _getBlockedContentDoc(userId).update({
        'blockedWebsites': updatedWebsites.map((w) => w.toMap()).toList(),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error adding blocked website: $e');
      rethrow;
    }
  }

  // Remove blocked website
  Future<void> removeBlockedWebsite(String userId, String url) async {
    try {
      final currentData = await getBlockedContent(userId);
      final currentWebsites = currentData?.blockedWebsites ?? [];

      final updatedWebsites = currentWebsites
          .where((w) => w.url != url)
          .toList();

      await _getBlockedContentDoc(userId).update({
        'blockedWebsites': updatedWebsites.map((w) => w.toMap()).toList(),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error removing blocked website: $e');
      rethrow;
    }
  }

  // Set multiple blocked websites
  Future<void> setBlockedWebsites(
    String userId,
    List<BlockedWebsite> websites,
  ) async {
    try {
      await _getBlockedContentDoc(userId).update({
        'blockedWebsites': websites.map((w) => w.toMap()).toList(),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error setting blocked websites: $e');
      rethrow;
    }
  }

  // Toggle website block status
  Future<void> toggleWebsiteBlockStatus(
    String userId,
    String url,
    bool isActive,
  ) async {
    try {
      final currentData = await getBlockedContent(userId);
      final currentWebsites = currentData?.blockedWebsites ?? [];

      final updatedWebsites = currentWebsites.map((website) {
        if (website.url == url) {
          return BlockedWebsite(
            url: website.url,
            name: website.name,
            isActive: isActive,
          );
        }
        return website;
      }).toList();

      await _getBlockedContentDoc(userId).update({
        'blockedWebsites': updatedWebsites.map((w) => w.toMap()).toList(),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error toggling website block status: $e');
      rethrow;
    }
  }

  // === SHORT FORM BLOCKS ===

  // Add or update short form block
  Future<void> setShortFormBlock(String userId, ShortFormBlock block) async {
    try {
      final key = '${block.platform}_${block.feature}'.toLowerCase();

      debugPrint('🔄 Setting short form block:');
      debugPrint('   - Key: $key');
      debugPrint('   - Platform: ${block.platform}');
      debugPrint('   - Feature: ${block.feature}');
      debugPrint('   - Is Blocked: ${block.isBlocked}');

      // Use set with merge to create document if it doesn't exist
      await _getBlockedContentDoc(userId).set({
        'shortFormBlocks.$key': block.toMap(),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));

      debugPrint('✅ Short form block saved to Firebase');
    } catch (e) {
      debugPrint('❌ Error setting short form block: $e');
      rethrow;
    }
  }

  // Remove short form block
  Future<void> removeShortFormBlock(
    String userId,
    String platform,
    String feature,
  ) async {
    try {
      final key = '${platform}_$feature'.toLowerCase();

      await _getBlockedContentDoc(userId).update({
        'shortFormBlocks.$key': FieldValue.delete(),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error removing short form block: $e');
      rethrow;
    }
  }

  // Set multiple short form blocks
  Future<void> setShortFormBlocks(
    String userId,
    Map<String, ShortFormBlock> blocks,
  ) async {
    try {
      final blocksMap = blocks.map(
        (key, value) => MapEntry(key, value.toMap()),
      );

      await _getBlockedContentDoc(userId).update({
        'shortFormBlocks': blocksMap,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error setting short form blocks: $e');
      rethrow;
    }
  }

  // Toggle short form block status
  Future<void> toggleShortFormBlockStatus(
    String userId,
    String platform,
    String feature,
    bool isBlocked,
  ) async {
    try {
      final key = '${platform}_$feature';

      await _getBlockedContentDoc(userId).update({
        'shortFormBlocks.$key.isBlocked': isBlocked,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error toggling short form block status: $e');
      rethrow;
    }
  }

  // === UTILITY METHODS ===

  // Check if app limit is exceeded
  Future<bool> isAppLimitExceeded(String userId, String packageName) async {
    try {
      final blockedContent = await getBlockedContent(userId);
      return blockedContent?.isAppLimitExceeded(packageName) ?? false;
    } catch (e) {
      debugPrint('Error checking if app limit exceeded: $e');
      return false;
    }
  }

  // Check if website is blocked
  Future<bool> isWebsiteBlocked(String userId, String url) async {
    try {
      final blockedContent = await getBlockedContent(userId);
      return blockedContent?.isWebsiteBlocked(url) ?? false;
    } catch (e) {
      debugPrint('Error checking if website is blocked: $e');
      return false;
    }
  }

  // Check if short form is blocked
  Future<bool> isShortFormBlocked(
    String userId,
    String platform,
    String feature,
  ) async {
    try {
      final blockedContent = await getBlockedContent(userId);
      return blockedContent?.isShortFormBlocked(platform, feature) ?? false;
    } catch (e) {
      debugPrint('Error checking if short form is blocked: $e');
      return false;
    }
  }

  // Clear all blocked content for user (useful for logout)
  Future<void> clearBlockedContent(String userId) async {
    try {
      await _getBlockedContentDoc(userId).delete();
    } catch (e) {
      debugPrint('Error clearing blocked content: $e');
      rethrow;
    }
  }

  // Reset to default empty state
  Future<void> resetBlockedContent(String userId) async {
    try {
      final defaultContent = BlockedContentModel();
      await setBlockedContent(userId, defaultContent);
    } catch (e) {
      debugPrint('Error resetting blocked content: $e');
      rethrow;
    }
  }
}
