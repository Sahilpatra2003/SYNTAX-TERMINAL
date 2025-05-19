import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:safety_app/models/report.dart';

class FirestoreService {
  final CollectionReference _reportsCollection = FirebaseFirestore.instance.collection('reports');

  Future<void> addReport(Report report) async {
    try {
      await _reportsCollection.doc(report.id).set(report.toMap());
      debugPrint('Report added to Firestore: ${report.id}');
    } catch (e) {
      debugPrint('Error adding report: $e');
      rethrow;
    }
  }

  Future<List<Report>> getReports() async {
    try {
      final snapshot = await _reportsCollection.get();
      final reports = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Report.fromMap(data);
      }).toList();
      debugPrint('Fetched ${reports.length} reports from Firestore');
      return reports;
    } catch (e) {
      debugPrint('Error fetching reports: $e');
      rethrow;
    }
  }

  // Delete all reports associated with a user
  Future<void> deleteUserReports(String userId) async {
    try {
      final snapshot = await _reportsCollection.where('userId', isEqualTo: userId).get();
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('Deleted ${snapshot.docs.length} reports for user ID: $userId');
    } catch (e) {
      debugPrint('Error deleting user reports: $e');
      rethrow;
    }
  }
}