import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'ParkUp Agent'**
  String get appName;

  /// Subtitle on the login page
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// Label for username field
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Hint text for username field
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get enterUsername;

  /// Label for password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Hint text for password field
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// Validation error for empty username
  ///
  /// In en, this message translates to:
  /// **'Please enter your username'**
  String get pleaseEnterUsername;

  /// Validation error for empty password
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// Sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Help text on login page
  ///
  /// In en, this message translates to:
  /// **'Contact your administrator if you forgot your password'**
  String get contactAdminForPassword;

  /// Generic login error message
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailed;

  /// Welcome message with user name
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeUser(String name);

  /// Subtitle on home page
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get whatWouldYouLikeToDo;

  /// Check vehicle action title
  ///
  /// In en, this message translates to:
  /// **'Check Vehicle'**
  String get checkVehicle;

  /// Check vehicle action subtitle
  ///
  /// In en, this message translates to:
  /// **'Check status & create tickets'**
  String get checkStatusCreateTickets;

  /// Remove sabots action title
  ///
  /// In en, this message translates to:
  /// **'Remove Sabots'**
  String get removeSabots;

  /// Remove sabots action subtitle
  ///
  /// In en, this message translates to:
  /// **'Paid sabots to remove'**
  String get paidSabotsToRemove;

  /// History action title
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// History action subtitle
  ///
  /// In en, this message translates to:
  /// **'View past tickets'**
  String get viewPastTickets;

  /// Active status label
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Inactive status label
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// Logout button/title
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// License plate label
  ///
  /// In en, this message translates to:
  /// **'License Plate'**
  String get licensePlate;

  /// GPS update success message
  ///
  /// In en, this message translates to:
  /// **'GPS location updated'**
  String get gpsLocationUpdated;

  /// GPS error message
  ///
  /// In en, this message translates to:
  /// **'Could not get GPS location'**
  String get couldNotGetGpsLocation;

  /// Invalid plate error message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid license plate'**
  String get pleaseEnterValidPlate;

  /// Vehicle check error message
  ///
  /// In en, this message translates to:
  /// **'Failed to check vehicle. Please try again.'**
  String get failedToCheckVehicle;

  /// Zone selection error
  ///
  /// In en, this message translates to:
  /// **'Please select a parking zone'**
  String get pleaseSelectParkingZone;

  /// Fallback to zone location message
  ///
  /// In en, this message translates to:
  /// **'Using zone location (GPS unavailable)'**
  String get usingZoneLocation;

  /// Ticket creation success message
  ///
  /// In en, this message translates to:
  /// **'Ticket #{number} created'**
  String ticketCreated(String number);

  /// Ticket creation error message
  ///
  /// In en, this message translates to:
  /// **'Failed to create ticket. Please try again.'**
  String get failedToCreateTicket;

  /// Loading state while checking vehicle
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// Check button text
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// Recheck button text
  ///
  /// In en, this message translates to:
  /// **'Recheck'**
  String get recheck;

  /// New search button text
  ///
  /// In en, this message translates to:
  /// **'New Search'**
  String get newSearch;

  /// Empty state hint
  ///
  /// In en, this message translates to:
  /// **'Enter license plate, then tap Check'**
  String get enterPlateThenCheck;

  /// Zone selector hint
  ///
  /// In en, this message translates to:
  /// **'Select Zone'**
  String get selectZone;

  /// GPS refresh tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh GPS'**
  String get refreshGps;

  /// Expired session text
  ///
  /// In en, this message translates to:
  /// **'Expired: {date}'**
  String expired(String date);

  /// Error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Empty state title for history
  ///
  /// In en, this message translates to:
  /// **'No tickets yet'**
  String get noTicketsYet;

  /// Empty state subtitle for history
  ///
  /// In en, this message translates to:
  /// **'Tickets you create will appear here'**
  String get ticketsWillAppearHere;

  /// Ticket count text
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ticket} other{{count} tickets}}'**
  String ticketCount(int count);

  /// Navigate to location button
  ///
  /// In en, this message translates to:
  /// **'Go to Location'**
  String get goToLocation;

  /// Print button text
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// Yesterday time label
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Minutes ago text
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// Hours ago text
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// Print preview page title
  ///
  /// In en, this message translates to:
  /// **'Print Preview'**
  String get printPreview;

  /// Share as image tooltip
  ///
  /// In en, this message translates to:
  /// **'Share as Image'**
  String get shareAsImage;

  /// Ticket header title
  ///
  /// In en, this message translates to:
  /// **'PARKING TICKET'**
  String get parkingTicket;

  /// QR code label
  ///
  /// In en, this message translates to:
  /// **'Scan to Pay'**
  String get scanToPay;

  /// View on map link text
  ///
  /// In en, this message translates to:
  /// **'View on Map'**
  String get viewOnMap;

  /// Share button text
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Bluetooth printing placeholder message
  ///
  /// In en, this message translates to:
  /// **'Bluetooth printing coming soon!'**
  String get bluetoothPrintingComingSoon;

  /// Share error message
  ///
  /// In en, this message translates to:
  /// **'Failed to share'**
  String get failedToShare;

  /// Print data load error
  ///
  /// In en, this message translates to:
  /// **'Failed to load print data'**
  String get failedToLoadPrintData;

  /// Pending removals page title
  ///
  /// In en, this message translates to:
  /// **'Pending Removals'**
  String get pendingRemovals;

  /// Removal confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Removal'**
  String get confirmRemoval;

  /// Removal confirmation message
  ///
  /// In en, this message translates to:
  /// **'Mark sabot for {plate} as removed?'**
  String markSabotAsRemoved(String plate);

  /// Removal success message
  ///
  /// In en, this message translates to:
  /// **'Sabot marked as removed'**
  String get sabotMarkedAsRemoved;

  /// Empty state title for pending removals
  ///
  /// In en, this message translates to:
  /// **'All clear!'**
  String get allClear;

  /// Empty state subtitle for pending removals
  ///
  /// In en, this message translates to:
  /// **'No sabots pending removal'**
  String get noSabotsPendingRemoval;

  /// Sabot count text
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sabot to remove} other{{count} sabots to remove}}'**
  String sabotCount(int count);

  /// Paid status label
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get paid;

  /// Paid time text
  ///
  /// In en, this message translates to:
  /// **'Paid {time}'**
  String paidTime(String time);

  /// Navigate button text
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// Removed button text
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get removed;

  /// Pending removals load error
  ///
  /// In en, this message translates to:
  /// **'Failed to load pending removals'**
  String get failedToLoadPendingRemovals;

  /// Tickets load error
  ///
  /// In en, this message translates to:
  /// **'Failed to load tickets'**
  String get failedToLoadTickets;

  /// Refresh tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Language selector tooltip and dialog title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Sessions map action title
  ///
  /// In en, this message translates to:
  /// **'Sessions Map'**
  String get sessionsMap;

  /// Sessions map action subtitle
  ///
  /// In en, this message translates to:
  /// **'View active sessions on map'**
  String get viewActiveSessionsOnMap;

  /// Active sessions page title
  ///
  /// In en, this message translates to:
  /// **'Active Sessions'**
  String get activeSessions;

  /// New session notification message
  ///
  /// In en, this message translates to:
  /// **'New session: {licensePlate}'**
  String newSession(String licensePlate);

  /// Session event notification message
  ///
  /// In en, this message translates to:
  /// **'Session {reason}: {sessionId}...'**
  String sessionEvent(String reason, String sessionId);

  /// Error message when agent has no assigned zones
  ///
  /// In en, this message translates to:
  /// **'No assigned zones'**
  String get noAssignedZones;

  /// Critical expiring session notification
  ///
  /// In en, this message translates to:
  /// **'CRITICAL: {licensePlate} expires in {minutes} min!'**
  String criticalExpiring(String licensePlate, int minutes);

  /// Session expiring notification
  ///
  /// In en, this message translates to:
  /// **'{licensePlate} expires in {minutes} min'**
  String sessionExpiring(String licensePlate, int minutes);

  /// View action button text
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Number of active sessions
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String activeCount(int count);

  /// Valid session status label
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get valid;

  /// Less than 10 minutes remaining label
  ///
  /// In en, this message translates to:
  /// **'< 10 min'**
  String get lessThan10Min;

  /// Expired status label without date
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredStatus;

  /// Minutes remaining for session
  ///
  /// In en, this message translates to:
  /// **'{minutes} min remaining'**
  String minutesRemaining(int minutes);

  /// Session end time
  ///
  /// In en, this message translates to:
  /// **'Ends at {time}'**
  String endsAt(String time);

  /// Duration label
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// Amount/price label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Standard license plate series
  ///
  /// In en, this message translates to:
  /// **'Standard Series'**
  String get serieNormale;

  /// Government license plates
  ///
  /// In en, this message translates to:
  /// **'Government'**
  String get gouvernement;

  /// Libyan license plates
  ///
  /// In en, this message translates to:
  /// **'Libya'**
  String get libye;

  /// Algerian license plates
  ///
  /// In en, this message translates to:
  /// **'Algeria'**
  String get algerie;

  /// European Union license plates
  ///
  /// In en, this message translates to:
  /// **'European Union'**
  String get unionEuropeenne;

  /// Other license plate types
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get autre;

  /// Diplomatic and consular plates section
  ///
  /// In en, this message translates to:
  /// **'Diplomatic & Consular'**
  String get diplomatiqueConsulaire;

  /// Diplomatic corps plates
  ///
  /// In en, this message translates to:
  /// **'Diplomatic Corps'**
  String get corpsDiplomatique;

  /// Consular corps plates
  ///
  /// In en, this message translates to:
  /// **'Consular Corps'**
  String get corpsConsulaire;

  /// Diplomatic plates bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Diplomatic Plates'**
  String get plaquesDiplomatiques;

  /// Title for the enforcement map page
  ///
  /// In en, this message translates to:
  /// **'Enforcement Map'**
  String get enforcementMap;

  /// Sessions header in bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// Tooltip for hiding ticketed sessions
  ///
  /// In en, this message translates to:
  /// **'Hide ticketed'**
  String get hideTicketed;

  /// Tooltip for showing ticketed sessions
  ///
  /// In en, this message translates to:
  /// **'Show ticketed'**
  String get showTicketed;

  /// Empty state when no violations exist
  ///
  /// In en, this message translates to:
  /// **'No violations found'**
  String get noViolationsFound;

  /// Empty state when search returns no results
  ///
  /// In en, this message translates to:
  /// **'No sessions found'**
  String get noSessionsFound;

  /// Badge text for ticketed sessions
  ///
  /// In en, this message translates to:
  /// **'Ticketed'**
  String get ticketed;

  /// Button text to create a ticket
  ///
  /// In en, this message translates to:
  /// **'Create Ticket'**
  String get createTicket;

  /// Status text for sessions that have been ticketed
  ///
  /// In en, this message translates to:
  /// **'Already ticketed'**
  String get alreadyTicketed;

  /// Location confidence: GPS auto-detected
  ///
  /// In en, this message translates to:
  /// **'GPS location'**
  String get locationGps;

  /// Location confidence: GPS detected but outside zone boundaries
  ///
  /// In en, this message translates to:
  /// **'GPS (outside zone)'**
  String get locationGpsOutsideZone;

  /// Location confidence: User manually placed marker
  ///
  /// In en, this message translates to:
  /// **'User-placed location'**
  String get locationUserPlaced;

  /// Location confidence: Only zone centroid available
  ///
  /// In en, this message translates to:
  /// **'Zone only (no precise location)'**
  String get locationZoneOnly;

  /// Location confidence: Unknown source
  ///
  /// In en, this message translates to:
  /// **'Location unknown'**
  String get locationUnknown;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
