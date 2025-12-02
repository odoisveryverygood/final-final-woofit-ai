import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _listenToAuthState();
  }

  // ------------------------------------------------
  // LISTEN TO AUTH CHANGES
  // ------------------------------------------------
  void _listenToAuthState() {
    _authService.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // ------------------------------------------------
  // LOGIN
  // ------------------------------------------------
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.login(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ------------------------------------------------
  // SIGNUP
  // ------------------------------------------------
  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signUp(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ------------------------------------------------
  // LOGOUT
  // ------------------------------------------------
  Future<void> logout() async {
    await _authService.logout();
  }

  // ------------------------------------------------
  // CLEAR ERROR MESSAGE
  // ------------------------------------------------
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
