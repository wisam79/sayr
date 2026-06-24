import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/sayr_data.dart';
import 'package:sayr_mobile/core/connectivity_cubit.dart';
import 'package:sayr_mobile/core/fcm_service.dart';
import 'package:sayr_mobile/core/locale_cubit.dart';
import 'package:sayr_mobile/core/models/fcm_payload.dart';
import 'package:sayr_mobile/core/offline_sync_service.dart';
import 'package:sayr_mobile/core/services/background_sync_service.dart';
import 'package:sayr_mobile/core/theme_cubit.dart';
import 'package:sayr_mobile/di/di.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';
import 'package:sayr_mobile/routing/app_router.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Root widget of the Sayr application.
class SayrApp extends StatelessWidget {
  /// Creates a [SayrApp].
  const SayrApp({
    required this.router,
    required this.authBloc,
    super.key,
  });

  /// The router configurations.
  final AppRouter router;

  /// The global auth bloc.
  final AuthBloc authBloc;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(
          value: authBloc,
        ),
        BlocProvider<LocaleCubit>(
          create: (_) => LocaleCubit()..load(),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit()..load(),
        ),
        BlocProvider<ConnectivityCubit>(
          create: (_) => ConnectivityCubit(),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            sl<OfflineSyncService>().start();
            // Register current FCM push token for notifications
            unawaited(
              FcmService.registerDeviceToken(
                sl<NotificationsRepository>(),
              ),
            );
          } else if (state is AuthUnauthenticated) {
            sl<OfflineSyncService>().stop();
            unawaited(FcmService.dispose());
          }
        },
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            final isRtl = locale.languageCode == 'ar';
            final themeMode = context.watch<ThemeCubit>().state;

            final isDark = themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    MediaQuery.platformBrightnessOf(context) ==
                        Brightness.dark);

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
                statusBarBrightness:
                    isDark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor:
                    isDark ? AppColors.backgroundDark : AppColors.background,
                systemNavigationBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
              ),
              child: MaterialApp.router(
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
                    textDirection:
                        isRtl ? TextDirection.rtl : TextDirection.ltr,
                    child: OfflineBannerWrapper(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  );
                },
                routerConfig: router.config,
              ),
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

  // Initialize Firebase (Only on supported platforms)
  final isFirebaseSupported =
      kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  if (isFirebaseSupported) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase failed to initialize: $e');
    }
  }

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
          ..tracesSampleRate = 0.2
          ..beforeSend = (event, hint) {
            final emailRegex = RegExp(
              r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
            );
            final phoneRegex = RegExp(r'\+?[0-9]{10,15}');
            final uuidRegex = RegExp(
              '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
            );

            String scrub(String text) {
              return text
                  .replaceAll(emailRegex, '[EMAIL_REDACTED]')
                  .replaceAll(phoneRegex, '[PHONE_REDACTED]')
                  .replaceAll(uuidRegex, '[UUID_REDACTED]');
            }

            final messageText = event.message?.formatted;
            final scrubbedMessage =
                messageText != null ? SentryMessage(scrub(messageText)) : null;

            final exceptions = event.exceptions?.map((ex) {
              return ex.copyWith(
                value: ex.value != null ? scrub(ex.value!) : null,
              );
            }).toList();

            return event.copyWith(
              message: scrubbedMessage,
              exceptions: exceptions,
            );
          };
      },
    );
  }

  // Initialize Supabase
  await SayrSupabase.instance.init();

  // Initialize GetIt service locator
  await initDependencies();

  // Initialize Background Sync
  await BackgroundSyncService.initialize();
  sl<BackgroundSyncTrigger>().setTrigger(() {
    unawaited(BackgroundSyncService.triggerOneOffSync());
  });

  // Initialize FCM service (non-blocking)
  unawaited(FcmService.init());

  // Register Offline Sync Service in Service Locator
  final offlineSyncService = OfflineSyncService(
    localDatasource: sl<LocalDatasource>(),
    tripRepository: sl<TripRepository>(),
    talker: sl<Talker>(),
  );
  sl.registerSingleton<OfflineSyncService>(offlineSyncService);

  // Set up bloc observer
  Bloc.observer = TalkerBlocObserver(
    talker: sl<Talker>(),
  );

  // Set up auth bloc
  final authBloc = AuthBloc(
    authRepository: sl<AuthRepository>(),
  )..add(const AuthCheckRequested());

  // Set up router
  final router = AppRouter(authBloc: authBloc);

  // Wire FCM notification taps to in-app navigation.
  FcmService.navigationHandler = (payload) {
    payload.when(
      trip: (tripId) => router.config.go('/trip/$tripId'),
      chat: (conversationId) => router.config.go('/chat/$conversationId'),
      route: (routeId) => router.config.go('/routes'),
      unknown: () => router.config.go('/notifications'),
    );
  };

  runApp(SayrApp(router: router, authBloc: authBloc));
}

/// A wrapper widget that listens to network connectivity changes and displays
/// an elegant banner at the top of the viewport when offline.
class OfflineBannerWrapper extends StatelessWidget {
  /// Creates an [OfflineBannerWrapper].
  const OfflineBannerWrapper({required this.child, super.key});

  /// The child widget to display.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, bool>(
      builder: (context, isOffline) {
        if (!isOffline) {
          return child;
        }

        final l10n = AppLocalizations.of(context);

        return Stack(
          children: [
            child,
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
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      },
    );
  }
}
