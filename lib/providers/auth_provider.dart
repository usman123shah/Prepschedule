import 'package:flutter/material.dart';
import '../data/local/sqlite_service.dart';
import '../data/remote/auth_service.dart';
import '../data/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final AuthService _authService = AuthService();
  final SqliteService _dbService = SqliteService();

  AuthProvider() {
    _checkSavedSession();
  }

  void _checkSavedSession() async {
    final fbUser = _authService.currentUser;
    if (fbUser != null) {
      // Try to get full profile from SQLite (for username and offline consistency)
      final offlineUser = await _dbService.getUserByUid(fbUser.id!);
      if (offlineUser != null) {
        _currentUser = offlineUser;
      } else {
        _currentUser = fbUser;
      }
      notifyListeners();
    }
  }

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      User? user = await _authService.login(identifier, password);
      if (user != null) {
        // Update user object with the password used for future offline login
        final userToSave = User(
          id: user.id,
          username: user.username,
          email: user.email,
          password: password,
        );
        _currentUser = userToSave;
        await _dbService.saveUser(userToSave);
      }
    } catch (e) {
      print("Online Login Failed, trying offline: $e");
      // Offline fallback: Check SQLite
      final offlineUser = await _dbService.getUserByUsernameOrEmail(identifier);
      if (offlineUser != null && offlineUser.password == password) {
        _currentUser = offlineUser;
      } else {
        _errorMessage = "Network error. Incorrect username or password for offline login.";
      }
    }

    _isLoading = false;
    notifyListeners();
    return _currentUser != null;
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      User? user = await _authService.signUp(email, password, username);
      if (user != null) {
        final userToSave = User(
          id: user.id,
          username: username,
          email: email,
          password: password,
        );
        _currentUser = userToSave;
        await _dbService.saveUser(userToSave);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = "Registration error: ${e.toString()}";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Reset error: ${e.toString()}";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }
}
