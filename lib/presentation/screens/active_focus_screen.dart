import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/presentation/providers/focus_session_provider.dart';
import 'package:lock_in/presentation/providers/blocked_content_provider.dart';
import 'package:lock_in/presentation/providers/auth_provider.dart';
import 'package:lock_in/core/constants/images.dart';
import 'package:lock_in/widgets/lumo_mascot_widget.dart';
import 'package:lock_in/models/model_manager.dart';
import 'package:lock_in/models/end_session_bottom_sheet.dart';
import 'package:lock_in/presentation/screens/save_session_screen.dart';

class ActiveFocusScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final int plannedDuration;
  final String sessionType;

  const ActiveFocusScreen({
    super.key,
    required this.sessionId,
    required this.plannedDuration,
    required this.sessionType,
  });

  @override
  ConsumerState<ActiveFocusScreen> createState() => _ActiveFocusScreenState();
}

class _ActiveFocusScreenState extends ConsumerState<ActiveFocusScreen> {

  Future<void> _pauseSession() async {
    try {
      await ref.read(focusSessionProvider.notifier).pauseSession();
    } catch (e) {
      debugPrint('Error pausing session: $e');
      _showErrorSnackBar('Failed to pause session');
    }
  }

  Future<void> _resumeSession() async {
    try {
      await ref.read(focusSessionProvider.notifier).resumeSession();
    } catch (e) {
      debugPrint('Error resuming session: $e');
      _showErrorSnackBar('Failed to resume session');
    }
  }

  Future<void> _endSession() async {
    final confirmed = await BottomSheetManager.show<bool>(
      context: context,
      height: 300,
      child: const EndSessionBottomSheet(),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(focusSessionProvider.notifier).endSession();
        
        // Navigate directly to save screen after ending session
        if (mounted) {
          final sessionData = ref.read(focusSessionProvider.notifier).getCurrentSessionData();
          debugPrint('🎯 _endSession: Navigating directly to save screen');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => SaveSessionScreen(
                sessionData: sessionData,
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error ending session: $e');
        _showErrorSnackBar('Failed to end session');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(focusSessionProvider);
    final user = ref.watch(currentUserProvider).value;

    // Listen to session status changes for navigation
    ref.listen<FocusSessionState>(focusSessionProvider, (previous, next) {
      debugPrint('🎯 ActiveFocusScreen: Status changed from ${previous?.status} to ${next.status}');
      
      // Only handle completed and idle states here - endingWithSave is handled directly in _endSession
      if (next.status == FocusSessionStatus.completed ||
          next.status == FocusSessionStatus.idle) {
        debugPrint('🎯 ActiveFocusScreen: Navigating to home (status: ${next.status})');
        // Navigate to home for completion scenarios
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      }
    });

    return PopScope(
      canPop: false,
      child: Stack(
        children: [
          // Background Image Layer
          Positioned.fill(
            child: Image.asset(
              kHomeBackgroundImage,
              fit: BoxFit.cover,
            ),
          ),

          // Main Content Layer
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // Header with notification banner
                      _buildHeader(sessionState),

                      const SizedBox(height: 60),

                      // Main Timer Circle
                      _buildTimerCircle(sessionState),

                      const Spacer(),

                      // Lumo Mascot
                      LumoMascotWidget(onTap: () {}),

                      const SizedBox(height: 50),

                      // Control Buttons
                      _buildControlButtons(sessionState),

                      const SizedBox(height: 20),

                      // Bottom Navigation Icons
                      _buildBottomNavigation(user),

                      const SizedBox(height: 5),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(FocusSessionState sessionState) {
    return Column(
      children: [
        // Notification Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_off,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Be the first to focus!',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Page Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
                (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == 0
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerCircle(FocusSessionState sessionState) {
    final elapsedSeconds = sessionState.elapsedSeconds ?? 0;
    final sessionType = sessionState.sessionType ?? widget.sessionType;
    final isPaused = sessionState.status == FocusSessionStatus.paused;

    return Container(
      width: 270,
      height: 270,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Session Type / Status
            Text(
              sessionType.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 4),

            // Dropdown indicator
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white.withOpacity(0.6),
              size: 20,
            ),

            const SizedBox(height: 15),

            // Timer Label
            Text(
              'Timer',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 3),

            // Main Timer Display
            Text(
              _formatTime(elapsedSeconds),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 15),

            // Take a Break Button
            if (!isPaused)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Take a break',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            if (isPaused)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'PAUSED',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(FocusSessionState sessionState) {
    final isPaused = sessionState.status == FocusSessionStatus.paused;
    final isActive = sessionState.status == FocusSessionStatus.active;
    final canControl = isActive || isPaused;

    return Row(
      children: [
        // Stop Focusing Button
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canControl ? _endSession : null,
                borderRadius: BorderRadius.circular(30),
                child: Center(
                  child: Text(
                    'Stop focusing',
                    style: TextStyle(
                      color: canControl
                          ? Colors.white.withOpacity(0.9)
                          : Colors.white.withOpacity(0.5),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Pause/Resume Button
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canControl
                    ? (isPaused ? _resumeSession : _pauseSession)
                    : null,
                borderRadius: BorderRadius.circular(30),
                child: Center(
                  child: Text(
                    isPaused ? 'Resume' : 'Pause',
                    style: TextStyle(
                      color: canControl
                          ? Colors.white.withOpacity(0.9)
                          : Colors.white.withOpacity(0.5),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavIcon(Icons.music_note, 'Music', false),
          _buildNavIcon(Icons.auto_awesome, 'Theme', false),
          _buildNavIcon(Icons.lock, 'Strict mode', false),
          _buildNavIcon(Icons.apps, 'Apps', false,
            blockedContentWidget: user != null ? Consumer(
              builder: (context, ref, child) {
                final blockedContentAsync = ref.watch(blockedContentProvider(user.uid));
                return blockedContentAsync.when(
                  data: (content) {
                    final count = content.permanentlyBlockedApps.length;
                    if (count > 0) {
                      return Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label, bool isActive, {Widget? blockedContentWidget}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                color: isActive
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
                size: 26,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
        if (blockedContentWidget != null) blockedContentWidget,
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}