import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/core.dart';
import 'features/auth/data/repositories/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize auth repository and check for saved session
  await authRepository.init();

  // Initialize locale service to load saved language preference
  await localeService.init();

  // Pre-initialize location service for instant GPS availability
  // Runs in background - doesn't block app startup
  locationService.init();

  // Initialize printer service to load saved printer
  printerService.init();

  runApp(const ParkUpAgentApp());
}

/// Main application widget
/// Entry point for the ParkUp Agent application
class ParkUpAgentApp extends StatefulWidget {
  const ParkUpAgentApp({super.key});

  @override
  State<ParkUpAgentApp> createState() => _ParkUpAgentAppState();
}

class _ParkUpAgentAppState extends State<ParkUpAgentApp> {
  @override
  void initState() {
    super.initState();
    // Listen for locale changes
    localeService.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    localeService.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    setState(() {});
  }

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
      supportedLocales: LocaleService.supportedLocales,
      locale: localeService.currentLocale,

      // Apply custom theme
      theme: AppTheme.lightTheme,

      // Initial route - based on auth state
      initialRoute: initialRoute,

      // Route generator
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
