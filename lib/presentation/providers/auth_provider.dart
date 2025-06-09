import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';

/// Authentication provider managing user state
/// Corresponds to Angular's AuthService with reactive state management
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  AuthProvider(this._authService) {
    _initializeAuth();
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;

  /// Initialize authentication state on app start
  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.getStoredUser();
      if (user != null) {
        final isAuth = await _authService.isAuthenticated();
        if (isAuth) {
          _currentUser = user;
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize authentication';
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Sign in user - matches Angular's login functionality
  Future<bool> signIn({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signIn(
        username: username,
        password: password,
      );
      
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register new user - matches Angular's register functionality
  Future<bool> signUp({
    required String username,
    required String password,
    required List<String> roles,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signUp(
        username: username,
        password: password,
        roles: roles,
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out user - matches Angular's logout functionality
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = 'Failed to sign out';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Update user data
  void updateUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }
}
