import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/app_bloc_observer.dart';
import 'core/fcm_service.dart';
import 'di/di.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/chat/presentation/bloc/chat_list_bloc.dart';
import 'features/emergency/presentation/bloc/emergency_bloc.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';
import 'features/routes/presentation/bloc/routes_bloc.dart';
import 'features/subscriptions/presentation/bloc/subscriptions_bloc.dart';
import 'features/tracking/presentation/bloc/tracking_bloc.dart';
import 'l10n/app_localizations.dart';
import 'routing/app_router.dart';

/// Root widget of the Sayr application.
class SayrApp extends StatelessWidget {
  const SayrApp({super.key, required this.router});

  final AppRouter router;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            authRepository: sl<AuthRepository>(),
          )..add(const AuthCheckRequested()),
        ),
        BlocProvider<RoutesBloc>(
          create: (_) => RoutesBloc(
            routeRepository: sl<RouteRepository>(),
          ),
        ),
        BlocProvider<SubscriptionsBloc>(
          create: (_) => SubscriptionsBloc(
            subscriptionRepository: sl<SubscriptionRepository>(),
          ),
        ),
        BlocProvider<TrackingBloc>(
          create: (_) => TrackingBloc(
            tripRepository: sl<TripRepository>(),
          ),
        ),
        BlocProvider<ChatBloc>(
          create: (_) => ChatBloc(
            chatRepository: sl<ChatRepository>(),
          ),
        ),
        BlocProvider<ChatListBloc>(
          create: (_) => ChatListBloc(
            chatRepository: sl<ChatRepository>(),
          ),
        ),
        BlocProvider<NotificationsBloc>(
          create: (_) => NotificationsBloc(
            notificationsRepository: sl<NotificationsRepository>(),
          ),
        ),
        BlocProvider<EmergencyBloc>(
          create: (_) => EmergencyBloc(
            emergencyRepository: sl<EmergencyRepository>(),
          ),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
        listener: (context, state) {
          final location =
              router.config.routerDelegate.currentConfiguration.uri.toString();
          final isPublic = AppRouter.publicPaths.contains(location);

          if (state is AuthAuthenticated && isPublic) {
            router.config.go('/');
          } else if (state is AuthUnauthenticated && !isPublic) {
            router.config.go('/login');
          }
        },
        child: MaterialApp.router(
          title: 'Sayr',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          locale: const Locale('ar'),
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },
          routerConfig: router.config,
        ),
      ),
    );
  }
}

/// Top-level wrapper that initializes Sentry and other services.
Future<void> runSayrApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Sentry (if DSN is set)
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.sendDefaultPii = false;
        options.environment = const String.fromEnvironment(
          'SENTRY_ENVIRONMENT',
          defaultValue: 'development',
        );
        options.tracesSampleRate = 0.2;
      },
    );
  }

  // Initialize Supabase
  await SayrSupabase.instance.init();

  // Initialize GetIt service locator
  await initDependencies();

  // Set up bloc observer
  Bloc.observer = AppBlocObserver();

  // Set up router
  final router = AppRouter();

  // Wire FCM notification taps to in-app navigation.
  FcmService.setNavigationHandler((data) {
    final String? tripId = data['trip_id'] as String?;
    if (tripId != null) {
      router.config.go('/trip/$tripId');
      return;
    }
    final String? conversationId = data['conversation_id'] as String?;
    if (conversationId != null) {
      router.config.go('/chat/$conversationId');
      return;
    }
    final String? routeId = data['route_id'] as String?;
    if (routeId != null) {
      router.config.go('/routes');
      return;
    }
    // Default destination for taps without a deep-link target.
    router.config.go('/notifications');
  });

  runApp(SayrApp(router: router));
}
