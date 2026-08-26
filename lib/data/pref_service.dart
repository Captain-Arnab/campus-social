import 'package:shared_preferences/shared_preferences.dart';

class PrefService {
  static const String _tokenKey = "token";
  static const String _userIdKey = "user_id";
  static const String _userNameKey = "user_name";
  static const String _isLoggedInKey = "is_logged_in";
  static const String _isStudentKey = "is_student";
  static const String _onboardingDoneKey = "onboarding_completed";

  static Future<void> saveUserSession(
    String userId,
    String name,
    String token, {
    bool isStudent = true, 
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_tokenKey, token);
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setBool(_isStudentKey, isStudent); 
  }

  /// Clears all login/session keys (user id, name, token, role). Preserves onboarding.
  static Future<void> clearProfileSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_isStudentKey);
  }

  /// Clears login session only. Preserves onboarding and other non-session prefs.
  static Future<void> clearSession() async {
    await clearProfileSession();
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // FIXED: Added missing getUserName member
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<bool> getIsStudent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isStudentKey) ?? true;
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingDoneKey) ?? false;
  }

  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingDoneKey, true);
  }
}