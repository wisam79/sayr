import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/auth_remote_datasource.dart';
import 'package:sayr_data/src/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../helpers/mock_supabase.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockUserResponse extends Mock implements supabase.UserResponse {}

void main() {
  late MockSayrSupabase mockSupabase;
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late AuthRemoteDatasourceImpl datasource;

  setUpAll(() {
    registerSupabaseFallbacks();
    registerFallbackValue(supabase.UserAttributes(password: ''));
    registerFallbackValue(supabase.OAuthProvider.google);
  });

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return true;
    });

    mockSupabase = MockSayrSupabase();
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockGoogleSignIn = MockGoogleSignIn();

    when(() => mockSupabase.client).thenReturn(mockClient);
    when(() => mockClient.auth).thenReturn(mockAuth);

    datasource = AuthRemoteDatasourceImpl(
      supabase: mockSupabase,
    )..googleSignIn = mockGoogleSignIn;
  });

  group('AuthRemoteDatasourceImpl', () {
    test('currentUser returns from client auth', () {
      final user = MockUser();
      when(() => mockAuth.currentUser).thenReturn(user);

      final result = datasource.currentUser;

      expect(result, equals(user));
      verify(() => mockAuth.currentUser).called(1);
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

    test('signInWithPassword calls client auth', () async {
      final response = MockAuthResponse();
      when(() => mockAuth.signInWithPassword(
          email: 'test@test.com',
          password: 'password')).thenAnswer((_) async => response);

      final result = await datasource.signInWithPassword(
          email: 'test@test.com', password: 'password');

      expect(result, equals(response));
      verify(() => mockAuth.signInWithPassword(
          email: 'test@test.com', password: 'password')).called(1);
    });

    test('signUp calls client auth', () async {
      final response = MockAuthResponse();
      when(
        () => mockAuth.signUp(
          email: 'test@test.com',
          password: 'password',
          data: {
            'full_name': 'Test User',
            'phone': '1234567890',
          },
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
        () => mockAuth.signUp(
          email: 'test@test.com',
          password: 'password',
          data: {
            'full_name': 'Test User',
            'phone': '1234567890',
          },
        ),
      ).called(1);
    });

    test('signInWithGoogle signs in using google and client auth', () async {
      final googleUser = MockGoogleSignInAccount();
      final googleAuth = MockGoogleSignInAuthentication();
      final response = MockAuthResponse();
      final user = MockUser();

      when(() => mockGoogleSignIn.signOut())
          .thenAnswer((_) async => googleUser);
      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => googleUser);
      when(() => googleUser.authentication).thenAnswer((_) async => googleAuth);
      when(() => googleAuth.idToken).thenReturn('googleToken');
      when(() => googleAuth.accessToken).thenReturn('accessToken');

      when(() => mockAuth.signInWithIdToken(
            provider: supabase.OAuthProvider.google,
            idToken: 'googleToken',
            accessToken: 'accessToken',
          )).thenAnswer((_) async => response);
      when(() => response.user).thenReturn(user);

      final result = await datasource.signInWithGoogle();

      expect(result, isTrue);
      verify(() => mockGoogleSignIn.signOut()).called(1);
      verify(() => mockGoogleSignIn.signIn()).called(1);
      verify(() => mockAuth.signInWithIdToken(
            provider: supabase.OAuthProvider.google,
            idToken: 'googleToken',
            accessToken: 'accessToken',
          )).called(1);
    });

    test('signInWithGoogle falls back to OAuth if native throws', () async {
      when(() => mockGoogleSignIn.signOut())
          .thenThrow(Exception('Native sign in failed'));
      when(() => mockAuth.getOAuthSignInUrl(
            provider: any<supabase.OAuthProvider>(named: 'provider'),
            redirectTo: any<String?>(named: 'redirectTo'),
            scopes: any<String?>(named: 'scopes'),
            queryParams: any<Map<String, String>?>(named: 'queryParams'),
          )).thenAnswer((_) async => const supabase.OAuthResponse(
            provider: supabase.OAuthProvider.google,
            url: 'https://mock.url',
          ));

      final result = await datasource.signInWithGoogle();

      expect(result, isTrue);
      verify(() => mockAuth.getOAuthSignInUrl(
            provider: any<supabase.OAuthProvider>(named: 'provider'),
            redirectTo: any<String?>(named: 'redirectTo'),
            scopes: any<String?>(named: 'scopes'),
            queryParams: any<Map<String, String>?>(named: 'queryParams'),
          )).called(1);
    });

    test('sendPasswordResetEmail calls client auth', () async {
      when(() => mockAuth.resetPasswordForEmail(
            'test@test.com',
            redirectTo: 'com.sayr.app://reset-password',
          )).thenAnswer((_) async {});

      await datasource.sendPasswordResetEmail('test@test.com');

      verify(() => mockAuth.resetPasswordForEmail(
            'test@test.com',
            redirectTo: 'com.sayr.app://reset-password',
          )).called(1);
    });

    test('updatePassword calls client auth', () async {
      final userResponse = MockUserResponse();
      when(() => mockAuth.updateUser(any()))
          .thenAnswer((_) async => userResponse);

      await datasource.updatePassword('newPassword');

      verify(() => mockAuth.updateUser(any())).called(1);
    });

    test('signOut calls client auth and google signout', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
      when(() => mockGoogleSignIn.signOut())
          .thenAnswer((_) async => MockGoogleSignInAccount());

      await datasource.signOut();

      verify(() => mockAuth.signOut()).called(1);
      verify(() => mockGoogleSignIn.signOut()).called(1);
    });

    test('fetchCurrentProfile executes correct supabase query', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockTransformBuilder =
          MockPostgrestTransformBuilder<Map<String, dynamic>?>();

      const expectedUser = UserModel(
        id: 'user1',
        role: UserRole.student,
        phone: '123',
      );

      mockTransformBuilder.completeWith(Future.value({
        'id': 'user1',
        'role': 'student',
        'phone': '123',
      }));

      when(() => mockClient.from('profiles'))
          .thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.select).thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.eq('id', 'user1'))
          .thenAnswer((_) => mockFilterBuilder);
      when(mockFilterBuilder.maybeSingle)
          .thenAnswer((_) => mockTransformBuilder);

      final result = await datasource.fetchCurrentProfile('user1');

      expect(result, equals(expectedUser));
    });

    test('updateProfile executes correct supabase query', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder =
          MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      mockFilterBuilder.completeWith(Future.value([]));

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user1');
      when(() => mockAuth.currentUser).thenReturn(mockUser);

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
