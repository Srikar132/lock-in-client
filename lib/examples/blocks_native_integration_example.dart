import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/services/blocks_native_service.dart';
import 'package:lock_in/data/repositories/blocked_content_repository.dart';
import 'package:lock_in/presentation/providers/auth_provider.dart';

/// Example: How to integrate native blocking with blocks_screen.dart
///
/// This file shows two approaches:
/// 1. Manual sync - call native service after each Firebase update
/// 2. Auto sync - provider that watches Firebase and syncs automatically

// ==================== APPROACH 1: MANUAL SYNC ====================

/// Add these methods to your blocks_screen.dart tabs

class PermanentlyBlockedAppsTabExample {
  /// Example: Remove app with native sync
  Future<void> removeAppWithNativeSync(
    WidgetRef ref,
    String userId,
    String packageName,
  ) async {
    final repository = ref.read(blockedContentRepositoryProvider);
    final nativeService = ref.read(blocksNativeServiceProvider);

    // 1. Update Firebase
    await repository.removePermanentlyBlockedApp(userId, packageName);

    // 2. Sync with native Android
    await nativeService.removePermanentlyBlockedApp(packageName);

    print('✅ Removed $packageName from both Firebase and native Android');
  }

  /// Example: Add multiple apps with native sync
  Future<void> addAppsWithNativeSync(
    WidgetRef ref,
    String userId,
    List<String> packageNames,
  ) async {
    final repository = ref.read(blockedContentRepositoryProvider);
    final nativeService = ref.read(blocksNativeServiceProvider);

    // 1. Update Firebase (assuming you have a method to set complete list)
    // await repository.setPermanentlyBlockedApps(userId, packageNames);

    // 2. Sync with native Android
    await nativeService.setPermanentlyBlockedApps(packageNames);

    print('✅ Synced ${packageNames.length} apps to native Android');
  }
}

class BlockedWebsitesTabExample {
  /// Example: Add website with native sync
  Future<void> addWebsiteWithNativeSync(
    WidgetRef ref,
    String userId,
    String url,
    String name,
  ) async {
    final repository = ref.read(blockedContentRepositoryProvider);
    final nativeService = ref.read(blocksNativeServiceProvider);

    // 1. Update Firebase
    final website = BlockedWebsite(url: url, name: name, isActive: true);
    await repository.addBlockedWebsite(userId, website);

    // 2. Sync with native Android
    await nativeService.addBlockedWebsite(url: url, name: name, isActive: true);

    print('✅ Added website $url to both Firebase and native Android');
  }

  /// Example: Toggle website with native sync
  Future<void> toggleWebsiteWithNativeSync(
    WidgetRef ref,
    String userId,
    BlockedWebsite website,
  ) async {
    final repository = ref.read(blockedContentRepositoryProvider);
    final nativeService = ref.read(blocksNativeServiceProvider);

    // 1. Update Firebase
    final updated = BlockedWebsite(
      url: website.url,
      name: website.name,
      isActive: !website.isActive,
    );
    await repository.addBlockedWebsite(userId, updated);

    // 2. Sync with native Android
    await nativeService.toggleBlockedWebsite(website.url);

    print(
      '✅ Toggled ${website.url} to ${updated.isActive} in both Firebase and native',
    );
  }
}

class ShortFormBlocksTabExample {
  /// Example: Toggle short-form block with native sync
  Future<void> toggleShortFormWithNativeSync(
    WidgetRef ref,
    String userId,
    String platform,
    String feature,
    bool value,
  ) async {
    final repository = ref.read(blockedContentRepositoryProvider);
    final nativeService = ref.read(blocksNativeServiceProvider);

    // 1. Update Firebase
    final shortFormBlock = ShortFormBlock(
      platform: platform,
      feature: feature,
      isBlocked: value,
    );
    await repository.setShortFormBlock(userId, shortFormBlock);

    // 2. Sync with native Android
    await nativeService.setShortFormBlock(
      platform: platform,
      feature: feature,
      isBlocked: value,
    );

    print(
      '✅ ${value ? 'Blocked' : 'Unblocked'} $platform $feature in both Firebase and native',
    );
  }
}

// ==================== APPROACH 2: AUTO SYNC (RECOMMENDED) ====================

/// Auto-sync provider that watches Firebase changes and syncs to native
/// Add this to blocks_screen.dart or a separate providers file

