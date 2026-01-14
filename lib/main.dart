import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/core.dart';
import 'features/auth/data/repositories/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize auth repository and check for saved session
  await authRepository.init();

  // Pre-initialize location service for instant GPS availability
  // Runs in background - doesn't block app startup
  locationService.init();

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

      // Localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('fr'), // French
        Locale('ar'), // Arabic
      ],

      // Apply custom theme
      theme: AppTheme.lightTheme,

      // Initial route - based on auth state
      initialRoute: initialRoute,

      // Route generator
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
