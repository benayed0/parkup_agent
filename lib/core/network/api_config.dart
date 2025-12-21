import 'package:flutter/foundation.dart';

/// API Configuration
/// Centralized API settings
class ApiConfig {
  ApiConfig._();

  // Base URLs for different environments
  static const String _devBaseUrl = 'http://localhost:3000/api/v1';
  static const String _prodBaseUrl = 'https://parkup-api.onrender.com/api/v1';

  // Base URL - automatically switches based on build mode
  static String get baseUrl => kReleaseMode ? _prodBaseUrl : _devBaseUrl;

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Endpoints - Agents
  static const String agentsLogin = '/agents/login';
  static const String agents = '/agents';

  // Endpoints - Parking Sessions
  static const String parkingSessions = '/parking-sessions';
  static String activeSessionByPlate(String plate) =>
      '/parking-sessions/plate/$plate/active';

  // Endpoints - Tickets
  static const String tickets = '/tickets';
  static String ticketsByAgent(String agentId) => '/tickets/agent/$agentId';
  static String ticketsByPlate(String plate) => '/tickets/plate/$plate';
  static String checkUnpaidTickets(String plate) => '/tickets/check/$plate';
}
