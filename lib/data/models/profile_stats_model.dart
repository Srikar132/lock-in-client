import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileStatsModel {
  final String userId;
  final int totalTimeSaved; // in minutes
  final int totalTimeFocused; // in minutes
  final int totalInvites;
  final DateTime? lastUpdated;

  const ProfileStatsModel({
    required this.userId,
    this.totalTimeSaved = 0,
    this.totalTimeFocused = 0,
    this.totalInvites = 0,
    this.lastUpdated,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'totalTimeSaved': totalTimeSaved,
      'totalTimeFocused': totalTimeFocused,
      'totalInvites': totalInvites,
      'lastUpdated': lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory ProfileStatsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      return ProfileStatsModel(userId: doc.id);
    }

    return ProfileStatsModel(
      userId: data['userId'] ?? doc.id,
      totalTimeSaved: data['totalTimeSaved'] ?? 0,
      totalTimeFocused: data['totalTimeFocused'] ?? 0,
      totalInvites: data['totalInvites'] ?? 0,
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  ProfileStatsModel copyWith({
    String? userId,
    int? totalTimeSaved,
    int? totalTimeFocused,
    int? totalInvites,
    DateTime? lastUpdated,
  }) {
    return ProfileStatsModel(
      userId: userId ?? this.userId,
      totalTimeSaved: totalTimeSaved ?? this.totalTimeSaved,
      totalTimeFocused: totalTimeFocused ?? this.totalTimeFocused,
      totalInvites: totalInvites ?? this.totalInvites,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  String getFormattedTimeSaved() {
    if (totalTimeSaved < 60) {
      return '${totalTimeSaved}m';
    }
    final hours = totalTimeSaved ~/ 60;
    final minutes = totalTimeSaved % 60;
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }

  String getFormattedTimeFocused() {
    if (totalTimeFocused < 60) {
      return '${totalTimeFocused}m';
    }
    final hours = totalTimeFocused ~/ 60;
    final minutes = totalTimeFocused % 60;
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }
}