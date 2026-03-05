import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pilot_report.dart';
class PilotReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Collection name
  static const String collectionName = 'pilot_reports';
  // Save a new pilot report
  Future<void> saveReport(PilotReport report) async {
    try {
      await _firestore.collection(collectionName).add(report.toMap());
    } catch (e) {
      debugPrint("Error saving pilot report: $e");
      rethrow;
    }
  }

  // Get reports for a site for a specific date (from midnight of that day to midnight of next day)
  Stream<List<PilotReport>> getRecentReports(
    String siteId, {
    DateTime? targetDate,
  }) {
    final date = targetDate ?? DateTime.now();
    final dayMidnight = DateTime(date.year, date.month, date.day);
    final nextDayMidnight = dayMidnight.add(const Duration(days: 1));
    return _firestore
        .collection(collectionName)
        .where('siteId', isEqualTo: siteId)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(dayMidnight),
        )
        .where('timestamp', isLessThan: Timestamp.fromDate(nextDayMidnight))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PilotReport.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get all reports for today (from midnight)
  Stream<List<PilotReport>> getAllRecentReports() {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    return _firestore
        .collection(collectionName)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(todayMidnight),
        )
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PilotReport.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get all reports for today (one-off Future)
  Future<List<PilotReport>> getAllRecentReportsFuture() async {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final snapshot = await _firestore
        .collection(collectionName)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(todayMidnight),
        )
        .get();
    return snapshot.docs.map((doc) {
      return PilotReport.fromMap(doc.data(), doc.id);
    }).toList();
  }

  // Delete a report
  Future<void> deleteReport(String reportId) async {
    try {
      await _firestore.collection(collectionName).doc(reportId).delete();
    } catch (e) {
      debugPrint("Error deleting pilot report: $e");
      rethrow;
    }
  }

  // Cleanup old reports (older than today)
  Future<void> cleanupOldReports() async {
    try {
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final oldReports = await _firestore
          .collection(collectionName)
          .where('timestamp', isLessThan: Timestamp.fromDate(todayMidnight))
          .get();
      if (oldReports.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (var doc in oldReports.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint("Cleaned up ${oldReports.docs.length} old reports");
    } catch (e) {
      debugPrint("Error cleaning up old reports: $e");
    }
  }
}
