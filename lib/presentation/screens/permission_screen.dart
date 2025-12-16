import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:lock_in/presentation/providers/permission_provider.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding. instance.addPostFrameCallback((_) {
      ref.read(permissionProvider.notifier).checkPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final permissionState = ref.watch(permissionProvider);
    final permissionNotifier = ref.read(permissionProvider. notifier);

    final permissions = [
      {
        'title': 'Usage permission',
        'description': 'This allows us to track your app usage.',
        'granted':  permissionState.usagePermission,
        'onTap': () => permissionNotifier. requestUsagePermission(),
      },
      {
        'title':  'Background permission',
        'description': 'Keep the app running in the background for continuous monitoring.',
        'granted': permissionState. backgroundPermission,
        'onTap': () => permissionNotifier.requestBackgroundPermission(),
      },
      {
        'title':  'Display over other apps',
        'description': 'Show blocking screens when you open distracting apps.',
        'granted': permissionState.overlayPermission,
        'onTap': () => permissionNotifier.requestOverlayPermission(),
      },
      {
        'title': 'Display pop up permission',
        'description': 'Show focus reminders and motivational popups.',
        'granted': permissionState.displayPopupPermission,
        'onTap': () => permissionNotifier.requestDisplayPopupPermission(),
      },
      {
        'title': 'Accessibility Permission',
        'description': 'Enable advanced app blocking capabilities.',
        'granted': permissionState. accessibilityPermission,
        'onTap': () => permissionNotifier.requestAccessibilityPermission(),
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children:  [
              // Progress bar at top
              Container(
                width: double.infinity,
                height: 4,
                decoration:  BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius. circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor:  0.8,
                  child: Container(
                    decoration: BoxDecoration(
                      color:  Colors.white,
                      borderRadius: BorderRadius. circular(2),
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
                        fit: BoxFit. cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            child: Icon(
                              Icons. android,
                              size: 30,
                              color: theme.colorScheme.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width:  12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration:  BoxDecoration(
                        color: theme.colorScheme. surfaceContainerHighest,
                        borderRadius: BorderRadius. circular(16),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme. titleMedium,
                          children: [
                            const TextSpan(text: 'Almost there, allow these\npermissions to '),
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

              // Permission list
              Expanded(
                child:  ListView.builder(
                  itemCount:  permissions.length,
                  itemBuilder: (context, index) {
                    final permission = permissions[index];
                    return _PermissionTile(
                      title: permission['title'] as String,
                      description: permission['description'] as String,
                      granted: permission['granted'] as bool,
                      onTap: permission['onTap'] as VoidCallback,
                      isFirst: index == 0,
                    );
                  },
                ),
              ),

              // Bottom section
              Column(
                children:  [
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
                      decoration:  BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius. circular(10),
                      ),
                      child:  Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color:  theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child:  const Icon(
                              Icons.question_mark,
                              color: Colors.black,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Why should I give this permission?',
                              style: theme.textTheme. bodyMedium,
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

class _PermissionTile extends StatelessWidget {
  final String title;
  final String description;
  final bool granted;
  final VoidCallback onTap;
  final bool isFirst;

  const _PermissionTile({
    required this.title,
    required this.description,
    required this.granted,
    required this.onTap,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme. of(context);
    
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
                  title,
                  style: theme.textTheme. titleMedium?.copyWith(
                    color: granted ? theme.textTheme.bodySmall?. color : null,
                    decoration: granted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (isFirst && !granted) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!granted)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical:  6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: GestureDetector(
                onTap: onTap,
                child: Text(
                  'Allow',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color:  Colors.black,
                    fontWeight: FontWeight. w500,
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
      title: Text(
        'Why these permissions?',
        style: theme.textTheme.titleLarge,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PermissionInfo(
              title:  'Usage Stats Permission',
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
                  'Keeps the app running in the background for continuous monitoring and blocking.',
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

  const _PermissionInfo({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:  theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme. primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          description,
          style: theme. textTheme.bodySmall,
        ),
      ],
    );
  }
}