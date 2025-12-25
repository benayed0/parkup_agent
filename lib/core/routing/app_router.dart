import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/check_vehicle/presentation/pages/check_vehicle_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/pending_removals/presentation/pages/pending_removals_page.dart';

/// Application router
/// Handles all navigation within the app
class AppRouter {
  AppRouter._();

  /// Generate routes for named navigation
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return _buildRoute(const LoginPage(), settings);

      case AppRoutes.home:
        return _buildRoute(const HomePage(), settings);

      case AppRoutes.checkVehicle:
        return _buildRoute(const CheckVehiclePage(), settings);

      case AppRoutes.history:
        return _buildRoute(const HistoryPage(), settings);

      case AppRoutes.pendingRemovals:
        return _buildRoute(const PendingRemovalsPage(), settings);

      default:
        return _buildRoute(const LoginPage(), settings);
    }
  }

  /// Build a route with consistent transition
  static MaterialPageRoute<T> _buildRoute<T>(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<T>(
      builder: (_) => page,
      settings: settings,
    );
  }
}
