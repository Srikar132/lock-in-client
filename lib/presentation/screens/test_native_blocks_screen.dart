import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/services/blocks_native_service.dart';

/// Debug screen to test native blocks implementation
///
/// To use: Add this screen to your navigation for testing
class TestNativeBlocksScreen extends ConsumerStatefulWidget {
  const TestNativeBlocksScreen({super.key});

  @override
  ConsumerState<TestNativeBlocksScreen> createState() =>
      _TestNativeBlocksScreenState();
}

class _TestNativeBlocksScreenState
    extends ConsumerState<TestNativeBlocksScreen> {
  String _testResults = '';
  bool _isTesting = false;

  void _log(String message) {
    setState(() {
      _testResults += '$message\n';
    });
    print(message);
  }

  Future<void> _runAllTests() async {
    setState(() {
      _testResults = '';
      _isTesting = true;
    });

    final nativeService = ref.read(blocksNativeServiceProvider);

    _log('🧪 Starting Native Blocks Tests...\n');

    try {
      // Test 1: Permanent App Blocking
      _log('📱 Test 1: Permanent App Blocking');
      await nativeService.addPermanentlyBlockedApp('com.instagram.android');
      final isBlocked = await nativeService.isPermanentlyBlocked(
        'com.instagram.android',
      );
      _log('  ✅ Add Instagram: ${isBlocked ? "SUCCESS" : "FAILED"}');

      final blockedApps = await nativeService.getPermanentlyBlockedApps();
      _log('  ℹ️ Total blocked apps: ${blockedApps.length}');
      _log('  ℹ️ Apps: ${blockedApps.join(", ")}\n');

      // Test 2: Website Blocking
      _log('🌐 Test 2: Website Blocking');
      await nativeService.addBlockedWebsite(
        url: 'instagram.com',
        name: 'Instagram',
        isActive: true,
      );
      final isUrlBlocked = await nativeService.isUrlBlocked('instagram.com');
      _log('  ✅ Block instagram.com: ${isUrlBlocked ? "SUCCESS" : "FAILED"}');

      final websites = await nativeService.getBlockedWebsites();
      _log('  ℹ️ Total blocked websites: ${websites.length}\n');

      // Test 3: Short-Form Blocking
      _log('📹 Test 3: Short-Form Content Blocking');
      await nativeService.setShortFormBlock(
        platform: 'YouTube',
        feature: 'Shorts',
        isBlocked: true,
      );
      final isShortsBlocked = await nativeService.isShortFormBlocked(
        platform: 'YouTube',
        feature: 'Shorts',
      );
      _log(
        '  ✅ Block YouTube Shorts: ${isShortsBlocked ? "SUCCESS" : "FAILED"}',
      );

      await nativeService.setShortFormBlock(
        platform: 'Instagram',
        feature: 'Reels',
        isBlocked: true,
      );
      final isReelsBlocked = await nativeService.isShortFormBlocked(
        platform: 'Instagram',
        feature: 'Reels',
      );
      _log(
        '  ✅ Block Instagram Reels: ${isReelsBlocked ? "SUCCESS" : "FAILED"}',
      );

      final shortFormBlocks = await nativeService.getShortFormBlocks();
      _log('  ℹ️ Total short-form blocks: ${shortFormBlocks.length}\n');

      _log('🎉 All tests completed successfully!');
      _log('\n💡 Next Steps:');
      _log('1. Exit this app');
      _log('2. Try opening Instagram → Should be blocked');
      _log('3. Try opening instagram.com in browser → Should be blocked');
      _log('4. Try opening YouTube Shorts → Should be blocked');
    } catch (e) {
      _log('❌ Error: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testPermanentBlock() async {
    setState(() {
      _testResults = '';
      _isTesting = true;
    });

    final nativeService = ref.read(blocksNativeServiceProvider);

    _log('📱 Testing Permanent App Block...\n');

    try {
      // Add Instagram
      _log('Adding Instagram to permanent blocks...');
      await nativeService.addPermanentlyBlockedApp('com.instagram.android');

      // Verify
      final isBlocked = await nativeService.isPermanentlyBlocked(
        'com.instagram.android',
      );
      _log('Is Instagram blocked? $isBlocked');

      // Get all blocked apps
      final blockedApps = await nativeService.getPermanentlyBlockedApps();
      _log('All blocked apps: $blockedApps');

      _log('\n✅ Test completed!');
      _log('💡 Now exit the app and try opening Instagram');
    } catch (e) {
      _log('❌ Error: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testWebsiteBlock() async {
    setState(() {
      _testResults = '';
      _isTesting = true;
    });

    final nativeService = ref.read(blocksNativeServiceProvider);

    _log('🌐 Testing Website Block...\n');

    try {
      // Add website
      _log('Adding instagram.com to blocked websites...');
      await nativeService.addBlockedWebsite(
        url: 'instagram.com',
        name: 'Instagram',
        isActive: true,
      );

      // Verify
      final isBlocked = await nativeService.isUrlBlocked('instagram.com');
      _log('Is instagram.com blocked? $isBlocked');

      // Get all websites
      final websites = await nativeService.getBlockedWebsites();
      _log('All blocked websites: $websites');

      _log('\n✅ Test completed!');
      _log('💡 Make sure Accessibility Service is enabled');
      _log('💡 Then open Chrome and go to instagram.com');
    } catch (e) {
      _log('❌ Error: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testShortFormBlock() async {
    setState(() {
      _testResults = '';
      _isTesting = true;
    });

    final nativeService = ref.read(blocksNativeServiceProvider);

    _log('📹 Testing Short-Form Block...\n');

    try {
      // Block YouTube Shorts
      _log('Blocking YouTube Shorts...');
      await nativeService.setShortFormBlock(
        platform: 'YouTube',
        feature: 'Shorts',
        isBlocked: true,
      );

      // Verify
      final isBlocked = await nativeService.isShortFormBlocked(
        platform: 'YouTube',
        feature: 'Shorts',
      );
      _log('Is YouTube Shorts blocked? $isBlocked');

      // Get all blocks
      final blocks = await nativeService.getShortFormBlocks();
      _log('All short-form blocks: $blocks');

      _log('\n✅ Test completed!');
      _log('💡 Make sure Accessibility Service is enabled');
      _log('💡 Then open YouTube and try to view a Short');
    } catch (e) {
      _log('❌ Error: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _clearAllBlocks() async {
    setState(() {
      _testResults = '';
      _isTesting = true;
    });

    final nativeService = ref.read(blocksNativeServiceProvider);

    _log('🧹 Clearing all blocks...\n');

    try {
      // Clear permanent app blocks
      _log('Clearing permanent app blocks...');
      await nativeService.setPermanentlyBlockedApps([]);

      // Clear short-form blocks
      _log('Clearing short-form blocks...');
      final blocks = await nativeService.getShortFormBlocks();
      for (final block in blocks) {
        await nativeService.setShortFormBlock(
          platform: block['platform'] as String,
          feature: block['feature'] as String,
          isBlocked: false,
        );
      }

      _log('\n✅ All blocks cleared!');
    } catch (e) {
      _log('❌ Error: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Test Native Blocks'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '🧪 Native Blocks Testing',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Test the native Kotlin implementation',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isTesting ? null : _runAllTests,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run All Tests'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isTesting ? null : _testPermanentBlock,
                    icon: const Icon(Icons.apps),
                    label: const Text('Test Permanent App Block'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue.withOpacity(0.2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isTesting ? null : _testWebsiteBlock,
                    icon: const Icon(Icons.language),
                    label: const Text('Test Website Block'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green.withOpacity(0.2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isTesting ? null : _testShortFormBlock,
                    icon: const Icon(Icons.video_library),
                    label: const Text('Test Short-Form Block'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.purple.withOpacity(0.2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isTesting ? null : _clearAllBlocks,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All Blocks'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.red.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.black.withOpacity(0.3),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults.isEmpty
                        ? '📝 Test results will appear here...'
                        : _testResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
