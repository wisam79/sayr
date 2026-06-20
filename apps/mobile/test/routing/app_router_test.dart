import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/routing/app_router.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  group('AppRouter Configuration', () {
    late AppRouter router;
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
      when(() => mockAuthBloc.close()).thenAnswer((_) async {});
      router = AppRouter(authBloc: mockAuthBloc);
    });

    tearDown(() {
      router.dispose();
      mockAuthBloc.close();
    });

    test('publicPaths contains expected authentication and entry paths', () {
      expect(AppRouter.publicPaths, contains('/splash'));
      expect(AppRouter.publicPaths, contains('/onboarding'));
      expect(AppRouter.publicPaths, contains('/login'));
      expect(AppRouter.publicPaths, contains('/signup'));
      expect(AppRouter.publicPaths, contains('/reset-password'));
      expect(AppRouter.publicPaths, contains('/complete-profile'));
    });

    test('authEntryPaths is a subset of publicPaths', () {
      for (final path in AppRouter.authEntryPaths) {
        expect(AppRouter.publicPaths, contains(path));
      }
    });

    test('all registered routes have non-empty and unique names', () {
      final names = <String>{};
      final routes = router.config.configuration.routes;

      for (final route in routes) {
        if (route is GoRoute) {
          expect(route.name, isNotNull);
          expect(route.name, isNotEmpty);
          expect(
            names.contains(route.name),
            isFalse,
            reason: 'Duplicate route name: ${route.name}',
          );
          names.add(route.name!);
        }
      }
    });

    test('has expected routes registered', () {
      final routeNames = router.config.configuration.routes
          .whereType<GoRoute>()
          .map((r) => r.name)
          .toList();

      expect(
        routeNames,
        containsAll([
          'splash',
          'onboarding',
          'login',
          'signup',
          'reset-password',
          'complete-profile',
          'home',
          'routes',
          'route-details',
          'subscriptions',
          'activate-license',
          'active-trips',
          'trip-tracking',
          'driver-trip-controls',
          'payment',
          'chat',
          'chats',
          'notifications',
          'boarding',
          'driver-boarding',
        ]),
      );
    });
  });
}
