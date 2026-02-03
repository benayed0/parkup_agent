// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

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
  String welcomeUser(String name) {
    return 'عسلامة يا $name!';
  }

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
  String ticketCreated(String number) {
    return 'يا سلام! خطية #$number تعملت';
  }

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
  String get done => 'تم';

  @override
  String get enterPlateThenCheck => 'اكتب الماتريكيل وبعد عيّط على شوف';

  @override
  String get selectZone => 'اختار الزون';

  @override
  String get refreshGps => 'حدّث البلاصة';

  @override
  String expired(String date) {
    return 'فات وقتو: $date';
  }

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
  String ticketCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خطيةات',
      one: 'خطية وحدة',
    );
    return '$_temp0';
  }

  @override
  String get goToLocation => 'امشي للبلاصة';

  @override
  String get print => 'اطبع';

  @override
  String get yesterday => 'البارح';

  @override
  String minutesAgo(int count) {
    return 'قبل $count دقيقة';
  }

  @override
  String hoursAgo(int count) {
    return 'قبل $count ساعات';
  }

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
  String markSabotAsRemoved(String plate) {
    return 'تحب تقول السابو متاع $plate تفكّ؟';
  }

  @override
  String get sabotMarkedAsRemoved => 'تمام! السابو تفكّ';

  @override
  String get allClear => 'كل شي باهي!';

  @override
  String get noSabotsPendingRemoval => 'ما فمّاش سابوات يستنّاو';

  @override
  String sabotCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سابوات للتفكيك',
      one: 'سابو واحد للتفكيك',
    );
    return '$_temp0';
  }

  @override
  String get paid => 'مخلّص';

  @override
  String paidTime(String time) {
    return 'خلّص $time';
  }

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

  @override
  String get language => 'اللغة';

  @override
  String get sessionsMap => 'خريطة التيكيات';

  @override
  String get viewActiveSessionsOnMap => 'شوف التيكيات الخدّامة على الخريطة';

  @override
  String get activeSessions => 'التيكيات الخدّامة';

  @override
  String newSession(String licensePlate) {
    return 'تيكي جديد: $licensePlate';
  }

  @override
  String sessionEvent(String reason, String sessionId) {
    return 'تيكي $reason: $sessionId...';
  }

  @override
  String get noAssignedZones => 'ما عندكش زونات';

  @override
  String criticalExpiring(String licensePlate, int minutes) {
    return 'انتباه! $licensePlate باقي $minutes دقيقة!';
  }

  @override
  String sessionExpiring(String licensePlate, int minutes) {
    return '$licensePlate باقي $minutes دقيقة';
  }

  @override
  String get view => 'شوف';

  @override
  String get retry => 'عاود';

  @override
  String activeCount(int count) {
    return '$count خدّامين';
  }

  @override
  String get valid => 'صالح';

  @override
  String get lessThan10Min => '< 10 دق';

  @override
  String get expiredStatus => 'فات وقتو';

  @override
  String minutesRemaining(int minutes) {
    return 'باقي $minutes دقيقة';
  }

  @override
  String endsAt(String time) {
    return 'يكمّل في $time';
  }

  @override
  String get duration => 'المدة';

  @override
  String get amount => 'المبلغ';

  @override
  String get serieNormale => 'سلسلة عادية';

  @override
  String get gouvernement => 'حكومة';

  @override
  String get libye => 'ليبيا';

  @override
  String get algerie => 'الجزائر';

  @override
  String get unionEuropeenne => 'الاتحاد الأوروبي';

  @override
  String get autre => 'آخر';

  @override
  String get diplomatiqueConsulaire => 'دبلوماسي وقنصلي';

  @override
  String get corpsDiplomatique => 'السلك الدبلوماسي';

  @override
  String get corpsConsulaire => 'السلك القنصلي';

  @override
  String get plaquesDiplomatiques => 'الماتريكيلات الدبلوماسية';

  @override
  String get enforcementMap => 'خريطة المراقبة';

  @override
  String get sessions => 'التيكيات';

  @override
  String get hideTicketed => 'خبّي المخطيين';

  @override
  String get showTicketed => 'وري المخطيين';

  @override
  String get noViolationsFound => 'ما لقيت حتى مخالفة';

  @override
  String get noSessionsFound => 'ما لقيت حتى تيكي';

  @override
  String get ticketed => 'تخطى';

  @override
  String get createTicket => 'اعمل خطية';

  @override
  String get alreadyTicketed => 'مخطي من قبل';

  @override
  String get locationGps => 'بلاصة GPS';

  @override
  String get locationGpsOutsideZone => 'GPS (برّا الزون)';

  @override
  String get locationUserPlaced => 'بلاصة وضعها المستعمل';

  @override
  String get locationZoneOnly => 'الزون فقط (بلاصة مش دقيقة)';

  @override
  String get locationUnknown => 'بلاصة مش معروفة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get printerSettings => 'إعدادات الطابعة';

  @override
  String get scanForPrinters => 'ابحث على طابعات';

  @override
  String get connectPrinter => 'اربط';

  @override
  String get disconnectPrinter => 'افصل';

  @override
  String get testPrint => 'طباعة تجريبية';

  @override
  String get noPrinterConnected => 'ما فماش طابعة مربوطة';

  @override
  String get printerConnected => 'الطابعة مربوطة';

  @override
  String get scanning => 'نبحث...';

  @override
  String get connecting => 'نربط...';

  @override
  String get noDevicesFound => 'ما لقيت حتى جهاز';

  @override
  String get enableBluetooth => 'شغّل البلوتوث';

  @override
  String get bluetoothPermissionDenied => 'ما عندكش إذن للبلوتوث';

  @override
  String get printSuccess => 'الطباعة نجحت';

  @override
  String get printFailed => 'الطباعة ما مشاتش';

  @override
  String connectedTo(String name) {
    return 'مربوط مع $name';
  }

  @override
  String get savedPrinter => 'طابعة محفوظة';

  @override
  String get tapToConnect => 'اضغط باش تربط';

  @override
  String get availableDevices => 'أجهزة متوفرة';

  @override
  String get stopScan => 'وقّف';

  @override
  String get connectToPrinterFirst => 'اربط طابعة الأول';

  @override
  String get printing => 'نطبع...';

  @override
  String get printLabelTicketNumber => 'رقم الخطية';

  @override
  String get printLabelPlate => 'الماتريكيل';

  @override
  String get printLabelReason => 'السبب';

  @override
  String get printLabelFine => 'المبلغ';

  @override
  String get printLabelDate => 'التاريخ';

  @override
  String get printLabelTime => 'الوقت';

  @override
  String get printLabelAddress => 'العنوان';

  @override
  String get printReasonCarSabot => 'سابو';

  @override
  String get printReasonPound => 'الحجز';

  @override
  String get printLabelZone => 'المنطقة';

  @override
  String get printLabelZoneAddress => 'عنوان المنطقة';

  @override
  String get printLabelZonePhone => 'الهاتف';

  @override
  String get stopPrint => 'وقّف';

  @override
  String get printCancelled => 'الطباعة تلغات';

  @override
  String get connectionFailed => 'فشل الاتصال';

  @override
  String get reconnectionFailed => 'فشل إعادة الاتصال';

  @override
  String get makeSurePrinterOn => 'تأكد إن الطابعة مشغّلة';

  @override
  String get noPrintersFound => 'ما لقيت حتى طابعة';

  @override
  String get turnOnPrinterAndScan => 'شغّل الطابعة واضغط على بحث';

  @override
  String showAllDevicesCount(int count) {
    return 'وري كل الأجهزة ($count مخبيين)';
  }

  @override
  String get printers => 'الطابعات';

  @override
  String get printersOnly => 'الطابعات فقط';

  @override
  String showAllCount(int count) {
    return 'وري الكل ($count)';
  }

  @override
  String get unknownDevice => 'جهاز مش معروف';

  @override
  String get notPairedTapToPair => 'مش مقترن - اضغط للاقتران';

  @override
  String get systemDefault => 'الافتراضي للنظام';

  @override
  String get unknownError => 'خطأ مش معروف';

  @override
  String get showPrintersOnly => 'وري الطابعات فقط';

  @override
  String get showAllDevices => 'وري كل الأجهزة';

  @override
  String failedToLoadTicketsWithError(String error) {
    return 'فشل تحميل الخطيةات: $error';
  }

  @override
  String get euShort => 'أوروبي';

  @override
  String get diploShort => 'دبلو.';

  @override
  String get today => 'اليوم';

  @override
  String get allTickets => 'الكل';

  @override
  String get thisWeek => 'هالجمعة';

  @override
  String get thisMonth => 'هالشهر';
}
