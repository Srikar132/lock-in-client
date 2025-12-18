import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/presentation/providers/focus_session_provider.dart';
import 'package:lock_in/presentation/providers/app_management_provide.dart';
import 'package:lock_in/presentation/providers/auth_provider.dart';
import 'package:lock_in/presentation/providers/session_provider.dart';
import 'package:lock_in/data/models/focus_session_model.dart';

/// Example widget showing how to start and stop focus sessions
///
/// This can be integrated into your FocusScreen or used as a reference
class FocusSessionControl extends ConsumerWidget {
  const FocusSessionControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusSession = ref.watch(activeFocusSessionProvider);
    final user = ref.watch(currentUserProvider).value;

    if (user == null) {
      return const SizedBox();
    }

    return Column(
      children: [
        // Session Status
        if (focusSession.isActive) ...[
          Card(
            color: const Color(0xFF1E1E1E),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lock,
                        color: Color(0xFF82D65D),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Focus Mode Active',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      if (focusSession.strictMode)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'STRICT MODE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: focusSession.progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF82D65D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${focusSession.elapsedMinutes} min elapsed',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '${focusSession.remainingMinutes} min remaining',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF82D65D),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Blocked apps count
                  Text(
                    '${focusSession.blockedApps.length} apps blocked',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stop button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: focusSession.isLoading
                  ? null
                  : () => _stopFocusSession(context, ref, user.uid),
              style: ElevatedButton.styleFrom(
                backgroundColor: focusSession.strictMode
                    ? Colors.grey
                    : Colors.red,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: focusSession.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      focusSession.strictMode
                          ? 'Cannot Stop (Strict Mode)'
                          : 'End Focus Session',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ] else ...[
          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: focusSession.isLoading
                  ? null
                  : () => _showStartSessionDialog(context, ref, user.uid),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF82D65D),
                foregroundColor: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: focusSession.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1A1A1A),
                      ),
                    )
                  : const Text(
                      'Start Focus Session',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],

        // Error message
        if (focusSession.error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    focusSession.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  onPressed: () {
                    ref.read(activeFocusSessionProvider.notifier).clearError();
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showStartSessionDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Start Focus Session',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will start a focus session with the currently selected blocked apps. Continue?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startFocusSession(context, ref, userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF82D65D),
              foregroundColor: const Color(0xFF1A1A1A),
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _startFocusSession(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final blockedApps = ref.read(blockedAppsProvider);

    // Show warning if no apps selected, but allow to continue
    if (blockedApps.isEmpty) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Apps Selected'),
          content: const Text(
            'You haven\'t selected any apps to block. You can still use Focus Mode to track your focus time.\n\n'
            'Do you want to continue without blocking apps?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      
      if (shouldContinue != true) {
        return;
      }
    }

    // Create session ID
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

    // Start native focus session
    final success = await ref
        .read(activeFocusSessionProvider.notifier)
        .startSession(
          sessionId: sessionId,
          blockedApps: blockedApps.toList(),
          durationMinutes: 25, // TODO: Get from settings
          strictMode: false, // TODO: Get from settings
          blockHomeScreen: false, // TODO: Get from settings
        );

    if (success && context.mounted) {
      // Also create Firestore session record
      final session = FocusSessionModel(
        sessionId: sessionId,
        userId: userId,
        startTime: DateTime.now(),
        plannedDuration: 25,
        sessionType: 'focus',
        status: 'active',
        date: _getTodayDateString(),
      );

      try {
        await ref.read(sessionRepositoryProvider).createSession(session);
      } catch (e) {
        debugPrint('Error creating Firestore session: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Focus session started!'),
          backgroundColor: Color(0xFF82D65D),
        ),
      );
    }
  }

  void _stopFocusSession(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final focusSession = ref.read(activeFocusSessionProvider);

    if (focusSession.strictMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot stop session in strict mode'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await ref
        .read(activeFocusSessionProvider.notifier)
        .stopSession();

    if (success && context.mounted) {
      // Update Firestore session
      if (focusSession.sessionId != null) {
        try {
          final duration = focusSession.elapsedMinutes;
          await ref
              .read(sessionRepositoryProvider)
              .completeSession(
                sessionId: focusSession.sessionId!,
                userId: userId,
                actualDuration: duration,
                date: _getTodayDateString(),
              );
        } catch (e) {
          debugPrint('Error completing Firestore session: $e');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Focus session ended'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
