import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// Authentication service matching Angular's AuthService functionality
class AuthService {
  final String _baseUrl = AppConstants.baseUrl + AppConstants.authEndpoint;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  /// Login request model matching Angular's LoginRequest interface
  static const String _tokenKey = AppConstants.tokenKey;
  static const String _userKey = AppConstants.userKey;

  /// Sign in user - corresponds to Angular's login method
  Future<UserModel> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sign-in'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Create user model from response
        final user = UserModel(
          id: data['id'],
          username: data['username'],
          name: data['username'], // Use username as name if not provided
          role: 'ROLE_USER', // Default role
          token: data['token'],
        );

        // Store token and user data securely
        await _storeAuthData(user);
        
        return user;
      } else {
        throw _handleHttpError(response);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: Unable to connect to server');
    }
  }

  /// Register new user - corresponds to Angular's register method
  Future<UserModel> signUp({
    required String username,
    required String password,
    required List<String> roles,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sign-up'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'roles': roles,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      } else {
        throw _handleHttpError(response);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: Unable to connect to server');
    }
  }

  /// Get stored authentication token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Get stored user data
  Future<UserModel?> getStoredUser() async {
    try {
      final userJson = await _secureStorage.read(key: _userKey);
      if (userJson != null) {
        return UserModel.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    final user = await getStoredUser();
    return token != null && user != null;
  }

  /// Sign out user - corresponds to Angular's logout method
  Future<void> signOut() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
    
    // Also clear any SharedPreferences if needed
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Store authentication data securely
  Future<void> _storeAuthData(UserModel user) async {
    if (user.token != null) {
      await _secureStorage.write(key: _tokenKey, value: user.token!);
    }
    await _secureStorage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  /// Handle HTTP errors with appropriate messages
  Exception _handleHttpError(http.Response response) {
    switch (response.statusCode) {
      case 400:
        return Exception('Invalid request data');
      case 401:
        return Exception('Invalid credentials');
      case 403:
        return Exception('Access denied');
      case 409:
        return Exception('Username already exists');
      case 500:
        return Exception('Server error. Please try again later');
      default:
        return Exception('Unexpected error occurred');
    }
  }
}
