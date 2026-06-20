import 'dart:async';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_data/src/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSayrSupabase extends Mock implements SayrSupabase {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

class MockFunctionResponse extends Mock implements FunctionResponse {}

class MockPostgrestFilterBuilder<T> extends Mock
    implements PostgrestFilterBuilder<T> {
  late Future<T> _future;
  void completeWith(Future<T> future) => _future = future;

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) async {
    return onValue(await _future);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) =>
      _future.catchError(onError, test: test);

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      _future.timeout(timeLimit, onTimeout: onTimeout);
}

class MockPostgrestTransformBuilder<T> extends Mock
    implements PostgrestTransformBuilder<T> {
  late Future<T> _future;
  void completeWith(Future<T> future) => _future = future;

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) async {
    return onValue(await _future);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) =>
      _future.catchError(onError, test: test);

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      _future.timeout(timeLimit, onTimeout: onTimeout);
}

class MockUser extends Mock implements User {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockSession extends Mock implements Session {}

class FakeUri extends Fake implements Uri {}

void registerSupabaseFallbacks() {
  registerFallbackValue(FakeUri());
  registerFallbackValue((List<Map<String, dynamic>> data) => data);
}
