import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/onboarding_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/chat/presentation/pages/chat_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/routes/presentation/pages/routes_list_page.dart';
import '../features/subscriptions/presentation/pages/my_subscriptions_page.dart';
import '../features/subscriptions/presentation/pages/activate_license_page.dart';
import '../features/tracking/presentation/pages/active_trips_page.dart';
import '../features/tracking/presentation/pages/trip_tracking_page.dart';
import '../features/tracking/presentation/pages/driver_trip_controls_page.dart';
import '../features/payment/presentation/pages/payment_page.dart';

/// Centralized router configuration for the app.
///
/// Auth-aware navigation is handled in `SayrApp` via a `BlocListener<AuthBloc>`
/// that calls [config.go] on state changes.
@lazySingleton
class AppRouter {
  AppRouter();

  /// Routes accessible without authentication.
  static const publicPaths = <String>{
    '/onboarding',
    '/login',
    '/signup',
  };

  late final GoRouter config = GoRouter(
    initialLocation: '/onboarding',
    routes: [
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
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
    errorBuilder: (context, state) => _ErrorPage(error: state.error?.toString()),
  );
}

class _ErrorPage extends StatelessWidget {
  const _ErrorPage({this.error});
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(error ?? 'Page not found'),
      ),
    );
  }
}
