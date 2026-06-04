// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sayr';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginSubtitle => 'Welcome back! Please sign in to continue';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'example@sayr.app';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get loginButton => 'Sign in';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get loginWithGoogle => 'Continue with Google';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signup => 'Sign up';

  @override
  String get signupTitle => 'Create account';

  @override
  String get signupSubtitle => 'Join Sayr to manage your university transit';

  @override
  String get fullName => 'Full name';

  @override
  String get fullNameHint => 'Ahmed Ali';

  @override
  String get phone => 'Phone (optional)';

  @override
  String get phoneHint => '07901234567';

  @override
  String get signupButton => 'Create account';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get signin => 'Sign in';

  @override
  String get homeTitle => 'Home';

  @override
  String get routesTitle => 'Available routes';

  @override
  String get mySubscriptions => 'My subscriptions';

  @override
  String get searchRoutes => 'Search routes...';

  @override
  String get activateLicense => 'Activate license';

  @override
  String get enterLicenseCode => 'Enter the 8-character license code';

  @override
  String get licenseCodeHint => 'A1B2C3D4';

  @override
  String get activate => 'Activate';

  @override
  String get licenseActivated => 'License activated successfully!';

  @override
  String get activeSubscription => 'Active subscription';

  @override
  String get noActiveSubscription => 'No active subscription';

  @override
  String get getSubscription => 'Get a subscription';

  @override
  String get expiresOn => 'Expires on';

  @override
  String daysRemaining(int days) {
    return '$days days remaining';
  }

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get logout => 'Log out';

  @override
  String get logoutConfirm => 'Are you sure you want to log out?';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get noInternet => 'No internet connection';

  @override
  String get maintenanceMode => 'App under maintenance';

  @override
  String get updateRequired => 'Update required';

  @override
  String get updateMessage =>
      'A new version of Sayr is available. Please update to continue.';
}
