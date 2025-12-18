import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/core/constants/images.dart';
import 'package:lock_in/presentation/providers/focus_session_provider.dart';
import 'package:lock_in/widgets/lumo_mascot_widget.dart';
import 'dart:math';

/// Screen displayed during an active focus session
class FocusSessionActiveScreen extends ConsumerStatefulWidget {
  const FocusSessionActiveScreen({super.key});

  @override
  ConsumerState<FocusSessionActiveScreen> createState() =>
      _FocusSessionActiveScreenState();
}

class _FocusSessionActiveScreenState
    extends ConsumerState<FocusSessionActiveScreen> {
  Timer? _timer;

  final List<String> _motivationalQuotes = [
    "Stay focused! You're doing great!",
    "Every minute counts. Keep going!",
    "Success is the sum of small efforts.",
    "Concentrate all your energy on the task at hand.",
    "The ability to focus is your superpower.",
    "Stay committed to your goals.",
  ];

  int _currentQuoteIndex = 0;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _changeQuote();
    // Auto-refresh elapsed time every minute
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        ref.invalidate(activeFocusSessionProvider);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _changeQuote() {
    setState(() {
      int newIndex;
      do {
        newIndex = _random.nextInt(_motivationalQuotes.length);
      } while (newIndex == _currentQuoteIndex &&
          _motivationalQuotes.length > 1);
      _currentQuoteIndex = newIndex;
    });
  }

  Future<void> _stopFocusSession(bool force) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Focus Session?'),
        content: Text(
          force
              ? 'This will end your focus session immediately.'
              : 'You can take a break and resume later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              force ? 'Stop' : 'Pause',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(activeFocusSessionProvider.notifier)
          .stopSession(force: force);
    }
  }

  @override
  Widget build(BuildContext context) {
    final focusSession = ref.watch(activeFocusSessionProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(kHomeBackgroundImage, fit: BoxFit.cover),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header
                  _buildHeader(context),

                  const Spacer(),

                  // Focus Timer Circle
                  _buildFocusTimer(focusSession),

                  const SizedBox(height: 40),

                  // Quote Card
                  _buildQuoteCard(),

                  const SizedBox(height: 20),

                  // Lumo Mascot
                  LumoMascotWidget(onTap: _changeQuote),

                  const Spacer(),

                  // Blocked Apps Count
                  _buildBlockedAppsCount(focusSession),

                  const SizedBox(height: 16),

                  // Stop Button
                  if (!focusSession.strictMode)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _stopFocusSession(false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: const Text('Pause Session'),
                      ),
                    ),

                  if (focusSession.strictMode)
                    Text(
                      'Strict Mode: Session cannot be paused',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Focus Mode Active',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).primaryColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, color: Theme.of(context).primaryColor, size: 16),
              const SizedBox(width: 4),
              Text(
                'Active',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFocusTimer(ActiveFocusSession session) {
    final progress = session.progress;
    final remainingMinutes = session.remainingMinutes;

    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Progress indicator
          Positioned.fill(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),

          // Timer text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$remainingMinutes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'minutes left',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey<int>(_currentQuoteIndex),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          _motivationalQuotes[_currentQuoteIndex],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontStyle: FontStyle.italic,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBlockedAppsCount(ActiveFocusSession session) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            session.blockedApps.isEmpty ? Icons.timer : Icons.block,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            session.blockedApps.isEmpty
                ? 'Tracking focus time'
                : '${session.blockedApps.length} app${session.blockedApps.length == 1 ? '' : 's'} blocked',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
