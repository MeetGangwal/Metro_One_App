import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';

class AppAuthProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final FirestoreService _firestore = FirestoreService();
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';

  AppAuthProvider(this._prefs) {
    _loadFromPrefs();
    _initFirebaseAuth();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;

  /// Whether the current user is an admin
  bool get isAdmin => _userEmail.toLowerCase() == 'admin@gmail.com';

  /// Get the current user's UID (or empty string if not authenticated)
  String get uid => _user?.uid ?? _prefs.getString('uid') ?? '';

  void _loadFromPrefs() {
    _isLoggedIn = _prefs.getBool('isLoggedIn') ?? false;
    _userName = _prefs.getString('userName') ?? '';
    _userEmail = _prefs.getString('userEmail') ?? '';
  }

  void _initFirebaseAuth() {
    try {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        _user = user;
        if (user != null) {
          _isLoggedIn = true;
          _userEmail = user.email ?? '';
          _userName = user.displayName ?? _userEmail.split('@').first;
          _prefs.setString('uid', user.uid);
          _prefs.setBool('isLoggedIn', true);
        } else {
          // Only clear if we were previously logged in to avoid race conditions
          if (_isLoggedIn) {
            _isLoggedIn = false;
            _prefs.setBool('isLoggedIn', false);
            _prefs.remove('uid');
          }
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Firebase Auth not available: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    await _prefs.setBool('isLoggedIn', _isLoggedIn);
    await _prefs.setString('userName', _userName);
    await _prefs.setString('userEmail', _userEmail);
  }

  Future<bool> signUp(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await credential.user?.updateDisplayName(name);
      _user = credential.user;
      _isLoggedIn = true;
      _userName = name;
      _userEmail = email;

      // Save user profile to Firestore
      if (_user != null) {
        await _prefs.setString('uid', _user!.uid);
        await _firestore.createUserProfile(_user!.uid, name, email);
      }

      await _saveToPrefs();
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // Fallback for when Firebase is not configured
      _isLoggedIn = true;
      _userName = name;
      _userEmail = email;
      await _saveToPrefs();
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = credential.user;
      _isLoggedIn = true;
      _userEmail = email;
      _userName = credential.user?.displayName ?? email.split('@').first;

      if (_user != null) {
        await _prefs.setString('uid', _user!.uid);
      }

      await _saveToPrefs();
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // Fallback for when Firebase is not configured
      _isLoggedIn = true;
      _userEmail = email;
      _userName = email.split('@').first;
      await _saveToPrefs();
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<bool> updateProfile(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_user != null) {
        await _user!.updateDisplayName(name);
      }
      _userName = name;
      await _prefs.setString('userName', name);

      // Update in Firestore
      if (uid.isNotEmpty) {
        await _firestore.createUserProfile(uid, name, _userEmail);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmergencyContacts(List<Map<String, dynamic>> contacts) async {
    if (uid.isEmpty) return false;
    return await _firestore.updateEmergencyContacts(uid, contacts);
  }

  Stream<DocumentSnapshot>? get userProfileStream {
    if (uid.isEmpty) return null;
    return _firestore.userProfileStream(uid);
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Firebase signOut error: $e');
    }
    _user = null;
    _isLoggedIn = false;
    _userName = '';
    _userEmail = '';
    await _prefs.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