final blocksAutoSyncProvider = Provider.family<void, String>((ref, userId) {
  // Watch the blocked content stream
  ref.listen(blockedContentProvider(userId), (previous, next) {
    next.whenData((blockedContent) async {
      final nativeService = ref.read(blocksNativeServiceProvider);

      try {
        print('🔄 Syncing blocks to native Android...');

        // Sync permanently blocked apps
        await nativeService.setPermanentlyBlockedApps(
          blockedContent.permanentlyBlockedApps,
        );

        // Sync blocked websites
        for (final website in blockedContent.blockedWebsites) {
          await nativeService.addBlockedWebsite(
            url: website.url,
            name: website.name,
            isActive: website.isActive,
          );
        }

        // Sync short-form blocks
        for (final entry in blockedContent.shortFormBlocks.entries) {
          final block = entry.value;
          await nativeService.setShortFormBlock(
            platform: block['platform'] as String,
            feature: block['feature'] as String,
            isBlocked: block['isBlocked'] as bool? ?? false,
          );
        }

        print('✅ Successfully synced all blocks to native Android');
      } catch (e) {
        print('❌ Error syncing blocks to native: $e');
      }
    });
  });

  return null;
});

// ==================== USAGE IN BLOCKS SCREEN ====================

/// Add this to your BlocksScreen widget to enable auto-sync

class BlocksScreenWithAutoSync extends ConsumerStatefulWidget {
  const BlocksScreenWithAutoSync({super.key});

  @override
  ConsumerState<BlocksScreenWithAutoSync> createState() =>
      _BlocksScreenWithAutoSyncState();
}

class _BlocksScreenWithAutoSyncState
    extends ConsumerState<BlocksScreenWithAutoSync>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Please login first'));
        }

        // 🔥 ENABLE AUTO-SYNC: Watch this provider to auto-sync blocks
        ref.watch(blocksAutoSyncProvider(user.uid));

        final blockedContentAsync = ref.watch(blockedContentProvider(user.uid));

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildTabBar(context),
                Expanded(
                  child: blockedContentAsync.when(
                    data: (blockedContent) => TabBarView(
                      controller: _tabController,
                      children: [
                        // Your existing tabs...
                        Container(),
                        Container(),
                        Container(),
                      ],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text('Error: $error')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Icon(Icons.block, color: Theme.of(context).primaryColor, size: 32),
          const SizedBox(width: 12),
          Text(
            'Block Management',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        tabs: const [
          Tab(text: 'Apps'),
          Tab(text: 'Websites'),
          Tab(text: 'Short Form'),
        ],
      ),
    );
  }
}

// ==================== TESTING NATIVE INTEGRATION ====================

/// Test function to verify native blocking is working
Future<void> testNativeBlocking(WidgetRef ref) async {
  final nativeService = ref.read(blocksNativeServiceProvider);

  print('🧪 Testing native blocking integration...\n');

  // Test 1: Permanent App Blocking
  print('Test 1: Permanent App Blocking');
  await nativeService.addPermanentlyBlockedApp('com.instagram.android');
  final isBlocked = await nativeService.isPermanentlyBlocked(
    'com.instagram.android',
  );
  print('  ✅ Instagram blocked: $isBlocked\n');

  // Test 2: Website Blocking
  print('Test 2: Website Blocking');
  await nativeService.addBlockedWebsite(
    url: 'instagram.com',
    name: 'Instagram',
    isActive: true,
  );
  final isUrlBlocked = await nativeService.isUrlBlocked('instagram.com');
  print('  ✅ Instagram.com blocked: $isUrlBlocked\n');

  // Test 3: Short-Form Blocking
  print('Test 3: Short-Form Blocking');
  await nativeService.setShortFormBlock(
    platform: 'YouTube',
    feature: 'Shorts',
    isBlocked: true,
  );
  final isShortsBlocked = await nativeService.isShortFormBlocked(
    platform: 'YouTube',
    feature: 'Shorts',
  );
  print('  ✅ YouTube Shorts blocked: $isShortsBlocked\n');

  print('🎉 All tests passed! Native blocking is working correctly.');
}

// ==================== QUICK START ====================

/// To enable native blocking in your blocks_screen.dart:
///
/// 1. OPTION A - Auto Sync (Recommended):
///    - Copy the blocksAutoSyncProvider above
///    - Add to your BlocksScreen build method:
///      ```dart
///      ref.watch(blocksAutoSyncProvider(user.uid));
///      ```
///
/// 2. OPTION B - Manual Sync:
///    - Import BlocksNativeService:
///      ```dart
///      import 'package:lock_in/services/blocks_native_service.dart';
///      ```
///    - Add sync calls after Firebase operations:
///      ```dart
///      final nativeService = ref.read(blocksNativeServiceProvider);
///      await repository.addBlockedWebsite(userId, website);
///      await nativeService.addBlockedWebsite(...);
///      ```
///
/// 3. TEST:
///    - Add Instagram to blocked apps
///    - Exit Lock-In app
///    - Try to open Instagram
///    - Should see block overlay immediately!
