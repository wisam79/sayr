// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'سير';

  @override
  String get approximateRouteWarning =>
      'المسار المعروض تقريبي بسبب عطل في خادم الاتجاهات';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginSubtitle => 'أهلاً بعودتك! يرجى تسجيل الدخول للمتابعة';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emailHint => 'example@sayr.app';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordHint => 'أدخل كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get resetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get resetPasswordSubtitle => 'أدخل كلمة مرور جديدة لحسابك';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get confirmPasswordHint => 'أعد إدخال كلمة المرور';

  @override
  String get updatePassword => 'تحديث كلمة المرور';

  @override
  String get passwordUpdated => 'تم تحديث كلمة المرور بنجاح';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get passwordTooShort => 'كلمة المرور قصيرة جداً';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String passwordResetEmailSent(String email) {
    return 'تم إرسال رابط استعادة كلمة المرور إلى $email';
  }

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get orContinueWith => 'أو تابع باستخدام';

  @override
  String get loginWithGoogle => 'متابعة باستخدام Google';

  @override
  String get noAccount => 'ليس لديك حساب؟';

  @override
  String get signup => 'إنشاء حساب';

  @override
  String get signupTitle => 'إنشاء حساب';

  @override
  String get signupSubtitle => 'انضم إلى سير لإدارة تنقلاتك الجامعية';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get fullNameHint => 'أحمد علي';

  @override
  String get phone => 'الهاتف (اختياري)';

  @override
  String get phoneHint => '07901234567';

  @override
  String get signupButton => 'إنشاء الحساب';

  @override
  String get haveAccount => 'لديك حساب بالفعل؟';

  @override
  String get signin => 'تسجيل الدخول';

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String get routesTitle => 'الخطوط';

  @override
  String get mySubscriptions => 'اشتراكاتي';

  @override
  String get searchRoutes => 'البحث عن خط...';

  @override
  String get activateLicense => 'تفعيل ترخيص';

  @override
  String get enterLicenseCode => 'أدخل كود الترخيص المكون من 8 أحرف';

  @override
  String get licenseCodeLabel => 'كود الترخيص';

  @override
  String get licenseCodeHint => 'A1B2C3D4';

  @override
  String get licenseCodeValidation => 'يجب أن يكون 8 أحرف';

  @override
  String get activate => 'تفعيل';

  @override
  String get licenseActivated => 'تم تفعيل الترخيص بنجاح!';

  @override
  String get activationFailed => 'فشل التفعيل';

  @override
  String get activeSubscription => 'اشتراك نشط';

  @override
  String get noActiveSubscription => 'لا يوجد اشتراك نشط';

  @override
  String get getSubscription => 'احصل على اشتراك';

  @override
  String get expiresOn => 'ينتهي في';

  @override
  String daysRemaining(int days) {
    return 'متبقي $days يوم';
  }

  @override
  String get profile => 'حسابي';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get chooseLanguage => 'اختر اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutConfirm => 'هل أنت متأكد من تسجيل الخروج؟';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get loadingRouteTitle => 'جاري تحميل الخط...';

  @override
  String get loadingStartLocation => 'جاري تحميل نقطة البداية...';

  @override
  String get loadingEndLocation => 'جاري تحميل نقطة النهاية...';

  @override
  String get error => 'خطأ';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get save => 'حفظ';

  @override
  String get next => 'التالي';

  @override
  String get back => 'رجوع';

  @override
  String get done => 'تم';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get noInternet => 'لا يوجد اتصال بالإنترنت';

  @override
  String get maintenanceMode => 'التطبيق تحت الصيانة';

  @override
  String get updateRequired => 'التحديث مطلوب';

  @override
  String get updateMessage => 'يتوفر إصدار جديد من سير. يرجى التحديث للمتابعة.';

  @override
  String get routeDetails => 'تفاصيل الخط';

  @override
  String get startLocation => 'نقطة البداية';

  @override
  String get endLocation => 'نقطة النهاية';

  @override
  String get price => 'السعر';

  @override
  String get availableSeats => 'المقاعد المتاحة';

  @override
  String get departureTime => 'وقت المغادرة';

  @override
  String get returnTime => 'وقت العودة';

  @override
  String get operatingDays => 'أيام العمل';

  @override
  String get subscribe => 'اشترك الآن';

  @override
  String get available => 'متوفر';

  @override
  String get full => 'ممتلئ';

  @override
  String get chats => 'المحادثات';

  @override
  String get help => 'المساعدة';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get activeTrips => 'الرحلات';

  @override
  String get noActiveTrips => 'لا توجد رحلات نشطة حالياً';

  @override
  String get activeTripsAvailable => 'يوجد رحلات نشطة، اضغط للمتابعة';

  @override
  String get noRoutesAvailable => 'لا توجد خطوط متاحة';

  @override
  String get tryAgainLater => 'حاول مرة أخرى لاحقاً';

  @override
  String helloUser(String name) {
    return 'مرحباً، $name';
  }

  @override
  String get browseRoutes => 'تصفح الخطوط';

  @override
  String get browseRoutesDesc => 'اعثر على خط يناسبك';

  @override
  String get createNewTrip => 'إنشاء رحلة جديدة';

  @override
  String get createNewTripDesc => 'ابدأ رحلة على خط مسجل لديك';

  @override
  String get myActiveTrips => 'رحلاتي النشطة';

  @override
  String get myActiveTripsDesc => 'عرض وإدارة رحلاتك الجارية';

  @override
  String activeSubscriptionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اشتراكات',
      one: 'اشتراك واحد',
    );
    return '$_temp0 نشطة';
  }

  @override
  String get subscription => 'اشتراك';

  @override
  String get failedToLoadRoutes => 'فشل تحميل الخطوط';

  @override
  String get createTrip => 'إنشاء رحلة جديدة';

  @override
  String get validationEmailRequired => 'البريد مطلوب';

  @override
  String get validationEmailInvalid => 'بريد غير صحيح';

  @override
  String get validationPasswordRequired => 'كلمة المرور مطلوبة';

  @override
  String get validationPasswordTooShort =>
      'كلمة المرور يجب أن تكون 6 أحرف على الأقل';

  @override
  String get validationFullNameRequired => 'الاسم الكامل مطلوب';

  @override
  String get validationPhoneInvalid => 'رقم هاتف غير صحيح';

  @override
  String get validationPasswordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get unknownError => 'خطأ غير معروف';

  @override
  String passwordResetLinkSent(String email) {
    return 'تم إرسال رابط استعادة كلمة المرور إلى $email';
  }

  @override
  String get skip => 'تخطي';

  @override
  String get getStarted => 'ابدأ';

  @override
  String get onboardingTitle1 => 'تنقل بسهولة';

  @override
  String get onboardingDesc1 =>
      'احجز اشتراكك على خطوط النقل الجامعي بضغطة زر وتابع رحلتك لحظة بلحظة.';

  @override
  String get onboardingTitle2 => 'تتبع مباشر';

  @override
  String get onboardingDesc2 =>
      'اعرف موقع الباص في الوقت الحقيقي واحصل على إشعارات عند اقترابه.';

  @override
  String get onboardingTitle3 => 'آمن وموثوق';

  @override
  String get onboardingDesc3 =>
      'نظام تراخيص مسبق الدفع يضمن لك مقعدك ويحمي حقوقك.';

  @override
  String get tripTracking => 'تتبع الرحلة';

  @override
  String get waitingForDriver => 'في انتظار السائق...';

  @override
  String get start => 'البداية';

  @override
  String get destination => 'الوجهة';

  @override
  String get routeTitle => 'الخط';

  @override
  String get tripTime => 'وقت الرحلة';

  @override
  String get create => 'إنشاء';

  @override
  String get tripTimeMustBeFuture => 'وقت الرحلة يجب أن يكون في المستقبل';

  @override
  String get failedToCreateTrip => 'فشل إنشاء الرحلة';

  @override
  String get noDriverRoutes => 'لا توجد خطوط مرتبطة بحسابك';

  @override
  String get activeRouteRequired => 'يجب توفر خط نشط قبل إنشاء رحلة.';

  @override
  String get noTripsYet => 'لم تقم بإنشاء أي رحلة بعد';

  @override
  String get tripLoadFailed => 'فشل تحميل تفاصيل الرحلة';

  @override
  String get routeNotFound => 'الخط غير موجود';

  @override
  String get routeLoadFailed => 'فشل تحميل تفاصيل الخط';

  @override
  String get noSubscriptionsTitle => 'لا يوجد اشتراكات';

  @override
  String get noSubscriptionsSubtitle => 'فعّل ترخيصك الأول للبدء';

  @override
  String get subscriptionType => 'اشتراك';

  @override
  String get subscriptionStatusActive => 'نشط';

  @override
  String get subscriptionStatusPending => 'قيد الانتظار';

  @override
  String get subscriptionStatusExpired => 'منتهي';

  @override
  String get subscriptionStatusCancelled => 'ملغي';

  @override
  String subscriptionEndsOn(String date) {
    return 'ينتهي: $date';
  }

  @override
  String subscriptionDaysLeft(int days) {
    return 'متبقي $days يوم';
  }

  @override
  String get cancelSubscription => 'إلغاء الاشتراك';

  @override
  String get errorOccurred => 'حدث خطأ';

  @override
  String get pageNotFound => 'الصفحة غير موجودة';

  @override
  String get version => 'الإصدار';

  @override
  String get payment => 'الدفع';

  @override
  String get choosePaymentMethod => 'اختر طريقة الدفع';

  @override
  String get voucher => 'بطاقة شحن';

  @override
  String get enterVoucherCode => 'أدخل كود البطاقة';

  @override
  String get processing => 'جاري المعالجة...';

  @override
  String get paymentSuccess => 'تم الدفع بنجاح';

  @override
  String get paymentSuccessSubscription => 'تم الدفع بنجاح! تم تفعيل اشتراكك';

  @override
  String get paymentFailed => 'فشل الدفع';

  @override
  String get paymentViaZainCash => 'الدفع عبر زين كاش';

  @override
  String get openZainCash => 'افتح زين كاش';

  @override
  String amount(String amount, String currency) {
    return 'المبلغ: $amount $currency';
  }

  @override
  String get awaitingPaymentConfirmation => 'في انتظار تأكيد الدفع...';

  @override
  String get completePaymentInZainCash =>
      'أكمل الدفع في تطبيق زين كاش ثم عد هنا';

  @override
  String get unexpectedError => 'حدث خطأ غير متوقع';

  @override
  String get invalidVoucher => 'بطاقة غير صالحة';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get noNotifications => 'لا توجد إشعارات';

  @override
  String get markAllAsRead => 'تحديد الكل كمقروء';

  @override
  String get loadFailed => 'فشل التحميل';

  @override
  String get allMarkedAsRead => 'تم وضع علامة قراءة على الكل';

  @override
  String get messageHint => 'اكتب رسالة...';

  @override
  String get send => 'إرسال';

  @override
  String get noChats => 'لا توجد محادثات بعد';

  @override
  String get offline => 'غير متصل';

  @override
  String get delete => 'حذف';

  @override
  String get unread => 'غير مقروء';

  @override
  String get lastMessage => 'آخر رسالة';

  @override
  String get failedToLoadMessages => 'فشل تحميل الرسائل';

  @override
  String get pullToRefresh => 'اسحب للأسفل للتحديث';

  @override
  String get sendEmergency => 'إرسال استغاثة';

  @override
  String get emergencyConfirm => 'هل أنت في خطر؟';

  @override
  String get emergencyConfirmMessage =>
      'هل تريد فعلاً إرسال تنبيه طوارئ؟ سيتم إخطار المسؤولين بموقعك الحالي.';

  @override
  String get sending => 'جاري الإرسال...';

  @override
  String get emergencySent => 'تم إرسال الاستغاثة';

  @override
  String get emergencySentMessage =>
      'تم إرسال تنبيه الطوارئ. سيتم التواصل معك قريباً.';

  @override
  String get emergencyFailed => 'فشل الإرسال';

  @override
  String get emergencyFailedOffline =>
      'فشل إرسال تنبيه الطوارئ الرقمي. هل تريد الاتصال هاتفياً بالدعم الأمني؟';

  @override
  String get locationUnavailable => 'تعذر تحديد موقعك. حاول مجدداً.';

  @override
  String get sos => 'طوارئ';

  @override
  String get sent => 'تم الإرسال';

  @override
  String seconds(int seconds) {
    return '$seconds ثانية';
  }

  @override
  String minutes(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String hours(int hours) {
    return '$hours ساعة';
  }

  @override
  String get driverControls => 'أدوات السائق';

  @override
  String get startTrip => 'بدء الرحلة';

  @override
  String get endTrip => 'إنهاء الرحلة';

  @override
  String get confirmStart => 'تأكيد البدء';

  @override
  String get tripScheduled => 'مجدول';

  @override
  String get tripInProgress => 'قيد التنفيذ';

  @override
  String get tripCompleted => 'مكتمل';

  @override
  String get tripCancelled => 'ملغي';

  @override
  String get tripControl => 'تحكم بالرحلة';

  @override
  String get locationPermissionRequired => 'يجب السماح بالوصول للموقع';

  @override
  String duration(String duration) {
    return 'المدة: $duration';
  }

  @override
  String get arrive => 'وصلت';

  @override
  String get begin => 'ابدأ';

  @override
  String get complete => 'أكمل';

  @override
  String get tripStatusScheduled => 'مجدولة';

  @override
  String get tripStatusDriverWaiting => 'السائق في الانتظار';

  @override
  String get tripStatusInTransit => 'قيد السير';

  @override
  String get tripStatusCompleted => 'مكتملة';

  @override
  String get tripStatusAbsent => 'غياب';

  @override
  String get tripStatusCancelled => 'ملغاة';

  @override
  String get completeProfileTitle => 'أكمل ملفك الشخصي';

  @override
  String get completeProfileSubtitle =>
      'نحتاج بعض المعلومات الإضافية لإكمال تسجيلك';

  @override
  String get completeProfile => 'إكمال التسجيل';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get university => 'الجامعة';

  @override
  String get noInstitutionsFound => 'لا توجد مؤسسات متاحة';

  @override
  String get rateTrip => 'تقييم الرحلة';

  @override
  String get howWasYourTrip => 'كيف كانت رحلتك مع السائق؟';

  @override
  String get ratingCommentHint => 'اكتب ملاحظاتك هنا (اختياري)...';

  @override
  String get submitRating => 'إرسال التقييم';

  @override
  String get ratingSuccess => 'شكراً لتقييمك!';

  @override
  String get driverDetails => 'تفاصيل السائق';

  @override
  String get callDriver => 'اتصال';

  @override
  String get chatDriver => 'مراسلة';

  @override
  String etaDistance(String distance, String eta) {
    return 'المسافة: $distance كم • الوصول: $eta دقيقة';
  }

  @override
  String driverRating(String rating) {
    return 'تقييم السائق: $rating';
  }

  @override
  String get ratingFailed => 'فشل حفظ التقييم. حاول مجدداً.';

  @override
  String get ratingRequired => 'يرجى تحديد التقييم بالنجوم';

  @override
  String get cancelTripConfirm => 'إلغاء الرحلة؟';

  @override
  String get cancelTripConfirmMessage =>
      'هل أنت متأكد من رغبتك في إلغاء هذه الرحلة؟';

  @override
  String get boardingTitle => 'الصعود إلى الحافلة';

  @override
  String get boardingShowQrToDriver => 'اعرض هذا الرمز على السائق عند الصعود';

  @override
  String get boardingRotatesAutomatically => 'الرمز يتجدد تلقائياً كل دقيقة';

  @override
  String get boardingNoActiveTrip => 'لا توجد رحلة نشطة حالياً';

  @override
  String get boardingNoActiveTripHint =>
      'ستظهر رحلتك هنا عندما يقترب موعدها ويبدأ السائق بالرحلة';

  @override
  String get boardingError => 'حدث خطأ';

  @override
  String get boardingScannerTitle => 'مسح صعود الركاب';

  @override
  String get boardingToggleFlash => 'تشغيل/إطفاء الفلاش';

  @override
  String get boardingSwitchCamera => 'تبديل الكاميرا';

  @override
  String boardingScanSuccess(String name) {
    return 'تم صعود $name بنجاح';
  }

  @override
  String boardingPassengers(int count) {
    return 'الركاب ($count)';
  }

  @override
  String get boardingNoPassengersYet => 'لم يصعد أحد بعد';

  @override
  String get boardingUnknownStudent => 'طالب';

  @override
  String get scanBoardingQr => 'مَسح رمز صعود الحافلة';

  @override
  String get boardingNearBus => 'أنت بالقرب من الحافلة';

  @override
  String get boardingNearBusHint => 'اسحب لتسجيل صعودك فوراً';

  @override
  String get boardingProximitySuccess => 'أهلاً بك على متن الحافلة!';

  @override
  String get slideToBoard => 'اسحب لتأكيد الصعود';

  @override
  String get browsingOffline => 'أنت تتصفح حالياً بدون اتصال بالإنترنت';

  @override
  String directPaymentAmount(String price) {
    return 'دفع إلكتروني مباشر بقيمة $price';
  }

  @override
  String get failedToStartChat => 'فشل بدء المحادثة';

  @override
  String get invalidLicenseCode => 'كود الترخيص غير صحيح';

  @override
  String get creatingPayment => 'جاري إنشاء الدفع...';

  @override
  String paymentFailedWithStatus(String status) {
    return 'فشل الدفع: $status';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours ساعة $minutes دقيقة';
  }

  @override
  String durationMinutesOnly(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get failureNetwork => 'لا يوجد اتصال بالإنترنت';

  @override
  String get failureServer => 'خطأ في الخادم';

  @override
  String get failureUnauthorized => 'غير مصرح';

  @override
  String get failureForbidden => 'غير مسموح';

  @override
  String get failureNotFound => 'الطلب غير موجود';

  @override
  String get failureValidation => 'بيانات غير صحيحة';

  @override
  String get failureRateLimit => 'تجاوزت الحد المسموح';

  @override
  String get failureCache => 'خطأ في التخزين المحلي';

  @override
  String get failureInvalidStateTransition => 'انتقال حالة غير مسموح';

  @override
  String get failureUnknown => 'خطأ غير معروف';

  @override
  String get alreadyHasActiveSubscription =>
      'لديك اشتراك نشط بالفعل على هذا الخط';

  @override
  String get licenseNotActive => 'الترخيص غير مفعّل';

  @override
  String get bluetoothRequired =>
      'يرجى تشغيل البلوتوث لاستخدام الصعود التقاربي';

  @override
  String get themeMode => 'مظهر التطبيق';

  @override
  String get themeLight => 'المظهر الفاتح';

  @override
  String get themeDark => 'المظهر الداكن';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get studentBadge => 'طالب';

  @override
  String get driverBadge => 'سائق';

  @override
  String get verified => 'حساب موثق';

  @override
  String get scanQrCode => 'مسح الرمز';

  @override
  String get myDigitalPass => 'بطاقتي الرقمية';

  @override
  String daysRemainingShort(int days) {
    return 'متبقي $days يوم';
  }

  @override
  String get quickActions => 'الوصول السريع';

  @override
  String get liveMap => 'خريطة الرحلات';

  @override
  String get chatSupport => 'الدعم الفني';

  @override
  String get safetyTips => 'إرشادات السلامة';

  @override
  String get safetyTipsTitle => 'نصائح السلامة في سير';

  @override
  String get safetyTip1 =>
      'احرص على إبقاء هاتفك قريباً وتفعيل البلوتوث للصعود التلقائي إلى الحافلة.';

  @override
  String get safetyTip2 =>
      'يرجى الانتظار حتى تتوقف الحافلة تماماً قبل الصعود أو النزول.';

  @override
  String get safetyTip3 =>
      'استخدم زر الاستغاثة (SOS) في صفحة التتبع إذا شعرت بعدم الأمان في أي وقت.';

  @override
  String get statsTrips => 'الرحلات المكتملة';

  @override
  String get statsRating => 'متوسط التقييم';

  @override
  String get driverDashboard => 'لوحة تحكم السائق';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get accountSettings => 'إعدادات الحساب';

  @override
  String get appPreferences => 'تفضيلات التطبيق';

  @override
  String get cacheAndSync => 'التخزين والمزامنة';

  @override
  String get aboutApp => 'حول تطبيق سير';

  @override
  String appVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get bleProximityBoarding => 'الصعود التقاربي التلقائي';

  @override
  String get bleProximityBoardingDesc =>
      'اكتشاف إشارات الحافلة تلقائياً للصعود السريع';

  @override
  String get forceSync => 'مزامنة البيانات المحلية';

  @override
  String get forceSyncDesc =>
      'تحديث الخطوط والاشتراكات ومزامنة التغييرات المعلقة';

  @override
  String get editProfileSuccess => 'تم تحديث الملف الشخصي بنجاح';

  @override
  String get changePasswordSuccess => 'تم تحديث كلمة المرور بنجاح';

  @override
  String get newPasswordLabel => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPasswordLabel => 'تأكيد كلمة المرور الجديدة';

  @override
  String get institutionLabel => 'المؤسسة التعليمية / الجامعة';

  @override
  String get phoneLabel => 'رقم الهاتف';

  @override
  String get saveButton => 'حفظ التغييرات';

  @override
  String get syncCompleted => 'اكتملت عملية المزامنة بنجاح';

  @override
  String get goHome => 'العودة للرئيسية';

  @override
  String get paymentHelpTitle => 'دعم الدفع';

  @override
  String get paymentHelpMessage =>
      'إذا واجهتك مشكلة في الدفع عبر زين كاش، يرجى التواصل مع فريق الدعم لدينا.';

  @override
  String get contactWhatsApp => 'التواصل عبر واتساب';

  @override
  String get contactEmail => 'التواصل عبر البريد الإلكتروني';

  @override
  String get confirmActivation => 'تأكيد التفعيل';

  @override
  String get licenseDetails => 'تفاصيل الترخيص';

  @override
  String get cancelSubscriptionConfirm => 'إلغاء الاشتراك؟';

  @override
  String get cancelSubscriptionConfirmMessage =>
      'هل أنت متأكد من رغبتك في إلغاء الاشتراك؟ ستفقد مقعدك المحجوز على هذا الخط، وقد لا تتمكن من الاشتراك مجدداً إذا أصبح الخط ممتلئاً.';

  @override
  String get pendingPayments => 'دفعات بانتظار الإتمام';

  @override
  String get resumePayment => 'إكمال الدفع';

  @override
  String pendingPaymentCardTitle(String amount) {
    return 'دفعة معلّقة بقيمة $amount د.ع';
  }

  @override
  String get whatsappSupportMessage =>
      'مرحباً، أواجه مشكلة في تفعيل اشتراكي في تطبيق سير.';

  @override
  String get tripTrackingActiveTitle => 'تتبع الرحلة نشط';

  @override
  String get tripTrackingActiveText =>
      'تطبيق سير يتتبع موقعك في الخلفية لضمان وصول الطلاب.';

  @override
  String get stationsTitle => 'المحطات';

  @override
  String get welcomeGuest => 'مرحباً بك';

  @override
  String get welcomeSubtitle => 'مرحباً بك في رحلات';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get statsComingSoon => 'ستتوفر الإحصائيات قريباً';

  @override
  String get flashTitleSuccess => 'نجاح';

  @override
  String get flashTitleError => 'خطأ';

  @override
  String get flashTitleWarning => 'تنبيه';

  @override
  String get flashTitleInfo => 'معلومة';

  @override
  String get genericError => 'حدث خطأ. يرجى المحاولة مرة أخرى.';

  @override
  String get genericException => 'حدث استثناء غير متوقع.';
}
