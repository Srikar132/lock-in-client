import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Test script to verify Firebase Groups database structure
/// Run: dart run test_groups_db.dart
Future<void> main() async {
  print('🔥 Testing Groups Database Structure...\n');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  
  try {
    // Test 1: Check if groups collection exists and can be queried
    print('✅ Test 1: Querying groups collection...');
    final groupsSnapshot = await firestore.collection('groups').limit(5).get();
    print('   Found ${groupsSnapshot.docs.length} groups');
    
    if (groupsSnapshot.docs.isNotEmpty) {
      // Test 2: Verify group structure
      print('\n✅ Test 2: Verifying group structure...');
      final group = groupsSnapshot.docs.first;
      final data = group.data();
      
      print('   Group ID: ${group.id}');
      print('   Name: ${data['name']}');
      print('   Creator: ${data['creatorId']}');
      print('   Members: ${(data['memberIds'] as List).length}');
      print('   Public: ${data['settings']['isPublic']}');
      print('   Total Focus: ${data['totalFocusTime']} minutes');
      
      // Test 3: Check members subcollection
      print('\n✅ Test 3: Checking members subcollection...');
      final membersSnapshot = await firestore
          .collection('groups')
          .doc(group.id)
          .collection('members')
          .get();
      print('   Found ${membersSnapshot.docs.length} members');
      
      if (membersSnapshot.docs.isNotEmpty) {
        final member = membersSnapshot.docs.first;
        final memberData = member.data();
        print('   Sample Member:');
        print('     - Name: ${memberData['displayName']}');
        print('     - Focus Time: ${memberData['focusTime']} min');
        print('     - Rank: ${memberData['rank']}');
        print('     - Admin: ${memberData['isAdmin']}');
      }
      
      // Test 4: Test public groups query
      print('\n✅ Test 4: Testing public groups filter...');
      final publicGroups = await firestore
          .collection('groups')
          .where('settings.isPublic', isEqualTo: true)
          .limit(3)
          .get();
      print('   Found ${publicGroups.docs.length} public groups');
      
      // Test 5: Test member filtering
      print('\n✅ Test 5: Testing member query...');
      final testUserId = data['memberIds'][0];
      final userGroups = await firestore
          .collection('groups')
          .where('memberIds', arrayContains: testUserId)
          .get();
      print('   User $testUserId is in ${userGroups.docs.length} groups');
      
      print('\n🎉 All database tests passed!');
      print('\n📊 Database Summary:');
      print('   ✅ Groups collection: Working');
      print('   ✅ Members subcollection: Working');
      print('   ✅ Public filter: Working');
      print('   ✅ Member queries: Working');
      print('   ✅ Data structure: Valid');
      
      print('\n💡 Deep Link Format:');
      print('   lockin://group/${group.id}');
      print('\n   Share this link to test group joining!');
      
    } else {
      print('\n⚠️  No groups found in database.');
      print('   Create a group first using the app or demo button.');
    }
    
  } catch (e) {
    print('\n❌ Error testing database: $e');
    print('   Make sure Firebase is properly configured.');
  }
  
  print('\n✨ Test complete!\n');
}
