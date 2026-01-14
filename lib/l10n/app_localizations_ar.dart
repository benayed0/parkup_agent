import 'app_localizations.dart';

class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([super.locale = 'ar']);

  @override
  String get appName => 'ParkUp Agent';

  @override
  String get signInToContinue => 'ادخل باش تكمّل';

  @override
  String get username => 'الإسم متاعك';

  @override
  String get enterUsername => 'اكتب اسمك هوني';

  @override
  String get password => 'الكلمة السرية';

  @override
  String get enterPassword => 'اكتب الكلمة السرية';

  @override
  String get pleaseEnterUsername => 'يا ولدي اكتب اسمك!';

  @override
  String get pleaseEnterPassword => 'وين الكلمة السرية؟';

  @override
  String get signIn => 'ادخل';

  @override
  String get contactAdminForPassword => 'نسيت الكلمة السرية؟ كلّم المسؤول';

  @override
  String get loginFailed => 'ما نجمتش تدخل. عاود حاول!';

  @override
  String welcomeUser(String name) => 'عسلامة يا $name!';

  @override
  String get whatWouldYouLikeToDo => 'آش تحب تعمل توّا؟';

  @override
  String get checkVehicle => 'شوف الكرهبة';

  @override
  String get checkStatusCreateTickets => 'شوف الحالة واعمل خطية';

  @override
  String get removeSabots => 'فكّ السابو';

  @override
  String get paidSabotsToRemove => 'سابوات خالصين لازم يتفكّو';

  @override
  String get history => 'التاريخ';

  @override
  String get viewPastTickets => 'شوف الخطيةات القديمة';

  @override
  String get active => 'خدّام';

  @override
  String get inactive => 'واقف';

  @override
  String get logout => 'اخرج';

  @override
  String get logoutConfirmation => 'متأكد تحب تخرج؟';

  @override
  String get cancel => 'لا خلّي';

  @override
  String get confirm => 'إيه أكّد';

  @override
  String get licensePlate => 'الماتريكيل';

  @override
  String get gpsLocationUpdated => 'البلاصة تحدّثت';

  @override
  String get couldNotGetGpsLocation => 'ما لقيتش البلاصة متاعك';

  @override
  String get pleaseEnterValidPlate => 'اكتب ماتريكيل صحيح!';

  @override
  String get failedToCheckVehicle => 'ما نجمتش نشوف الكرهبة. عاود حاول';

  @override
  String get pleaseSelectParkingZone => 'اختار الزون وين الكرهبة';

  @override
  String get usingZoneLocation => 'نستعمل بلاصة الزون (GPS ما يخدمش)';

  @override
  String ticketCreated(String number) => 'يا سلام! خطية #$number تعملت';

  @override
  String get failedToCreateTicket => 'ما نجمتش نعمل خطية. عاود حاول';

  @override
  String get checking => 'مستنّي... نشوف';

  @override
  String get check => 'شوف';

  @override
  String get recheck => 'عاود شوف';

  @override
  String get newSearch => 'بحث جديد';

  @override
  String get enterPlateThenCheck => 'اكتب الماتريكيل وبعد عيّط على شوف';

  @override
  String get selectZone => 'اختار الزون';

  @override
  String get refreshGps => 'حدّث البلاصة';

  @override
  String expired(String date) => 'فات وقتو: $date';

  @override
  String get error => 'مشكلة!';

  @override
  String get somethingWentWrong => 'صار شي ما يصلحش';

  @override
  String get tryAgain => 'عاود حاول';

  @override
  String get noTicketsYet => 'مازال ما عندك حتى خطية';

  @override
  String get ticketsWillAppearHere => 'الخطيةات اللي تعملها تظهر هوني';

  @override
  String ticketCount(int count) => count == 1 ? 'خطية وحدة' : '$count خطيةات';

  @override
  String get goToLocation => 'امشي للبلاصة';

  @override
  String get print => 'اطبع';

  @override
  String get yesterday => 'البارح';

  @override
  String minutesAgo(int count) => 'قبل $count دقيقة';

  @override
  String hoursAgo(int count) => 'قبل $count ساعات';

  @override
  String get printPreview => 'شوف قبل ما تطبع';

  @override
  String get shareAsImage => 'ابعث كتصويرة';

  @override
  String get parkingTicket => 'خطية باركينغ';

  @override
  String get scanToPay => 'سكاني باش تخلّص';

  @override
  String get viewOnMap => 'شوف في الكارطة';

  @override
  String get share => 'ابعث';

  @override
  String get bluetoothPrintingComingSoon => 'الطباعة بالبلوتوث جايّة قريب!';

  @override
  String get failedToShare => 'ما نجمتش نبعث';

  @override
  String get failedToLoadPrintData => 'ما نجمتش نحمّل بيانات الطباعة';

  @override
  String get pendingRemovals => 'سابوات يستنّاو التفكيك';

  @override
  String get confirmRemoval => 'أكّد التفكيك';

  @override
  String markSabotAsRemoved(String plate) => 'تحب تقول السابو متاع $plate تفكّ؟';

  @override
  String get sabotMarkedAsRemoved => 'تمام! السابو تفكّ';

  @override
  String get allClear => 'كل شي باهي!';

  @override
  String get noSabotsPendingRemoval => 'ما فمّاش سابوات يستنّاو';

  @override
  String sabotCount(int count) => count == 1 ? 'سابو واحد للتفكيك' : '$count سابوات للتفكيك';

  @override
  String get paid => 'مخلّص';

  @override
  String paidTime(String time) => 'خلّص $time';

  @override
  String get navigate => 'روّح للبلاصة';

  @override
  String get removed => 'تفكّ';

  @override
  String get failedToLoadPendingRemovals => 'ما نجمتش نجيب السابوات';

  @override
  String get failedToLoadTickets => 'ما نجمتش نجيب الخطيةات';

  @override
  String get refresh => 'حدّث';
}
