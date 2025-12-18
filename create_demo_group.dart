import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Script to create a demo public group in Firestore
/// Run this once to add a sample public group that users can join
Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  print('Creating demo public group...');

  try {
    // Create a demo public group
    final demoGroupRef = await firestore.collection('groups').add({
      'name': 'Study Warriors 📚',
      'description': 'Join us for daily focused study sessions! We help each other stay accountable and reach our academic goals together.',
      'creatorId': 'demo_creator_001',
      'memberIds': ['demo_creator_001'],
      'adminIds': ['demo_creator_001'],
      'createdAt': FieldValue.serverTimestamp(),
      'totalFocusTime': 450, // 7.5 hours
      'memberFocusTime': {
        'demo_creator_001': 450,
      },
      'settings': {
        'isPublic': true,
        'allowMemberInvites': true,
        'focusGoalMinutes': 120, // 2 hours daily goal
        'showLeaderboard': true,
      },
    });

    // Add the creator as a member in the members subcollection
    await firestore
        .collection('groups')
        .doc(demoGroupRef.id)
        .collection('members')
        .doc('demo_creator_001')
        .set({
      'userId': 'demo_creator_001',
      'groupId': demoGroupRef.id,
      'displayName': 'Alex Chen',
      'focusTime': 450,
      'joinedAt': FieldValue.serverTimestamp(),
      'isAdmin': true,
      'rank': 1,
    });

    print('✅ Demo group created successfully!');
    print('   Group ID: ${demoGroupRef.id}');
    print('   Name: Study Warriors 📚');
    print('   Members: 1');
    print('   Status: Public');
    print('');
    print('🎉 You can now see this group in "Suggested Groups" section!');
    print('   Go to Groups tab → Look for "Suggested Groups"');
    print('   Tap the group → Tap "Join Group" button');
  } catch (e) {
    print('❌ Error creating demo group: $e');
  }
}
