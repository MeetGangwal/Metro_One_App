import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';

class WalletProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  
  String? _uid;
  double _balance = 0.0;
  bool _isLoading = false;

  double get balance => _balance;
  bool get isLoading => _isLoading;

  void setUid(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    if (uid.isNotEmpty) {
      _fetchWalletBalance();
    } else {
      _balance = 0.0;
      notifyListeners();
    }
  }

  Future<void> _fetchWalletBalance() async {
    if (_uid == null || _uid!.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    _balance = await _firestore.getWalletBalance(_uid!);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addMoney(double amount) async {
    if (_uid == null || _uid!.isEmpty || amount <= 0) return false;
    
    _isLoading = true;
    notifyListeners();

    try {
      final newBalance = _balance + amount;
      await _firestore.updateWalletBalance(_uid!, newBalance);
      
      final transaction = {
        'id': const Uuid().v4(),
        'type': 'credit',
        'description': 'Added Money',
        'amount': amount,
        'balanceAfter': newBalance,
        'date': DateTime.now().toIso8601String(),
      };
      
      await _firestore.addWalletTransaction(_uid!, transaction);
      
      _balance = newBalance;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding money: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deductMoney(double amount, String description) async {
    if (_uid == null || _uid!.isEmpty || amount <= 0 || _balance < amount) return false;
    
    _isLoading = true;
    notifyListeners();

    try {
      final newBalance = _balance - amount;
      await _firestore.updateWalletBalance(_uid!, newBalance);
      
      final transaction = {
        'id': const Uuid().v4(),
        'type': 'debit',
        'description': description,
        'amount': amount,
        'balanceAfter': newBalance,
        'date': DateTime.now().toIso8601String(),
      };
      
      await _firestore.addWalletTransaction(_uid!, transaction);
      
      _balance = newBalance;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deducting money: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearData() {
    _uid = null;
    _balance = 0.0;
    notifyListeners();
  }
}
