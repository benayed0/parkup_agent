/// API Configuration
/// Centralized API settings
class ApiConfig {
  ApiConfig._();

  // Environment flag — pass --dart-define=ENV=dev to use localhost
  static const String _env = String.fromEnvironment('ENV', defaultValue: 'prod');

  // Base URLs for different environments
  static const String _devBaseUrl = 'http://localhost:3000/api/v1';
  static const String _prodBaseUrl = 'https://parkup-api.onrender.com/api/v1';

  // Base URL — only uses dev when explicitly passed via --dart-define=ENV=dev
  static String get baseUrl => _env == 'dev' ? _devBaseUrl : _prodBaseUrl;

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

  // Endpoints - Parking Zones
  static const String parkingZones = '/parking-zones';
  static String parkingZoneById(String id) => '/parking-zones/$id';
}
