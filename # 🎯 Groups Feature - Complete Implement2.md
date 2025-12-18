# 🎯 Groups Feature - Complete Implementation Guide

This guide will walk you through implementing the complete Groups feature for the Lock In app from scratch.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Step 1: Data Models](#step-1-data-models)
4. [Step 2: Repository Layer](#step-2-repository-layer)
5. [Step 3: State Management](#step-3-state-management)
6. [Step 4: UI Screens](#step-4-ui-screens)
7. [Step 5: Integration](#step-5-integration)
8. [Step 6: Testing](#step-6-testing)
9. [Troubleshooting](#troubleshooting)

---

## Overview

### What You'll Build

- ✅ Create and manage focus groups
- ✅ Join public/private groups
- ✅ Real-time leaderboards
- ✅ Automatic focus time tracking
- ✅ Member management
- ✅ Group search and discovery
- ✅ Share groups with friends

### Architecture

```
lib/
├── data/
│   ├── models/
│   │   ├── group_model.dart           # Group data structure
│   │   └── group_member_model.dart    # Member data structure
│   └── repositories/
│       └── group_repository.dart      # Database operations
├── presentation/
│   ├── providers/
│   │   └── group_provider.dart        # State management
│   └── screens/
│       ├── groups_screen.dart         # Main groups list
│       ├── create_group_screen.dart   # Create new group
│       └── group_detail_screen.dart   # Group details & leaderboard
```

### Firebase Structure

```
Firestore:
  groups/
    {groupId}/
      - name: string
      - description: string
      - creatorId: string
      - memberIds: array
      - adminIds: array
      - totalFocusTime: number
      - memberFocusTime: map
      - settings: map
      - createdAt: timestamp
      
      members/
        {userId}/
          - userId: string
          - displayName: string
          - focusTime: number
          - joinedAt: timestamp
          - isAdmin: boolean
          - rank: number
```

---

## Prerequisites

### 1. Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.9
  
  # Firebase
  cloud_firestore: ^4.13.6
  firebase_auth: ^4.15.3
  
  # UI & Utils
  intl: ^0.19.0
  share_plus: ^7.2.1
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

Ensure Firebase is already configured in your project:
- ✅ `google-services.json` (Android)
- ✅ `GoogleService-Info.plist` (iOS)
- ✅ Firebase initialized in `main.dart`

---

## Step 1: Data Models

### 1.1 Create Group Model

Create `lib/data/models/group_model.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final List<String> memberIds;
  final List<String> adminIds;
  final String? imageUrl;
  final DateTime createdAt;
  final int totalFocusTime; // Combined focus time of all members
  final Map<String, int> memberFocusTime; // Per member focus tracking
  final GroupSettings settings;

  const GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.memberIds,
    required this.adminIds,
    this.imageUrl,
    required this.createdAt,
    this.totalFocusTime = 0,
    this.memberFocusTime = const {},
    required this.settings,
  });

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'totalFocusTime': totalFocusTime,
      'memberFocusTime': memberFocusTime,
      'settings': settings.toMap(),
    };
  }

  // Create from Firestore
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      creatorId: data['creatorId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      adminIds: List<String>.from(data['adminIds'] ?? []),
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      totalFocusTime: data['totalFocusTime'] ?? 0,
      memberFocusTime: Map<String, int>.from(data['memberFocusTime'] ?? {}),
      settings: GroupSettings.fromMap(data['settings'] ?? {}),
    );
  }

  // Copy with method for updates
  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    List<String>? memberIds,
    List<String>? adminIds,
    String? imageUrl,
    DateTime? createdAt,
    int? totalFocusTime,
    Map<String, int>? memberFocusTime,
    GroupSettings? settings,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      totalFocusTime: totalFocusTime ?? this.totalFocusTime,
      memberFocusTime: memberFocusTime ?? this.memberFocusTime,
      settings: settings ?? this.settings,
    );
  }

  // Helper methods
  bool isMember(String userId) => memberIds.contains(userId);
  bool isAdmin(String userId) => adminIds.contains(userId);
  bool isCreator(String userId) => creatorId == userId;
  
  String getFormattedFocusTime() {
    if (totalFocusTime < 60) return '${totalFocusTime}m';
    final hours = totalFocusTime ~/ 60;
    final minutes = totalFocusTime % 60;
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }
}

// Group Settings Model
class GroupSettings {
  final bool isPublic;
  final bool allowMemberInvites;
  final int focusGoalMinutes;
  final bool showLeaderboard;

  const GroupSettings({
    this.isPublic = false,
    this.allowMemberInvites = true,
    this.focusGoalMinutes = 0,
    this.showLeaderboard = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'isPublic': isPublic,
      'allowMemberInvites': allowMemberInvites,
      'focusGoalMinutes': focusGoalMinutes,
      'showLeaderboard': showLeaderboard,
    };
  }

  factory GroupSettings.fromMap(Map<String, dynamic> map) {
    return GroupSettings(
      isPublic: map['isPublic'] ?? false,
      allowMemberInvites: map['allowMemberInvites'] ?? true,
      focusGoalMinutes: map['focusGoalMinutes'] ?? 0,
      showLeaderboard: map['showLeaderboard'] ?? true,
    );
  }
}
```

**✅ Verification:**
- Run: `flutter analyze lib/data/models/group_model.dart`
- Should show no errors

### 1.2 Create Group Member Model

Create `lib/data/models/group_member_model.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMemberModel {
  final String userId;
  final String groupId;
  final String displayName;
  final String? photoUrl;
  final int focusTime; // in minutes
  final DateTime joinedAt;
  final bool isAdmin;
  final int rank; // Position in leaderboard

  const GroupMemberModel({
    required this.userId,
    required this.groupId,
    required this.displayName,
    this.photoUrl,
    this.focusTime = 0,
    required this.joinedAt,
    this.isAdmin = false,
    this.rank = 0,
  });

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'groupId': groupId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'focusTime': focusTime,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isAdmin': isAdmin,
      'rank': rank,
    };
  }

  // Create from Firestore
  factory GroupMemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return GroupMemberModel(
      userId: data['userId'] ?? '',
      groupId: data['groupId'] ?? '',
      displayName: data['displayName'] ?? 'Unknown',
      photoUrl: data['photoUrl'],
      focusTime: data['focusTime'] ?? 0,
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      isAdmin: data['isAdmin'] ?? false,
      rank: data['rank'] ?? 0,
    );
  }

  // Format focus time for display
  String getFormattedFocusTime() {
    if (focusTime < 60) return '${focusTime}m';
    final hours = focusTime ~/ 60;
    final minutes = focusTime % 60;
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }

  // Copy with method
  GroupMemberModel copyWith({
    String? userId,
    String? groupId,
    String? displayName,
    String? photoUrl,
    int? focusTime,
    DateTime? joinedAt,
    bool? isAdmin,
    int? rank,
  }) {
    return GroupMemberModel(
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      focusTime: focusTime ?? this.focusTime,
      joinedAt: joinedAt ?? this.joinedAt,
      isAdmin: isAdmin ?? this.isAdmin,
      rank: rank ?? this.rank,
    );
  }
}
```

**✅ Verification:**
- Run: `flutter analyze lib/data/models/group_member_model.dart`
- Should show no errors

---

## Step 2: Repository Layer

### 2.1 Create Group Repository

Create `lib/data/repositories/group_repository.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_model.dart';
import '../models/group_member_model.dart';

// Provider for repository
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(FirebaseFirestore.instance);
});

class GroupRepository {
  final FirebaseFirestore _firestore;

  GroupRepository(this._firestore);

  // ==================== CREATE ====================
  
  /// Creates a new group and adds the creator as the first member
  Future<String> createGroup({
    required String name,
    required String description,
    required String creatorId,
    required String creatorDisplayName,
    required GroupSettings settings,
  }) async {
    try {
      // Create group document
      final docRef = await _firestore.collection('groups').add({
        'name': name,
        'description': description,
        'creatorId': creatorId,
        'memberIds': [creatorId],
        'adminIds': [creatorId],
        'createdAt': FieldValue.serverTimestamp(),
        'totalFocusTime': 0,
        'memberFocusTime': {creatorId: 0},
        'settings': settings.toMap(),
      });

      // Add creator as first member
      await _firestore
          .collection('groups')
          .doc(docRef.id)
          .collection('members')
          .doc(creatorId)
          .set({
        'userId': creatorId,
        'groupId': docRef.id,
        'displayName': creatorDisplayName,
        'focusTime': 0,
        'joinedAt': FieldValue.serverTimestamp(),
        'isAdmin': true,
        'rank': 1,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  // ==================== READ ====================

  /// Get all groups where user is a member
  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupModel.fromFirestore(doc))
            .toList());
  }

  /// Get a specific group by ID
  Stream<GroupModel?> getGroup(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .snapshots()
        .map((doc) => doc.exists ? GroupModel.fromFirestore(doc) : null);
  }

  /// Get all members of a group
  Stream<List<GroupMemberModel>> getGroupMembers(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .orderBy('focusTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupMemberModel.fromFirestore(doc))
            .toList());
  }

  /// Search for public groups
  Stream<List<GroupModel>> searchPublicGroups(String query) {
    return _firestore
        .collection('groups')
        .where('settings.isPublic', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupModel.fromFirestore(doc))
            .where((group) =>
                group.name.toLowerCase().contains(query.toLowerCase()))
            .toList());
  }

  // ==================== UPDATE ====================

  /// Join an existing group
  Future<void> joinGroup(
    String groupId,
    String userId,
    String displayName,
  ) async {
    try {
      final batch = _firestore.batch();

      // Add user to group's memberIds
      final groupRef = _firestore.collection('groups').doc(groupId);
      batch.update(groupRef, {
        'memberIds': FieldValue.arrayUnion([userId]),
        'memberFocusTime.$userId': 0,
      });

      // Add member document
      final memberRef = groupRef.collection('members').doc(userId);
      batch.set(memberRef, {
        'userId': userId,
        'groupId': groupId,
        'displayName': displayName,
        'focusTime': 0,
        'joinedAt': FieldValue.serverTimestamp(),
        'isAdmin': false,
        'rank': 0,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to join group: $e');
    }
  }

  /// Update group focus time when user completes a session
  Future<void> updateGroupFocusTime(
    String groupId,
    String userId,
    int focusMinutes,
  ) async {
    try {
      final batch = _firestore.batch();

      // Update group total and member focus time
      final groupRef = _firestore.collection('groups').doc(groupId);
      batch.update(groupRef, {
        'totalFocusTime': FieldValue.increment(focusMinutes),
        'memberFocusTime.$userId': FieldValue.increment(focusMinutes),
      });

      // Update member focus time
      final memberRef = groupRef.collection('members').doc(userId);
      batch.update(memberRef, {
        'focusTime': FieldValue.increment(focusMinutes),
      });

      await batch.commit();

      // Update rankings (async, doesn't block)
      _updateGroupRankings(groupId);
    } catch (e) {
      throw Exception('Failed to update group focus time: $e');
    }
  }

  /// Update member rankings in group (internal method)
  Future<void> _updateGroupRankings(String groupId) async {
    try {
      final membersSnapshot = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .orderBy('focusTime', descending: true)
          .get();

      final batch = _firestore.batch();
      
      for (var i = 0; i < membersSnapshot.docs.length; i++) {
        batch.update(membersSnapshot.docs[i].reference, {'rank': i + 1});
      }

      await batch.commit();
    } catch (e) {
      print('Failed to update rankings: $e');
    }
  }

  // ==================== DELETE ====================

  /// Leave a group (removes user from members)
  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Remove user from group's memberIds
      final groupRef = _firestore.collection('groups').doc(groupId);
      batch.update(groupRef, {
        'memberIds': FieldValue.arrayRemove([userId]),
        'adminIds': FieldValue.arrayRemove([userId]),
        'memberFocusTime.$userId': FieldValue.delete(),
      });

      // Delete member document
      final memberRef = groupRef.collection('members').doc(userId);
      batch.delete(memberRef);

      await batch.commit();

      // Update rankings after member leaves
      _updateGroupRankings(groupId);
    } catch (e) {
      throw Exception('Failed to leave group: $e');
    }
  }

  /// Delete entire group (admin only)
  Future<void> deleteGroup(String groupId) async {
    try {
      // Delete all members first
      final membersSnapshot = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .get();

      final batch = _firestore.batch();
      
      for (var doc in membersSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete group document
      batch.delete(_firestore.collection('groups').doc(groupId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }

  // ==================== UTILITY ====================

  /// Check if user is member of group
  Future<bool> isMember(String groupId, String userId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (!doc.exists) return false;
      
      final memberIds = List<String>.from(doc.data()?['memberIds'] ?? []);
      return memberIds.contains(userId);
    } catch (e) {
      return false;
    }
  }

  /// Check if user is admin of group
  Future<bool> isAdmin(String groupId, String userId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (!doc.exists) return false;
      
      final adminIds = List<String>.from(doc.data()?['adminIds'] ?? []);
      return adminIds.contains(userId);
    } catch (e) {
      return false;
    }
  }
}
```

**✅ Verification:**
- Run: `flutter analyze lib/data/repositories/group_repository.dart`
- Should show no errors

---

## Step 3: State Management

### 3.1 Create Group Providers

Create `lib/presentation/providers/group_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/group_model.dart';
import '../../data/models/group_member_model.dart';
import '../../data/repositories/group_repository.dart';

// ==================== STREAM PROVIDERS ====================

/// Get all groups where user is a member
final userGroupsProvider = StreamProvider.family<List<GroupModel>, String>((ref, userId) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getUserGroups(userId);
});

/// Get a specific group by ID
final groupProvider = StreamProvider.family<GroupModel?, String>((ref, groupId) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroup(groupId);
});

/// Get all members of a group
final groupMembersProvider = StreamProvider.family<List<GroupMemberModel>, String>((ref, groupId) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroupMembers(groupId);
});

/// Search for public groups
final groupSearchProvider = StreamProvider.family<List<GroupModel>, String>((ref, query) {
  if (query.isEmpty) {
    return Stream.value([]);
  }
  final repository = ref.watch(groupRepositoryProvider);
  return repository.searchPublicGroups(query);
});

// ==================== ACTION PROVIDERS ====================

/// Provider for group actions (create, join, leave, etc.)
final groupActionsProvider = Provider<GroupActions>((ref) {
  return GroupActions(ref.watch(groupRepositoryProvider));
});

/// Class containing all group action methods
class GroupActions {
  final GroupRepository _repository;

  GroupActions(this._repository);

  /// Create a new group
  Future<String> createGroup({
    required String name,
    required String description,
    required String creatorId,
    required String creatorDisplayName,
    required GroupSettings settings,
  }) {
    return _repository.createGroup(
      name: name,
      description: description,
      creatorId: creatorId,
      creatorDisplayName: creatorDisplayName,
      settings: settings,
    );
  }

  /// Join an existing group
  Future<void> joinGroup(
    String groupId,
    String userId,
    String displayName,
  ) {
    return _repository.joinGroup(groupId, userId, displayName);
  }

  /// Leave a group
  Future<void> leaveGroup(String groupId, String userId) {
    return _repository.leaveGroup(groupId, userId);
  }

  /// Update group focus time after completing a session
  Future<void> updateGroupFocusTime(
    String groupId,
    String userId,
    int minutes,
  ) {
    return _repository.updateGroupFocusTime(groupId, userId, minutes);
  }

  /// Delete a group (admin only)
  Future<void> deleteGroup(String groupId) {
    return _repository.deleteGroup(groupId);
  }

  /// Check if user is member
  Future<bool> isMember(String groupId, String userId) {
    return _repository.isMember(groupId, userId);
  }

  /// Check if user is admin
  Future<bool> isAdmin(String groupId, String userId) {
    return _repository.isAdmin(groupId, userId);
  }
}

// ==================== STATE PROVIDERS ====================

/// Provider to track selected group
final selectedGroupProvider = StateProvider<String?>((ref) => null);

/// Provider to track group creation loading state
final groupCreationLoadingProvider = StateProvider<bool>((ref) => false);
```

**✅ Verification:**
- Run: `flutter analyze lib/presentation/providers/group_provider.dart`
- Should show no errors

---

## Step 4: UI Screens

### 4.1 Groups List Screen

Create `lib/presentation/screens/groups_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: Text(
            'Please login to view groups',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final groupsAsync = ref.watch(userGroupsProvider(user.uid));

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text(
          'Groups',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(
                context: context,
                delegate: GroupSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _GroupCard(group: group);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF82D65D)),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateGroupScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF82D65D),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'Create Group',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF82D65D).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group_outlined,
              size: 60,
              color: Color(0xFF82D65D),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'No Groups Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Create or join a group to\nstay focused together',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGroupScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF82D65D),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text(
              'Create Group',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Group Card Widget
class _GroupCard extends ConsumerWidget {
  final dynamic group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: const Color(0xFF2D2D2D),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(groupId: group.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Group Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF82D65D),
                      const Color(0xFF82D65D).withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.group,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              // Group Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.people,
                          color: Colors.white54,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.memberIds.length} members',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Color(0xFF82D65D),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          group.getFormattedFocusTime(),
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
              const Icon(
                Icons.chevron_right,
                color: Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Search Delegate for finding groups
class GroupSearchDelegate extends SearchDelegate<String> {
  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: Colors.white),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Consumer(
        builder: (context, ref, child) {
          if (query.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 64,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Search for public groups',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final searchResults = ref.watch(groupSearchProvider(query));
          
          return searchResults.when(
            data: (groups) {
              if (groups.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.white24,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No groups found',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  return _GroupCard(group: groups[index]);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF82D65D)),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error: $error',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

**Continue to Part 2 of documentation...**

---

## ⏭️ Next Steps

The documentation continues with:
- Create Group Screen (Step 4.2)
- Group Detail Screen (Step 4.3)
- Integration with Focus Sessions (Step 5)
- Testing Guide (Step 6)
- Troubleshooting (Step 7)

Would you like me to continue with Part 2?
