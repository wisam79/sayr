import 'dart:io' show Platform;

import 'package:flutter/material.dart' hide Route;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:sayr_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:sayr_mobile/features/auth/presentation/pages/onboarding_page.dart';
import 'package:sayr_mobile/features/auth/presentation/pages/reset_password_page.dart';
import 'package:sayr_mobile/features/auth/presentation/pages/signup_page.dart';
import 'package:sayr_mobile/features/auth/presentation/pages/splash_page.dart';
import 'package:sayr_mobile/features/boarding/presentation/pages/boarding_qr_page.dart';
import 'package:sayr_mobile/features/boarding/presentation/pages/boarding_scanner_page.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_list_bloc.dart';
import 'package:sayr_mobile/features/chat/presentation/pages/chat_list_page.dart';
import 'package:sayr_mobile/features/chat/presentation/pages/chat_page.dart';
import 'package:sayr_mobile/features/emergency/presentation/bloc/emergency_bloc.dart';
import 'package:sayr_mobile/features/home/presentation/pages/home_page.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:sayr_mobile/features/notifications/presentation/pages/notifications_page.dart';
import 'package:sayr_mobile/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:sayr_mobile/features/payment/presentation/pages/payment_page.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_bloc.dart';
import 'package:sayr_mobile/features/routes/presentation/pages/route_details_page.dart';
import 'package:sayr_mobile/features/routes/presentation/pages/routes_list_page.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_bloc.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/pages/activate_license_page.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/pages/my_subscriptions_page.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:sayr_mobile/features/tracking/presentation/pages/active_trips_page.dart';
import 'package:sayr_mobile/features/tracking/presentation/pages/driver_trip_controls_page.dart';
import 'package:sayr_mobile/features/tracking/presentation/pages/trip_tracking_page.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_mobile/routing/go_router_refresh_stream.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';
import 'package:talker_flutter/talker_flutter.dart';

CustomTransitionPage<void> _slideTransitionPage({required Widget child}) {
  return CustomTransitionPage<void>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (!const bool.fromEnvironment('dart.vm.product') &&
          Platform.environment.containsKey('FLUTTER_TEST')) {
        return child;
      }
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}

class AppRouter {
  AppRouter({required AuthBloc authBloc})
      : _authBloc = authBloc,
        _refreshListenable = GoRouterRefreshStream(authBloc.stream);

  final AuthBloc _authBloc;
  final GoRouterRefreshStream _refreshListenable;

  void dispose() {
    _refreshListenable.dispose();
  }

  static const publicPaths = <String>{
    '/splash',
    '/onboarding',
    '/login',
    '/signup',
    '/reset-password',
    '/complete-profile',
  };

  static const authEntryPaths = <String>{
    '/onboarding',
    '/login',
    '/signup',
    '/complete-profile',
  };

