import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/models.dart';

/// Auth storage service
/// Handles persistent storage of authentication data
class AuthStorageService {
  static const String _agentKey = 'agent_data';
  static const String _tokenKey = 'auth_token';

  SharedPreferences? _prefs;

  /// Initialize shared preferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save agent data
  Future<void> saveAgent(Agent agent) async {
    await init();
    await _prefs!.setString(_agentKey, jsonEncode(agent.toJson()));
  }

  /// Get saved agent data
  Future<Agent?> getAgent() async {
    await init();
    final data = _prefs!.getString(_agentKey);
    if (data == null) return null;

    try {
      return Agent.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Save auth token (for future JWT support)
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
    await _prefs!.remove(_agentKey);
    await _prefs!.remove(_tokenKey);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final agent = await getAgent();
    return agent != null;
  }
}

/// Singleton instance
final authStorageService = AuthStorageService();
