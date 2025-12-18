import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/core/theme/app_theme.dart'; // Ensure theme access
import 'package:lock_in/presentation/providers/auth_provider.dart';
import 'package:lock_in/presentation/providers/app_limits_provider.dart';
import 'package:lock_in/presentation/providers/blocked_content_provider.dart';
import 'package:lock_in/data/models/blocked_content_model.dart';
import 'package:lock_in/data/models/app_limit_model.dart';

class BlocksScreen extends ConsumerStatefulWidget {
  const BlocksScreen({super.key});

  @override
  ConsumerState<BlocksScreen> createState() => _BlocksScreenState();
}

class _BlocksScreenState extends ConsumerState<BlocksScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              floating: true,
              pinned: true,
              title: const Text(
                'Blocks',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 1. App Limits
                  _AppLimitsSection(userId: user.uid),
                  const SizedBox(height: 24),

                  // 2. Short Form Content
                  _ShortFormBlocksSection(userId: user.uid),
                  const SizedBox(height: 24),

                  // 3. Website Blocking
                  _WebsiteBlockingSection(userId: user.uid),
                  const SizedBox(height: 24),

                  // 4. Notifications
                  _NotificationBlockingSection(userId: user.uid),
                  const SizedBox(height: 100), // Bottom padding for scrolling
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 1. APP LIMITS SECTION
// ============================================================================

class _AppLimitsSection extends ConsumerWidget {
  final String userId;

  const _AppLimitsSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLimitsAsync = ref.watch(appLimitsProvider(userId));

    return _BlockSection(
      title: 'App Limits',
      icon: Icons.timer_outlined,
      description: 'Set daily usage limits for specific apps',
      child: appLimitsAsync.when(
        data: (limits) {
          if (limits.isEmpty) {
            return _EmptyState(
              icon: Icons.timer_off_outlined,
              message: 'No app limits set yet',
              actionLabel: 'Add Limit',
              onAction: () => _showAddAppLimitDialog(context),
            );
          }

          return Column(
            children: [
              ...limits.map((limit) => _AppLimitTile(
                limit: limit,
                userId: userId,
              )),
              const SizedBox(height: 12),
              _AddButton(
                label: 'Add App Limit',
                onPressed: () => _showAddAppLimitDialog(context),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: 'Could not load limits'),
      ),
    );
  }

  void _showAddAppLimitDialog(BuildContext context) {
    // TODO: Connect this to the AppSelectionScreen we built earlier
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add App Limit', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Select an app to limit its daily usage. (Feature integration pending)',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF82D65D))),
          ),
        ],
      ),
    );
  }
}

class _AppLimitTile extends ConsumerWidget {
  final AppLimitModel limit;
  final String userId;

  const _AppLimitTile({required this.limit, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Surface color
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.timer, color: Colors.white70),
        ),
        title: Text(limit.appName, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          '${limit.dailyLimit} min/day',
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
        trailing: Transform.scale(
          scale: 0.8,
          child: Switch(
            value: limit.isActive,
            activeColor: const Color(0xFF82D65D), // ReGain Green
            activeTrackColor: const Color(0xFF82D65D).withOpacity(0.3),
            inactiveTrackColor: Colors.grey.withOpacity(0.2),
            onChanged: (value) {
              ref.read(appLimitNotifierProvider.notifier).toggleAppLimitStatus(
                userId,
                limit.packageName,
                value,
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. SHORT FORM BLOCKS SECTION
// ============================================================================

class _ShortFormBlocksSection extends ConsumerWidget {
  final String userId;

  const _ShortFormBlocksSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortFormsAsync = ref.watch(shortFormBlocksProvider(userId));

    return _BlockSection(
      title: 'Short Form Content',
      icon: Icons.video_library_outlined,
      description: 'Block addictive short-form feeds',
      child: shortFormsAsync.when(
        data: (blocks) {
          return Column(
            children: [
              _ShortFormToggle(
                title: 'YouTube Shorts',
                subtitle: 'Block Shorts shelf & feed',
                icon: Icons.play_circle_outline,
                isBlocked: blocks['youtube_shorts']?.isBlocked ?? false,
                onChanged: (value) => _updateBlock(ref, 'youtube', 'shorts', value),
              ),
              _ShortFormToggle(
                title: 'Instagram Reels',
                subtitle: 'Block Reels tab & feed',
                icon: Icons.camera_alt_outlined,
                isBlocked: blocks['instagram_reels']?.isBlocked ?? false,
                onChanged: (value) => _updateBlock(ref, 'instagram', 'reels', value),
              ),
              _ShortFormToggle(
                title: 'TikTok',
                subtitle: 'Block app entirely',
                icon: Icons.music_note_outlined,
                isBlocked: blocks['tiktok_all']?.isBlocked ?? false,
                onChanged: (value) => _updateBlock(ref, 'tiktok', 'all', value),
              ),
              _ShortFormToggle(
                title: 'Facebook Reels',
                subtitle: 'Block Reels section',
                icon: Icons.facebook_outlined,
                isBlocked: blocks['facebook_reels']?.isBlocked ?? false,
                onChanged: (value) => _updateBlock(ref, 'facebook', 'reels', value),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: 'Could not load settings'),
      ),
    );
  }

  void _updateBlock(WidgetRef ref, String platform, String feature, bool isBlocked) {
    final block = ShortFormBlock(
      platform: platform,
      feature: feature,
      isBlocked: isBlocked,
    );
    ref.read(blockedContentNotifierProvider.notifier).setShortFormBlock(userId, block);
  }
}

class _ShortFormToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isBlocked;
  final ValueChanged<bool> onChanged;

  const _ShortFormToggle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isBlocked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(icon, color: isBlocked ? const Color(0xFF82D65D) : Colors.grey),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5))),
        value: isBlocked,
        activeColor: const Color(0xFF82D65D),
        activeTrackColor: const Color(0xFF82D65D).withOpacity(0.3),
        inactiveTrackColor: Colors.grey.withOpacity(0.2),
        onChanged: onChanged,
      ),
    );
  }
}

// ============================================================================
// 3. WEBSITE BLOCKING SECTION
// ============================================================================

class _WebsiteBlockingSection extends ConsumerWidget {
  final String userId;

