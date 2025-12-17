import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/data/models/blocked_content_model.dart';
import 'package:lock_in/data/repositories/blocked_content_repository.dart';

// ============================================================================
// REPOSITORY PROVIDER
// ============================================================================
final blockedContentRepositoryProvider = Provider<BlockedContentRepository>((ref) {
  return BlockedContentRepository();
});

// ============================================================================
// STREAM PROVIDER (Auto-cached by Firebase)
// ============================================================================

// Stream blocked content for a user
final blockedContentProvider = StreamProvider.family<BlockedContentModel, String>(
  (ref, userId) {
    return ref.watch(blockedContentRepositoryProvider).getBlockedContentStream(userId);
  },
);

// ============================================================================
// FUTURE PROVIDER
// ============================================================================

// Get blocked content (one-time fetch)
final fetchBlockedContentProvider = FutureProvider.family<BlockedContentModel?, String>(
  (ref, userId) async {
    return ref.watch(blockedContentRepositoryProvider).getBlockedContent(userId);
  },
);

// ============================================================================
// STATE NOTIFIER FOR BLOCKED CONTENT OPERATIONS
// ============================================================================

class BlockedContentNotifier extends Notifier<AsyncValue<void>> {
  late final BlockedContentRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.read(blockedContentRepositoryProvider);
    return const AsyncValue.data(null);
  }

  // Set or update blocked content
  Future<void> setBlockedContent(
    String userId,
    BlockedContentModel blockedContent,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.setBlockedContent(userId, blockedContent);
      debugPrint('✅ Blocked content updated');
    });
  }

  // Update specific fields
  Future<void> updateBlockedContent(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateBlockedContent(userId, updates);
      debugPrint('✅ Blocked content fields updated');
    });
  }

  // === PERMANENTLY BLOCKED APPS ===

  Future<void> addPermanentlyBlockedApp(String userId, String packageName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.addPermanentlyBlockedApp(userId, packageName);
      debugPrint('✅ App permanently blocked: $packageName');
    });
  }

  Future<void> removePermanentlyBlockedApp(String userId, String packageName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.removePermanentlyBlockedApp(userId, packageName);
      debugPrint('✅ App unblocked: $packageName');
    });
  }

  Future<void> setPermanentlyBlockedApps(
    String userId,
    List<String> packageNames,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.setPermanentlyBlockedApps(userId, packageNames);
      debugPrint('✅ ${packageNames.length} apps permanently blocked');
    });
  }

  // === BLOCKED WEBSITES ===

  Future<void> addBlockedWebsite(String userId, BlockedWebsite website) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.addBlockedWebsite(userId, website);
      debugPrint('✅ Website blocked: ${website.url}');
    });
  }

  Future<void> removeBlockedWebsite(String userId, String url) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.removeBlockedWebsite(userId, url);
      debugPrint('✅ Website unblocked: $url');
    });
  }

  Future<void> setBlockedWebsites(
    String userId,
    List<BlockedWebsite> websites,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.setBlockedWebsites(userId, websites);
      debugPrint('✅ ${websites.length} websites blocked');
    });
  }

  Future<void> toggleWebsiteBlockStatus(
    String userId,
    String url,
    bool isActive,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.toggleWebsiteBlockStatus(userId, url, isActive);
      debugPrint('✅ Website block status toggled: $url -> $isActive');
    });
  }

  // === SHORT FORM BLOCKS ===

  Future<void> setShortFormBlock(String userId, ShortFormBlock block) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.setShortFormBlock(userId, block);
      debugPrint('✅ Short form blocked: ${block.platform} ${block.feature}');
    });
  }

  Future<void> removeShortFormBlock(
    String userId,
    String platform,
    String feature,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.removeShortFormBlock(userId, platform, feature);
      debugPrint('✅ Short form unblocked: $platform $feature');
    });
  }

  Future<void> setShortFormBlocks(
    String userId,
    Map<String, ShortFormBlock> blocks,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.setShortFormBlocks(userId, blocks);
      debugPrint('✅ ${blocks.length} short forms blocked');
    });
  }

  Future<void> toggleShortFormBlockStatus(
    String userId,
    String platform,
    String feature,
    bool isBlocked,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.toggleShortFormBlockStatus(
        userId,
        platform,
        feature,
        isBlocked,
      );
      debugPrint('✅ Short form block toggled: $platform $feature -> $isBlocked');
    });
  }

  // === UTILITY METHODS ===

  Future<void> clearBlockedContent(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.clearBlockedContent(userId);
      debugPrint('✅ All blocked content cleared');
    });
  }

  Future<void> resetBlockedContent(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.resetBlockedContent(userId);
      debugPrint('✅ Blocked content reset to default');
    });
  }
}

