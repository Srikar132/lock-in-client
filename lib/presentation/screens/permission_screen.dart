import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:lock_in/presentation/providers/permission_provider.dart';
import 'package:lock_in/presentation/providers/auth_provider.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen>
    with WidgetsBindingObserver {
  bool _hasCompletedPermissions = false;

  @override
  void initState() {
    super.initState();
    // Add lifecycle observer to detect when user returns from settings
    WidgetsBinding.instance.addObserver(this);

    // Initial permission check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(permissionProvider.notifier).checkPermissions();
    });
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app returns to foreground, recheck all permissions
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionProvider.notifier).checkPermissions();
    }
  }

  Future<void> _handlePermissionsCompleted(
    PermissionState permissionState,
  ) async {
    try {
      // Get current user from auth state
      final authState = ref.read(authStateProvider);

      await authState.when(
        data: (user) async {
          if (user != null) {
            // Update user account with permission completion
            await ref
                .read(permissionProvider.notifier)
                .completePermissions(user.uid);
          }
        },
        loading: () {
         
        },
        error: (error, stack) {
         
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update account: $e')));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final permissionState = ref.watch(permissionProvider);
    final permissionNotifier = ref.read(permissionProvider.notifier);

    // Listen for permission changes and complete setup when all are granted
    ref.listen(permissionProvider, (previous, current) {
      // Reset completion status if permissions are no longer all granted
      if (previous != null && previous.allGranted && !current.allGranted) {
        _hasCompletedPermissions = false;
      }

      // Handle completion when all permissions are granted for the first time
      if (previous != null &&
          !previous.allGranted &&
          current.allGranted &&
          !_hasCompletedPermissions &&
          !current.hasCompletedSetup) {
        _hasCompletedPermissions = true;
        _handlePermissionsCompleted(current);
      }

    });

    final permissions = [
      {
        'title': 'Usage permission',
        'description': 'This allows us to track your app usage.',
        'granted': permissionState.usagePermission,
        'onTap': () async {
          await permissionNotifier.requestUsagePermission();
          // Recheck after a short delay to allow settings to update
          await Future.delayed(const Duration(milliseconds: 500));
          await permissionNotifier.checkPermissions();
        },
      },
      {
        'title': 'Background permission',
        'description':
            'Keep the app running in the background for continuous monitoring.',
        'granted': permissionState.backgroundPermission,
        'onTap': () async {
          await permissionNotifier.requestBackgroundPermission();
          // Recheck after a short delay
          await Future.delayed(const Duration(milliseconds: 500));
          await permissionNotifier.checkPermissions();
        },
      },
      {
        'title': 'Display over other apps',
        'description': 'Show blocking screens when you open distracting apps.',
        'granted': permissionState.overlayPermission,
        'onTap': () async {
          await permissionNotifier.requestOverlayPermission();
          await Future.delayed(const Duration(milliseconds: 500));
          await permissionNotifier.checkPermissions();
        },
      },
      {
        'title': 'Display pop up permission',
        'description': 'Show focus reminders and motivational popups.',
        'granted': permissionState.displayPopupPermission,
        'onTap': () async {
          await permissionNotifier.requestDisplayPopupPermission();
          await Future.delayed(const Duration(milliseconds: 500));
          await permissionNotifier.checkPermissions();
        },
      },
      {
        'title': 'Accessibility Permission',
        'description': 'Enable advanced app blocking capabilities.',
        'granted': permissionState.accessibilityPermission,
        'onTap': () async {
          await permissionNotifier.requestAccessibilityPermission();
          await Future.delayed(const Duration(milliseconds: 500));
          await permissionNotifier.checkPermissions();
        },
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Progress bar at top
              Container(
                width: double.infinity,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Mascot + Message
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.outline,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/mascot.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            child: Icon(
                              Icons.android,
                              size: 30,
                              color: theme.colorScheme.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.titleMedium,
                          children: [
                            const TextSpan(
                              text:
                                  'Almost there, allow these\npermissions to ',
                            ),
                            TextSpan(
                              text: 'focus\nalongside 9566 people\nnow! ',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // // Debug info (remove in production)
              // Container(
              //   padding: const EdgeInsets.all(12),
              //   decoration: BoxDecoration(
              //     color: Colors.blue.withOpacity(0.1),
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Text(
              //         'Debug Info:',
              //         style: theme.textTheme.labelSmall?.copyWith(
              //           color: Colors.blue,
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //       const SizedBox(height: 4),
              //       Text(
              //         'Background: ${permissionState.backgroundPermission}',
              //         style: theme.textTheme.labelSmall?.copyWith(color: Colors.blue),
              //       ),
              //       Text(
              //         'Usage: ${permissionState.usagePermission}',
              //         style: theme.textTheme.labelSmall?.copyWith(color: Colors.blue),
              //       ),
              //       Text(
              //         'Overlay: ${permissionState.overlayPermission}',
              //         style: theme.textTheme.labelSmall?.copyWith(color: Colors.blue),
              //       ),
              //     ],
              //   ),
              // ),

              // const SizedBox(height: 16),

              // Permission list
              Expanded(
                child: ListView.builder(
                  itemCount: permissions.length,
                  itemBuilder: (context, index) {
                    final permission = permissions[index];
                    return _PermissionTile(
                      title: permission['title'] as String,
                      description: permission['description'] as String,
                      granted: permission['granted'] as bool,
                      onTap: permission['onTap'] as Future<void> Function(),
                      isFirst: index == 0,
                    );
                  },
                ),
              ),


              Column(
                children: [



                  const SizedBox(height: 8),

                  // Info button
                  GestureDetector(
                    onTap: () {
                      _showPermissionInfoDialog(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.question_mark,
                              color: Colors.black,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Why should I give this permission?',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: theme.textTheme.bodyMedium?.color,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Trust badge
                  Text(
                    'Trusted by 2M+ students ❤️',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatefulWidget {
  final String title;
  final String description;
  final bool granted;
  final Future<void> Function() onTap;
  final bool isFirst;

  const _PermissionTile({
    required this.title,
    required this.description,
    required this.granted,
    required this.onTap,
    this.isFirst = false,
  });

  @override
  State<_PermissionTile> createState() => _PermissionTileState();
}

class _PermissionTileState extends State<_PermissionTile> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: widget.granted
                        ? theme.textTheme.bodySmall?.color
                        : null,
                    decoration: widget.granted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (widget.isFirst && !widget.granted) ...[
                  const SizedBox(height: 2),
                  Text(widget.description, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!widget.granted)
            _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        setState(() => _isLoading = true);
                        try {
                          await widget.onTap();
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                      child: Text(
                        'Allow',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
        ],
      ),
    );
  }
}

void _showPermissionInfoDialog(BuildContext context) {
  final theme = Theme.of(context);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Why these permissions?', style: theme.textTheme.titleLarge),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PermissionInfo(
              title: 'Usage Stats Permission',
              description:
                  'Helps us understand which apps distract you most, so we can block them during focus sessions.',
            ),
            const SizedBox(height: 12),
            _PermissionInfo(
              title: 'Display Over Other Apps',
              description:
                  'Allows us to show a blocking screen when you try to open distracting apps.',
            ),
            const SizedBox(height: 12),
            _PermissionInfo(
              title: 'Notification Permission',
              description:
                  'Sends you focus reminders and session completion notifications.',
            ),
            const SizedBox(height: 12),
            _PermissionInfo(
              title: 'Accessibility Permission',
              description:
                  'Enables advanced app blocking to help you stay focused.',
            ),
            const SizedBox(height: 12),
            _PermissionInfo(
              title: 'Background Permission',
              description:
                  'Keeps the app running in the background for continuous monitoring and blocking. This exempts the app from battery optimization.',
            ),
            const SizedBox(height: 12),
            _PermissionInfo(
              title: 'Display Popup Permission',
              description:
                  'Shows focus reminders and motivational popups to keep you on track.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}

class _PermissionInfo extends StatelessWidget {
  final String title;
  final String description;

  const _PermissionInfo({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(description, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
