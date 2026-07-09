import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';

class TicketProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final FirestoreService _firestore = FirestoreService();
  List<MetroTicket> _tickets = [];
  bool _isLoading = false;
  String? _uid;
  bool _hasSynced = false;

  TicketProvider(this._prefs) {
    _uid = _prefs.getString('uid');
    _loadTickets();
  }

  List<MetroTicket> get tickets => _tickets;
  List<MetroTicket> get activeTickets => _tickets
      .where((t) {
        if (t.status == 'active') {
          final isMonthly = t.ticketType == 'monthly_pass';
          return DateTime.now().difference(t.createdAt).inHours < (isMonthly ? 720 : 24);
        }
        return false;
      })
      .toList();
  List<MetroTicket> get usedTickets => _tickets
      .where((t) {
        if (t.status == 'active') {
          final isMonthly = t.ticketType == 'monthly_pass';
          return DateTime.now().difference(t.createdAt).inHours >= (isMonthly ? 720 : 24);
        }
        return true;
      })
      .toList();
  bool get isLoading => _isLoading;

  /// Set the user ID for Firestore operations
  void setUid(String uid) {
    if (_uid == uid) {
      if (!_hasSynced && uid.isNotEmpty) {
        _hasSynced = true;
        syncFromFirestore();
      }
      return;
    }
    _tickets.clear(); // Clear previous user's data
    _uid = uid;
    _hasSynced = true;
    if (uid.isNotEmpty) {
      syncFromFirestore();
    }
  }

  void _loadTickets() {
    final ticketJson = _prefs.getStringList('tickets') ?? [];
    _tickets = ticketJson
        .map((json) => MetroTicket.fromMap(jsonDecode(json)))
        .toList();
    _checkExpirations();
    _tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _checkExpirations() {
    bool updated = false;
    final now = DateTime.now();
    for (int i = 0; i < _tickets.length; i++) {
        if (_tickets[i].status == 'active') {
            final isMonthly = _tickets[i].ticketType == 'monthly_pass';
            final hoursLimit = isMonthly ? 720 : 24;
            if (now.difference(_tickets[i].createdAt).inHours >= hoursLimit) {
                final old = _tickets[i];
                _tickets[i] = MetroTicket(
                  id: old.id,
                  source: old.source,
                  destination: old.destination,
                  stops: old.stops,
                  fare: old.fare,
                  estimatedMinutes: old.estimatedMinutes,
                  createdAt: old.createdAt,
                  status: 'used',
                  routeSummary: old.routeSummary,
                  linesTaken: old.linesTaken,
                  ticketType: old.ticketType,
                );
                updated = true;
                if (_uid != null && _uid!.isNotEmpty) {
                   _firestore.updateTicketStatus(_uid!, old.id, 'used');
                }
            }
        }
    }
    if (updated) {
       _saveTickets();
    }
  }

  Future<void> _saveTickets() async {
    final ticketJson = _tickets.map((t) => jsonEncode(t.toMap())).toList();
    await _prefs.setStringList('tickets', ticketJson);
  }

  /// Sync tickets from Firestore (called after login)
  Future<void> syncFromFirestore() async {
    if (_uid == null || _uid!.isEmpty) return;
    try {
      final firestoreTickets = await _firestore.getTicketHistory(_uid!);
      
      // Override local tickets with Firestore content
      _tickets = firestoreTickets;
      _checkExpirations();
      _tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      await _saveTickets();
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing tickets from Firestore: $e');
    }
  }

  Future<MetroTicket> bookTicket({
    required String source,
    required String destination,
    required int stops,
    required double fare,
    required int estimatedMinutes,
    required String routeSummary,
    String linesTaken = '',
    String ticketType = 'single',
  }) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final ticket = MetroTicket(
      id: const Uuid().v4(),
      source: source,
      destination: destination,
      stops: stops,
      fare: fare,
      estimatedMinutes: estimatedMinutes,
      createdAt: DateTime.now(),
      status: 'active',
      routeSummary: routeSummary,
      linesTaken: linesTaken,
      ticketType: ticketType,
    );

    _tickets.insert(0, ticket);
    await _saveTickets();

    // Save to Firestore
    if (_uid != null && _uid!.isNotEmpty) {
      _firestore.saveTicket(_uid!, ticket);
    }

    _isLoading = false;
    notifyListeners();
    return ticket;
  }

  Future<void> useTicket(String ticketId) async {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      final old = _tickets[index];
      
      if (old.ticketType == 'monthly_pass') return;

      _tickets[index] = MetroTicket(
        id: old.id,
        source: old.source,
        destination: old.destination,
        stops: old.stops,
        fare: old.fare,
        estimatedMinutes: old.estimatedMinutes,
        createdAt: old.createdAt,
        status: 'used',
        routeSummary: old.routeSummary,
        linesTaken: old.linesTaken,
        ticketType: old.ticketType,
      );
      await _saveTickets();

      // Update in Firestore
      if (_uid != null && _uid!.isNotEmpty) {
        _firestore.updateTicketStatus(_uid!, ticketId, 'used');
      }

      notifyListeners();
    }
  }



  int get totalSpent => _tickets.fold(0, (sum, t) => sum + t.fare.toInt());
  int get totalTrips => _tickets.length;

  void clearData() {
    _uid = null;
    _tickets.clear();
    _prefs.remove('tickets');
    Future.microtask(() => notifyListeners());
  }
}
