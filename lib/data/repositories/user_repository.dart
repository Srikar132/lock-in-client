import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:lock_in/data/models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Update user onboarding status
  Future<void> updateOnboardingStatus(String uid, bool completed) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'hasCompletedOnboarding': completed,
      });
    } catch (e) {
      debugPrint('Error updating onboarding status: $e');
      rethrow;
    }
  }

  // Update permission status
  Future<void> updatePermissionStatus(String uid, bool granted) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'hasGrantedPermissions': granted,
      });
    } catch (e) {
      debugPrint('Error updating permission status: $e');
      rethrow;
    }
  }

  // Update onboarding answers
  Future<void> updateOnboardingAnswers({
    required String uid,
    String? procrastinationLevel,
    List<String>? distractions,
    String? preferredStudyTime,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (procrastinationLevel != null) {
        updates['procrastinationLevel'] = procrastinationLevel;
      }
      if (distractions != null) {
        updates['distractions'] = distractions;
      }
      if (preferredStudyTime != null) {
        updates['preferredStudyTime'] = preferredStudyTime;
      }

      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      debugPrint('Error updating onboarding answers: $e');
      rethrow;
    }
  }

  // Stream user data
  Stream<UserModel?> streamUserData(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }
}
