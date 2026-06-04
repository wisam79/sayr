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
}
