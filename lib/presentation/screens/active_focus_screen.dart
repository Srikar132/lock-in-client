import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/presentation/providers/focus_session_provider.dart';
import 'package:lock_in/presentation/providers/blocked_content_provider.dart';
import 'package:lock_in/presentation/providers/auth_provider.dart';
import 'package:lock_in/presentation/providers/background_image_provider.dart';
import 'package:lock_in/core/constants/images.dart';
import 'package:lock_in/widgets/background_image_selector.dart';
import 'package:lock_in/widgets/lumo_mascot_widget.dart';
import 'package:lock_in/widgets/allowed_apps_drawer.dart';
import 'package:lock_in/models/model_manager.dart';
import 'package:lock_in/models/end_session_bottom_sheet.dart';
import 'package:lock_in/models/audio_bottom_model.dart';
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

class _ActiveFocusScreenState extends ConsumerState<ActiveFocusScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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

    void _showBackgroundSelector() {
    BottomSheetManager.show(
      context: context,
      height: MediaQuery.of(context).size.height * 0.8,
      child: const BackgroundImageSelector(),
    );
  }

  void _showAllowedAppsDrawer() {
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      BottomSheetManager.show(
        context: context,
        height: MediaQuery.of(context).size.height * 0.75,
        child: AllowedAppsDrawer(userId: user.uid),
      );
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
        debugPrint('🎯 _endSession: Calling endSession()');
        await ref.read(focusSessionProvider.notifier).endSession();
        debugPrint(
          '🎯 _endSession: endSession() completed, listener will handle navigation',
        );
        // Navigation will be handled by the listener when status changes to endingWithSave
      } catch (e) {
        debugPrint('Error ending session: $e');
        _showErrorSnackBar('Failed to end session');
      }
    }
  }

  void _showAudioBottomSheet() {
    BottomSheetManager.show(context: context, child: const AudioBottomSheet());
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
    // Listen to session status changes for navigation
    ref.listen<FocusSessionState>(focusSessionProvider, (previous, next) {
      debugPrint(
        '🎯 ActiveFocusScreen: Status changed from ${previous?.status} to ${next.status}',
      );

      // Handle endingWithSave by navigating to save screen
      if (next.status == FocusSessionStatus.endingWithSave) {
        debugPrint('🎯 ActiveFocusScreen: Detected endingWithSave status');

        // Use WidgetsBinding to ensure navigation happens after current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          debugPrint('🎯 ActiveFocusScreen: PostFrameCallback executing');

          if (!mounted) {
            debugPrint(
              '🎯 ActiveFocusScreen: Widget not mounted, skipping navigation',
            );
            return;
          }

          try {
            final sessionData = ref
                .read(focusSessionProvider.notifier)
                .getCurrentSessionData();
            debugPrint(
              '🎯 ActiveFocusScreen: Session data retrieved: $sessionData',
            );

            // Use pushReplacement instead of pushAndRemoveUntil to avoid conflicts
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) {
                  debugPrint(
                    '🎯 SaveSessionScreen: MaterialPageRoute builder called',
                  );
                  return SaveSessionScreen(sessionData: sessionData);
                },
              ),
            );
            debugPrint(
              '🎯 ActiveFocusScreen: Navigation to SaveSessionScreen initiated',
            );
          } catch (e, stackTrace) {
            debugPrint('🎯 ActiveFocusScreen: Navigation error: $e');
            debugPrint('🎯 ActiveFocusScreen: Stack trace: $stackTrace');
          }
        });
      }
      // Handle completed and idle states by going back to home
      else if (next.status == FocusSessionStatus.completed ||
          next.status == FocusSessionStatus.idle) {
        debugPrint(
          '🎯 ActiveFocusScreen: Navigating to home (status: ${next.status})',
        );

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
          // Background Image Layer - Now using dynamic background
          Positioned.fill(
            child: Consumer(
              builder: (context, ref, child) {
                final currentBackground = ref.watch(currentBackgroundImageProvider);
                return Image.asset(
                  currentBackground,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to default if image fails to load
                    return Image.asset(
                      kHomeBackgroundImage,
                      fit: BoxFit.cover,
                    );
                  },
                );
              },
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
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
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
    final remainingSeconds = sessionState.remainingSeconds ?? 0;
    final plannedDuration =
        sessionState.plannedDuration ?? widget.plannedDuration;
    final sessionType = sessionState.sessionType ?? widget.sessionType;
    final isPaused = sessionState.status == FocusSessionStatus.paused;

    // Calculate progress based on session type
    double progress = 0.0;
    String displayTime = _formatTime(elapsedSeconds);
    String timerLabel = _getTimerLabel(sessionType);
    Color progressColor = _getProgressColor(sessionType);
    IconData sessionIcon = _getSessionIcon(sessionType);

    if (sessionType.toLowerCase() == 'timer') {
      // For timer, show countdown and progress towards completion
      progress = plannedDuration > 0
          ? (elapsedSeconds / (plannedDuration * 60)).clamp(0.0, 1.0)
          : 0.0;
      displayTime = _formatTime(remainingSeconds);
    } else {
      // For stopwatch/pomodoro, show elapsed time and progress (if applicable)
      if (sessionType.toLowerCase() == 'pomodoro' && plannedDuration > 0) {
        progress = (elapsedSeconds / (plannedDuration * 60)).clamp(0.0, 1.0);
      } else {
        // For stopwatch, show a pulsing animation instead of progress
        progress = 1.0;
      }
      displayTime = _formatTime(elapsedSeconds);
    }

    return Container(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow effect

          // Progress ring
          SizedBox(
            width: 250,
            height: 250,
            child: sessionType.toLowerCase() == 'stopwatch' && !isPaused
                ? AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: CircularProgressPainter(
                          progress: progress,
                          strokeWidth: 4,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          progressColor: progressColor,
                          isPulsing: true,
                          isPaused: isPaused,
                          animationValue: _pulseAnimation.value,
                        ),
                      );
                    },
                  )
                : CustomPaint(
                    painter: CircularProgressPainter(
                      progress: progress,
                      strokeWidth: 4,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      progressColor: progressColor,
                      isPulsing: false,
                      isPaused: isPaused,
                    ),
                  ),
          ),

          // Inner circle with gradient
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                  Colors.transparent,
                ],
                stops: [0.0, 0.7, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),

          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Session Type with Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(sessionIcon, color: progressColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    sessionType.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Timer Label
              Text(
                timerLabel,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 8),

              // Main Timer Display
              Text(
                displayTime,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 1,
                  height: 0.9,
                ),
              ),

              const SizedBox(height: 12),

              // Progress indicator or status
              if (sessionType.toLowerCase() == 'timer' && plannedDuration > 0)
                Text(
                  '${(progress * 100).round()}% Complete',
                  style: TextStyle(
                    color: progressColor.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

              const SizedBox(height: 8),

              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPaused
                      ? Colors.orange.withOpacity(0.2)
                      : progressColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isPaused
                        ? Colors.orange.withOpacity(0.4)
                        : progressColor.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  isPaused ? 'PAUSED' : _getStatusText(sessionType),
                  style: TextStyle(
                    color: isPaused ? Colors.orange : progressColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(String sessionType) {
    switch (sessionType.toLowerCase()) {
      case 'timer':
        return const Color(0xFF4CAF50); // Green
      case 'stopwatch':
        return const Color(0xFF2196F3); // Blue
      case 'pomodoro':
        return const Color(0xFFFF5722); // Orange-red
      default:
        return const Color(0xFF4CAF50);
    }
  }

  IconData _getSessionIcon(String sessionType) {
    switch (sessionType.toLowerCase()) {
      case 'timer':
        return Icons.timer_outlined;
      case 'stopwatch':
        return Icons.access_time_outlined;
      case 'pomodoro':
        return Icons.local_fire_department_outlined;
      default:
        return Icons.timer_outlined;
    }
  }

  String _getTimerLabel(String sessionType) {
    switch (sessionType.toLowerCase()) {
      case 'timer':
        return 'Time Left';
      case 'stopwatch':
        return 'Elapsed Time';
      case 'pomodoro':
        return 'Focus Time';
      default:
        return 'Timer';
    }
  }

  String _getStatusText(String sessionType) {
    switch (sessionType.toLowerCase()) {
      case 'timer':
        return 'COUNTING DOWN';
      case 'stopwatch':
        return 'TRACKING TIME';
      case 'pomodoro':
        return 'FOCUS MODE';
      default:
        return 'ACTIVE';
    }
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
          _buildNavIcon(
            Icons.music_note,
            'Music',
            true,
            onTap: _showAudioBottomSheet,
          ),
          _buildNavIcon(Icons.auto_awesome, 'Theme', true , onTap : _showBackgroundSelector),
          _buildNavIcon(
            Icons.apps,
            'Apps',
            true,
            onTap: _showAllowedAppsDrawer,
            // blockedContentWidget: user != null
            //     ? Consumer(
            //         builder: (context, ref, child) {
            //           final blockedContentAsync = ref.watch(
            //             blockedContentProvider(user.uid),
            //           );
            //           return blockedContentAsync.when(
            //             data: (content) {
            //               final count = content.permanentlyBlockedApps.length;
            //               if (count > 0) {
            //                 return Positioned(
            //                   right: -4,
            //                   top: -4,
            //                   child: Container(
            //                     padding: const EdgeInsets.all(4),
            //                     decoration: const BoxDecoration(
            //                       color: Colors.red,
            //                       shape: BoxShape.circle,
            //                     ),
            //                     constraints: const BoxConstraints(
            //                       minWidth: 18,
            //                       minHeight: 18,
            //                     ),
            //                     child: Text(
            //                       '$count',
            //                       style: const TextStyle(
            //                         color: Colors.white,
            //                         fontSize: 10,
            //                         fontWeight: FontWeight.bold,
            //                       ),
            //                       textAlign: TextAlign.center,
            //                     ),
            //                   ),
            //                 );
            //               }
            //               return const SizedBox.shrink();
            //             },
            //             loading: () => const SizedBox.shrink(),
            //             error: (_, __) => const SizedBox.shrink(),
            //           );
            //         },
            //       )
            //     : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(
    IconData icon,
    String label,
    bool isActive, {
    Widget? blockedContentWidget,
    VoidCallback? onTap,
  }) {
    Widget navIcon = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
            size: 26,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );

    if (onTap != null) {
      navIcon = GestureDetector(onTap: onTap, child: navIcon);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        navIcon,
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

// Custom painter for the circular progress ring
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;
  final bool isPulsing;
  final bool isPaused;
  final double? animationValue;

  CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
    this.isPulsing = false,
    this.isPaused = false,
    this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    if (progress > 0 || isPulsing) {
      final progressPaint = Paint()
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (isPaused) {
        // Paused state - dimmed color
        progressPaint.color = progressColor.withOpacity(0.5);
      } else if (isPulsing) {
        // Pulsing effect for stopwatch
        final pulseProgress = animationValue ?? 0.5;
        progressPaint.color = Color.lerp(
          progressColor.withOpacity(0.6),
          progressColor,
          pulseProgress,
        )!;
      } else {
        // Normal progress color
        progressPaint.color = progressColor;
      }

      // Add gradient effect
      if (!isPaused && !isPulsing) {
        final rect = Rect.fromCircle(center: center, radius: radius);
        progressPaint.shader = SweepGradient(
          colors: [
            progressColor.withOpacity(0.5),
            progressColor,
            progressColor,
            progressColor.withOpacity(0.8),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + (2 * math.pi * progress),
        ).createShader(rect);
      }

      final sweepAngle = isPulsing ? 2 * math.pi : 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }

    // Inner highlight ring
    if (progress > 0.1 || isPulsing) {
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(center, radius - strokeWidth / 2 - 2, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPaused != isPaused ||
        oldDelegate.isPulsing != isPulsing ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.animationValue != animationValue;
  }
}
