import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:lock_in/data/models/group_model.dart';
import 'package:lock_in/data/models/group_member_model.dart';
import 'package:lock_in/data/models/group_goal_model.dart';

class GroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== GROUP CRUD ==========

  // Create a new group
  Future<String> createGroup({
    required String name,
    required String description,
    required String creatorId,
    String? photoURL,
    GroupPrivacy privacy = GroupPrivacy.public,
    bool requiresApproval = false,
    int maxMembers = 50,
    List<String> categories = const [],
  }) async {
    try {
      final inviteCode = _generateInviteCode();
      final now = DateTime.now();

      final groupRef = _firestore.collection('groups').doc();
      
      final group = GroupModel(
        id: groupRef.id,
        name: name,
        description: description,
        photoURL: photoURL,
        creatorId: creatorId,
        createdAt: now,
        updatedAt: now,
        privacy: privacy,
        requiresApproval: requiresApproval,
        maxMembers: maxMembers,
        inviteCode: inviteCode,
        categories: categories,
      );

      await groupRef.set(group.toFirestore());

      // Add creator as admin member
      await _firestore
          .collection('groups')
          .doc(groupRef.id)
          .collection('members')
          .doc(creatorId)
          .set({
        'userId': creatorId,
        'groupId': groupRef.id,
        'role': 'admin',
        'status': 'active',
        'joinedAt': Timestamp.fromDate(now),
        'approvedAt': Timestamp.fromDate(now),
        'goalsCompleted': 0,
        'studyTime': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'canInvite': true,
        'canPostGoals': true,
      });

      return groupRef.id;
    } catch (e) {
      debugPrint('Error creating group: $e');
      rethrow;
    }
  }

  // Get group by ID
  Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      
      if (!doc.exists) return null;
      
      return GroupModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting group: $e');
      return null;
    }
  }

  // Update group
  Future<void> updateGroup(String groupId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection('groups').doc(groupId).update(updates);
    } catch (e) {
      debugPrint('Error updating group: $e');
      rethrow;
    }
  }

  // Delete group
  Future<void> deleteGroup(String groupId) async {
    try {
      // Delete all members
      final membersSnapshot = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .get();
      
      for (var doc in membersSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all goals
      final goalsSnapshot = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('goals')
          .get();
      
      for (var doc in goalsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete group
      await _firestore.collection('groups').doc(groupId).delete();
    } catch (e) {
      debugPrint('Error deleting group: $e');
      rethrow;
    }
  }

  // ========== GROUP DISCOVERY ==========

  // Get public groups
  Stream<List<GroupModel>> getPublicGroups({int limit = 20}) {
    return _firestore
        .collection('groups')
        .where('privacy', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupModel.fromFirestore(doc))
            .toList());
  }

  // Search groups by name or category
  Stream<List<GroupModel>> searchGroups(String query) {
    return _firestore
        .collection('groups')
        .where('privacy', isEqualTo: 'public')
        .snapshots()
        .map((snapshot) {
      final groups = snapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc))
          .toList();
      
      // Filter by name or categories
      return groups.where((group) {
        final nameMatch = group.name.toLowerCase().contains(query.toLowerCase());
        final categoryMatch = group.categories.any((cat) => 
            cat.toLowerCase().contains(query.toLowerCase()));
        return nameMatch || categoryMatch;
      }).toList();
    });
  }

  // Get groups user is a member of
  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _firestore
        .collectionGroup('members')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((snapshot) async {
      List<GroupModel> groups = [];
      
      for (var doc in snapshot.docs) {
        final groupId = doc.reference.parent.parent!.id;
        final groupDoc = await _firestore.collection('groups').doc(groupId).get();
        
        if (groupDoc.exists) {
          groups.add(GroupModel.fromFirestore(groupDoc));
        }
      }
      
      return groups;
    });
  }

  // ========== GROUP MEMBERS ==========

  // Join group
  Future<void> joinGroup({
    required String groupId,
    required String userId,
    required String displayName,
    required String email,
    String? photoURL,
  }) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) throw Exception('Group not found');

      final now = DateTime.now();
      final status = group.requiresApproval ? MemberStatus.pending : MemberStatus.active;

      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .set({
        'userId': userId,
        'groupId': groupId,
        'displayName': displayName,
        'photoURL': photoURL,
        'email': email,
        'role': 'member',
        'status': status.name,
        'joinedAt': Timestamp.fromDate(now),
        'approvedAt': status == MemberStatus.active ? Timestamp.fromDate(now) : null,
        'goalsCompleted': 0,
        'studyTime': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'canInvite': true,
        'canPostGoals': true,
      });

      // Update member count if approved immediately
      if (status == MemberStatus.active) {
        await _firestore.collection('groups').doc(groupId).update({
          'memberCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint('Error joining group: $e');
      rethrow;
    }
  }

  // Join group by invite code
  Future<String?> joinGroupByInviteCode({
    required String inviteCode,
    required String userId,
    required String displayName,
    required String email,
    String? photoURL,
  }) async {
    try {
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (groupsSnapshot.docs.isEmpty) {
        return null; // Invalid code
      }

      final groupId = groupsSnapshot.docs.first.id;

      await joinGroup(
        groupId: groupId,
        userId: userId,
        displayName: displayName,
        email: email,
        photoURL: photoURL,
      );

      return groupId;
    } catch (e) {
      debugPrint('Error joining group by invite code: $e');
      rethrow;
    }
  }

  // Leave group
  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .delete();

      await _firestore.collection('groups').doc(groupId).update({
        'memberCount': FieldValue.increment(-1),
      });
    } catch (e) {
      debugPrint('Error leaving group: $e');
      rethrow;
    }
  }

  // Get group members
  Stream<List<GroupMemberModel>> getGroupMembers(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((snapshot) async {
      List<GroupMemberModel> members = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Get user display name and photo from users collection
        final userDoc = await _firestore.collection('users').doc(doc.id).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          data['displayName'] = userData['displayName'] ?? data['displayName'];
          data['photoURL'] = userData['photoURL'] ?? data['photoURL'];
          data['email'] = userData['email'] ?? data['email'];
        }
        members.add(GroupMemberModel.fromMap(data));
      }
      
      return members;
    });
  }

  // Update member role
  Future<void> updateMemberRole(String groupId, String userId, MemberRole role) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .update({'role': role.name});
    } catch (e) {
      debugPrint('Error updating member role: $e');
      rethrow;
    }
  }

  // Approve pending member
  Future<void> approveMember(String groupId, String userId) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .update({
        'status': 'active',
        'approvedAt': Timestamp.fromDate(DateTime.now()),
      });

      await _firestore.collection('groups').doc(groupId).update({
        'memberCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error approving member: $e');
      rethrow;
    }
  }

  // ========== GROUP GOALS ==========

  // Create group goal
  Future<String> createGroupGoal({
    required String groupId,
    required String title,
    required String description,
    required String createdBy,
    required String createdByName,
    required GoalType type,
    required DateTime startDate,
    required DateTime endDate,
    int targetMinutes = 0,
    int targetSessions = 0,
    bool isShared = true,
    bool isCompetitive = false,
  }) async {
    try {
      final goalRef = _firestore
          .collection('groups')
          .doc(groupId)
          .collection('goals')
          .doc();

      final goal = GroupGoalModel(
        id: goalRef.id,
        groupId: groupId,
        title: title,
        description: description,
        createdBy: createdBy,
        createdByName: createdByName,
        type: type,
        status: GoalStatus.inProgress,
        createdAt: DateTime.now(),
        startDate: startDate,
        endDate: endDate,
        targetMinutes: targetMinutes,
        targetSessions: targetSessions,
        isShared: isShared,
        isCompetitive: isCompetitive,
      );

      await goalRef.set(goal.toFirestore());
      return goalRef.id;
    } catch (e) {
      debugPrint('Error creating group goal: $e');
      rethrow;
    }
  }

  // Get group goals
  Stream<List<GroupGoalModel>> getGroupGoals(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('goals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupGoalModel.fromFirestore(doc))
            .toList());
  }

  // Update goal progress
  Future<void> updateGoalProgress({
    required String groupId,
    required String goalId,
    required String userId,
    int? minutesToAdd,
    int? sessionsToAdd,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (minutesToAdd != null && minutesToAdd > 0) {
        updates['completedMinutes'] = FieldValue.increment(minutesToAdd);
      }
      
      if (sessionsToAdd != null && sessionsToAdd > 0) {
        updates['completedSessions'] = FieldValue.increment(sessionsToAdd);
      }

      if (updates.isNotEmpty) {
        await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('goals')
            .doc(goalId)
            .update(updates);

        // Mark user as having completed the goal
        await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('goals')
            .doc(goalId)
            .update({
          'completedByUserIds': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      debugPrint('Error updating goal progress: $e');
      rethrow;
    }
  }

  // ========== UTILITIES ==========

  // Generate unique invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Get member info
  Future<GroupMemberModel?> getMemberInfo(String groupId, String userId) async {
    try {
      final doc = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      return GroupMemberModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting member info: $e');
      return null;
    }
  }

  // Update member stats
  Future<void> updateMemberStats({
    required String groupId,
    required String userId,
    int? goalsCompleted,
    int? studyTime,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (goalsCompleted != null) {
        updates['goalsCompleted'] = FieldValue.increment(goalsCompleted);
      }
      
      if (studyTime != null) {
        updates['studyTime'] = FieldValue.increment(studyTime);
      }

      if (updates.isNotEmpty) {
        updates['lastActiveDate'] = Timestamp.fromDate(DateTime.now());
        
        await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .doc(userId)
            .update(updates);
      }
    } catch (e) {
      debugPrint('Error updating member stats: $e');
      rethrow;
    }
  }
}
