import 'app_localizations.dart';

class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([super.locale = 'ar']);

  @override
  String get appName => 'ParkUp Agent';

  @override
  String get signInToContinue => 'سجل الدخول للمتابعة';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get enterUsername => 'أدخل اسم المستخدم';

  @override
  String get password => 'كلمة المرور';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get pleaseEnterUsername => 'الرجاء إدخال اسم المستخدم';

  @override
  String get pleaseEnterPassword => 'الرجاء إدخال كلمة المرور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get contactAdminForPassword => 'تواصل مع المسؤول إذا نسيت كلمة المرور';

  @override
  String get loginFailed => 'فشل تسجيل الدخول. يرجى المحاولة مرة أخرى.';

  @override
  String welcomeUser(String name) => 'مرحباً، $name';

  @override
  String get whatWouldYouLikeToDo => 'ماذا تريد أن تفعل؟';

  @override
  String get checkVehicle => 'فحص المركبة';

  @override
  String get checkStatusCreateTickets => 'فحص الحالة وإنشاء المخالفات';

  @override
  String get removeSabots => 'إزالة السابوهات';

  @override
  String get paidSabotsToRemove => 'سابوهات مدفوعة للإزالة';

  @override
  String get history => 'السجل';

  @override
  String get viewPastTickets => 'عرض المخالفات السابقة';

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'غير نشط';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutConfirmation => 'هل أنت متأكد من أنك تريد تسجيل الخروج؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get licensePlate => 'لوحة الترخيص';

  @override
  String get gpsLocationUpdated => 'تم تحديث موقع GPS';

  @override
  String get couldNotGetGpsLocation => 'تعذر الحصول على موقع GPS';

  @override
  String get pleaseEnterValidPlate => 'الرجاء إدخال لوحة ترخيص صالحة';

  @override
  String get failedToCheckVehicle => 'فشل فحص المركبة. يرجى المحاولة مرة أخرى.';

  @override
  String get pleaseSelectParkingZone => 'الرجاء اختيار منطقة الوقوف';

  @override
  String get usingZoneLocation => 'استخدام موقع المنطقة (GPS غير متوفر)';

  @override
  String ticketCreated(String number) => 'تم إنشاء المخالفة #$number';

  @override
  String get failedToCreateTicket => 'فشل إنشاء المخالفة. يرجى المحاولة مرة أخرى.';

  @override
  String get checking => 'جاري الفحص...';

  @override
  String get check => 'فحص';

  @override
  String get recheck => 'إعادة الفحص';

  @override
  String get newSearch => 'بحث جديد';

  @override
  String get enterPlateThenCheck => 'أدخل لوحة الترخيص، ثم اضغط فحص';

  @override
  String get selectZone => 'اختر المنطقة';

  @override
  String get refreshGps => 'تحديث GPS';

  @override
  String expired(String date) => 'منتهي: $date';

  @override
  String get error => 'خطأ';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get noTicketsYet => 'لا توجد مخالفات بعد';

  @override
  String get ticketsWillAppearHere => 'المخالفات التي تنشئها ستظهر هنا';

  @override
  String ticketCount(int count) => count == 1 ? 'مخالفة واحدة' : '$count مخالفات';

  @override
  String get goToLocation => 'الذهاب إلى الموقع';

  @override
  String get print => 'طباعة';

  @override
  String get yesterday => 'أمس';

  @override
  String minutesAgo(int count) => 'قبل $count دقيقة';

  @override
  String hoursAgo(int count) => 'قبل $count ساعة';

  @override
  String get printPreview => 'معاينة الطباعة';

  @override
  String get shareAsImage => 'مشاركة كصورة';

  @override
  String get parkingTicket => 'مخالفة وقوف';

  @override
  String get scanToPay => 'امسح للدفع';

  @override
  String get viewOnMap => 'عرض على الخريطة';

  @override
  String get share => 'مشاركة';

  @override
  String get bluetoothPrintingComingSoon => 'طباعة البلوتوث قريباً!';

  @override
  String get failedToShare => 'فشلت المشاركة';

  @override
  String get failedToLoadPrintData => 'فشل تحميل بيانات الطباعة';

  @override
  String get pendingRemovals => 'إزالات معلقة';

  @override
  String get confirmRemoval => 'تأكيد الإزالة';

  @override
  String markSabotAsRemoved(String plate) => 'تحديد السابو للوحة $plate كمُزال؟';

  @override
  String get sabotMarkedAsRemoved => 'تم تحديد السابو كمُزال';

  @override
  String get allClear => 'كل شيء على ما يرام!';

  @override
  String get noSabotsPendingRemoval => 'لا توجد سابوهات معلقة للإزالة';

  @override
  String sabotCount(int count) => count == 1 ? 'سابو واحد للإزالة' : '$count سابوهات للإزالة';

  @override
  String get paid => 'مدفوع';

  @override
  String paidTime(String time) => 'مدفوع $time';

  @override
  String get navigate => 'التنقل';

  @override
  String get removed => 'تمت الإزالة';

  @override
  String get failedToLoadPendingRemovals => 'فشل تحميل الإزالات المعلقة';

  @override
  String get failedToLoadTickets => 'فشل تحميل المخالفات';

  @override
  String get refresh => 'تحديث';
}
