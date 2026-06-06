import 'package:flutter/material.dart' hide Route;
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:sayr_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:sayr_mobile/features/auth/presentation/pages/onboarding_page.dart';
import 'package:sayr_mobile/features/auth/presentation/pages/reset_password_page.dart';
import 'package:sayr_mobile/features/auth/presentation/pages/signup_page.dart';
import 'package:sayr_mobile/features/auth/presentation/pages/splash_page.dart';
import 'package:sayr_mobile/features/chat/presentation/pages/chat_list_page.dart';
import 'package:sayr_mobile/features/chat/presentation/pages/chat_page.dart';
import 'package:sayr_mobile/features/home/presentation/pages/home_page.dart';
import 'package:sayr_mobile/features/notifications/presentation/pages/notifications_page.dart';
import 'package:sayr_mobile/features/payment/presentation/pages/payment_page.dart';
import 'package:sayr_mobile/features/routes/presentation/pages/route_details_page.dart';
import 'package:sayr_mobile/features/routes/presentation/pages/routes_list_page.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/pages/activate_license_page.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/pages/my_subscriptions_page.dart';
import 'package:sayr_mobile/features/tracking/presentation/pages/active_trips_page.dart';
import 'package:sayr_mobile/features/tracking/presentation/pages/driver_trip_controls_page.dart';
import 'package:sayr_mobile/features/tracking/presentation/pages/trip_tracking_page.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

/// Centralized router configuration for the app.
///
/// Auth-aware navigation is handled in `SayrApp` via a `BlocListener<AuthBloc>`
/// that calls `config.go` on state changes.
@lazySingleton
class AppRouter {
  /// Creates an [AppRouter].
  AppRouter();

  /// Routes accessible without authentication.
  static const publicPaths = <String>{
    '/splash',
    '/onboarding',
    '/login',
    '/signup',
    '/reset-password',
    '/complete-profile',
  };

  /// Public entry screens that should redirect home after authentication.
  static const authEntryPaths = <String>{
    '/onboarding',
    '/login',
    '/signup',
  };

  /// The main [GoRouter] configuration instance.
  late final GoRouter config = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: '/complete-profile',
        name: 'complete-profile',
        builder: (context, state) => const CompleteProfilePage(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/routes',
        name: 'routes',
        builder: (context, state) => const RoutesListPage(),
      ),
      GoRoute(
        path: '/route/:routeId',
        name: 'route-details',
        builder: (context, state) {
          final route = state.extra as Route?;
          final routeId = RouteId(state.pathParameters['routeId']!);
          return RouteDetailsPage(route: route, routeId: routeId);
        },
      ),
      GoRoute(
        path: '/subscriptions',
        name: 'subscriptions',
        builder: (context, state) => const MySubscriptionsPage(),
      ),
      GoRoute(
        path: '/activate-license',
        name: 'activate-license',
        builder: (context, state) => const ActivateLicensePage(),
      ),
      GoRoute(
        path: '/active-trips',
        name: 'active-trips',
        builder: (context, state) => const ActiveTripsPage(),
      ),
      GoRoute(
        path: '/trip/:tripId',
        name: 'trip-tracking',
        builder: (context, state) {
          final tripId = TripId(state.pathParameters['tripId']!);
          return TripTrackingPage(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/driver-trip/:tripId',
        name: 'driver-trip-controls',
        builder: (context, state) {
          final tripId = TripId(state.pathParameters['tripId']!);
          return DriverTripControlsPage(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/payment/:routeId/:amount',
        name: 'payment',
        builder: (context, state) {
          final routeId = RouteId(state.pathParameters['routeId']!);
          final amount = int.parse(state.pathParameters['amount']!);
          return PaymentPage(routeId: routeId, amount: amount);
        },
      ),
      GoRoute(
        path: '/chat/:conversationId',
        name: 'chat',
        builder: (context, state) {
          return ChatPage(
            conversationId: ConversationId(
              state.pathParameters['conversationId']!,
            ),
          );
        },
      ),
      GoRoute(
        path: '/chats',
        name: 'chats',
        builder: (context, state) => const ChatListPage(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        _ErrorPage(error: state.error?.toString()),
  );
}

class _ErrorPage extends StatelessWidget {
  const _ErrorPage({this.error});
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(error ?? AppLocalizations.of(context).pageNotFound),
      ),
    );
  }
}
