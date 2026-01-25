import 'package:flutter/foundation.dart';

/// API Configuration
/// Centralized API settings
class ApiConfig {
  ApiConfig._();

  // Base URLs for different environments
  static const String _devBaseUrl = 'http://localhost:3000/api/v1';
  static const String _prodBaseUrl = 'https://parkup-api.onrender.com/api/v1';

  // Base URL - uses prod on release mode OR on physical mobile devices
  // (localhost doesn't work on physical devices)
  static String get baseUrl {
    if (kReleaseMode) return _prodBaseUrl;
    // In debug mode, use prod for mobile (physical devices can't reach localhost)
    // Use dev only for web where localhost works
    // Note: kIsWeb check must come first since Platform.* throws on web
    if (kIsWeb) return _devBaseUrl;
    // For mobile (Android/iOS), use prod since localhost doesn't work on physical devices
    return _prodBaseUrl;
  }

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Endpoints - Agents
  static const String agentsLogin = '/agents/login';
  static const String agentsMe = '/agents/me';
  static const String agents = '/agents';

  // Endpoints - Parking Sessions
  static const String parkingSessions = '/parking-sessions';
  static const String checkVehicle = '/parking-sessions/check-vehicle';
  static const String agentEnforcement = '/parking-sessions/agent/enforcement';

  // Endpoints - Tickets
  static const String tickets = '/tickets';
  static String ticketById(String id) => '/tickets/$id';
  static String ticketsByAgent(String agentId) => '/tickets/agent/$agentId';
  static String ticketsByPlate(String plate) => '/tickets/plate/$plate';
  static String checkUnpaidTickets(String plate) => '/tickets/check/$plate';
}
