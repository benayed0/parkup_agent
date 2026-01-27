/// Route names for the application
/// Centralized route definitions for easy navigation management
class AppRoutes {
  AppRoutes._();

  // Auth routes
  static const String login = '/login';

  // Main routes
  static const String home = '/home';

  // Feature routes
  static const String checkVehicle = '/check-vehicle';
  static const String history = '/history';
  static const String pendingRemovals = '/pending-removals';
  static const String activeSessionsMap = '/active-sessions-map';

  // Settings routes
  static const String settings = '/settings';
  static const String printerScan = '/printer-scan';
}
