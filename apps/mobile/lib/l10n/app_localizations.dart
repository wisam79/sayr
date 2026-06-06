import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Sayr'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'example@sayr.app'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password for your account'**
  String get resetPasswordSubtitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordHint;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdated;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password is too short'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to {email}'**
  String passwordResetEmailSent(String email);

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginButton;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginWithGoogle;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signup;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Sayr to manage your university transit'**
  String get signupSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ahmed Ali'**
  String get fullNameHint;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phone;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'07901234567'**
  String get phoneHint;

  /// No description provided for @signupButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signupButton;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @signin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signin;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @routesTitle.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get routesTitle;

  /// No description provided for @mySubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get mySubscriptions;

  /// No description provided for @searchRoutes.
  ///
  /// In en, this message translates to:
  /// **'Search routes...'**
  String get searchRoutes;

  /// No description provided for @activateLicense.
  ///
  /// In en, this message translates to:
  /// **'Activate license'**
  String get activateLicense;

  /// No description provided for @enterLicenseCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 8-character license code'**
  String get enterLicenseCode;

  /// No description provided for @licenseCodeHint.
  ///
  /// In en, this message translates to:
  /// **'A1B2C3D4'**
  String get licenseCodeHint;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @licenseActivated.
  ///
  /// In en, this message translates to:
  /// **'License activated successfully!'**
  String get licenseActivated;

  /// No description provided for @activeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Active subscription'**
  String get activeSubscription;

  /// No description provided for @noActiveSubscription.
  ///
  /// In en, this message translates to:
  /// **'No active subscription'**
  String get noActiveSubscription;

  /// No description provided for @getSubscription.
  ///
  /// In en, this message translates to:
  /// **'Get a subscription'**
  String get getSubscription;

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires on'**
  String get expiresOn;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days remaining'**
  String daysRemaining(int days);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternet;

  /// No description provided for @maintenanceMode.
  ///
  /// In en, this message translates to:
  /// **'App under maintenance'**
  String get maintenanceMode;

  /// No description provided for @updateRequired.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequired;

  /// No description provided for @updateMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version of Sayr is available. Please update to continue.'**
  String get updateMessage;

  /// No description provided for @routeDetails.
  ///
  /// In en, this message translates to:
  /// **'Route details'**
  String get routeDetails;

  /// No description provided for @startLocation.
  ///
  /// In en, this message translates to:
  /// **'Start location'**
  String get startLocation;

  /// No description provided for @endLocation.
  ///
  /// In en, this message translates to:
  /// **'End location'**
  String get endLocation;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @availableSeats.
  ///
  /// In en, this message translates to:
  /// **'Available seats'**
  String get availableSeats;

  /// No description provided for @departureTime.
  ///
  /// In en, this message translates to:
  /// **'Departure time'**
  String get departureTime;

  /// No description provided for @returnTime.
  ///
  /// In en, this message translates to:
  /// **'Return time'**
  String get returnTime;

  /// No description provided for @operatingDays.
  ///
  /// In en, this message translates to:
  /// **'Operating days'**
  String get operatingDays;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe now'**
  String get subscribe;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @activeTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get activeTrips;

  /// No description provided for @noActiveTrips.
  ///
  /// In en, this message translates to:
  /// **'No active trips right now'**
  String get noActiveTrips;

  /// No description provided for @activeTripsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Active trips available, tap to follow'**
  String get activeTripsAvailable;

  /// No description provided for @noRoutesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No routes available'**
  String get noRoutesAvailable;

  /// No description provided for @tryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Try again later'**
  String get tryAgainLater;

  /// No description provided for @helloUser.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloUser(String name);

  /// No description provided for @browseRoutes.
  ///
  /// In en, this message translates to:
  /// **'Browse routes'**
  String get browseRoutes;

  /// No description provided for @browseRoutesDesc.
  ///
  /// In en, this message translates to:
  /// **'Find a route that suits you'**
  String get browseRoutesDesc;

  /// No description provided for @createNewTrip.
  ///
  /// In en, this message translates to:
  /// **'Create new trip'**
  String get createNewTrip;

  /// No description provided for @createNewTripDesc.
  ///
  /// In en, this message translates to:
  /// **'Start a trip on a registered route'**
  String get createNewTripDesc;

  /// No description provided for @myActiveTrips.
  ///
  /// In en, this message translates to:
  /// **'My active trips'**
  String get myActiveTrips;

  /// No description provided for @myActiveTripsDesc.
  ///
  /// In en, this message translates to:
  /// **'View and manage your active trips'**
  String get myActiveTripsDesc;

  /// No description provided for @activeSubscriptionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} subscription active} other{{count} subscriptions active}}'**
  String activeSubscriptionCount(int count);

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @failedToLoadRoutes.
  ///
  /// In en, this message translates to:
  /// **'Failed to load routes'**
  String get failedToLoadRoutes;

  /// No description provided for @createTrip.
  ///
  /// In en, this message translates to:
  /// **'Create new trip'**
  String get createTrip;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get validationPasswordTooShort;

  /// No description provided for @validationFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get validationFullNameRequired;

  /// No description provided for @validationPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get validationPhoneInvalid;

  /// No description provided for @validationPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordsDoNotMatch;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @passwordResetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to {email}'**
  String passwordResetLinkSent(String email);

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Travel with ease'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Book your university transit subscription with one tap and track your trip live.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Live tracking'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'See the bus location in real time and get notified when it approaches.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Safe and reliable'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'A pre-paid license system secures your seat and protects your rights.'**
  String get onboardingDesc3;

  /// No description provided for @tripTracking.
  ///
  /// In en, this message translates to:
  /// **'Trip tracking'**
  String get tripTracking;

  /// No description provided for @waitingForDriver.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the driver...'**
  String get waitingForDriver;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @routeTitle.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get routeTitle;

  /// No description provided for @tripTime.
  ///
  /// In en, this message translates to:
  /// **'Trip time'**
  String get tripTime;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @tripTimeMustBeFuture.
  ///
  /// In en, this message translates to:
  /// **'Trip time must be in the future'**
  String get tripTimeMustBeFuture;

  /// No description provided for @failedToCreateTrip.
  ///
  /// In en, this message translates to:
  /// **'Failed to create trip'**
  String get failedToCreateTrip;

  /// No description provided for @noDriverRoutes.
  ///
  /// In en, this message translates to:
  /// **'No routes assigned to your account'**
  String get noDriverRoutes;

  /// No description provided for @activeRouteRequired.
  ///
  /// In en, this message translates to:
  /// **'You need an active route before creating a trip.'**
  String get activeRouteRequired;

  /// No description provided for @noTripsYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t created any trips yet'**
  String get noTripsYet;

  /// No description provided for @tripLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load trip details'**
  String get tripLoadFailed;

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Route not found'**
  String get routeNotFound;

  /// No description provided for @routeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load route details'**
  String get routeLoadFailed;

  /// No description provided for @noSubscriptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions yet'**
  String get noSubscriptionsTitle;

  /// No description provided for @noSubscriptionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Activate your first license to get started'**
  String get noSubscriptionsSubtitle;

  /// No description provided for @subscriptionType.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionType;

  /// No description provided for @subscriptionStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subscriptionStatusActive;

  /// No description provided for @subscriptionStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get subscriptionStatusExpired;

  /// No description provided for @subscriptionEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Ends on: {date}'**
  String subscriptionEndsOn(String date);

  /// No description provided for @subscriptionDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String subscriptionDaysLeft(int days);

  /// No description provided for @cancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get cancelSubscription;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @choosePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose payment method'**
  String get choosePaymentMethod;

  /// No description provided for @voucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get voucher;

  /// No description provided for @enterVoucherCode.
  ///
  /// In en, this message translates to:
  /// **'Enter voucher code'**
  String get enterVoucherCode;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @paymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get paymentSuccess;

  /// No description provided for @paymentSuccessSubscription.
  ///
  /// In en, this message translates to:
  /// **'Payment successful! Your subscription is now active'**
  String get paymentSuccessSubscription;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get paymentFailed;

  /// No description provided for @paymentViaZainCash.
  ///
  /// In en, this message translates to:
  /// **'Pay via Zain Cash'**
  String get paymentViaZainCash;

  /// No description provided for @openZainCash.
  ///
  /// In en, this message translates to:
  /// **'Open Zain Cash'**
  String get openZainCash;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount: {amount} {currency}'**
  String amount(String amount, String currency);

  /// No description provided for @awaitingPaymentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment confirmation...'**
  String get awaitingPaymentConfirmation;

  /// No description provided for @completePaymentInZainCash.
  ///
  /// In en, this message translates to:
  /// **'Complete the payment in Zain Cash app then return here'**
  String get completePaymentInZainCash;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedError;

  /// No description provided for @invalidVoucher.
  ///
  /// In en, this message translates to:
  /// **'Invalid voucher'**
  String get invalidVoucher;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get loadFailed;

  /// No description provided for @allMarkedAsRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get allMarkedAsRead;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get messageHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @noChats.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get noChats;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @lastMessage.
  ///
  /// In en, this message translates to:
  /// **'Last message'**
  String get lastMessage;

  /// No description provided for @failedToLoadMessages.
  ///
  /// In en, this message translates to:
  /// **'Failed to load messages'**
  String get failedToLoadMessages;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh'**
  String get pullToRefresh;

  /// No description provided for @sendEmergency.
  ///
  /// In en, this message translates to:
  /// **'Send emergency'**
  String get sendEmergency;

  /// No description provided for @emergencyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you in danger?'**
  String get emergencyConfirm;

  /// No description provided for @emergencyConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to send an emergency alert? Officials will be notified of your current location.'**
  String get emergencyConfirmMessage;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @emergencySent.
  ///
  /// In en, this message translates to:
  /// **'Emergency sent'**
  String get emergencySent;

  /// No description provided for @emergencySentMessage.
  ///
  /// In en, this message translates to:
  /// **'Your emergency alert has been sent. We will contact you soon.'**
  String get emergencySentMessage;

  /// No description provided for @emergencyFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send'**
  String get emergencyFailed;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to determine your location. Please try again.'**
  String get locationUnavailable;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String seconds(int seconds);

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String minutes(int minutes);

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String hours(int hours);

  /// No description provided for @driverControls.
  ///
  /// In en, this message translates to:
  /// **'Driver controls'**
  String get driverControls;

  /// No description provided for @startTrip.
  ///
  /// In en, this message translates to:
  /// **'Start trip'**
  String get startTrip;

  /// No description provided for @endTrip.
  ///
  /// In en, this message translates to:
  /// **'End trip'**
  String get endTrip;

  /// No description provided for @confirmStart.
  ///
  /// In en, this message translates to:
  /// **'Confirm start'**
  String get confirmStart;

  /// No description provided for @tripScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get tripScheduled;

  /// No description provided for @tripInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get tripInProgress;

  /// No description provided for @tripCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tripCompleted;

  /// No description provided for @tripCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get tripCancelled;

  /// No description provided for @tripControl.
  ///
  /// In en, this message translates to:
  /// **'Trip control'**
  String get tripControl;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required'**
  String get locationPermissionRequired;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String duration(String duration);

  /// No description provided for @arrive.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get arrive;

  /// No description provided for @begin.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get begin;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @tripStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get tripStatusScheduled;

  /// No description provided for @tripStatusDriverWaiting.
  ///
  /// In en, this message translates to:
  /// **'Driver waiting'**
  String get tripStatusDriverWaiting;

  /// No description provided for @tripStatusInTransit.
  ///
  /// In en, this message translates to:
  /// **'In transit'**
  String get tripStatusInTransit;

  /// No description provided for @tripStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tripStatusCompleted;

  /// No description provided for @tripStatusAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get tripStatusAbsent;

  /// No description provided for @tripStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get tripStatusCancelled;

  /// No description provided for @completeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeProfileTitle;

  /// No description provided for @completeProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We need a few more details to finish setting up your account'**
  String get completeProfileSubtitle;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Registration'**
  String get completeProfile;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @university.
  ///
  /// In en, this message translates to:
  /// **'University'**
  String get university;

  /// No description provided for @noInstitutionsFound.
  ///
  /// In en, this message translates to:
  /// **'No institutions available'**
  String get noInstitutionsFound;

  /// No description provided for @rateTrip.
  ///
  /// In en, this message translates to:
  /// **'Rate Trip'**
  String get rateTrip;

  /// No description provided for @howWasYourTrip.
  ///
  /// In en, this message translates to:
  /// **'How was your trip with the driver?'**
  String get howWasYourTrip;

  /// No description provided for @ratingCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write your comments here (optional)...'**
  String get ratingCommentHint;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit Rating'**
  String get submitRating;

  /// No description provided for @ratingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your rating!'**
  String get ratingSuccess;

  /// No description provided for @driverDetails.
  ///
  /// In en, this message translates to:
  /// **'Driver Details'**
  String get driverDetails;

  /// No description provided for @callDriver.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callDriver;

  /// No description provided for @chatDriver.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chatDriver;

  /// No description provided for @etaDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance} km • Arrival: {eta} min'**
  String etaDistance(String distance, String eta);

  /// No description provided for @driverRating.
  ///
  /// In en, this message translates to:
  /// **'Driver Rating: {rating}'**
  String driverRating(String rating);

  /// No description provided for @ratingFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save rating. Try again.'**
  String get ratingFailed;

  /// No description provided for @ratingRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a star rating'**
  String get ratingRequired;
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
      <String>['ar', 'en'].contains(locale.languageCode);

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
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
