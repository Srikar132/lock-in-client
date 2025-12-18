import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/presentation/providers/focus_session_provider.dart';
import 'package:lock_in/presentation/providers/blocked_content_provider.dart';
import 'package:lock_in/presentation/providers/auth_provider.dart';

// Active Focus Screen - Where user sees running timer connected to focus session provider
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
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  Future<void> _endSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text('Are you sure you want to end your focus session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(focusSessionProvider.notifier).endSession();
        // Navigator.of(context).pushNamedAndRemoveUntil(
        //   '/', // Navigate back to home or root
        //   (route) => false,
        // );
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
    final theme = Theme.of(context);
    final sessionState = ref.watch(focusSessionProvider);
    final user = ref.watch(currentUserProvider).value;
    
    // Listen to session status changes for navigation
    ref.listen<FocusSessionState>(focusSessionProvider, (previous, next) {
      if (next.status == FocusSessionStatus.completed || 
          next.status == FocusSessionStatus.idle) {
        // Session ended, navigate back
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      }
    });
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back and settings
            _buildHeader(theme, sessionState),
            
            // Tab bar
            _buildTabBar(theme),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTimerTab(theme, sessionState, user),
                  _buildMusicTab(theme),
                  _buildThemesTab(theme),
                ],
              ),
            ),
            
            // Bottom controls
            _buildBottomControls(theme, sessionState),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, FocusSessionState sessionState) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              sessionState.status == FocusSessionStatus.active 
                  ? 'Focus Session Active'
                  : sessionState.status == FocusSessionStatus.paused
                      ? 'Focus Session Paused'
                      : 'Focus Session',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Show settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Timer'),
          Tab(text: 'Music'),
          Tab(text: 'Themes'),
        ],
      ),
    );
  }

  Widget _buildTimerTab(ThemeData theme, FocusSessionState sessionState, dynamic user) {
    final elapsedSeconds = sessionState.elapsedSeconds ?? 0;
    final remainingSeconds = sessionState.remainingSeconds ?? 0;
    final sessionType = sessionState.sessionType ?? widget.sessionType;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large timer display
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 4,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(elapsedSeconds),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (remainingSeconds > 0) ...[
                    Text(
                      'Remaining: ${_formatTime(remainingSeconds)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Session type and status
          Column(
            children: [
              Text(
                sessionType.toUpperCase(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sessionState.status == FocusSessionStatus.active
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sessionState.status == FocusSessionStatus.active
                      ? 'ACTIVE'
                      : sessionState.status == FocusSessionStatus.paused
                          ? 'PAUSED'
                          : 'PREPARING',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: sessionState.status == FocusSessionStatus.active
                        ? Colors.green
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Stats row - Get blocked content stats
          user != null ? Consumer(
            builder: (context, ref, child) {
              final blockedContentAsync = ref.watch(blockedContentProvider(user.uid));
              return blockedContentAsync.when(
                data: (content) {
                  final blockedAppsCount = content.permanentlyBlockedApps.length;
                  final blockedWebsitesCount = content.blockedWebsites
                      .where((w) => w.isActive)
                      .length;
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatCard('Apps Blocked', '$blockedAppsCount', theme),
                      const SizedBox(width: 16),
                      _buildStatCard('Websites Blocked', '$blockedWebsitesCount', theme),
                    ],
                  );
                },
                loading: () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatCard('Apps Blocked', '...', theme),
                    const SizedBox(width: 16),
                    _buildStatCard('Websites Blocked', '...', theme),
                  ],
                ),
                error: (_, __) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatCard('Apps Blocked', '0', theme),
                    const SizedBox(width: 16),
                    _buildStatCard('Websites Blocked', '0', theme),
                  ],
                ),
              );
            },
          ) : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatCard('Apps Blocked', '0', theme),
              const SizedBox(width: 16),
              _buildStatCard('Websites Blocked', '0', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMusicTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Focus Music', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildMusicTile('Lo-fi Beats', 'Chill study vibes', theme),
        _buildMusicTile('Classical Piano', 'Bach & Mozart', theme),
        _buildMusicTile('Nature Sounds', 'Rain & Forest', theme),
        _buildMusicTile('White Noise', 'Pure focus', theme),
      ],
    );
  }

  Widget _buildThemesTab(ThemeData theme) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildThemeCard('Ocean', Colors.blue.shade900, theme),
        _buildThemeCard('Forest', Colors.green.shade900, theme),
        _buildThemeCard('Sunset', Colors.orange.shade900, theme),
        _buildThemeCard('Night', Colors.indigo.shade900, theme),
      ],
    );
  }

  Widget _buildBottomControls(ThemeData theme, FocusSessionState sessionState) {
    final isPaused = sessionState.status == FocusSessionStatus.paused;
    final isActive = sessionState.status == FocusSessionStatus.active;
    final canControl = isActive || isPaused;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pause/Resume button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canControl ? (isPaused ? _resumeSession : _pauseSession) : null,
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
              label: Text(isPaused ? 'Resume' : 'Pause'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: canControl 
                    ? (isPaused ? Colors.green : theme.colorScheme.primary)
                    : theme.colorScheme.outline,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // End button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canControl ? _endSession : null,
              icon: const Icon(Icons.stop),
              label: const Text('End'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: canControl ? Colors.red : theme.colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMusicTile(String title, String subtitle, ThemeData theme) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.music_note),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () {
            // Play music
          },
        ),
      ),
    );
  }

  Widget _buildThemeCard(String name, Color color, ThemeData theme) {
    return Card(
      color: color,
      child: InkWell(
        onTap: () {
          // Apply theme
        },
        child: Center(
          child: Text(
            name,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}