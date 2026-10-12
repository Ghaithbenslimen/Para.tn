import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final String baseUrl = 'http://10.0.2.2:3000';
  String? _token;
  String? _userId;
  String? _userName;
  bool? _isParapharmacie;

  String? get currentUserId => _userId;
  String? get currentUserName => _userName;
  String? get token => _token;
  bool get isParapharmacie => _isParapharmacie ?? false;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<void> initialize() async {
    await _loadTokenFromStorage();
    debugPrint(
        'Initialized AuthService - userName: $_userName, userId: $_userId, isParapharmacie: $_isParapharmacie');
  }

  Future<void> _loadTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    _token = prefs.getString('auth_token') ?? prefs.getString('token');
    _userId = prefs.getString('user_id');
    _userName = prefs.getString('username');
    _isParapharmacie = prefs.getBool('is_parapharmacie');

    debugPrint(
        'Loaded from storage - userName: $_userName, userId: $_userId, isParapharmacie: $_isParapharmacie');

    // If we have a token but missing user info, fetch user details
    if (_token != null &&
        (_userName == null || _userId == null || _isParapharmacie == null)) {
      await _fetchUserDetails();
    }
  }

  Future<void> _fetchUserDetails() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Profile response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Profile data: $data');

        // Save user type from the backend
        final isParapharmacie = data['isParapharmacie'] ?? false;
        await saveUserType(isParapharmacie);

        // Extract username based on user type
        String username = '';
        if (isParapharmacie) {
          username = data['name'] ?? '';
        } else {
          username = data['username'] ?? '';
        }

        if (username.isNotEmpty) {
          await saveUsername(username);
        }

        // Save user ID if not already saved
        if (_userId == null || _userId!.isEmpty) {
          final userId = data['_id'];
          if (userId != null) {
            await saveUserId(userId);
          }
        }
      } else {
        debugPrint('Failed to fetch user details: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching user details: $e');
    }
  }

  Future<void> saveUsername(String username) async {
    if (username.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    _userName = username;
    debugPrint('Saved username: $_userName');
  }

  Future<void> saveUserId(String userId) async {
    if (userId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    _userId = userId;
    debugPrint('Saved userId: $_userId');
  }

  Future<void> saveUserType(bool isParapharmacie) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_parapharmacie', isParapharmacie);
    _isParapharmacie = isParapharmacie;
    debugPrint('Saved isParapharmacie: $_isParapharmacie');
  }

  // Login method
  Future<bool> login(String email, String password) async {
    try {
      // First, ensure we're logged out to clear any existing tokens
      await logout();

      debugPrint('Attempting login for email: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract token from response
        final token = data['token'];

        if (token == null) {
          debugPrint('Error: No token in response');
          return false;
        }

        // Save token to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('token', token);

        // Update in-memory token
        _token = token;

        // Fetch user details to get username, ID, and user type
        await _fetchUserDetails();

        debugPrint('Login successful, isParapharmacie: $_isParapharmacie');
        return true;
      }

      debugPrint('Login failed: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  // Helper method to clear auth data from storage
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('is_parapharmacie');

    debugPrint('Auth data cleared from storage');
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    if (_token == null) {
      await _loadTokenFromStorage();
    }
    return _token != null;
  }

  // Get current user ID
  Future<String?> getCurrentUserId() async {
    if (_userId == null) {
      await _loadTokenFromStorage();
    }
    return _userId;
  }

  // Get current username
  Future<String?> getCurrentUsername() async {
    if (_userName == null) {
      await _loadTokenFromStorage();
    }
    return _userName;
  }

  // Check if user is a parapharmacie user
  Future<bool> isParapharmacieUser() async {
    if (_isParapharmacie == null) {
      await _loadTokenFromStorage();
    }
    return _isParapharmacie ?? false;
  }

  // Get auth token
  Future<String?> getToken() async {
    if (_token == null) {
      await _loadTokenFromStorage();
    }
    return _token;
  }

  // Logout method
  Future<bool> logout() async {
    try {
      debugPrint('Logging out user: $_userName');

      // Clear local storage and memory
      await _clearAuthData();

      // Reset in-memory variables
      _token = null;
      _userId = null;
      _userName = null;
      _isParapharmacie = null;

      debugPrint('User logged out completely');
      return true;
    } catch (e) {
      debugPrint('Error during logout: $e');
      return false;
    }
  }
}
