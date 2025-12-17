import 'package:cloud_firestore/cloud_firestore.dart';


class FocusSessionModel {
  final String sessionId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final int plannedDuration;
  final int? actualDuration;
  final String sessionType;
  final String status;
  final String date; // "2024-01-15"
  final double completionRate;

  FocusSessionModel({
    required this.sessionId,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.plannedDuration,
    this.actualDuration,
    required this.sessionType,
    required this.status,
    required this.date,
    this.completionRate = 0.0,
  });

  factory FocusSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FocusSessionModel(
      sessionId: doc.id,
      userId: data['userId'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null 
          ? (data['endTime'] as Timestamp).toDate() 
          : null,
      plannedDuration: data['plannedDuration'],
      actualDuration: data['actualDuration'],
      sessionType: data['sessionType'],
      status: data['status'],
      date: data['date'],
      completionRate: data['completionRate']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'plannedDuration': plannedDuration,
      'actualDuration': actualDuration,
      'sessionType': sessionType,
      'status': status,
      'date': date,
      'completionRate': completionRate,
    };
  }


  // COPY WITH METHOD
  FocusSessionModel copyWith({
    String? sessionId,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    int? plannedDuration,
    int? actualDuration,
    String? sessionType,
    String? status,
    String? date,
    double? completionRate,
  }) {
    return FocusSessionModel(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      sessionType: sessionType ?? this.sessionType,
      status: status ?? this.status,
      date: date ?? this.date,
      completionRate: completionRate ?? this.completionRate,
    );
  }
}