  late final GoRouter config = GoRouter(
    initialLocation: '/splash',
    refreshListenable: _refreshListenable,
    redirect: (context, state) {
      final authState = _authBloc.state;
      final isPublic = publicPaths.contains(state.matchedLocation);
      final isAuthEntry = authEntryPaths.contains(state.matchedLocation);

      if (authState is AuthInitial || authState is AuthLoading) {
        // App is still checking auth status; keep them on splash unless they are somehow navigating elsewhere
        if (state.matchedLocation != '/splash') {
          sl<Talker>().info('Redirecting to /splash because auth is loading');
          return '/splash';
        }
        return null;
      }

      if (authState is AuthAuthenticated) {
        if (isAuthEntry || state.matchedLocation == '/splash') {
          sl<Talker>().info('Redirecting to / because auth is authenticated');
          return '/';
        }
        return null;
      }

      if (authState is AuthUnauthenticated) {
        if (!isPublic) {
          sl<Talker>().info(
            'Redirecting to /login because auth is unauthenticated and path is not public',
          );
          return '/login';
        }
        if (state.matchedLocation == '/splash') {
          sl<Talker>().info(
            'Redirecting to /onboarding because auth is unauthenticated and path is /splash',
          );
          return '/onboarding';
        }
        return null;
      }

      if (authState is AuthProfileIncomplete) {
        if (state.matchedLocation != '/complete-profile') {
          return '/complete-profile';
        }
        return null;
      }

      if (authState is AuthError) {
        if (!isPublic || state.matchedLocation == '/splash') {
          sl<Talker>().info(
            'Redirecting to /login because auth state is AuthError',
          );
          return '/login';
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (_, __) => const SignupPage(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (_, __) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: '/complete-profile',
        name: 'complete-profile',
        builder: (_, __) => const CompleteProfilePage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<RoutesBloc>(
                create: (_) => RoutesBloc(
                  routeRepository: sl<RouteRepository>(),
                ),
              ),
              BlocProvider<SubscriptionsBloc>(
                create: (_) => SubscriptionsBloc(
                  subscriptionRepository: sl<SubscriptionRepository>(),
                  paymentRepository: sl<PaymentRepository>(),
                ),
              ),
              BlocProvider<TrackingBloc>(
                create: (_) => TrackingBloc(
                  tripRepository: sl<TripRepository>(),
                  authRepository: sl<AuthRepository>(),
                  driverLocationService: sl<LocationService>(),
                  talker: sl<Talker>(),
                ),
              ),
            ],
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (_, __) => NoTransitionPage(
              child: BlocProvider<NotificationsBloc>(
                create: (_) => NotificationsBloc(
                  notificationsRepository: sl<NotificationsRepository>(),
                ),
                child: const HomePage(),
              ),
            ),
          ),
          GoRoute(
            path: '/routes',
            name: 'routes',
            pageBuilder: (_, __) =>
                _slideTransitionPage(child: const RoutesListPage()),
          ),
          GoRoute(
            path: '/route/:routeId',
            name: 'route-details',
            pageBuilder: (context, state) => _slideTransitionPage(
              child: RouteDetailsPage(
                route: state.extra is Route ? state.extra! as Route : null,
                routeId: RouteId(state.pathParameters['routeId']!),
              ),
            ),
          ),
          GoRoute(
            path: '/subscriptions',
            name: 'subscriptions',
            pageBuilder: (_, __) =>
                _slideTransitionPage(child: const MySubscriptionsPage()),
          ),
          GoRoute(
            path: '/activate-license',
            name: 'activate-license',
            pageBuilder: (_, __) =>
                _slideTransitionPage(child: const ActivateLicensePage()),
          ),
          GoRoute(
            path: '/active-trips',
            name: 'active-trips',
            pageBuilder: (_, __) =>
                _slideTransitionPage(child: const ActiveTripsPage()),
          ),
          GoRoute(
            path: '/trip/:tripId',
            name: 'trip-tracking',
            pageBuilder: (context, state) => _slideTransitionPage(
              child: BlocProvider<EmergencyBloc>(
                create: (_) => EmergencyBloc(
                  emergencyRepository: sl<EmergencyRepository>(),
                ),
                child: TripTrackingPage(
                  tripId: TripId(state.pathParameters['tripId']!),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/driver-trip/:tripId',
            name: 'driver-trip-controls',
            pageBuilder: (context, state) => _slideTransitionPage(
              child: BlocProvider<EmergencyBloc>(
                create: (_) => EmergencyBloc(
                  emergencyRepository: sl<EmergencyRepository>(),
                ),
                child: DriverTripControlsPage(
                  tripId: TripId(state.pathParameters['tripId']!),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/payment/:routeId/:amount',
            name: 'payment',
            pageBuilder: (context, state) {
              final paymentId = state.uri.queryParameters['paymentId'];
              final paymentUrl = state.uri.queryParameters['paymentUrl'];
              return _slideTransitionPage(
                child: BlocProvider<PaymentBloc>(
                  create: (_) => PaymentBloc(
                    paymentRepository: sl<PaymentRepository>(),
                  ),
                  child: PaymentPage(
                    routeId: RouteId(state.pathParameters['routeId']!),
                    amount: int.tryParse(state.pathParameters['amount'] ?? '') ?? 0,
                    paymentId: paymentId,
                    paymentUrl: paymentUrl,
                  ),
                ),
              );
            },
          ),
          GoRoute(
            path: '/chat/:conversationId',
            name: 'chat',
            pageBuilder: (context, state) => _slideTransitionPage(
              child: BlocProvider<ChatBloc>(
                create: (_) => ChatBloc(
                  chatRepository: sl<ChatRepository>(),
                ),
                child: ChatPage(
                  conversationId: ConversationId(
                    state.pathParameters['conversationId']!,
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/chats',
            name: 'chats',
            pageBuilder: (_, __) => _slideTransitionPage(
              child: BlocProvider<ChatListBloc>(
                create: (_) => ChatListBloc(
                  chatRepository: sl<ChatRepository>(),
                ),
                child: const ChatListPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            pageBuilder: (_, __) => _slideTransitionPage(
              child: BlocProvider<NotificationsBloc>(
                create: (_) => NotificationsBloc(
                  notificationsRepository: sl<NotificationsRepository>(),
                ),
                child: const NotificationsPage(),
              ),
            ),
          ),
          GoRoute(
            path: '/boarding',
            name: 'boarding',
            pageBuilder: (_, __) =>
                _slideTransitionPage(child: const BoardingQrPage()),
          ),
          GoRoute(
            path: '/driver-trip/:tripId/boarding',
            name: 'driver-boarding',
            pageBuilder: (context, state) => _slideTransitionPage(
              child: BoardingScannerPage(
                tripId: TripId(state.pathParameters['tripId']!),
              ),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: AppErrorWidget(
        title: AppLocalizations.of(context).error,
        message: state.error?.toString() ??
            AppLocalizations.of(context).pageNotFound,
        retryLabel: AppLocalizations.of(context).goHome,
        onRetry: () => context.go('/'),
      ),
    ),
  );
}
