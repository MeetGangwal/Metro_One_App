import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final FirestoreService _firestore = FirestoreService();
  List<SavedRoute> _favorites = [];
  List<String> _recentSearches = [];
  String? _uid;

  FavoritesProvider(this._prefs) {
    _uid = _prefs.getString('uid');
    _loadFavorites();
    _loadRecentSearches();
  }

  List<SavedRoute> get favorites => _favorites;
  List<String> get recentSearches => _recentSearches;

  /// Set the user ID for Firestore operations
  void setUid(String uid) {
    if (_uid == uid) return;
    _favorites.clear(); // Clear previous user's data
    _uid = uid;
    syncFromFirestore();
  }

  void _loadFavorites() {
    final favJson = _prefs.getStringList('favorites') ?? [];
    _favorites = favJson
        .map((json) => SavedRoute.fromMap(jsonDecode(json)))
        .toList();
  }

  void _loadRecentSearches() {
    _recentSearches = _prefs.getStringList('recentSearches') ?? [];
  }

  Future<void> _saveFavorites() async {
    final favJson = _favorites.map((f) => jsonEncode(f.toMap())).toList();
    await _prefs.setStringList('favorites', favJson);
  }

  Future<void> _saveRecentSearches() async {
    await _prefs.setStringList('recentSearches', _recentSearches);
  }

  /// Sync from Firestore (called after login)
  Future<void> syncFromFirestore() async {
    if (_uid == null || _uid!.isEmpty) return;
    try {
      // Sync saved routes
      final firestoreRoutes = await _firestore.getSavedRoutes(_uid!);
      _favorites = firestoreRoutes;
      await _saveFavorites();

      // Sync recent searches
      final firestoreSearches = await _firestore.getRecentSearches(_uid!);
      if (firestoreSearches.isNotEmpty) {
        _recentSearches = firestoreSearches;
        await _saveRecentSearches();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Firestore favorites sync error: $e');
    }
  }

  bool isFavorite(String source, String destination) {
    return _favorites.any(
      (f) => f.source == source && f.destination == destination,
    );
  }

  Future<void> toggleFavorite(String source, String destination) async {
    if (isFavorite(source, destination)) {
      _favorites.removeWhere(
        (f) => f.source == source && f.destination == destination,
      );
      // Remove from Firestore
      if (_uid != null && _uid!.isNotEmpty) {
        _firestore.removeSavedRoute(_uid!, source, destination);
      }
    } else {
      _favorites.add(SavedRoute(
        source: source,
        destination: destination,
        savedAt: DateTime.now(),
      ));
      // Save to Firestore
      if (_uid != null && _uid!.isNotEmpty) {
        _firestore.saveRoute(_uid!, source, destination);
      }
    }
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> addRecentSearch(String search) async {
    _recentSearches.remove(search);
    _recentSearches.insert(0, search);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    await _saveRecentSearches();

    // Save to Firestore
    if (_uid != null && _uid!.isNotEmpty) {
      _firestore.addRecentSearch(_uid!, search);
    }

    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    _recentSearches.clear();
    await _saveRecentSearches();

    // Clear from Firestore
    if (_uid != null && _uid!.isNotEmpty) {
      _firestore.clearRecentSearches(_uid!);
    }

    notifyListeners();
  }

  void clearData() {
    _uid = null;
    _favorites.clear();
    _prefs.remove('favorites');
    // Note: Not clearing recent searches since they might be useful device-wide 
    // or you can clear them if desired. Let's clear them to be fully secure.
    _recentSearches.clear();
    _prefs.remove('recentSearches');
    Future.microtask(() => notifyListeners());
  }
}
