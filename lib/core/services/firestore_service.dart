import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';

/// Service class for all Firestore database operations.
///
/// Firestore Collections Structure:
/// ```
/// users/{uid}
///   ├── name: string
///   ├── email: string
///   └── createdAt: timestamp
///
/// users/{uid}/tickets/{ticketId}
///   ├── source, destination, fare, stops, estimatedMinutes
///   ├── routeSummary, linesTaken, status
///   └── createdAt: timestamp
///
/// users/{uid}/savedRoutes/{autoId}
///   ├── source, destination
///   └── savedAt: timestamp
///
/// users/{uid}/recentSearches/{autoId}
///   ├── query: string
///   └── searchedAt: timestamp
/// ```
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  FirebaseFirestore? _db;

  FirebaseFirestore get db {
    _db ??= FirebaseFirestore.instance;
    return _db!;
  }

  bool get isAvailable {
    try {
      db;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==================== USER DATA ====================

  /// Create or update user profile in Firestore
  Future<void> createUserProfile(String uid, String name, String email) async {
    try {
      await db.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore createUserProfile error: $e');
    }
  }

  /// Update emergency contacts list
  Future<bool> updateEmergencyContacts(String uid, List<Map<String, dynamic>> contacts) async {
    try {
      await db.collection('users').doc(uid).set({
        'emergencyContacts': contacts,
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Firestore updateEmergencyContacts error: $e');
      return false;
    }
  }

  /// Stream user profile (including emergency contact)
  Stream<DocumentSnapshot> userProfileStream(String uid) {
    return db.collection('users').doc(uid).snapshots();
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await db.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Firestore getUserProfile error: $e');
      return null;
    }
  }

  // ==================== TICKET HISTORY ====================

  /// Save a ticket to Firestore
  Future<void> saveTicket(String uid, MetroTicket ticket) async {
    try {
      await db
          .collection('users')
          .doc(uid)
          .collection('tickets')
          .doc(ticket.id)
          .set(ticket.toMap());
    } catch (e) {
      debugPrint('Firestore saveTicket error: $e');
    }
  }

  /// Get all tickets for a user
  Future<List<MetroTicket>> getTicketHistory(String uid) async {
    try {
      final snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('tickets')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MetroTicket.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Firestore getTicketHistory error: $e');
      return [];
    }
  }

  /// Update ticket status
  Future<void> updateTicketStatus(String uid, String ticketId, String status) async {
    try {
      await db
          .collection('users')
          .doc(uid)
          .collection('tickets')
          .doc(ticketId)
          .update({'status': status});
    } catch (e) {
      debugPrint('Firestore updateTicketStatus error: $e');
    }
  }

  /// Delete a ticket permanently from Firestore
  Future<void> deleteTicket(String uid, String ticketId) async {
    try {
      await db
          .collection('users')
          .doc(uid)
          .collection('tickets')
          .doc(ticketId)
          .delete();
    } catch (e) {
      debugPrint('Firestore deleteTicket error: $e');
    }
  }



  // ==================== SAVED ROUTES ====================

  /// Save a favorite route
  Future<void> saveRoute(String uid, String source, String destination) async {
    try {
      // Use a deterministic ID to prevent duplicates
      final docId = '${source}_$destination'.replaceAll(' ', '_').toLowerCase();
      await db
          .collection('users')
          .doc(uid)
          .collection('savedRoutes')
          .doc(docId)
          .set({
        'source': source,
        'destination': destination,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore saveRoute error: $e');
    }
  }

  /// Remove a saved route
  Future<void> removeSavedRoute(String uid, String source, String destination) async {
    try {
      final docId = '${source}_$destination'.replaceAll(' ', '_').toLowerCase();
      await db
          .collection('users')
          .doc(uid)
          .collection('savedRoutes')
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint('Firestore removeSavedRoute error: $e');
    }
  }

  /// Get all saved routes for a user
  Future<List<SavedRoute>> getSavedRoutes(String uid) async {
    try {
      final snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('savedRoutes')
          .orderBy('savedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SavedRoute(
          source: data['source'] ?? '',
          destination: data['destination'] ?? '',
          savedAt: (data['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Firestore getSavedRoutes error: $e');
      return [];
    }
  }

  // ==================== RECENT SEARCHES ====================

  /// Add a recent search
  Future<void> addRecentSearch(String uid, String searchQuery) async {
    try {
      // Use query as doc ID to auto-deduplicate
      final docId = searchQuery.replaceAll(' ', '_').toLowerCase();
      await db
          .collection('users')
          .doc(uid)
          .collection('recentSearches')
          .doc(docId)
          .set({
        'query': searchQuery,
        'searchedAt': FieldValue.serverTimestamp(),
      });

      // Keep only the latest 10 searches
      final snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('recentSearches')
          .orderBy('searchedAt', descending: true)
          .get();

      if (snapshot.docs.length > 10) {
        for (int i = 10; i < snapshot.docs.length; i++) {
          await snapshot.docs[i].reference.delete();
        }
      }
    } catch (e) {
      debugPrint('Firestore addRecentSearch error: $e');
    }
  }

  /// Get recent searches
  Future<List<String>> getRecentSearches(String uid) async {
    try {
      final snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('recentSearches')
          .orderBy('searchedAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['query'] as String? ?? '')
          .where((q) => q.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Firestore getRecentSearches error: $e');
      return [];
    }
  }

  /// Clear all recent searches
  Future<void> clearRecentSearches(String uid) async {
    try {
      final snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('recentSearches')
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Firestore clearRecentSearches error: $e');
    }
  }
}
