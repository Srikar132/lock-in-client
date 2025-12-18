import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/services/blocks_native_service.dart';

/// Quick debug widget to test and add blocks
class QuickBlockDebugger extends ConsumerWidget {
  const QuickBlockDebugger({super.key});

  Future<void> _addTestBlocks(BuildContext context, WidgetRef ref) async {
    final service = ref.read(blocksNativeServiceProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Add cred.club to website blocks
      await service.addBlockedWebsite(
        url: 'cred.club',
        name: 'Cred',
        isActive: true,
      );

      // Add instagram.com
      await service.addBlockedWebsite(
        url: 'instagram.com',
        name: 'Instagram',
        isActive: true,
      );

      // Enable YouTube Shorts blocking
      await service.setShortFormBlock(
        platform: 'YouTube',
        feature: 'Shorts',
        isBlocked: true,
      );

      // Enable Instagram Reels blocking
      await service.setShortFormBlock(
        platform: 'Instagram',
        feature: 'Reels',
        isBlocked: true,
      );

      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Blocks added! Check logs and test in browser/apps'),
          backgroundColor: Colors.green,
        ),
      );

      print('✅ Blocks added successfully');
      print('📝 Now try:');
      print('   1. Open Chrome → go to cred.club');
      print('   2. Open Chrome → go to instagram.com');
      print('   3. Open YouTube → try to view a Short');
      print('   4. Open Instagram → try to view Reels');
    } catch (e) {
      print('❌ Error adding blocks: $e');
      messenger.showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _verifyBlocks(BuildContext context, WidgetRef ref) async {
    final service = ref.read(blocksNativeServiceProvider);

    try {
      // Check websites
      final websites = await service.getBlockedWebsites();
      print('🌐 Blocked websites: ${websites.length}');
      for (final site in websites) {
        print(
          '   - ${site['name']}: ${site['url']} (active: ${site['isActive']})',
        );
      }

      final isCredBlocked = await service.isUrlBlocked('cred.club');
      final isInstaBlocked = await service.isUrlBlocked('instagram.com');
      print('   Is cred.club blocked? $isCredBlocked');
      print('   Is instagram.com blocked? $isInstaBlocked');

      // Check short-form blocks
      final shortFormBlocks = await service.getShortFormBlocks();
      print('\n📹 Short-form blocks: ${shortFormBlocks.length}');
      for (final block in shortFormBlocks) {
        print(
          '   - ${block['platform']} ${block['feature']}: ${block['isBlocked']}',
        );
      }

      final isYTBlocked = await service.isShortFormBlocked(
        platform: 'YouTube',
        feature: 'Shorts',
      );
      final isIGReelsBlocked = await service.isShortFormBlocked(
        platform: 'Instagram',
        feature: 'Reels',
      );
      print('   Is YouTube Shorts blocked? $isYTBlocked');
      print('   Is Instagram Reels blocked? $isIGReelsBlocked');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check console for results'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('❌ Error verifying blocks: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🐛 Quick Block Debugger',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add test blocks and verify they work',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _addTestBlocks(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Test Blocks'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _verifyBlocks(context, ref),
              icon: const Icon(Icons.check_circle),
              label: const Text('Verify Blocks'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💡 After adding blocks:\n'
                '1. Check console logs\n'
                '2. Keep app running in background\n'
                '3. Test in browser/apps',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
