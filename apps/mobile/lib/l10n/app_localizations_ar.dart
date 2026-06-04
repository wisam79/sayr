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
  String get routesTitle => 'الخطوط المتاحة';

  @override
  String get mySubscriptions => 'اشتراكاتي';

  @override
  String get searchRoutes => 'البحث عن خط...';

  @override
  String get activateLicense => 'تفعيل ترخيص';

  @override
  String get enterLicenseCode => 'أدخل كود الترخيص المكون من 8 أحرف';

  @override
  String get licenseCodeHint => 'A1B2C3D4';

  @override
  String get activate => 'تفعيل';

  @override
  String get licenseActivated => 'تم تفعيل الترخيص بنجاح!';

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
  String get profile => 'الملف الشخصي';

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
  String get chats => 'المحادثات';

  @override
  String get help => 'المساعدة';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get activeTrips => 'الرحلات النشطة';

  @override
  String get noActiveTrips => 'لا توجد رحلات نشطة حالياً';

  @override
  String get activeTripsAvailable => 'يوجد رحلات نشطة، اضغط للمتابعة';

  @override
  String get noRoutesAvailable => 'لا توجد خطوط متاحة';

  @override
  String get tryAgainLater => 'حاول مرة أخرى لاحقاً';
}
