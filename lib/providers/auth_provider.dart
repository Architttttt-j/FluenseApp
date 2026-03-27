// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService.login(email, password);
    if (result['success']) {
      final data = result['data'];
      _user = UserModel.fromJson(data['user'] ?? data);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _error = result['message'];
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await ApiService.getMe();
    } catch (e) {
      _user = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiService.deleteToken();
    _user = null;
    notifyListeners();
  }
}
