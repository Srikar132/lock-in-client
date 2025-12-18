import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/presentation/providers/auth_provider.dart';
import 'package:lock_in/presentation/providers/app_management_provide.dart';
import 'package:lock_in/data/repositories/blocked_content_repository.dart';
import 'package:lock_in/data/models/blocked_content_model.dart';
import 'package:lock_in/models/block_app_bottom_model.dart';
import 'package:lock_in/models/model_manager.dart';
import 'package:lock_in/services/blocks_native_service.dart';
import 'dart:async';

// Provider for blocked content repository
final blockedContentRepositoryProvider = Provider<BlockedContentRepository>((
  ref,
) {
  return BlockedContentRepository();
});

// Provider for blocked content stream
final blockedContentProvider =
    StreamProvider.family<BlockedContentModel, String>((ref, userId) {
      final repository = ref.read(blockedContentRepositoryProvider);
      return repository.getBlockedContentStream(userId);
    });

class BlocksScreen extends ConsumerStatefulWidget {
  const BlocksScreen({super.key});

  @override
  ConsumerState<BlocksScreen> createState() => _BlocksScreenState();
}

class _BlocksScreenState extends ConsumerState<BlocksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<Map<String, dynamic>>? _blockingEventsSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupBlockingEventListener();
  }

  void _setupBlockingEventListener() {
    try {
      final nativeService = ref.read(blocksNativeServiceProvider);
      _blockingEventsSubscription = nativeService.blockingEventsStream.listen(
        (event) {
          _handleBlockingEvent(event);
        },
        onError: (error) {
          print('Error listening to blocking events: $error');
        },
      );
    } catch (e) {
      print('Error setting up blocking event listener: $e');
    }
  }

  void _handleBlockingEvent(Map<String, dynamic> event) {
    try {
      final eventType = event['type'] as String?;

      if (eventType == 'website_blocked') {
        final url = event['url'] as String?;
        final appName = event['app_name'] as String?;

        if (url != null && mounted) {
          _showWebsiteBlockedSnackBar(url, appName ?? 'Browser');
        }
      }
    } catch (e) {
      print('Error handling blocking event: $e');
    }
  }

  void _showWebsiteBlockedSnackBar(String url, String appName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.block, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🚫 Website Blocked',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$url was blocked in $appName',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _blockingEventsSubscription?.cancel();
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
                        _AppLimitsTab(
                          userId: user.uid,
                          blockedContent: blockedContent,
                        ),
                        _BlockedWebsitesTab(
                          userId: user.uid,
                          blockedContent: blockedContent,
                        ),
                        _ShortFormBlocksTab(
                          userId: user.uid,
                          blockedContent: blockedContent,
                        ),
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
          Tab(text: 'App Limits'),
          Tab(text: 'Websites'),
          Tab(text: 'Short Form'),
        ],
      ),
    );
  }
}

// === APP LIMITS TAB ===
class _AppLimitsTab extends ConsumerWidget {
  final String userId;
  final BlockedContentModel blockedContent;

