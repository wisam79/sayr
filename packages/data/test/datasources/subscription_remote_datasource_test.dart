import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_data/src/datasources/subscription_remote_datasource.dart';
import 'package:sayr_data/src/models/subscription_model.dart';
import '../helpers/mock_supabase.dart';

void main() {
  late MockSayrSupabase mockSupabase;
  late MockSupabaseClient mockClient;
  late SubscriptionRemoteDatasourceImpl datasource;

  setUpAll(registerSupabaseFallbacks);

  setUp(() {
    mockSupabase = MockSayrSupabase();
    mockClient = MockSupabaseClient();

    when(() => mockSupabase.client).thenReturn(mockClient);

    datasource = SubscriptionRemoteDatasourceImpl(supabase: mockSupabase);
  });

  group('SubscriptionRemoteDatasourceImpl', () {
    test('getMySubscriptions executes correct query', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder1 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockFilterBuilder2 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();

      final subJson = {
        'id': 'sub1',
        'student_id': 'user1',
        'route_id': 'route1',
        'status': 'active',
        'start_date': '2026-06-21T00:00:00Z',
      };

      mockTransformBuilder.completeWith(Future.value([subJson]));

      when(() => mockClient.from('subscriptions'))
          .thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.select).thenAnswer((_) => mockFilterBuilder1);
      when(() => mockFilterBuilder1.eq('student_id', 'user1'))
          .thenAnswer((_) => mockFilterBuilder2);
      when(() => mockFilterBuilder2.order('start_date', ascending: false))
          .thenAnswer((_) => mockTransformBuilder);

      final result = await datasource.getMySubscriptions('user1');

      expect(
          result,
          equals([
            SubscriptionModel.fromJson(subJson),
          ]));
    });

    test('cancelSubscription executes rpc', () async {
      final mockRpcFilterBuilder = MockPostgrestFilterBuilder<void>();
      mockRpcFilterBuilder.completeWith(Future.value());

      when(
        () => mockClient.rpc<void>(
          'cancel_subscription',
          params: {
            'p_subscription_id': 'sub1',
          },
        ),
      ).thenAnswer((_) => mockRpcFilterBuilder);

      await datasource.cancelSubscription('sub1');

      verify(
        () => mockClient.rpc<void>(
          'cancel_subscription',
          params: {
            'p_subscription_id': 'sub1',
          },
        ),
      ).called(1);
    });

    test('activateLicense executes rpc', () async {
      final mockRpcFilterBuilder = MockPostgrestFilterBuilder<String>();
      mockRpcFilterBuilder.completeWith(Future.value('sub2'));

      when(
        () => mockClient.rpc<String>(
          'activate_license',
          params: {
            'p_code': 'ABCDEF',
          },
        ),
      ).thenAnswer((_) => mockRpcFilterBuilder);

      final result = await datasource.activateLicense('ABCDEF');

      expect(result, equals('sub2'));
    });

    test('getLicenseDetails returns first item', () async {
      final mockRpcFilterBuilder = MockPostgrestFilterBuilder<List<dynamic>>();
      mockRpcFilterBuilder.completeWith(
        Future.value([
          {'id': 'license1'},
        ]),
      );

      when(
        () => mockClient.rpc<List<dynamic>>(
          'get_license_details',
          params: {
            'p_code': 'ABCDEF',
          },
        ),
      ).thenAnswer((_) => mockRpcFilterBuilder);

      final result = await datasource.getLicenseDetails('ABCDEF');

      expect(result, equals({'id': 'license1'}));
    });

    test('getLicenseDetails throws Exception if empty', () async {
      final mockRpcFilterBuilder = MockPostgrestFilterBuilder<List<dynamic>>();
      mockRpcFilterBuilder.completeWith(Future.value([]));

      when(
        () => mockClient.rpc<List<dynamic>>(
          'get_license_details',
          params: {
            'p_code': 'ABCDEF',
          },
        ),
      ).thenAnswer((_) => mockRpcFilterBuilder);

      expect(
        () => datasource.getLicenseDetails('ABCDEF'),
        throwsException,
      );
    });
  });
}
