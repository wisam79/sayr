import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:sayr_mobile/core/fcm_service.dart';
import 'package:sayr_mobile/core/locale_cubit.dart';
import 'package:sayr_mobile/core/offline_sync_service.dart';
import 'package:sayr_mobile/core/theme_cubit.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_list_bloc.dart';
import 'package:sayr_mobile/features/emergency/presentation/bloc/emergency_bloc.dart';
import 'package:sayr_mobile/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:sayr_mobile/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:sayr_mobile/features/routes/presentation/bloc/routes_bloc.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_bloc.dart';
import 'package:sayr_mobile/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_mobile/routing/app_router.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Root widget of the Sayr application.
class SayrApp extends StatelessWidget {
  /// Creates a [SayrApp].
  const SayrApp({required this.router, super.key});

  /// The router configurations.
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
        BlocProvider<PaymentBloc>(
          create: (_) => PaymentBloc(
            paymentRepository: sl<PaymentRepository>(),
          ),
        ),
        BlocProvider<LocaleCubit>(
          create: (_) => LocaleCubit()..load(),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit()..load(),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
        listener: (context, state) {
          final uri = router.config.routerDelegate.currentConfiguration.uri;
          final path = uri.path;
          final isPublic = AppRouter.publicPaths.contains(path);
          final isAuthEntry = AppRouter.authEntryPaths.contains(path);

          if (state is AuthAuthenticated) {
            // Register current FCM push token for notifications
            unawaited(
              FcmService.registerDeviceToken(
                context.read<NotificationsBloc>(),
              ),
            );

            if (isAuthEntry) {
              router.config.go('/');
            }
          } else if (state is AuthUnauthenticated && !isPublic) {
            router.config.go('/login');
          } else if (state is AuthProfileIncomplete) {
            router.config.go('/complete-profile');
          }
        },
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            final isRtl = locale.languageCode == 'ar';
            final themeMode = context.watch<ThemeCubit>().state;
            return MaterialApp.router(
              title: 'Sayr',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
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
              locale: locale,
              builder: (context, child) {
                return Directionality(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: OfflineBannerWrapper(
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
              routerConfig: router.config,
            );
          },
        ),
      ),
    );
  }
}

/// Top-level wrapper that initializes Sentry and other services.
Future<void> runSayrApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Disable dynamic font download to force loading from assets/google_fonts
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Sentry (if DSN is set)
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options
          ..dsn = sentryDsn
          ..sendDefaultPii = false
          ..environment = const String.fromEnvironment(
            'SENTRY_ENVIRONMENT',
            defaultValue: 'development',
          )
          ..tracesSampleRate = 0.2;
      },
    );
  }

  // Initialize Supabase
  await SayrSupabase.instance.init();

  // Initialize GetIt service locator
  await initDependencies();

  // Initialize FCM service (non-blocking)
  unawaited(FcmService.init());

  // Initialize Offline Sync Service
  OfflineSyncService(
    localDatasource: sl<LocalDatasource>(),
    tripRepository: sl<TripRepository>(),
  ).start();

  // Set up bloc observer
  Bloc.observer = TalkerBlocObserver(
    talker: sl<Talker>(),
  );

  // Set up router
  final router = AppRouter();

  // Wire FCM notification taps to in-app navigation.
  FcmService.navigationHandler = (data) {
    final tripId = data['trip_id'] as String?;
    if (tripId != null) {
      router.config.go('/trip/$tripId');
      return;
    }
    final conversationId = data['conversation_id'] as String?;
    if (conversationId != null) {
      router.config.go('/chat/$conversationId');
      return;
    }
    final routeId = data['route_id'] as String?;
    if (routeId != null) {
      router.config.go('/routes');
      return;
    }
    // Default destination for taps without a deep-link target.
    router.config.go('/notifications');
  };

  runApp(SayrApp(router: router));
}

/// A wrapper widget that listens to network connectivity changes and displays
/// an elegant banner at the top of the viewport when offline.
class OfflineBannerWrapper extends StatefulWidget {
  /// Creates an [OfflineBannerWrapper].
  const OfflineBannerWrapper({required this.child, super.key});

  /// The child widget to display.
  final Widget child;

  @override
  State<OfflineBannerWrapper> createState() => _OfflineBannerWrapperState();
}

class _OfflineBannerWrapperState extends State<OfflineBannerWrapper> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final isNowOffline =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      if (_isOffline != isNowOffline) {
        setState(() {
          _isOffline = isNowOffline;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) {
      return widget.child;
    }

    final l10n = AppLocalizations.of(context);

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.browsingOffline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