  const _AppLimitsTab({required this.userId, required this.blockedContent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installedAppsAsync = ref.watch(installedAppsProvider);
    final appLimits = blockedContent.appLimits;

    // Debug logging
    print('🔍 BlocksScreen Debug:');
    print('   - App limits count: ${appLimits.length}');
    print('   - App limits keys: ${appLimits.keys.toList()}');
    if (appLimits.isNotEmpty) {
      appLimits.forEach((key, value) {
        print('   - $key: ${value.dailyLimitMinutes} minutes');
      });
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        _buildAddButton(context, ref),
        const SizedBox(height: 16),
        Expanded(
          child: installedAppsAsync.when(
            data: (allApps) {
              if (appLimits.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.timer,
                  title: 'No App Limits Set',
                  subtitle: 'Set time limits for apps to control your usage',
                );
              }

              final appLimitsList = appLimits.entries.map((entry) {
                final app = allApps.firstWhere(
                  (a) => a.packageName == entry.key,
                  orElse: () => allApps.first,
                );
                return MapEntry(entry.key, {'app': app, 'limit': entry.value});
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: appLimitsList.length,
                itemBuilder: (context, index) {
                  final entry = appLimitsList[index];
                  final packageName = entry.key;
                  final appData = entry.value;
                  final app = appData['app'] as dynamic;
                  final limit = appData['limit'] as AppLimit;

                  return _buildAppLimitTile(
                    context,
                    ref,
                    packageName,
                    app.appName as String,
                    limit,
                    () => _removeAppLimit(ref, userId, packageName),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showAppLimitSheet(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Add App Time Limit'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _showAppLimitSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AppLimitSelectionSheet(
        userId: userId,
        existingLimits: blockedContent.appLimits,
      ),
    );
  }

  Future<void> _removeAppLimit(
    WidgetRef ref,
    String userId,
    String packageName,
  ) async {
    final repository = ref.read(blockedContentRepositoryProvider);
    final nativeService = ref.read(blocksNativeServiceProvider);

    try {
      // Remove from Firebase
      await repository.removeAppLimit(userId, packageName);

      // Remove from native service
      await nativeService.removeAppLimit(packageName);

      print('✅ App limit removed: $packageName');
    } catch (e) {
      print('❌ Error removing app limit: $e');
    }
  }

  Widget _buildAppLimitTile(
    BuildContext context,
    WidgetRef ref,
    String packageName,
    String appName,
    AppLimit limit,
    VoidCallback onRemove,
  ) {
    final iconAsync = ref.watch(appIconProvider(packageName));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: limit.hasExceededLimit
            ? Border.all(color: Colors.red, width: 2)
            : null,
      ),
      child: ListTile(
        leading: iconAsync.when(
          data: (iconBytes) {
            if (iconBytes != null) {
              return Image.memory(iconBytes, width: 40, height: 40);
            }
            return const Icon(Icons.android, size: 40, color: Colors.white);
          },
          loading: () => const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) =>
              const Icon(Icons.android, size: 40, color: Colors.white),
        ),
        title: Text(
          appName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Limit: ${limit.dailyLimitMinutes} min/day',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: limit.usagePercentage / 100,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        limit.hasExceededLimit
                            ? Colors.red
                            : Theme.of(context).primaryColor,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${limit.usedMinutesToday}/${limit.dailyLimitMinutes} min',
                  style: TextStyle(
                    color: limit.hasExceededLimit
                        ? Colors.red
                        : Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editAppLimit(context, ref, packageName, limit),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editAppLimit(
    BuildContext context,
    WidgetRef ref,
    String packageName,
    AppLimit currentLimit,
  ) async {
    final newMinutes = await showDialog<int>(
      context: context,
      builder: (context) =>
          _TimePickerDialog(currentMinutes: currentLimit.dailyLimitMinutes),
    );

    if (newMinutes != null && newMinutes != currentLimit.dailyLimitMinutes) {
      final repository = ref.read(blockedContentRepositoryProvider);
      final nativeService = ref.read(blocksNativeServiceProvider);
      final updatedLimit = currentLimit.copyWith(dailyLimitMinutes: newMinutes);

      try {
        // Update Firebase
        await repository.setAppLimit(userId, updatedLimit);

        // Update native service
        await nativeService.setAppLimit(
          packageName: packageName,
          limitMinutes: newMinutes,
        );

        print('✅ App limit updated: $packageName to $newMinutes minutes');
      } catch (e) {
        print('❌ Error updating app limit: $e');
      }
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// === BLOCKED WEBSITES TAB ===
class _BlockedWebsitesTab extends ConsumerStatefulWidget {
  final String userId;
  final BlockedContentModel blockedContent;

  const _BlockedWebsitesTab({
    required this.userId,
    required this.blockedContent,
  });

  @override
  ConsumerState<_BlockedWebsitesTab> createState() =>
      _BlockedWebsitesTabState();
}

class _BlockedWebsitesTabState extends ConsumerState<_BlockedWebsitesTab> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blockedWebsites = widget.blockedContent.blockedWebsites;

    return Column(
      children: [
        const SizedBox(height: 16),
        _buildAddWebsiteForm(context),
        const SizedBox(height: 12),
        _buildDiagnosticsButton(context),
        const SizedBox(height: 16),
        Expanded(
          child: blockedWebsites.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: blockedWebsites.length,
                  itemBuilder: (context, index) {
                    final website = blockedWebsites[index];
                    return _buildWebsiteTile(context, website);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDiagnosticsButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _runWebsiteBlockingDiagnostics(context),
          icon: const Icon(Icons.bug_report, color: Colors.white),
          label: const Text(
            'Run Website Blocking Diagnostics',
            style: TextStyle(color: Colors.white),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _runWebsiteBlockingDiagnostics(BuildContext context) async {
    try {
      final nativeService = ref.read(blocksNativeServiceProvider);

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔍 Running website blocking diagnostics...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Get diagnostics
      final diagnostics = await nativeService.getWebsiteBlockingDiagnostics();
      final supportedBrowsers = await nativeService.getSupportedBrowsers();

      final result = StringBuffer();
      result.writeln('🔍 Website Blocking Diagnostics\n');

      // Service status
      final accessibilityEnabled =
          diagnostics['accessibilityServiceEnabled'] as bool? ?? false;
      final serviceRunning = diagnostics['serviceRunning'] as bool? ?? false;

      if (!accessibilityEnabled) {
        result.writeln('🚨 CRITICAL ISSUE:');
        result.writeln('❌ Accessibility Service: DISABLED');
        result.writeln('');
        result.writeln('Website blocking requires accessibility service.');
        result.writeln('Please enable it by following these steps:');
        result.writeln('');
        result.writeln('📱 STEP-BY-STEP GUIDE:');
        result.writeln('1. Go to Settings → Accessibility');
        result.writeln('2. Find "LockIn" in the service list');
        result.writeln('3. Tap on "LockIn"');
        result.writeln('4. Turn the toggle ON');
        result.writeln('5. Grant permissions when prompted');
        result.writeln('');
        result.writeln('💡 TIP: After enabling, return to LockIn');
        result.writeln('and run diagnostics again to verify!');
        result.writeln('');
      } else {
        result.writeln('✅ Accessibility Service: ENABLED');
        result.writeln('✅ Service Running: ${serviceRunning ? "YES" : "NO"}');
      }

      // Active blocked websites
      final activeWebsites =
          diagnostics['activeBlockedWebsites'] as List? ?? [];
      result.writeln('');
      result.writeln('🚫 Active Blocked Websites: ${activeWebsites.length}');
      if (activeWebsites.isNotEmpty) {
        for (final website in activeWebsites) {
          final url = website['url'] ?? 'Unknown URL';
          final name = website['name'] ?? 'Unknown Name';
          result.writeln('  • $name ($url)');
        }
      } else {
        result.writeln('  ⚠️ No websites are currently blocked');
      }

      // Supported browsers
      result.writeln('');
      result.writeln('🌐 Installed Supported Browsers:');
      if (supportedBrowsers.isNotEmpty) {
        for (final browser in supportedBrowsers) {
          result.writeln('  ✅ $browser');
        }
      } else {
        result.writeln('  ❌ No supported browsers found');
      }

      // Testing instructions
      result.writeln('');
      result.writeln('🧪 Testing Instructions:');
      result.writeln('');
      result.writeln('1. Add a website to block (e.g., "facebook.com")');
      result.writeln('2. Open any supported browser');
      result.writeln('3. Navigate to the blocked website');
      result.writeln('4. You should see:');
      result.writeln('   • Blocking overlay appears');
      result.writeln('   • Browser navigates back automatically');
      result.writeln('   • OR tab closes');
      result.writeln('   • OR address bar clears');
      result.writeln('');

      if (!accessibilityEnabled) {
        result.writeln('💡 Next Steps:');
        result.writeln('1. Enable Accessibility Service first');
        result.writeln('2. Add websites to block');
        result.writeln('3. Test in any supported browser');
      } else if (activeWebsites.isEmpty) {
        result.writeln('💡 Next Steps:');
        result.writeln('1. Add at least one website to block');
        result.writeln('2. Open a browser and navigate to that website');
        result.writeln('3. Blocking should activate automatically');
      } else {
        result.writeln('🔧 Troubleshooting Tips:');
        result.writeln('• Force close browser before testing');
        result.writeln('• Try different browsers for comparison');
        result.writeln('• Check if website URL matches exactly');
        result.writeln('• Look for notification when blocking activates');
      }

      // Show results
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text(
              'Website Blocking Diagnostics',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Text(
                result.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ Diagnostics error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error running diagnostics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAddWebsiteForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Website Name (e.g., Instagram)',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(
                Icons.label,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'URL (e.g., instagram.com)',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(
                Icons.link,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addWebsite,
              icon: const Icon(Icons.add),
              label: const Text('Add Website'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addWebsite() async {
    if (_urlController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both fields')),
      );
      return;
    }

    final repository = ref.read(blockedContentRepositoryProvider);
    final nativeService = ref.read(blocksNativeServiceProvider);
    final newWebsite = BlockedWebsite(
      url: _urlController.text.trim(),
      name: _nameController.text.trim(),
    );

    try {
      // Save to Firebase
      await repository.addBlockedWebsite(widget.userId, newWebsite);

      // Enforce blocking via native service
      await nativeService.addBlockedWebsite(
        url: newWebsite.url,
        name: newWebsite.name,
        isActive: newWebsite.isActive,
      );

      _urlController.clear();
      _nameController.clear();
      FocusScope.of(context).unfocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Website blocked successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error adding blocked website: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error blocking website: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeWebsite(String url) async {
    final repository = ref.read(blockedContentRepositoryProvider);
    final nativeService = ref.read(blocksNativeServiceProvider);

    try {
      // Remove from Firebase
      await repository.removeBlockedWebsite(widget.userId, url);

      // Remove from native service
      await nativeService.removeBlockedWebsite(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Website unblocked'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error removing blocked website: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error unblocking website: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleWebsite(BlockedWebsite website) async {
    final repository = ref.read(blockedContentRepositoryProvider);
    final nativeService = ref.read(blocksNativeServiceProvider);
    final updated = BlockedWebsite(
      url: website.url,
      name: website.name,
      isActive: !website.isActive,
    );

    try {
      // Update Firebase
      await repository.addBlockedWebsite(widget.userId, updated);

      // Update native service
      await nativeService.addBlockedWebsite(
        url: updated.url,
        name: updated.name,
        isActive: updated.isActive,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updated.isActive
                  ? 'Website blocking enabled'
                  : 'Website blocking disabled',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error toggling website block: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error toggling website: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildWebsiteTile(BuildContext context, BlockedWebsite website) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          Icons.language,
          color: website.isActive
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
        title: Text(
          website.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          website.url,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: website.isActive,
              onChanged: (_) => _toggleWebsite(website),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeWebsite(website.url),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.language, size: 80, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 20),
          const Text(
            'No Blocked Websites',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add websites that you want to block',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// === SHORT FORM BLOCKS TAB ===
class _ShortFormBlocksTab extends ConsumerStatefulWidget {
  final String userId;
  final BlockedContentModel blockedContent;

  const _ShortFormBlocksTab({
    required this.userId,
    required this.blockedContent,
  });

  @override
  ConsumerState<_ShortFormBlocksTab> createState() =>
      _ShortFormBlocksTabState();
}

class _ShortFormBlocksTabState extends ConsumerState<_ShortFormBlocksTab> {
  static final List<Map<String, dynamic>> _shortFormPlatforms = [
    {'platform': 'YouTube', 'feature': 'Shorts', 'icon': Icons.video_library},
    {'platform': 'Instagram', 'feature': 'Reels', 'icon': Icons.camera_alt},
    {
      'platform': 'Facebook',
      'feature': 'Reels',
      'icon': Icons.video_collection,
    },
    {'platform': 'Snapchat', 'feature': 'Stories', 'icon': Icons.flash_on},
    {'platform': 'TikTok', 'feature': 'Videos', 'icon': Icons.music_note},
  ];

  // Local state for optimistic UI updates
  final Map<String, bool> _pendingToggles = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildInfoCard(context),
        const SizedBox(height: 12),
        _buildDiagnosticsButton(context),
        const SizedBox(height: 8),
        _buildBulkActions(context, ref),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _shortFormPlatforms.length,
            itemBuilder: (context, index) {
              final platform = _shortFormPlatforms[index];
              final key = '${platform['platform']}_${platform['feature']}'
                  .toLowerCase();
              final shortFormBlock = widget.blockedContent.shortFormBlocks[key];

              // Debug logging
              if (platform['platform'] == 'YouTube') {
                print('🟡 YouTube toggle debug:');
                print('   Key: $key');
                print('   shortFormBlock: $shortFormBlock');
                print('   isBlocked from block: ${shortFormBlock?.isBlocked}');
                print('   pending toggle: ${_pendingToggles[key]}');
                print('   has pending: ${_pendingToggles.containsKey(key)}');
              }

              // Use pending toggle if available, otherwise use Firebase data
              final isBlocked = _pendingToggles.containsKey(key)
                  ? _pendingToggles[key]!
                  : (shortFormBlock?.isBlocked ?? false);

              if (platform['platform'] == 'YouTube') {
                print('   Final isBlocked value: $isBlocked');
              }

              return _buildShortFormTile(
                context,
                ref,
                platform['platform'] as String,
                platform['feature'] as String,
                platform['icon'] as IconData,
                isBlocked,
                key,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosticsButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _runDiagnostics(context),
          icon: const Icon(Icons.bug_report, size: 18),
          label: const Text('Run Diagnostics'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
          ),
        ),
      ),
    );
  }

  Future<void> _runDiagnostics(BuildContext context) async {
    try {
      final nativeService = ref.read(blocksNativeServiceProvider);

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Running diagnostics...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Check accessibility service
      final accessibilityEnabled = await nativeService
          .isAccessibilityServiceEnabled();

      // Get current blocks
      final blocks = await nativeService.getShortFormBlocks();

      // Get blocking status
      final status = await nativeService.getShortFormBlockingStatus();

      final result = StringBuffer();
      result.writeln('🔍 Short-Form Blocking Diagnostics\n');

      if (!accessibilityEnabled) {
        result.writeln('🚨 CRITICAL ISSUE:');
        result.writeln('❌ Accessibility Service: DISABLED');
        result.writeln('');
        result.writeln(
          'Short-form blocking CANNOT work without accessibility service.',
        );
        result.writeln('Please enable it by:');
        result.writeln('1. Go to Settings → Accessibility');
        result.writeln('2. Find "LockIn" service');
        result.writeln('3. Turn it ON');
        result.writeln('');
      } else {
        result.writeln('✅ Accessibility Service: ENABLED');
      }

      // Add platform-specific instructions
      result.writeln('📱 Platform-Specific Instructions:');
      result.writeln('');
      result.writeln('📺 YouTube Shorts:');
      result.writeln('  • Open YouTube → Go to Shorts');
      result.writeln('  • Should show overlay and navigate to Home');
      result.writeln('  • Force close YouTube if not working');
      result.writeln('');
      result.writeln('📸 Instagram Reels:');
      result.writeln('  • Open Instagram → Tap Reels icon');
      result.writeln('  • Should show blocking overlay');
      result.writeln('  • Force close Instagram if not working');
      result.writeln('  • Clear Instagram cache if issues persist');
      result.writeln('');

      result.writeln('Active Blocks: ${blocks.length}');

      if (blocks.isNotEmpty) {
        result.writeln('\nActive Blocks:');
        for (final block in blocks) {
          result.writeln(
            '  • ${block['platform']} ${block['feature']}: ${block['isBlocked']}',
          );
        }
      } else {
        result.writeln('\n⚠️  No blocks are currently active');
      }

      if (status.isNotEmpty) {
        result.writeln('\nDetailed Status:');
        status.forEach((key, value) {
          final emoji = value == true ? '✅' : '❌';
          result.writeln('  $emoji $key: $value');
        });
      }

      if (!accessibilityEnabled) {
        result.writeln('\n💡 Next Steps:');
        result.writeln('1. Enable Accessibility Service first');
        result.writeln('2. Toggle desired platforms ON:');
        result.writeln('   • YouTube Shorts: Test with YouTube app');
        result.writeln('   • Instagram Reels: Test with Instagram app');
        result.writeln('3. Force close target apps');
        result.writeln('4. Open apps and navigate to short-form content');
      } else {
        result.writeln('\n🧪 Testing Instructions:');
        result.writeln('');
        result.writeln('For YouTube Shorts:');
        result.writeln('1. Open YouTube → Shorts tab');
        result.writeln('2. Should see overlay + auto-navigate to Home');
        result.writeln('');
        result.writeln('For Instagram Reels:');
        result.writeln('1. Open Instagram → Reels tab (bottom)');
        result.writeln('2. Should see blocking overlay');
        result.writeln('3. Try accessing via Explore → Reels section');
        result.writeln('');
        result.writeln('🔧 Troubleshooting:');
        result.writeln('• Force close apps between tests');
        result.writeln('• Clear app cache if blocking inconsistent');
        result.writeln('• Restart device if accessibility issues');
      }

      // Show results
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              'Diagnostics Results',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Text(
                result.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ Diagnostics error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Diagnostics failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoCard(BuildContext context) {
    // Check if Instagram is blocked for special message
    final instagramBlock =
        widget.blockedContent.shortFormBlocks['instagram_reels'];
    final isInstagramBlocked = instagramBlock?.isBlocked ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Block addictive short-form content across apps to reduce distractions',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                  if (isInstagramBlocked) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📸', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            'Instagram Reels blocked',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkActions(BuildContext context, WidgetRef ref) {
    final allBlocked = _shortFormPlatforms.every((platform) {
      final key = '${platform['platform']}_${platform['feature']}'
          .toLowerCase();
      final shortFormBlock = widget.blockedContent.shortFormBlocks[key];
      return shortFormBlock?.isBlocked ?? false;
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _bulkToggle(context, ref, false),
              icon: const Icon(Icons.block, size: 18),
              label: const Text('Block All'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _bulkToggle(context, ref, true),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Unblock All'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkToggle(
    BuildContext context,
    WidgetRef ref,
    bool unblock,
  ) async {
    final shouldBlock = !unblock;

    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              shouldBlock
                  ? 'Blocking all platforms...'
                  : 'Unblocking all platforms...',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // Toggle all platforms
      for (final platform in _shortFormPlatforms) {
        await _toggleShortForm(
          ref,
          platform['platform'] as String,
          platform['feature'] as String,
          shouldBlock,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              shouldBlock
                  ? 'All short-form content blocked'
                  : 'All short-form content unblocked',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error in bulk toggle: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating blocks: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildShortFormTile(
    BuildContext context,
    WidgetRef ref,
    String platform,
    String feature,
    IconData icon,
    bool isBlocked,
    String key,
  ) {
    final isPending = _pendingToggles.containsKey(key);
    final effectiveBlocked = isPending ? _pendingToggles[key]! : isBlocked;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(effectiveBlocked ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: effectiveBlocked
              ? Theme.of(context).primaryColor.withOpacity(0.7)
              : Colors.transparent,
          width: effectiveBlocked ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            icon,
            color: effectiveBlocked
                ? Theme.of(context).primaryColor
                : Colors.grey,
            size: 32,
          ),
        ),
        title: Text(
          platform,
          style: TextStyle(
            color: effectiveBlocked
                ? Colors.white
                : Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              'Block $feature',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            if (isPending) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
            ],
          ],
        ),
        trailing: Switch(
          value: effectiveBlocked,
          onChanged: isPending
              ? null
              : (value) => _handleToggleShortForm(
                  context,
                  ref,
                  platform,
                  feature,
                  value,
                  key,
                ),
          activeColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Future<void> _handleToggleShortForm(
    BuildContext context,
    WidgetRef ref,
    String platform,
    String feature,
    bool value,
    String key,
  ) async {
    // Prevent multiple simultaneous toggles
    if (_pendingToggles.containsKey(key)) {
      print('⚠️ Toggle already in progress for $key');
      return;
    }

    // Optimistically update UI with animation
    setState(() {
      _pendingToggles[key] = value;
    });

    // Show immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value
                  ? 'Enabling $platform $feature blocking...'
                  : 'Disabling $platform $feature blocking...',
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      await _toggleShortForm(ref, platform, feature, value);

      if (mounted) {
        // Clear pending toggle after successful update
        setState(() {
          _pendingToggles.remove(key);
        });

        final platformEmoji = _getPlatformEmoji(platform);
        final actionText = _getActionText(platform, feature, value);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  value ? Icons.block : Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('$platformEmoji $actionText'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error in _handleToggleShortForm: $e');

      if (mounted) {
        // Revert the optimistic update on error
        setState(() {
          _pendingToggles.remove(key);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to toggle $platform $feature: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleToggleShortForm(
                context,
                ref,
                platform,
                feature,
                value,
                key,
              ),
            ),
          ),
        );
      }
    }
  }

  String _getPlatformEmoji(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return '📺';
      case 'instagram':
        return '📸';
      case 'facebook':
        return '📘';
      case 'snapchat':
        return '👻';
      case 'tiktok':
        return '🎵';
      default:
        return '📱';
    }
  }

  String _getActionText(String platform, String feature, bool isBlocked) {
    if (isBlocked) {
      switch (platform.toLowerCase()) {
        case 'instagram':
          return 'Instagram Reels are now blocked! Force close Instagram for immediate effect.';
        case 'youtube':
          return 'YouTube Shorts are now blocked! Auto-navigation to Home enabled.';
        default:
          return '$platform $feature are now blocked!';
      }
    } else {
      return '$platform $feature are now unblocked';
    }
  }

  Future<void> _toggleShortForm(
    WidgetRef ref,
    String platform,
    String feature,
    bool value,
  ) async {
    final repository = ref.read(blockedContentRepositoryProvider);
    final nativeService = ref.read(blocksNativeServiceProvider);

    final shortFormBlock = ShortFormBlock(
      platform: platform,
      feature: feature,
      isBlocked: value,
    );

    print('🔄 Starting toggle for $platform $feature to $value');

    try {
      // Update Firebase first
      print('   📤 Updating Firebase...');
      await repository.setShortFormBlock(widget.userId, shortFormBlock);
      print('   ✅ Firebase updated successfully');

      // Update native service
      print('   📤 Updating native service...');
      print(
        '   📋 Sending parameters: platform="$platform", feature="$feature", isBlocked=$value',
      );
      final nativeResult = await nativeService.setShortFormBlock(
        platform: platform,
        feature: feature,
        isBlocked: value,
      );

      if (nativeResult) {
        print('   ✅ Native service updated successfully');
        print(
          '   💡 Short-form content blocking is now ${value ? "ENABLED" : "DISABLED"} for $platform $feature',
        );
        print(
          '   💡 Note: You may need to restart the target app for blocking to take effect',
        );
      } else {
        print(
          '   ❌ Native service returned false - blocking may not be working',
        );
        throw Exception('Native service failed to set short-form block');
      }
    } catch (e) {
      print('❌ Error toggling short-form block: $e');
      print('   Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
}

// === APP LIMIT SELECTION SHEET ===
class _AppLimitSelectionSheet extends ConsumerStatefulWidget {
  final String userId;
  final Map<String, AppLimit> existingLimits;

  const _AppLimitSelectionSheet({
    required this.userId,
    required this.existingLimits,
  });

  @override
  ConsumerState<_AppLimitSelectionSheet> createState() =>
      _AppLimitSelectionSheetState();
}

class _AppLimitSelectionSheetState
    extends ConsumerState<_AppLimitSelectionSheet> {
  String _searchQuery = '';
  String? _selectedPackage;
  int _selectedMinutes = 30;

  @override
  Widget build(BuildContext context) {
    final installedAppsAsync = ref.watch(installedAppsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTimeLimitSelector(),
          _buildSearchBar(),
          Expanded(
            child: installedAppsAsync.when(
              data: (apps) => _buildAppList(apps),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Set App Time Limit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLimitSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Text(
              'Daily Limit:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.white,
              ),
              onPressed: () {
                if (_selectedMinutes > 5) {
                  setState(() => _selectedMinutes -= 5);
                }
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_selectedMinutes min',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              onPressed: () {
                setState(() => _selectedMinutes += 5);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search apps...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildAppList(List<dynamic> apps) {
    final filteredApps = apps.where((app) {
      final packageName = (app as dynamic).packageName as String;
      final appName = (app as dynamic).appName as String;
      if (widget.existingLimits.containsKey(packageName)) return false;
      if (_searchQuery.isEmpty) return true;
      return appName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredApps.length,
      itemBuilder: (context, index) {
        final app = filteredApps[index];
        final isSelected =
            _selectedPackage == (app as dynamic).packageName as String;

        return _buildAppItem(app, isSelected);
      },
    );
  }

  Widget _buildAppItem(dynamic app, bool isSelected) {
    final iconAsync = ref.watch(
      appIconProvider((app as dynamic).packageName as String),
    );

    return GestureDetector(
      onTap: () => setState(
        () => _selectedPackage = (app as dynamic).packageName as String,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
              : null,
        ),
        child: Row(
          children: [
            iconAsync.when(
              data: (iconBytes) {
                if (iconBytes != null) {
                  return Image.memory(iconBytes, width: 40, height: 40);
                }
                return const Icon(Icons.android, size: 40, color: Colors.white);
              },
              loading: () => const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) =>
                  const Icon(Icons.android, size: 40, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                (app as dynamic).appName as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _selectedPackage != null ? _saveAppLimit : null,
              child: const Text('Set Limit'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAppLimit() async {
    if (_selectedPackage == null) return;

    final repository = ref.read(blockedContentRepositoryProvider);
    final nativeService = ref.read(blocksNativeServiceProvider);

    final appLimit = AppLimit(
      packageName: _selectedPackage!,
      dailyLimitMinutes: _selectedMinutes,
      usedMinutesToday: 0,
      isActive: true,
    );

    print('💾 Saving app limit:');
    print('   - Package: ${appLimit.packageName}');
    print('   - Limit: ${appLimit.dailyLimitMinutes} minutes');
    print('   - User ID: ${widget.userId}');

    try {
      await repository.setAppLimit(widget.userId, appLimit);
      print('✅ Firebase save successful');

      await nativeService.setAppLimit(
        packageName: _selectedPackage!,
        limitMinutes: _selectedMinutes,
      );
      print('✅ Native service save successful');
    } catch (e) {
      print('❌ Error saving app limit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting limit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Time limit set to $_selectedMinutes minutes'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// === TIME PICKER DIALOG ===
class _TimePickerDialog extends StatefulWidget {
  final int currentMinutes;

  const _TimePickerDialog({required this.currentMinutes});

  @override
  State<_TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _minutes = widget.currentMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text(
        'Edit Time Limit',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove_circle,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  if (_minutes > 5) {
                    setState(() => _minutes -= 5);
                  }
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_minutes min',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  setState(() => _minutes += 5);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Daily time limit',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _minutes),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