// Notifier Provider
final blockedContentNotifierProvider = NotifierProvider<BlockedContentNotifier, AsyncValue<void>>(() {
  return BlockedContentNotifier();
});

// ============================================================================
// DERIVED PROVIDERS (Computed values)
// ============================================================================

// Get permanently blocked apps list
final permanentlyBlockedAppsProvider = Provider.family<List<String>, String>((ref, userId) {
  final blockedContentAsync = ref.watch(blockedContentProvider(userId));
  return blockedContentAsync.maybeWhen(
    data: (content) => content.permanentlyBlockedApps,
    orElse: () => [],
  );
});

// Get blocked websites list
final blockedWebsitesProvider = Provider.family<List<BlockedWebsite>, String>((ref, userId) {
  final blockedContentAsync = ref.watch(blockedContentProvider(userId));
  return blockedContentAsync.maybeWhen(
    data: (content) => content.blockedWebsites,
    orElse: () => [],
  );
});

// Get short form blocks map
final shortFormBlocksProvider = Provider.family<Map<String, ShortFormBlock>, String>((ref, userId) {
  final blockedContentAsync = ref.watch(blockedContentProvider(userId));
  return blockedContentAsync.maybeWhen(
    data: (content) => content.shortFormBlocks,
    orElse: () => {},
  );
});

// Check if specific app is blocked
final isAppBlockedProvider = Provider.family<bool, ({String userId, String packageName})>((ref, params) {
  final blockedApps = ref.watch(permanentlyBlockedAppsProvider(params.userId));
  return blockedApps.contains(params.packageName);
});

// Check if specific website is blocked
final isWebsiteBlockedProvider = Provider.family<bool, ({String userId, String url})>((ref, params) {
  final websites = ref.watch(blockedWebsitesProvider(params.userId));
  return websites.any((w) => w.isActive && w.url.contains(params.url));
});

// Check if specific short form is blocked
final isShortFormBlockedProvider = Provider.family<bool, ({String userId, String platform, String feature})>((ref, params) {
  final shortForms = ref.watch(shortFormBlocksProvider(params.userId));
  final key = '${params.platform}_${params.feature}';
  return shortForms[key]?.isBlocked ?? false;
});

// Get counts
final blockedAppsCountProvider = Provider.family<int, String>((ref, userId) {
  final blockedApps = ref.watch(permanentlyBlockedAppsProvider(userId));
  return blockedApps.length;
});

final blockedWebsitesCountProvider = Provider.family<int, String>((ref, userId) {
  final websites = ref.watch(blockedWebsitesProvider(userId));
  return websites.where((w) => w.isActive).length;
});

final blockedShortFormsCountProvider = Provider.family<int, String>((ref, userId) {
  final shortForms = ref.watch(shortFormBlocksProvider(userId));
  return shortForms.values.where((b) => b.isBlocked).length;
});

// Get total blocked content count
final totalBlockedContentCountProvider = Provider.family<int, String>((ref, userId) {
  final appsCount = ref.watch(blockedAppsCountProvider(userId));
  final websitesCount = ref.watch(blockedWebsitesCountProvider(userId));
  final shortFormsCount = ref.watch(blockedShortFormsCountProvider(userId));
  return appsCount + websitesCount + shortFormsCount;
});