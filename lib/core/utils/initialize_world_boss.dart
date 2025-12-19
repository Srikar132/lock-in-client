import 'package:cloud_firestore/cloud_firestore.dart';

/// Initialize a World Boss for testing
/// Call this once from your app to create the first boss
Future<void> initializeWorldBoss() async {
  final firestore = FirebaseFirestore.instance;

  // Check if there's already an active boss
  final activeBoss = await firestore
      .collection('challenges')
      .where('type', isEqualTo: 'worldBoss')
      .where('status', isEqualTo: 'active')
      .limit(1)
      .get();

  if (activeBoss.docs.isNotEmpty) {
    print('✅ World Boss already exists');
    return;
  }

  // Create a new boss
  final now = DateTime.now();
  final endTime = now.add(const Duration(days: 7));

  await firestore.collection('challenges').add({
    'type': 'worldBoss',
    'bossName': 'Digital Distraction Dragon',
    'bossDescription': 'Defeat this beast through focused work!',
    'maxHP': 100000,
    'currentHP': 100000,
    'startTime': Timestamp.fromDate(now),
    'endTime': Timestamp.fromDate(endTime),
    'status': 'active',
    'totalContributors': 0,
    'userContributions': {},
    'minimumContributionMinutes': 300, // 5 hours
    'createdAt': Timestamp.fromDate(now),
  });

  print('✅ World Boss created successfully!');
  print('Name: Digital Distraction Dragon');
  print('HP: 100,000');
  print('Duration: 7 days');
  print('Minimum contribution: 5 hours');
}
