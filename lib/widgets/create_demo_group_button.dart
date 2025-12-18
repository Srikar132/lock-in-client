import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Temporary button to create a demo public group
/// Add this to your Groups screen temporarily, then remove after creating the group
class CreateDemoGroupButton extends StatelessWidget {
  const CreateDemoGroupButton({super.key});

  Future<void> _createDemoGroup(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Create multiple diverse demo public groups
      final demoGroups = [
        {
          'name': 'Study Warriors 📚',
          'description': 'Join us for daily focused study sessions! We help each other stay accountable and reach our academic goals together.',
          'creatorId': 'demo_user_001',
          'displayName': 'Alex Chen',
          'focusTime': 450,
          'memberCount': 1,
        },
        {
          'name': 'Gym Legends 💪',
          'description': 'Early morning workout crew! 6 AM workouts, no excuses. Track your fitness journey with us.',
          'creatorId': 'demo_user_002',
          'displayName': 'Sarah Johnson',
          'focusTime': 320,
          'memberCount': 1,
        },
        {
          'name': 'Coding Masters 💻',
          'description': 'Daily coding practice and deep work sessions. Learn, build, and grow together as developers.',
          'creatorId': 'demo_user_003',
          'displayName': 'Mike Zhang',
          'focusTime': 680,
          'memberCount': 1,
        },
        {
          'name': 'Reading Club 📖',
          'description': 'Book lovers unite! Daily reading sessions and monthly book discussions. Let\'s read more together.',
          'creatorId': 'demo_user_004',
          'displayName': 'Emma Wilson',
          'focusTime': 240,
          'memberCount': 1,
        },
        {
          'name': 'Meditation Circle 🧘',
          'description': 'Daily mindfulness and meditation practice. Find your inner peace and focus with our supportive community.',
          'creatorId': 'demo_user_005',
          'displayName': 'Raj Patel',
          'focusTime': 180,
          'memberCount': 1,
        },
      ];

      for (var group in demoGroups) {
        // Create group
        final groupRef = await firestore.collection('groups').add({
          'name': group['name'],
          'description': group['description'],
          'creatorId': group['creatorId'],
          'memberIds': [group['creatorId']],
          'adminIds': [group['creatorId']],
          'createdAt': FieldValue.serverTimestamp(),
          'totalFocusTime': group['focusTime'],
          'memberFocusTime': {group['creatorId'] as String: group['focusTime']},
          'settings': {
            'isPublic': true,
            'allowMemberInvites': true,
            'focusGoalMinutes': 120,
            'showLeaderboard': true,
          },
        });

        // Add creator as member
        await firestore
            .collection('groups')
            .doc(groupRef.id)
            .collection('members')
            .doc(group['creatorId'] as String)
            .set({
          'userId': group['creatorId'],
          'groupId': groupRef.id,
          'displayName': group['displayName'],
          'focusTime': group['focusTime'],
          'joinedAt': FieldValue.serverTimestamp(),
          'isAdmin': true,
          'rank': 1,
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('✅ ${demoGroups.length} demo groups created!'),
              ],
            ),
            backgroundColor: const Color(0xFF82D65D),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () => _createDemoGroup(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Demo Public Group',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
