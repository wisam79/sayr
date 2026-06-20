import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_data/src/datasources/auth_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../helpers/mock_supabase.dart';

void main() {
  late MockSayrSupabase mockSupabase;
  late MockSupabaseClient mockClient;
  late AuthRemoteDatasourceImpl datasource;

  setUpAll(registerSupabaseFallbacks);

  setUp(() {
    mockSupabase = MockSayrSupabase();
    mockClient = MockSupabaseClient();

    when(() => mockSupabase.client).thenReturn(mockClient);

    datasource = AuthRemoteDatasourceImpl(supabase: mockSupabase);
  });

  group('AuthRemoteDatasourceImpl', () {
    test('currentUser delegates to SayrSupabase', () {
      final user = MockUser();
      when(() => mockSupabase.currentUser).thenReturn(user);

      final result = datasource.currentUser;

      expect(result, equals(user));
      verify(() => mockSupabase.currentUser).called(1);
    });

    test('authStateChanges delegates to SayrSupabase', () {
      final state =
          supabase.AuthState(supabase.AuthChangeEvent.signedIn, MockSession());
      when(() => mockSupabase.authStateChanges)
          .thenAnswer((_) => Stream.value(state));

      final result = datasource.authStateChanges;

      expect(result, emits(state));
      verify(() => mockSupabase.authStateChanges).called(1);
    });

    test('signInWithPassword delegates to SayrSupabase', () async {
      final response = MockAuthResponse();
      when(() => mockSupabase.signInWithPassword(
          email: 'test@test.com',
          password: 'password')).thenAnswer((_) async => response);

      final result = await datasource.signInWithPassword(
          email: 'test@test.com', password: 'password');

      expect(result, equals(response));
      verify(() => mockSupabase.signInWithPassword(
          email: 'test@test.com', password: 'password')).called(1);
    });

    test('signUp delegates to SayrSupabase', () async {
      final response = MockAuthResponse();
      when(
        () => mockSupabase.signUp(
          email: 'test@test.com',
          password: 'password',
          fullName: 'Test User',
          phone: '1234567890',
        ),
      ).thenAnswer((_) async => response);

      final result = await datasource.signUp(
        email: 'test@test.com',
        password: 'password',
        fullName: 'Test User',
        phone: '1234567890',
      );

      expect(result, equals(response));
      verify(
        () => mockSupabase.signUp(
          email: 'test@test.com',
          password: 'password',
          fullName: 'Test User',
          phone: '1234567890',
        ),
      ).called(1);
    });

    test('signInWithGoogle delegates to SayrSupabase', () async {
      when(() => mockSupabase.signInWithGoogle()).thenAnswer((_) async => true);

      final result = await datasource.signInWithGoogle();

      expect(result, isTrue);
      verify(() => mockSupabase.signInWithGoogle()).called(1);
    });

    test('sendPasswordResetEmail delegates to SayrSupabase', () async {
      when(() => mockSupabase.sendPasswordResetEmail('test@test.com'))
          .thenAnswer((_) async {});

      await datasource.sendPasswordResetEmail('test@test.com');

      verify(() => mockSupabase.sendPasswordResetEmail('test@test.com'))
          .called(1);
    });

    test('updatePassword delegates to SayrSupabase', () async {
      when(() => mockSupabase.updatePassword('newPassword'))
          .thenAnswer((_) async {});

      await datasource.updatePassword('newPassword');

      verify(() => mockSupabase.updatePassword('newPassword')).called(1);
    });

    test('signOut delegates to SayrSupabase', () async {
      when(() => mockSupabase.signOut()).thenAnswer((_) async {});

      await datasource.signOut();

      verify(() => mockSupabase.signOut()).called(1);
    });

    test('fetchCurrentProfile executes correct supabase query', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder =
          MockPostgrestTransformBuilder<Map<String, dynamic>?>();

      mockTransformBuilder
          .completeWith(Future.value({'id': 'user1', 'phone': '123'}));

      when(() => mockClient.from('profiles'))
          .thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.select).thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.eq('id', 'user1'))
          .thenAnswer((_) => mockFilterBuilder);
      when(mockFilterBuilder.maybeSingle)
          .thenAnswer((_) => mockTransformBuilder);

      final result = await datasource.fetchCurrentProfile('user1');

      expect(result, equals({'id': 'user1', 'phone': '123'}));
    });

    test('updateProfile executes correct supabase query', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockFilterBuilder.completeWith(Future.value([]));

      final mockAuth = MockGoTrueClient();
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user1');
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockClient.auth).thenReturn(mockAuth);

      when(() => mockClient.from('profiles'))
          .thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.update({
          'phone': '123456',
          'institution_id': 'inst1',
        }),
      ).thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.eq('id', 'user1'))
          .thenAnswer((_) => mockFilterBuilder);

      await datasource.updateProfile(phone: '123456', institutionId: 'inst1');

      verify(() => mockFilterBuilder.eq('id', 'user1')).called(1);
    });

    test('getInstitutions executes correct supabase query', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder1 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockFilterBuilder2 =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();

      final mockTransformBuilder =
          MockPostgrestTransformBuilder<List<Map<String, dynamic>>>();
      mockTransformBuilder.completeWith(
        Future.value([
          {'id': '1', 'name': 'Inst 1', 'city': 'City 1'},
        ]),
      );

      when(() => mockClient.from('institutions'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select('id, name, city'))
          .thenAnswer((_) => mockFilterBuilder1);
      when(() => mockFilterBuilder1.eq('is_active', true))
          .thenAnswer((_) => mockFilterBuilder2);
      when(() => mockFilterBuilder2.order('name'))
          .thenAnswer((_) => mockTransformBuilder);

      final result = await datasource.getInstitutions();

      expect(
        result,
        equals([
          {'id': '1', 'name': 'Inst 1', 'city': 'City 1'},
        ]),
      );
    });
  });
}
