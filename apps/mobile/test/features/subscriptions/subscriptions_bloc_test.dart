import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_bloc.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_event.dart';
import 'package:sayr_mobile/features/subscriptions/presentation/bloc/subscriptions_state.dart';

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const SubscriptionId('fallback'));
    registerFallbackValue(LicenseCode('A1B2C3D4'));
  });

  late MockSubscriptionRepository mockRepo;
  late SubscriptionsBloc bloc;

  setUp(() {
    mockRepo = MockSubscriptionRepository();
    bloc = SubscriptionsBloc(subscriptionRepository: mockRepo);
  });

  tearDown(() => bloc.close());

  final testSubscriptions = [
    Subscription(
      id: const SubscriptionId('sub-1'),
      studentId: const UserId('user-1'),
      routeId: const RouteId('route-1'),
      status: SubscriptionStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      endDate: DateTime.now().add(const Duration(days: 20)),
    ),
  ];

  group('SubscriptionsBloc', () {
    test('initial state is SubscriptionsInitial', () {
      expect(bloc.state, isA<SubscriptionsInitial>());
    });

    blocTest<SubscriptionsBloc, SubscriptionsState>(
      'emits [Loading, Loaded] on load success',
      build: () {
        when(() => mockRepo.getMySubscriptions()).thenAnswer(
          (_) async => Right<Failure, List<Subscription>>(testSubscriptions),
        );
        return SubscriptionsBloc(subscriptionRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const SubscriptionsLoadRequested()),
      expect: () => [
        isA<SubscriptionsLoading>(),
        isA<SubscriptionsLoaded>().having(
          (s) => s.subscriptions.length,
          'subscriptions',
          1,
        ),
      ],
    );

    blocTest<SubscriptionsBloc, SubscriptionsState>(
      'emits [Loading, Error] on load failure',
      build: () {
        when(() => mockRepo.getMySubscriptions()).thenAnswer(
          (_) async => const Left<Failure, List<Subscription>>(
            ServerFailure(message: 'Server error'),
          ),
        );
        return SubscriptionsBloc(subscriptionRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const SubscriptionsLoadRequested()),
      expect: () => [
        isA<SubscriptionsLoading>(),
        isA<SubscriptionsError>(),
      ],
    );

    blocTest<SubscriptionsBloc, SubscriptionsState>(
      'emits error then reloads on cancel success',
      build: () {
        when(() => mockRepo.cancel(any())).thenAnswer(
          (_) async => const Right<Failure, Unit>(unit),
        );
        when(() => mockRepo.getMySubscriptions()).thenAnswer(
          (_) async => Right<Failure, List<Subscription>>(testSubscriptions),
        );
        return SubscriptionsBloc(subscriptionRepository: mockRepo);
      },
      act: (bloc) => bloc.add(
        const SubscriptionCancelRequested(SubscriptionId('sub-1')),
      ),
      expect: () => [
        isA<SubscriptionsLoading>(),
        isA<SubscriptionsLoaded>(),
      ],
    );

    blocTest<SubscriptionsBloc, SubscriptionsState>(
      'emits error on cancel failure',
      build: () {
        when(() => mockRepo.cancel(any())).thenAnswer(
          (_) async => const Left<Failure, Unit>(
            ServerFailure(message: 'Cancel failed'),
          ),
        );
        return SubscriptionsBloc(subscriptionRepository: mockRepo);
      },
      act: (bloc) => bloc.add(
        const SubscriptionCancelRequested(SubscriptionId('sub-1')),
      ),
      expect: () => [isA<SubscriptionsError>()],
    );

    blocTest<SubscriptionsBloc, SubscriptionsState>(
      'emits SubscriptionsError when code is invalid',
      build: () => SubscriptionsBloc(subscriptionRepository: mockRepo),
      act: (bloc) => bloc.add(const LicenseActivateRequested('invalid')),
      expect: () => [isA<SubscriptionsError>()],
    );

    blocTest<SubscriptionsBloc, SubscriptionsState>(
      'emits [LicenseActivating, LicenseActivated] on activate success',
      build: () {
        when(() => mockRepo.activateLicense(any())).thenAnswer(
          (_) async => const Right<Failure, SubscriptionId>(
            SubscriptionId('new-sub'),
          ),
        );
        when(() => mockRepo.getMySubscriptions()).thenAnswer(
          (_) async => Right<Failure, List<Subscription>>(testSubscriptions),
        );
        return SubscriptionsBloc(subscriptionRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const LicenseActivateRequested('A1B2C3D4')),
      expect: () => [
        isA<LicenseActivating>(),
        isA<LicenseActivated>(),
        isA<SubscriptionsLoading>(),
        isA<SubscriptionsLoaded>(),
      ],
    );

    blocTest<SubscriptionsBloc, SubscriptionsState>(
      'emits [LicenseActivating, Error] on activate failure',
      build: () {
        when(() => mockRepo.activateLicense(any())).thenAnswer(
          (_) async => const Left<Failure, SubscriptionId>(
            BusinessRuleFailure(message: 'Already have active subscription'),
          ),
        );
        return SubscriptionsBloc(subscriptionRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const LicenseActivateRequested('A1B2C3D4')),
      expect: () => [
        isA<LicenseActivating>(),
        isA<SubscriptionsError>(),
      ],
    );
  });
}
