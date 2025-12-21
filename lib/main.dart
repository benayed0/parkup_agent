import 'package:flutter/material.dart';
import 'core/core.dart';
import 'features/auth/data/repositories/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize auth repository and check for saved session
  await authRepository.init();

  runApp(const ParkUpAgentApp());
}

/// Main application widget
/// Entry point for the ParkUp Agent application
class ParkUpAgentApp extends StatelessWidget {
  const ParkUpAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine initial route based on auth state
    final initialRoute =
        authRepository.isLoggedIn ? AppRoutes.home : AppRoutes.login;

    return MaterialApp(
      title: 'ParkUp Agent',
      debugShowCheckedModeBanner: false,

      // Apply custom theme
      theme: AppTheme.lightTheme,

      // Initial route - based on auth state
      initialRoute: initialRoute,

      // Route generator
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