  const _WebsiteBlockingSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final websitesAsync = ref.watch(blockedWebsitesProvider(userId));

    return _BlockSection(
      title: 'Website Blocking',
      icon: Icons.language,
      description: 'Block distracting websites in browsers',
      child: websitesAsync.when(
        data: (websites) {
          if (websites.isEmpty) {
            return _EmptyState(
              icon: Icons.public_off,
              message: 'No websites blocked',
              actionLabel: 'Add Website',
              onAction: () => _showAddWebsiteDialog(context, ref),
            );
          }

          return Column(
            children: [
              ...websites.map((website) => _WebsiteTile(
                website: website,
                userId: userId,
              )),
              const SizedBox(height: 12),
              _AddButton(
                label: 'Add Website',
                onPressed: () => _showAddWebsiteDialog(context, ref),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: 'Could not load websites'),
      ),
    );
  }

  void _showAddWebsiteDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Block Website', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Website URL',
            hintText: 'e.g. facebook.com',
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                final website = BlockedWebsite(url: url, name: url, isActive: true);
                ref.read(blockedContentNotifierProvider.notifier).addBlockedWebsite(userId, website);
                Navigator.pop(context);
              }
            },
            child: const Text('Block', style: TextStyle(color: Color(0xFF82D65D), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _WebsiteTile extends ConsumerWidget {
  final BlockedWebsite website;
  final String userId;

  const _WebsiteTile({required this.website, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: const Icon(Icons.public_off, color: Colors.white70),
        title: Text(website.url, style: const TextStyle(color: Colors.white)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: website.isActive,
                activeColor: const Color(0xFF82D65D),
                activeTrackColor: const Color(0xFF82D65D).withOpacity(0.3),
                inactiveTrackColor: Colors.grey.withOpacity(0.2),
                onChanged: (value) {
                  ref.read(blockedContentNotifierProvider.notifier)
                      .toggleWebsiteBlockStatus(userId, website.url, value);
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.white.withOpacity(0.4)),
              onPressed: () {
                ref.read(blockedContentNotifierProvider.notifier).removeBlockedWebsite(userId, website.url);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 4. NOTIFICATION BLOCKING SECTION
// ============================================================================

class _NotificationBlockingSection extends ConsumerStatefulWidget {
  final String userId;

  const _NotificationBlockingSection({required this.userId});

  @override
  ConsumerState<_NotificationBlockingSection> createState() => _NotificationBlockingSectionState();
}

class _NotificationBlockingSectionState extends ConsumerState<_NotificationBlockingSection> {
  // TODO: Move this state to a provider for persistence
  bool _blockAllNotifications = false;

  @override
  Widget build(BuildContext context) {
    return _BlockSection(
      title: 'Notifications',
      icon: Icons.notifications_off_outlined,
      description: 'Control notification access globally',
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              secondary: Icon(
                Icons.notifications_off,
                color: _blockAllNotifications ? const Color(0xFF82D65D) : Colors.grey,
              ),
              title: const Text('Block All Notifications', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Silence all app notifications',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
              value: _blockAllNotifications,
              activeColor: const Color(0xFF82D65D),
              activeTrackColor: const Color(0xFF82D65D).withOpacity(0.3),
              inactiveTrackColor: Colors.grey.withOpacity(0.2),
              onChanged: (value) {
                setState(() => _blockAllNotifications = value);
                // TODO: Save to backend via provider
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SHARED WIDGETS
// ============================================================================

class _BlockSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final Widget child;

  const _BlockSection({
    required this.title,
    required this.icon,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF82D65D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF82D65D), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _AddButton(label: actionLabel, onPressed: onAction),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Text(message, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _AddButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.add, size: 20),
        label: Text(label),
      ),
    );
  }
}