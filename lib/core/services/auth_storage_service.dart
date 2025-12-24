import 'package:shared_preferences/shared_preferences.dart';

/// Auth storage service
/// Handles persistent storage of authentication token only
class AuthStorageService {
  static const String _tokenKey = 'auth_token';

  SharedPreferences? _prefs;

  /// Initialize shared preferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save auth token
  Future<void> saveToken(String token) async {
    await init();
    await _prefs!.setString(_tokenKey, token);
  }

  /// Get saved token
  Future<String?> getToken() async {
    await init();
    return _prefs!.getString(_tokenKey);
  }

  /// Clear all auth data (logout)
  Future<void> clear() async {
    await init();
    await _prefs!.remove(_tokenKey);
  }

  /// Check if user is logged in (has token)
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

/// Singleton instance
final authStorageService = AuthStorageService();
