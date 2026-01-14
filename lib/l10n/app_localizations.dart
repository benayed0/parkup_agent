import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  String get appName;
  String get signInToContinue;
  String get username;
  String get enterUsername;
  String get password;
  String get enterPassword;
  String get pleaseEnterUsername;
  String get pleaseEnterPassword;
  String get signIn;
  String get contactAdminForPassword;
  String get loginFailed;
  String welcomeUser(String name);
  String get whatWouldYouLikeToDo;
  String get checkVehicle;
  String get checkStatusCreateTickets;
  String get removeSabots;
  String get paidSabotsToRemove;
  String get history;
  String get viewPastTickets;
  String get active;
  String get inactive;
  String get logout;
  String get logoutConfirmation;
  String get cancel;
  String get confirm;
  String get licensePlate;
  String get gpsLocationUpdated;
  String get couldNotGetGpsLocation;
  String get pleaseEnterValidPlate;
  String get failedToCheckVehicle;
  String get pleaseSelectParkingZone;
  String get usingZoneLocation;
  String ticketCreated(String number);
  String get failedToCreateTicket;
  String get checking;
  String get check;
  String get recheck;
  String get newSearch;
  String get enterPlateThenCheck;
  String get selectZone;
  String get refreshGps;
  String expired(String date);
  String get error;
  String get somethingWentWrong;
  String get tryAgain;
  String get noTicketsYet;
  String get ticketsWillAppearHere;
  String ticketCount(int count);
  String get goToLocation;
  String get print;
  String get yesterday;
  String minutesAgo(int count);
  String hoursAgo(int count);
  String get printPreview;
  String get shareAsImage;
  String get parkingTicket;
  String get scanToPay;
  String get viewOnMap;
  String get share;
  String get bluetoothPrintingComingSoon;
  String get failedToShare;
  String get failedToLoadPrintData;
  String get pendingRemovals;
  String get confirmRemoval;
  String markSabotAsRemoved(String plate);
  String get sabotMarkedAsRemoved;
  String get allClear;
  String get noSabotsPendingRemoval;
  String sabotCount(int count);
  String get paid;
  String paidTime(String time);
  String get navigate;
  String get removed;
  String get failedToLoadPendingRemovals;
  String get failedToLoadTickets;
  String get refresh;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
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
    'that was used.'
  );
}
