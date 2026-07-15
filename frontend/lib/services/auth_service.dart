import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

/// Authentication service — login state management via SharedPreferences
class AuthService {
  static const String _keyUser = 'user_data';
  static const String _keyLoggedIn = 'is_logged_in';

  /// Save user session
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    await prefs.setBool(_keyLoggedIn, true);
  }

  /// Get current logged-in user (null if not logged in)
  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    if (!isLoggedIn) return null;

    final userData = prefs.getString(_keyUser);
    if (userData == null) return null;

    return UserModel.fromJson(jsonDecode(userData));
  }

  /// Check login status
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  /// Logout — clear all saved data
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.setBool(_keyLoggedIn, false);
  }
}
