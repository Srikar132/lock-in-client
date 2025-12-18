# 🎯 Groups Feature - Complete Implementation Guide (Part 2)

**Continuation: Create Group Screen, Group Details, Integration & Testing**

---

## 📋 Table of Contents

1. [Step 4.2: Create Group Screen](#step-42-create-group-screen)
2. [Step 4.3: Group Detail Screen](#step-43-group-detail-screen)
3. [Step 5: Integration with Focus Sessions](#step-5-integration-with-focus-sessions)
4. [Step 6: Testing](#step-6-testing)
5. [Step 7: Troubleshooting](#step-7-troubleshooting)
6. [Step 8: Firebase Security Rules](#step-8-firebase-security-rules)
7. [Step 9: Advanced Features](#step-9-advanced-features)

---

## Step 4.2: Create Group Screen

### File Structure
```
lib/presentation/screens/
└── create_group_screen.dart
```

### Implementation

**File:** `lib/presentation/screens/create_group_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/group_model.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';

/// Screen for creating a new group
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Group settings
  bool _isPublic = false;
  bool _allowMemberInvites = true;
  bool _showLeaderboard = true;
  int _focusGoalMinutes = 0;
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Validates and creates the group
  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final groupActions = ref.read(groupActionsProvider);
      
      // Create the group
      final groupId = await groupActions.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        creatorId: user.uid,
        creatorDisplayName: user.displayName ?? 'User',
        settings: GroupSettings(
          isPublic: _isPublic,
          allowMemberInvites: _allowMemberInvites,
          focusGoalMinutes: _focusGoalMinutes,
          showLeaderboard: _showLeaderboard,
        ),
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Group "${_nameController.text}" created!'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF82D65D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        // Navigate back to groups list
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Group',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Group Icon Preview
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF82D65D),
                      const Color(0xFF82D65D).withOpacity(0.6),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF82D65D).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.group,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Group Name Input
            _buildTextField(
              controller: _nameController,
              label: 'Group Name',
              hint: 'e.g., Study Squad, Gym Warriors',
              icon: Icons.groups,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a group name';
                }
                if (value.length < 3) {
                  return 'Name must be at least 3 characters';
                }
                if (value.length > 50) {
                  return 'Name must be less than 50 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Description Input
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'What is this group about?',
              icon: Icons.description,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                if (value.length < 10) {
                  return 'Description must be at least 10 characters';
                }
                if (value.length > 200) {
                  return 'Description must be less than 200 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Settings Section Header
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF82D65D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Group Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Public Group Toggle
            _buildSwitchTile(
              title: 'Public Group',
              subtitle: 'Anyone can find and join this group',
              icon: Icons.public,
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
            ),

            // Allow Member Invites Toggle
            _buildSwitchTile(
              title: 'Member Invites',
              subtitle: 'Allow members to invite others',
              icon: Icons.person_add,
              value: _allowMemberInvites,
              onChanged: (value) => setState(() => _allowMemberInvites = value),
            ),

            // Show Leaderboard Toggle
            _buildSwitchTile(
              title: 'Leaderboard',
              subtitle: 'Show member rankings and competition',
              icon: Icons.emoji_events,
              value: _showLeaderboard,
              onChanged: (value) => setState(() => _showLeaderboard = value),
            ),

            const SizedBox(height: 20),

            // Daily Focus Goal Slider
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF82D65D).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF82D65D).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.flag,
                          color: Color(0xFF82D65D),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Daily Focus Goal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set a daily focus target (optional)',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Slider with current value
                  Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF82D65D),
                            inactiveTrackColor: Colors.white24,
                            thumbColor: const Color(0xFF82D65D),
                            overlayColor: const Color(0xFF82D65D).withOpacity(0.2),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 12,
                            ),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _focusGoalMinutes.toDouble(),
                            min: 0,
                            max: 480, // 8 hours
                            divisions: 48, // 10-minute increments
                            onChanged: (value) {
                              setState(() => _focusGoalMinutes = value.toInt());
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Current value display
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF82D65D).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF82D65D).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _focusGoalMinutes == 0
                              ? 'None'
                              : _focusGoalMinutes < 60
                                  ? '${_focusGoalMinutes}m'
                                  : '${_focusGoalMinutes ~/ 60}h ${_focusGoalMinutes % 60}m',
                          style: const TextStyle(
                            color: Color(0xFF82D65D),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Quick select buttons
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickSelectChip(0, 'None'),
                      _buildQuickSelectChip(30, '30m'),
                      _buildQuickSelectChip(60, '1h'),
                      _buildQuickSelectChip(120, '2h'),
                      _buildQuickSelectChip(240, '4h'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Create Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF82D65D),
                  disabledBackgroundColor: const Color(0xFF82D65D).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'Create Group',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Build text input field with custom styling
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF82D65D), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF2D2D2D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF82D65D),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  /// Build switch tile for settings
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value 
              ? const Color(0xFF82D65D).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF82D65D).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF82D65D), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF82D65D),
            activeTrackColor: const Color(0xFF82D65D).withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  /// Build quick select chip for focus goal
  Widget _buildQuickSelectChip(int minutes, String label) {
    final isSelected = _focusGoalMinutes == minutes;
    
    return InkWell(
      onTap: () => setState(() => _focusGoalMinutes = minutes),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF82D65D).withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF82D65D)
                : Colors.white24,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF82D65D) : Colors.white54,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
```

**✅ Verification:**
```bash
flutter analyze lib/presentation/screens/create_group_screen.dart
```

### Features Included:

✅ **Form Validation** - Name and description requirements
✅ **Visual Feedback** - Loading states and animations
✅ **Group Settings** - Public/private, invites, leaderboard
✅ **Focus Goal** - Slider with quick select options
✅ **Error Handling** - User-friendly error messages
✅ **Beautiful UI** - Gradient icons, smooth transitions

---

## Step 4.3: Group Detail Screen

This is the most complex screen with tabs for members and leaderboard.

**File:** `lib/presentation/screens/group_detail_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/group_model.dart';
import '../../data/models/group_member_model.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';

/// Detailed view of a specific group with members and leaderboard
class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupProvider(widget.groupId));
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return _buildErrorState('Group not found');
          }

          final isAdmin = user != null && group.isAdmin(user.uid);
          final isMember = user != null && group.isMember(user.uid);
          final isCreator = user != null && group.isCreator(user.uid);

          return CustomScrollView(
            slivers: [
              // Expandable App Bar with Group Info
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: const Color(0xFF1A1A1A),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  // Share Button
                  if (isMember)
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.share, color: Colors.white),
                      ),
                      onPressed: () => _shareGroup(group),
                    ),
                  
                  // Admin Menu
                  if (isAdmin)
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_vert, color: Colors.white),
                      ),
                      color: const Color(0xFF2D2D2D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'delete' && isCreator) {
                          _deleteGroup(group);
                        } else if (value == 'edit') {
                          // TODO: Implement edit functionality
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Color(0xFF82D65D)),
                              SizedBox(width: 8),
                              Text(
                                'Edit Group',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        if (isCreator)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete Group',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient Background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF82D65D).withOpacity(0.3),
                              const Color(0xFF1A1A1A),
                            ],
                          ),
                        ),
                      ),
                      
                      // Content
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Group Icon
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF82D65D),
                                      const Color(0xFF82D65D).withOpacity(0.6),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF82D65D).withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.group,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Group Name
                              Text(
                                group.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Member Count & Status
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.people,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${group.memberIds.length} members',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (group.settings.isPublic)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF82D65D).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.public,
                                            color: Color(0xFF82D65D),
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Public',
                                            style: TextStyle(
                                              color: Color(0xFF82D65D),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.access_time,
                          label: 'Total Focus',
                          value: group.getFormattedFocusTime(),
                          color: const Color(0xFF82D65D),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.emoji_events,
                          label: 'Daily Goal',
                          value: group.settings.focusGoalMinutes > 0
                              ? '${group.settings.focusGoalMinutes}m'
                              : 'None',
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Description Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF82D65D).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.description,
                                color: Color(0xFF82D65D),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'About',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          group.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Tab Bar (Members & Leaderboard)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF82D65D),
                    unselectedLabelColor: Colors.white54,
                    indicatorColor: const Color(0xFF82D65D),
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.people),
                        text: 'Members',
                      ),
                      Tab(
                        icon: Icon(Icons.emoji_events),
                        text: 'Leaderboard',
                      ),
                    ],
                  ),
                ),
              ),

              // Tab Content
              membersAsync.when(
                data: (members) {
                  return SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMembersTab(members, group),
                        _buildLeaderboardTab(members, group),
                      ],
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF82D65D),
                    ),
                  ),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: _buildErrorState('Error loading members: $error'),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF82D65D)),
        ),
        error: (error, stack) => _buildErrorState('Error: $error'),
      ),
      
      // Bottom Action Button (Join/Leave)
      bottomNavigationBar: groupAsync.whenData((group) {
        if (group == null) return null;
        
        final user = ref.watch(authStateProvider).value;
        if (user == null) return null;

        final isMember = group.isMember(user.uid);
        final isCreator = group.isCreator(user.uid);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isMember
                ? (isCreator 
                    ? null // Creator can't leave their own group
                    : _buildLeaveButton(group))
                : _buildJoinButton(group),
          ),
        );
      }).value,
    );
  }

  /// Build stat card widget
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Build members tab content
  Widget _buildMembersTab(List<GroupMemberModel> members, GroupModel group) {
    if (members.isEmpty) {
      return const Center(
        child: Text(
          'No members yet',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final isAdmin = group.isAdmin(member.userId);
        final isCreator = group.isCreator(member.userId);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCreator 
                  ? const Color(0xFF82D65D).withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF82D65D).withOpacity(0.2),
                    child: Text(
                      member.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF82D65D),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  if (isCreator)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF82D65D),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF2D2D2D),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.black,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              
              // Member Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCreator) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF82D65D).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CREATOR',
                              style: TextStyle(
                                color: Color(0xFF82D65D),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else if (isAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white54,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${member.getFormattedFocusTime()} focused',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build leaderboard tab content
  Widget _buildLeaderboardTab(List<GroupMemberModel> members, GroupModel group) {
    if (!group.settings.showLeaderboard) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_off,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'Leaderboard is disabled',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Sort members by focus time (already sorted from Firestore)
    final sortedMembers = List<GroupMemberModel>.from(members);

    if (sortedMembers.isEmpty) {
      return const Center(
        child: Text(
          'No members yet',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedMembers.length,
      itemBuilder: (context, index) {
        final member = sortedMembers[index];
        final rank = index + 1;
        final medal = member.getMedalEmoji();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: rank <= 3
                  ? (rank == 1
                      ? Colors.amber.withOpacity(0.5)
                      : rank == 2
                          ? Colors.grey.withOpacity(0.5)
                          : Colors.brown.withOpacity(0.5))
                  : Colors.white.withOpacity(0.1),
              width: rank <= 3 ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Rank Badge
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: rank <= 3
                      ? (rank == 1
                          ? Colors.amber.withOpacity(0.2)
                          : rank == 2
                              ? Colors.grey.withOpacity(0.2)
                              : Colors.brown.withOpacity(0.2))
                      : const Color(0xFF82D65D).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: medal != null
                      ? Text(
                          medal,
                          style: const TextStyle(fontSize: 24),
                        )
                      : Text(
                          '#$rank',
                          style: const TextStyle(
                            color: Color(0xFF82D65D),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Member Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Color(0xFF82D65D),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          member.getFormattedFocusTime(),
                          style: const TextStyle(
                            color: Color(0xFF82D65D),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Trophy icon for top 3
              if (rank <= 3)
                Icon(
                  Icons.emoji_events,
                  color: rank == 1
                      ? Colors.amber
                      : rank == 2
                          ? Colors.grey
                          : Colors.brown,
                  size: 28,
                ),
            ],
          ),
        );
      },
    );
  }

  /// Build join button
  Widget _buildJoinButton(GroupModel group) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: () => _joinGroup(group),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF82D65D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_add, color: Colors.black),
            SizedBox(width: 8),
            Text(
              'Join Group',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build leave button
  Widget _buildLeaveButton(GroupModel group) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: () => _leaveGroup(group),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.exit_to_app, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Leave Group',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state widget
  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF82D65D),
            ),
            child: const Text(
              'Go Back',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // Action Methods

  void _shareGroup(GroupModel group) {
    Share.share(
      '🎯 Join my focus group "${group.name}" on Lock In!\n\n'
      '${group.description}\n\n'
      '👥 ${group.memberIds.length} members\n'
      '⏱️ ${group.getFormattedFocusTime()} total focus time\n\n'
      'Group ID: ${group.id}',
      subject: 'Join my focus group: ${group.name}',
    );
  }

  Future<void> _joinGroup(GroupModel group) async {
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      final groupActions = ref.read(groupActionsProvider);
      await groupActions.joinGroup(
        group.id,
        user.uid,
        user.displayName ?? 'User',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Successfully joined "${group.name}"!'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF82D65D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveGroup(GroupModel group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Leave Group?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to leave "${group.name}"?\n\nYour focus time contributions will remain, but you won\'t receive updates.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      final groupActions = ref.read(groupActionsProvider);
      await groupActions.leaveGroup(group.id, user.uid);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Left group successfully'),
            backgroundColor: Color(0xFF82D65D),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteGroup(GroupModel group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text(
              'Delete Group?',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'This action cannot be undone!\n\n'
          'All group data, members, and focus time records will be permanently deleted.\n\n'
          'Are you absolutely sure you want to delete "${group.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final groupActions = ref.read(groupActionsProvider);
      await groupActions.deleteGroup(group.id);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group deleted successfully'),
            backgroundColor: Color(0xFF82D65D),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Delegate for pinned tab bar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
```

**✅ Verification:**
```bash
flutter analyze lib/presentation/screens/group_detail_screen.dart
```

---

## Step 5: Integration with Focus Sessions

### 5.1 Update Focus Session to Sync with Groups

Find your focus session completion handler and add group sync logic.

**Option A: If you have a separate focus session provider**

**File:** `lib/presentation/providers/focus_session_provider.dart`

```dart
// Add this import at the top
import 'group_provider.dart';

// In your focus session completion method, add:

Future<void> completeFocusSession({
  required String userId,
  required int focusMinutes,
}) async {
  try {
    // Your existing logic to update profile stats
    await _updateProfileStats(userId, focusMinutes);
    
    // NEW: Update all user's groups with focus time
    final groups = await ref.read(userGroupsProvider(userId).future);
    
    if (groups.isNotEmpty) {
      final groupActions = ref.read(groupActionsProvider);
      
      // Update each group in parallel
      await Future.wait(
        groups.map((group) => 
          groupActions.updateGroupFocusTime(
            group.id,
            userId,
            focusMinutes,
          )
        ),
      );
      
      print('✅ Updated ${groups.length} groups with $focusMinutes minutes');
    }
  } catch (e) {
    print('❌ Error completing focus session: $e');
    rethrow;
  }
}
```

**Option B: If focus completion is in a screen/widget**

Add this code where you handle focus session completion:

```dart
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';

// After completing a focus session
Future<void> _onFocusSessionComplete(int focusMinutes) async {
  try {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    
    // Update profile stats (your existing code)
    // ...
    
    // Update all groups
    final groupsAsync = await ref.read(userGroupsProvider(user.uid).future);
    
    if (groupsAsync.isNotEmpty) {
      final groupActions = ref.read(groupActionsProvider);
      
      for (final group in groupsAsync) {
        await groupActions.updateGroupFocusTime(
          group.id,
          user.uid,
          focusMinutes,
        );
      }
      
      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Updated ${groupsAsync.length} group(s) with $focusMinutes minutes!',
            ),
            backgroundColor: const Color(0xFF82D65D),
          ),
        );
      }
    }
  } catch (e) {
    print('Error updating groups: $e');
  }
}
```

### 5.2 Add Groups Badge to Profile

Show how many groups the user is in on their profile screen.

**File:** `lib/presentation/screens/profile_screen.dart` (or wherever your profile is)

```dart
// Add this widget to show groups count

Widget _buildGroupsCard(String userId) {
  return Consumer(
    builder: (context, ref, child) {
      final groupsAsync = ref.watch(userGroupsProvider(userId));
      
      return groupsAsync.when(
        data: (groups) => InkWell(
          onTap: () {
            // Navigate to groups tab
            // Or you can navigate to groups screen
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF82D65D).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.group,
                    color: Color(0xFF82D65D),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${groups.length} Groups',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Tap to view all',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      );
    },
  );
}
```

---

## Step 6: Testing

### 6.1 Manual Testing Checklist

**✅ Group Creation**
- [ ] Create a public group
- [ ] Create a private group
- [ ] Try creating with empty name (should fail)
- [ ] Try creating with very long name (should fail)
- [ ] Set focus goal to different values
- [ ] Toggle all settings

**✅ Group Discovery**
- [ ] Search for public groups
- [ ] Search with no results
- [ ] Join a public group
- [ ] Try joining same group twice (should fail)

**✅ Group// filepath: GROUPS_FEATURE_PART2_README.md
# 🎯 Groups Feature - Complete Implementation Guide (Part 2)

**Continuation: Create Group Screen, Group Details, Integration & Testing**

---

## 📋 Table of Contents

1. [Step 4.2: Create Group Screen](#step-42-create-group-screen)
2. [Step 4.3: Group Detail Screen](#step-43-group-detail-screen)
3. [Step 5: Integration with Focus Sessions](#step-5-integration-with-focus-sessions)
4. [Step 6: Testing](#step-6-testing)
5. [Step 7: Troubleshooting](#step-7-troubleshooting)
6. [Step 8: Firebase Security Rules](#step-8-firebase-security-rules)
7. [Step 9: Advanced Features](#step-9-advanced-features)

---

## Step 4.2: Create Group Screen

### File Structure
```
lib/presentation/screens/
└── create_group_screen.dart
```

### Implementation

**File:** `lib/presentation/screens/create_group_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/group_model.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';

/// Screen for creating a new group
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Group settings
  bool _isPublic = false;
  bool _allowMemberInvites = true;
  bool _showLeaderboard = true;
  int _focusGoalMinutes = 0;
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Validates and creates the group
  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final groupActions = ref.read(groupActionsProvider);
      
      // Create the group
      final groupId = await groupActions.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        creatorId: user.uid,
        creatorDisplayName: user.displayName ?? 'User',
        settings: GroupSettings(
          isPublic: _isPublic,
          allowMemberInvites: _allowMemberInvites,
          focusGoalMinutes: _focusGoalMinutes,
          showLeaderboard: _showLeaderboard,
        ),
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Group "${_nameController.text}" created!'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF82D65D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        // Navigate back to groups list
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Group',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Group Icon Preview
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF82D65D),
                      const Color(0xFF82D65D).withOpacity(0.6),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF82D65D).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.group,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Group Name Input
            _buildTextField(
              controller: _nameController,
              label: 'Group Name',
              hint: 'e.g., Study Squad, Gym Warriors',
              icon: Icons.groups,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a group name';
                }
                if (value.length < 3) {
                  return 'Name must be at least 3 characters';
                }
                if (value.length > 50) {
                  return 'Name must be less than 50 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Description Input
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'What is this group about?',
              icon: Icons.description,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                if (value.length < 10) {
                  return 'Description must be at least 10 characters';
                }
                if (value.length > 200) {
                  return 'Description must be less than 200 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Settings Section Header
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF82D65D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Group Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Public Group Toggle
            _buildSwitchTile(
              title: 'Public Group',
              subtitle: 'Anyone can find and join this group',
              icon: Icons.public,
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
            ),

            // Allow Member Invites Toggle
            _buildSwitchTile(
              title: 'Member Invites',
              subtitle: 'Allow members to invite others',
              icon: Icons.person_add,
              value: _allowMemberInvites,
              onChanged: (value) => setState(() => _allowMemberInvites = value),
            ),

            // Show Leaderboard Toggle
            _buildSwitchTile(
              title: 'Leaderboard',
              subtitle: 'Show member rankings and competition',
              icon: Icons.emoji_events,
              value: _showLeaderboard,
              onChanged: (value) => setState(() => _showLeaderboard = value),
            ),

            const SizedBox(height: 20),

            // Daily Focus Goal Slider
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF82D65D).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF82D65D).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.flag,
                          color: Color(0xFF82D65D),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Daily Focus Goal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set a daily focus target (optional)',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Slider with current value
                  Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF82D65D),
                            inactiveTrackColor: Colors.white24,
                            thumbColor: const Color(0xFF82D65D),
                            overlayColor: const Color(0xFF82D65D).withOpacity(0.2),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 12,
                            ),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _focusGoalMinutes.toDouble(),
                            min: 0,
                            max: 480, // 8 hours
                            divisions: 48, // 10-minute increments
                            onChanged: (value) {
                              setState(() => _focusGoalMinutes = value.toInt());
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Current value display
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF82D65D).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF82D65D).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _focusGoalMinutes == 0
                              ? 'None'
                              : _focusGoalMinutes < 60
                                  ? '${_focusGoalMinutes}m'
                                  : '${_focusGoalMinutes ~/ 60}h ${_focusGoalMinutes % 60}m',
                          style: const TextStyle(
                            color: Color(0xFF82D65D),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Quick select buttons
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickSelectChip(0, 'None'),
                      _buildQuickSelectChip(30, '30m'),
                      _buildQuickSelectChip(60, '1h'),
                      _buildQuickSelectChip(120, '2h'),
                      _buildQuickSelectChip(240, '4h'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Create Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF82D65D),
                  disabledBackgroundColor: const Color(0xFF82D65D).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'Create Group',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Build text input field with custom styling
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF82D65D), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF2D2D2D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF82D65D),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  /// Build switch tile for settings
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value 
              ? const Color(0xFF82D65D).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF82D65D).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF82D65D), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF82D65D),
            activeTrackColor: const Color(0xFF82D65D).withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  /// Build quick select chip for focus goal
  Widget _buildQuickSelectChip(int minutes, String label) {
    final isSelected = _focusGoalMinutes == minutes;
    
    return InkWell(
      onTap: () => setState(() => _focusGoalMinutes = minutes),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF82D65D).withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF82D65D)
                : Colors.white24,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF82D65D) : Colors.white54,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
```

**✅ Verification:**
```bash
flutter analyze lib/presentation/screens/create_group_screen.dart
```

### Features Included:

✅ **Form Validation** - Name and description requirements
✅ **Visual Feedback** - Loading states and animations
✅ **Group Settings** - Public/private, invites, leaderboard
✅ **Focus Goal** - Slider with quick select options
✅ **Error Handling** - User-friendly error messages
✅ **Beautiful UI** - Gradient icons, smooth transitions

---

## Step 4.3: Group Detail Screen

This is the most complex screen with tabs for members and leaderboard.

**File:** `lib/presentation/screens/group_detail_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/group_model.dart';
import '../../data/models/group_member_model.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';

/// Detailed view of a specific group with members and leaderboard
class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupProvider(widget.groupId));
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return _buildErrorState('Group not found');
          }

          final isAdmin = user != null && group.isAdmin(user.uid);
          final isMember = user != null && group.isMember(user.uid);
          final isCreator = user != null && group.isCreator(user.uid);

          return CustomScrollView(
            slivers: [
              // Expandable App Bar with Group Info
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: const Color(0xFF1A1A1A),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  // Share Button
                  if (isMember)
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.share, color: Colors.white),
                      ),
                      onPressed: () => _shareGroup(group),
                    ),
                  
                  // Admin Menu
                  if (isAdmin)
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_vert, color: Colors.white),
                      ),
                      color: const Color(0xFF2D2D2D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'delete' && isCreator) {
                          _deleteGroup(group);
                        } else if (value == 'edit') {
                          // TODO: Implement edit functionality
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Color(0xFF82D65D)),
                              SizedBox(width: 8),
                              Text(
                                'Edit Group',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        if (isCreator)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete Group',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient Background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF82D65D).withOpacity(0.3),
                              const Color(0xFF1A1A1A),
                            ],
                          ),
                        ),
                      ),
                      
                      // Content
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Group Icon
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF82D65D),
                                      const Color(0xFF82D65D).withOpacity(0.6),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF82D65D).withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.group,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Group Name
                              Text(
                                group.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Member Count & Status
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.people,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${group.memberIds.length} members',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (group.settings.isPublic)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF82D65D).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.public,
                                            color: Color(0xFF82D65D),
                              …