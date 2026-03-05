import 'package:cloud_firestore/cloud_firestore.dart';

class PilotReport {
  final String? id;
  final String siteId;
  final String userId;
  final String userName;
  final double windDirection;
  final double windSpeedMin;
  final double windSpeedMax;
  final String observations;
  final String cloudCover;
  final DateTime timestamp;
  PilotReport({
    this.id,
    required this.siteId,
    required this.userId,
    required this.userName,
    required this.windDirection,
    required this.windSpeedMin,
    required this.windSpeedMax,
    this.cloudCover = '0/8',
    this.observations = '',
    required this.timestamp,
  });
  Map<String, dynamic> toMap() {
    return {
      'siteId': siteId,
      'userId': userId,
      'userName': userName,
      'windDirection': windDirection,
      'windSpeedMin': windSpeedMin,
      'windSpeedMax': windSpeedMax,
      'cloudCover': cloudCover,
      'observations': observations,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory PilotReport.fromMap(Map<String, dynamic> map, String id) {
    return PilotReport(
      id: id,
      siteId: map['siteId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous Pilot',
      windDirection: (map['windDirection'] ?? 0.0).toDouble(),
      windSpeedMin: (map['windSpeedMin'] ?? 0.0).toDouble(),
      windSpeedMax: (map['windSpeedMax'] ?? 0.0).toDouble(),
      cloudCover: map['cloudCover'] ?? '0/8',
      observations: map['observations'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
