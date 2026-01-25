// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ParkUp Agent';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get username => 'Username';

  @override
  String get enterUsername => 'Enter your username';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get pleaseEnterUsername => 'Please enter your username';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get signIn => 'Sign In';

  @override
  String get contactAdminForPassword =>
      'Contact your administrator if you forgot your password';

  @override
  String get loginFailed => 'Login failed. Please try again.';

  @override
  String welcomeUser(String name) {
    return 'Welcome, $name';
  }

  @override
  String get whatWouldYouLikeToDo => 'What would you like to do?';

  @override
  String get checkVehicle => 'Check Vehicle';

  @override
  String get checkStatusCreateTickets => 'Check status & create tickets';

  @override
  String get removeSabots => 'Remove Sabots';

  @override
  String get paidSabotsToRemove => 'Paid sabots to remove';

  @override
  String get history => 'History';

  @override
  String get viewPastTickets => 'View past tickets';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get licensePlate => 'License Plate';

  @override
  String get gpsLocationUpdated => 'GPS location updated';

  @override
  String get couldNotGetGpsLocation => 'Could not get GPS location';

  @override
  String get pleaseEnterValidPlate => 'Please enter a valid license plate';

  @override
  String get failedToCheckVehicle =>
      'Failed to check vehicle. Please try again.';

  @override
  String get pleaseSelectParkingZone => 'Please select a parking zone';

  @override
  String get usingZoneLocation => 'Using zone location (GPS unavailable)';

  @override
  String ticketCreated(String number) {
    return 'Ticket #$number created';
  }

  @override
  String get failedToCreateTicket =>
      'Failed to create ticket. Please try again.';

  @override
  String get checking => 'Checking...';

  @override
  String get check => 'Check';

  @override
  String get recheck => 'Recheck';

  @override
  String get newSearch => 'New Search';

  @override
  String get enterPlateThenCheck => 'Enter license plate, then tap Check';

  @override
  String get selectZone => 'Select Zone';

  @override
  String get refreshGps => 'Refresh GPS';

  @override
  String expired(String date) {
    return 'Expired: $date';
  }

  @override
  String get error => 'Error';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get noTicketsYet => 'No tickets yet';

  @override
  String get ticketsWillAppearHere => 'Tickets you create will appear here';

  @override
  String ticketCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets',
      one: '1 ticket',
    );
    return '$_temp0';
  }

  @override
  String get goToLocation => 'Go to Location';

  @override
  String get print => 'Print';

  @override
  String get yesterday => 'Yesterday';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String get printPreview => 'Print Preview';

  @override
  String get shareAsImage => 'Share as Image';

  @override
  String get parkingTicket => 'PARKING TICKET';

  @override
  String get scanToPay => 'Scan to Pay';

  @override
  String get viewOnMap => 'View on Map';

  @override
  String get share => 'Share';

  @override
  String get bluetoothPrintingComingSoon => 'Bluetooth printing coming soon!';

  @override
  String get failedToShare => 'Failed to share';

  @override
  String get failedToLoadPrintData => 'Failed to load print data';

  @override
  String get pendingRemovals => 'Pending Removals';

  @override
  String get confirmRemoval => 'Confirm Removal';

  @override
  String markSabotAsRemoved(String plate) {
    return 'Mark sabot for $plate as removed?';
  }

  @override
  String get sabotMarkedAsRemoved => 'Sabot marked as removed';

  @override
  String get allClear => 'All clear!';

  @override
  String get noSabotsPendingRemoval => 'No sabots pending removal';

  @override
  String sabotCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sabots to remove',
      one: '1 sabot to remove',
    );
    return '$_temp0';
  }

  @override
  String get paid => 'PAID';

  @override
  String paidTime(String time) {
    return 'Paid $time';
  }

  @override
  String get navigate => 'Navigate';

  @override
  String get removed => 'Removed';

  @override
  String get failedToLoadPendingRemovals => 'Failed to load pending removals';

  @override
  String get failedToLoadTickets => 'Failed to load tickets';

  @override
  String get refresh => 'Refresh';

  @override
  String get language => 'Language';

  @override
  String get sessionsMap => 'Sessions Map';

  @override
  String get viewActiveSessionsOnMap => 'View active sessions on map';

  @override
  String get activeSessions => 'Active Sessions';

  @override
  String newSession(String licensePlate) {
    return 'New session: $licensePlate';
  }

  @override
  String sessionEvent(String reason, String sessionId) {
    return 'Session $reason: $sessionId...';
  }

  @override
  String get noAssignedZones => 'No assigned zones';

  @override
  String criticalExpiring(String licensePlate, int minutes) {
    return 'CRITICAL: $licensePlate expires in $minutes min!';
  }

  @override
  String sessionExpiring(String licensePlate, int minutes) {
    return '$licensePlate expires in $minutes min';
  }

  @override
  String get view => 'View';

  @override
  String get retry => 'Retry';

  @override
  String activeCount(int count) {
    return '$count active';
  }

  @override
  String get valid => 'Valid';

  @override
  String get lessThan10Min => '< 10 min';

  @override
  String get expiredStatus => 'Expired';

  @override
  String minutesRemaining(int minutes) {
    return '$minutes min remaining';
  }

  @override
  String endsAt(String time) {
    return 'Ends at $time';
  }

  @override
  String get duration => 'Duration';

  @override
  String get amount => 'Amount';

  @override
  String get serieNormale => 'Standard Series';

  @override
  String get gouvernement => 'Government';

  @override
  String get libye => 'Libya';

  @override
  String get algerie => 'Algeria';

  @override
  String get unionEuropeenne => 'European Union';

  @override
  String get autre => 'Other';

  @override
  String get diplomatiqueConsulaire => 'Diplomatic & Consular';

  @override
  String get corpsDiplomatique => 'Diplomatic Corps';

  @override
  String get corpsConsulaire => 'Consular Corps';

  @override
  String get plaquesDiplomatiques => 'Diplomatic Plates';

  @override
  String get enforcementMap => 'Enforcement Map';

  @override
  String get sessions => 'Sessions';

  @override
  String get hideTicketed => 'Hide ticketed';

  @override
  String get showTicketed => 'Show ticketed';

  @override
  String get noViolationsFound => 'No violations found';

  @override
  String get noSessionsFound => 'No sessions found';

  @override
  String get ticketed => 'Ticketed';

  @override
  String get createTicket => 'Create Ticket';

  @override
  String get alreadyTicketed => 'Already ticketed';

  @override
  String get locationGps => 'GPS location';

  @override
  String get locationGpsOutsideZone => 'GPS (outside zone)';

  @override
  String get locationUserPlaced => 'User-placed location';

  @override
  String get locationZoneOnly => 'Zone only (no precise location)';

  @override
  String get locationUnknown => 'Location unknown';
}
