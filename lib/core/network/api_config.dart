/// API Configuration
/// Centralized API settings
class ApiConfig {
  ApiConfig._();

  // Base URL - change this for different environments
  static const String baseUrl = 'http://localhost:3000/api/v1';

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
