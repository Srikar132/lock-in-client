import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FocusTimerWidget extends ConsumerStatefulWidget {
  final String initialTimerMode;
  final int initialDefaultDuration;
  final VoidCallback onTap;

  const FocusTimerWidget({
    super.key,
    this.initialTimerMode = 'timer',
    this.initialDefaultDuration = 25,
    required this.onTap,
  });

  @override
  ConsumerState<FocusTimerWidget> createState() => _FocusTimerWidgetState();
}

class _FocusTimerWidgetState extends ConsumerState<FocusTimerWidget> {
  // Timer state
  late int _totalSeconds;
  late int _currentSeconds;
  int _blockedAppsCount = 120;

  @override
  void initState() {
    super.initState();
    _totalSeconds =
        widget.initialDefaultDuration * 60; // Convert minutes to seconds
    _currentSeconds = _totalSeconds;
  }

  @override
  void didUpdateWidget(FocusTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update timer when settings change
    if (oldWidget.initialDefaultDuration != widget.initialDefaultDuration) {
      setState(() {
        _totalSeconds = widget.initialDefaultDuration * 60;
        _currentSeconds = _totalSeconds;
      });
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final timerSize = screenWidth * 0.6; // 60% of screen width

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: timerSize,
        height: timerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.cyan.withOpacity(0.005),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Circular progress indicator
            Positioned.fill(
              child: CircularProgressIndicator(
                value: _totalSeconds > 0 ? _currentSeconds / _totalSeconds : 0,
                strokeWidth: 4,
                backgroundColor: Colors.white.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.3),
                ),
              ),
            ),

            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: timerSize * 0.05),
                  // Timer display
                  Text(
                    _formatTime(_currentSeconds),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: timerSize * 0.2,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                    ),
                  ),

                  SizedBox(height: timerSize * 0.04),

                  // Blocked apps indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App icons (mock)
                        _buildAppIcon(Colors.red, 'Y'),

                        _buildAppIcon(Colors.green, 'W'),

                        _buildAppIcon(Colors.blue, 'F'),

                        const SizedBox(width: 8),

                        Text(
                          '$_blockedAppsCount apps blocked',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: timerSize * 0.09),

                  // Edit button
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: Colors.white.withOpacity(0.9),
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIcon(Color color, String initial) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
