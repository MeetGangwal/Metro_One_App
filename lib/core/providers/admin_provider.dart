import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

/// Provider for all admin-panel operations:
/// - Announcements CRUD (line-specific)
/// - Peak-hour toggles per metro line
/// - Timetable overrides
class AdminProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  // ==================== ANNOUNCEMENTS ====================

  /// Publish a new announcement
  Future<bool> publishAnnouncement({
    required String message,
    required String category,
    required String line,
  }) async {
    try {
      await _firestore.db.collection('announcements').add({
        'message': message,
        'category': category,
        'line': line,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error publishing announcement: $e');
      return false;
    }
  }

  /// Delete an announcement by document ID
  Future<bool> deleteAnnouncement(String docId) async {
    try {
      await _firestore.db.collection('announcements').doc(docId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting announcement: $e');
      return false;
    }
  }

  /// Stream all announcements ordered by newest first
  Stream<QuerySnapshot> get announcementsStream {
    return _firestore.db
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream only active announcements (for user-facing UI)
  Stream<QuerySnapshot> get activeAnnouncementsStream {
    return _firestore.db
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ==================== PEAK HOURS ====================

  /// Stream peak-hour status for all lines
  Stream<DocumentSnapshot> get peakHoursStream {
    return _firestore.db
        .collection('admin_config')
        .doc('peak_hours')
        .snapshots();
  }

  /// Toggle peak hour for a specific line
  Future<bool> togglePeakHour(String lineId, bool isActive) async {
    try {
      await _firestore.db
          .collection('admin_config')
          .doc('peak_hours')
          .set({lineId: isActive}, SetOptions(merge: true));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error toggling peak hour: $e');
      return false;
    }
  }

  /// Get current peak-hour map (one-shot)
  Future<Map<String, bool>> getPeakHours() async {
    try {
      final doc = await _firestore.db
          .collection('admin_config')
          .doc('peak_hours')
          .get();
      if (!doc.exists) return {};
      final data = doc.data() ?? {};
      return {
        'blue': data['blue'] ?? false,
        'yellow': data['yellow'] ?? false,
        'red': data['red'] ?? false,
        'aqua': data['aqua'] ?? false,
      };
    } catch (e) {
      debugPrint('Error getting peak hours: $e');
      return {};
    }
  }

  // ==================== TIMETABLE ====================

  /// Save timetable overrides for a metro line
  Future<bool> saveStationTiming({
    required String lineId,
    required String stationId,
    required String stationName,
    required String firstTrain,
    required String lastTrain,
    required int frequency,
  }) async {
    try {
      await _firestore.db
          .collection('timetable')
          .doc(lineId)
          .set({
        stationId: {
          'name': stationName,
          'firstTrain': firstTrain,
          'lastTrain': lastTrain,
          'frequency': frequency,
        },
      }, SetOptions(merge: true));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving station timing: $e');
      return false;
    }
  }

  /// Get timetable overrides for a line
  Future<Map<String, dynamic>> getTimetable(String lineId) async {
    try {
      final doc = await _firestore.db
          .collection('timetable')
          .doc(lineId)
          .get();
      return doc.data() ?? {};
    } catch (e) {
      debugPrint('Error getting timetable: $e');
      return {};
    }
  }

  /// Stream timetable data for a line
  Stream<DocumentSnapshot> timetableStream(String lineId) {
    return _firestore.db
        .collection('timetable')
        .doc(lineId)
        .snapshots();
  }

  // ==================== EMERGENCY OPERATIONS ====================

  /// Set the global emergency alert status
  Future<bool> setEmergencyAlert({
    required bool isActive,
    String message = '',
    String type = 'Critical',
  }) async {
    try {
      await _firestore.db
          .collection('admin_config')
          .doc('emergency')
          .set({
        'isActive': isActive,
        'message': message,
        'type': type,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error setting emergency alert: $e');
      return false;
    }
  }

  /// Stream global emergency alert status
  Stream<DocumentSnapshot> get emergencyStatusStream {
    return _firestore.db
        .collection('admin_config')
        .doc('emergency')
        .snapshots();
  }

  // ==================== STATION STATUS ====================

  /// Update station operational status (crowd level & facilities)
  Future<bool> updateStationStatus(
    String stationId, {
    int? crowdLevel,
    Map<String, bool>? facilities,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (crowdLevel != null) updates['crowdLevel'] = crowdLevel;
      if (facilities != null) updates['facilities'] = facilities;

      await _firestore.db
          .collection('station_status')
          .doc(stationId)
          .set(updates, SetOptions(merge: true));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating station status: $e');
      return false;
    }
  }

  /// Stream all stations' operational status
  Stream<QuerySnapshot> get allStationStatusStream {
    return _firestore.db.collection('station_status').snapshots();
  }

  /// Stream a single station's operational status
  Stream<DocumentSnapshot> stationStatusStream(String stationId) {
    return _firestore.db
        .collection('station_status')
        .doc(stationId)
        .snapshots();
  }
}
