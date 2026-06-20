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
  String get approximateRouteWarning =>
      'Displayed route is approximate due to a routing server issue';

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
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordSubtitle => 'Enter a new password for your account';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get confirmPasswordHint => 'Re-enter your password';

  @override
  String get updatePassword => 'Update password';

  @override
  String get passwordUpdated => 'Password updated successfully';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password is too short';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String passwordResetEmailSent(String email) {
    return 'Password reset link sent to $email';
  }

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
  String get routesTitle => 'Routes';

  @override
  String get mySubscriptions => 'Subscriptions';

  @override
  String get searchRoutes => 'Search routes...';

  @override
  String get activateLicense => 'Activate license';

  @override
  String get enterLicenseCode => 'Enter the 8-character license code';

  @override
  String get licenseCodeLabel => 'License code';

  @override
  String get licenseCodeHint => 'A1B2C3D4';

  @override
  String get licenseCodeValidation => 'Must be 8 characters';

  @override
  String get activate => 'Activate';

  @override
  String get licenseActivated => 'License activated successfully!';

  @override
  String get activationFailed => 'Activation failed';

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
  String get chooseLanguage => 'Choose language';

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
  String get loadingRouteTitle => 'Loading route...';

  @override
  String get loadingStartLocation => 'Loading start location...';

  @override
  String get loadingEndLocation => 'Loading end location...';

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

  @override
  String get routeDetails => 'Route details';

  @override
  String get startLocation => 'Start location';

  @override
  String get endLocation => 'End location';

  @override
  String get price => 'Price';

  @override
  String get availableSeats => 'Available seats';

  @override
  String get departureTime => 'Departure time';

  @override
  String get returnTime => 'Return time';

  @override
  String get operatingDays => 'Operating days';

  @override
  String get subscribe => 'Subscribe now';

  @override
  String get available => 'Available';

  @override
  String get full => 'Full';

  @override
  String get chats => 'Chats';

  @override
  String get help => 'Help';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get activeTrips => 'Trips';

  @override
  String get noActiveTrips => 'No active trips right now';

  @override
  String get activeTripsAvailable => 'Active trips available, tap to follow';

  @override
  String get noRoutesAvailable => 'No routes available';

  @override
  String get tryAgainLater => 'Try again later';

  @override
  String helloUser(String name) {
    return 'Hello, $name';
  }

  @override
  String get browseRoutes => 'Browse routes';

  @override
  String get browseRoutesDesc => 'Find a route that suits you';

  @override
  String get createNewTrip => 'Create new trip';

  @override
  String get createNewTripDesc => 'Start a trip on a registered route';

  @override
  String get myActiveTrips => 'My active trips';

  @override
  String get myActiveTripsDesc => 'View and manage your active trips';

  @override
  String activeSubscriptionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subscriptions active',
      one: '$count subscription active',
    );
    return '$_temp0';
  }

  @override
  String get subscription => 'Subscription';

  @override
  String get failedToLoadRoutes => 'Failed to load routes';

  @override
  String get createTrip => 'Create new trip';

  @override
  String get validationEmailRequired => 'Email is required';

  @override
  String get validationEmailInvalid => 'Invalid email';

  @override
  String get validationPasswordRequired => 'Password is required';

  @override
  String get validationPasswordTooShort =>
      'Password must be at least 6 characters';

  @override
  String get validationFullNameRequired => 'Full name is required';

  @override
  String get validationPhoneInvalid => 'Invalid phone number';

  @override
  String get validationPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get unknownError => 'Unknown error';

  @override
  String passwordResetLinkSent(String email) {
    return 'Password reset link sent to $email';
  }

  @override
  String get skip => 'Skip';

  @override
  String get getStarted => 'Get started';

  @override
  String get onboardingTitle1 => 'Travel with ease';

  @override
  String get onboardingDesc1 =>
      'Book your university transit subscription with one tap and track your trip live.';

  @override
  String get onboardingTitle2 => 'Live tracking';

  @override
  String get onboardingDesc2 =>
      'See the bus location in real time and get notified when it approaches.';

  @override
  String get onboardingTitle3 => 'Safe and reliable';

  @override
  String get onboardingDesc3 =>
      'A pre-paid license system secures your seat and protects your rights.';

  @override
  String get tripTracking => 'Trip tracking';

  @override
  String get waitingForDriver => 'Waiting for the driver...';

  @override
  String get start => 'Start';

  @override
  String get destination => 'Destination';

  @override
  String get routeTitle => 'Route';

  @override
  String get tripTime => 'Trip time';

  @override
  String get create => 'Create';

  @override
  String get tripTimeMustBeFuture => 'Trip time must be in the future';

  @override
  String get failedToCreateTrip => 'Failed to create trip';

  @override
  String get noDriverRoutes => 'No routes assigned to your account';

  @override
  String get activeRouteRequired =>
      'You need an active route before creating a trip.';

  @override
  String get noTripsYet => 'You haven\'t created any trips yet';

  @override
  String get tripLoadFailed => 'Failed to load trip details';

  @override
  String get routeNotFound => 'Route not found';

  @override
  String get routeLoadFailed => 'Failed to load route details';

  @override
  String get noSubscriptionsTitle => 'No subscriptions yet';

  @override
  String get noSubscriptionsSubtitle =>
      'Activate your first license to get started';

  @override
  String get subscriptionType => 'Subscription';

  @override
  String get subscriptionStatusActive => 'Active';

  @override
  String get subscriptionStatusPending => 'Pending';

  @override
  String get subscriptionStatusExpired => 'Expired';

  @override
  String get subscriptionStatusCancelled => 'Cancelled';

  @override
  String subscriptionEndsOn(String date) {
    return 'Ends on: $date';
  }

  @override
  String subscriptionDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String get cancelSubscription => 'Cancel subscription';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get version => 'Version';

  @override
  String get payment => 'Payment';

  @override
  String get choosePaymentMethod => 'Choose payment method';

  @override
  String get voucher => 'Voucher';

  @override
  String get enterVoucherCode => 'Enter voucher code';

  @override
  String get processing => 'Processing...';

  @override
  String get paymentSuccess => 'Payment successful';

  @override
  String get paymentSuccessSubscription =>
      'Payment successful! Your subscription is now active';

  @override
  String get paymentFailed => 'Payment failed';

  @override
  String get paymentViaZainCash => 'Pay via Zain Cash';

  @override
  String get openZainCash => 'Open Zain Cash';

  @override
  String amount(String amount, String currency) {
    return 'Amount: $amount $currency';
  }

  @override
  String get awaitingPaymentConfirmation => 'Awaiting payment confirmation...';

  @override
  String get completePaymentInZainCash =>
      'Complete the payment in Zain Cash app then return here';

  @override
  String get unexpectedError => 'An unexpected error occurred';

  @override
  String get invalidVoucher => 'Invalid voucher';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get loadFailed => 'Failed to load';

  @override
  String get allMarkedAsRead => 'All notifications marked as read';

  @override
  String get messageHint => 'Type a message...';

  @override
  String get send => 'Send';

  @override
  String get noChats => 'No chats yet';

  @override
  String get offline => 'Offline';

  @override
  String get delete => 'Delete';

  @override
  String get unread => 'Unread';

  @override
  String get lastMessage => 'Last message';

  @override
  String get failedToLoadMessages => 'Failed to load messages';

  @override
  String get pullToRefresh => 'Pull down to refresh';

  @override
  String get sendEmergency => 'Send emergency';

  @override
  String get emergencyConfirm => 'Are you in danger?';

  @override
  String get emergencyConfirmMessage =>
      'Do you really want to send an emergency alert? Officials will be notified of your current location.';

  @override
  String get sending => 'Sending...';

  @override
  String get emergencySent => 'Emergency sent';

  @override
  String get emergencySentMessage =>
      'Your emergency alert has been sent. We will contact you soon.';

  @override
  String get emergencyFailed => 'Failed to send';

  @override
  String get locationUnavailable =>
      'Unable to determine your location. Please try again.';

  @override
  String get sos => 'SOS';

  @override
  String get sent => 'Sent';

  @override
  String seconds(int seconds) {
    return '$seconds seconds';
  }

  @override
  String minutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String hours(int hours) {
    return '$hours hours';
  }

  @override
  String get driverControls => 'Driver controls';

  @override
  String get startTrip => 'Start trip';

  @override
  String get endTrip => 'End trip';

  @override
  String get confirmStart => 'Confirm start';

  @override
  String get tripScheduled => 'Scheduled';

  @override
  String get tripInProgress => 'In progress';

  @override
  String get tripCompleted => 'Completed';

  @override
  String get tripCancelled => 'Cancelled';

  @override
  String get tripControl => 'Trip control';

  @override
  String get locationPermissionRequired => 'Location permission is required';

  @override
  String duration(String duration) {
    return 'Duration: $duration';
  }

  @override
  String get arrive => 'Arrived';

  @override
  String get begin => 'Begin';

  @override
  String get complete => 'Complete';

  @override
  String get tripStatusScheduled => 'Scheduled';

  @override
  String get tripStatusDriverWaiting => 'Driver waiting';

  @override
  String get tripStatusInTransit => 'In transit';

  @override
  String get tripStatusCompleted => 'Completed';

  @override
  String get tripStatusAbsent => 'Absent';

  @override
  String get tripStatusCancelled => 'Cancelled';

  @override
  String get completeProfileTitle => 'Complete Your Profile';

  @override
  String get completeProfileSubtitle =>
      'We need a few more details to finish setting up your account';

  @override
  String get completeProfile => 'Complete Registration';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get university => 'University';

  @override
  String get noInstitutionsFound => 'No institutions available';

  @override
  String get rateTrip => 'Rate Trip';

  @override
  String get howWasYourTrip => 'How was your trip with the driver?';

  @override
  String get ratingCommentHint => 'Write your comments here (optional)...';

  @override
  String get submitRating => 'Submit Rating';

  @override
  String get ratingSuccess => 'Thank you for your rating!';

  @override
  String get driverDetails => 'Driver Details';

  @override
  String get callDriver => 'Call';

  @override
  String get chatDriver => 'Message';

  @override
  String etaDistance(String distance, String eta) {
    return 'Distance: $distance km • Arrival: $eta min';
  }

  @override
  String driverRating(String rating) {
    return 'Driver Rating: $rating';
  }

  @override
  String get ratingFailed => 'Failed to save rating. Try again.';

  @override
  String get ratingRequired => 'Please select a star rating';

  @override
  String get cancelTripConfirm => 'Cancel Trip?';

  @override
  String get cancelTripConfirmMessage =>
      'Are you sure you want to cancel this trip?';

  @override
  String get boardingTitle => 'Board Bus';

  @override
  String get boardingShowQrToDriver =>
      'Show this QR code to the driver at boarding';

  @override
  String get boardingRotatesAutomatically =>
      'Code refreshes automatically every minute';

  @override
  String get boardingNoActiveTrip => 'No active trip right now';

  @override
  String get boardingNoActiveTripHint =>
      'Your trip will appear here when it\'s time to board';

  @override
  String get boardingError => 'Something went wrong';

  @override
  String get boardingScannerTitle => 'Scan Boarding Pass';

  @override
  String get boardingToggleFlash => 'Toggle flash';

  @override
  String get boardingSwitchCamera => 'Switch camera';

  @override
  String boardingScanSuccess(String name) {
    return 'Boarded $name successfully';
  }

  @override
  String boardingPassengers(int count) {
    return 'Passengers ($count)';
  }

  @override
  String get boardingNoPassengersYet => 'No passengers yet';

  @override
  String get boardingUnknownStudent => 'Student';

  @override
  String get scanBoardingQr => 'Scan Boarding QR';

  @override
  String get boardingNearBus => 'You are near the bus';

  @override
  String get boardingNearBusHint => 'Slide to board the bus instantly';

  @override
  String get boardingProximitySuccess => 'Welcome aboard!';

  @override
  String get slideToBoard => 'Slide to Board';

  @override
  String get browsingOffline => 'You are currently browsing offline';

  @override
  String directPaymentAmount(String price) {
    return 'Direct electronic payment of $price';
  }

  @override
  String get failedToStartChat => 'Failed to start chat';

  @override
  String get invalidLicenseCode => 'Invalid license code';

  @override
  String get creatingPayment => 'Creating payment...';

  @override
  String paymentFailedWithStatus(String status) {
    return 'Payment failed: $status';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours hours $minutes minutes';
  }

  @override
  String durationMinutesOnly(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get failureNetwork => 'No internet connection';

  @override
  String get failureServer => 'Server error';

  @override
  String get failureUnauthorized => 'Unauthorized';

  @override
  String get failureForbidden => 'Forbidden';

  @override
  String get failureNotFound => 'Resource not found';

  @override
  String get failureValidation => 'Invalid data';

  @override
  String get failureRateLimit => 'Rate limit exceeded';

  @override
  String get failureCache => 'Local storage error';

  @override
  String get failureInvalidStateTransition => 'Invalid state transition';

  @override
  String get failureUnknown => 'Unknown error';

  @override
  String get alreadyHasActiveSubscription =>
      'You already have an active subscription on this route';

  @override
  String get licenseNotActive => 'License is not active';

  @override
  String get bluetoothRequired =>
      'Please enable Bluetooth to use proximity boarding';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get themeLight => 'Light Mode';

  @override
  String get themeDark => 'Dark Mode';

  @override
  String get themeSystem => 'System Default';

  @override
  String get studentBadge => 'Student';

  @override
  String get driverBadge => 'Driver';

  @override
  String get verified => 'Verified';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get myDigitalPass => 'My Digital Pass';

  @override
  String daysRemainingShort(int days) {
    return '$days days';
  }

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get liveMap => 'Live Map';

  @override
  String get chatSupport => 'Chat Support';

  @override
  String get safetyTips => 'Safety Tips';

  @override
  String get safetyTipsTitle => 'Sayr Safety Tips';

  @override
  String get safetyTip1 =>
      'Always keep your phone handy and ensure Bluetooth is on for automatic boarding.';

  @override
  String get safetyTip2 =>
      'Please wait for the bus to come to a complete stop before boarding or leaving.';

  @override
  String get safetyTip3 =>
      'Use the SOS emergency button on the tracking page if you feel unsafe at any point.';

  @override
  String get statsTrips => 'Trips Completed';

  @override
  String get statsRating => 'Average Rating';

  @override
  String get driverDashboard => 'Driver Dashboard';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get changePassword => 'Change Password';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get appPreferences => 'App Preferences';

  @override
  String get cacheAndSync => 'Cache & Synchronization';

  @override
  String get aboutApp => 'About Sayr';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get bleProximityBoarding => 'Auto BLE Boarding';

  @override
  String get bleProximityBoardingDesc =>
      'Automatically detect bus beacons for quick boarding';

  @override
  String get forceSync => 'Synchronize Offline Cache';

  @override
  String get forceSyncDesc =>
      'Force refresh routes, subscriptions, and sync pending updates';

  @override
  String get editProfileSuccess => 'Profile updated successfully';

  @override
  String get changePasswordSuccess => 'Password updated successfully';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get confirmNewPasswordLabel => 'Confirm New Password';

  @override
  String get institutionLabel => 'University / Institution';

  @override
  String get phoneLabel => 'Phone Number';

  @override
  String get saveButton => 'Save Changes';

  @override
  String get syncCompleted => 'Synchronization completed';

  @override
  String get goHome => 'Go Home';

  @override
  String get paymentHelpTitle => 'Payment Support';

  @override
  String get paymentHelpMessage =>
      'If you faced issues with Zain Cash payment, please contact our support team.';

  @override
  String get contactWhatsApp => 'Contact via WhatsApp';

  @override
  String get contactEmail => 'Contact via Email';

  @override
  String get confirmActivation => 'Confirm Activation';

  @override
  String get licenseDetails => 'License Details';

  @override
  String get cancelSubscriptionConfirm => 'Cancel Subscription?';

  @override
  String get cancelSubscriptionConfirmMessage =>
      'Are you sure you want to cancel your subscription? You will lose your reserved seat on this route, and you might not be able to subscribe again if the route becomes full.';

  @override
  String get pendingPayments => 'Pending Payments';

  @override
  String get resumePayment => 'Resume Payment';

  @override
  String pendingPaymentCardTitle(String amount) {
    return 'Pending payment - $amount IQD';
  }

  @override
  String get whatsappSupportMessage =>
      'Hello, I\'m having an issue activating my subscription in the Sayr app.';

  @override
  String get tripTrackingActiveTitle => 'Trip Tracking Active';

  @override
  String get tripTrackingActiveText =>
      'Sayr is tracking your location in the background for this trip.';
}
