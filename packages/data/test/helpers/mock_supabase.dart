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

class MockPostgrestBuilder<T, R, C> extends Mock
    implements PostgrestBuilder<T, R, C> {
  late Future<T> _future;
  void completeWith(Future<T> future) => _future = future;

  @override
  Future<S> then<S>(FutureOr<S> Function(T value) onValue,
      {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) =>
      _future.catchError(onError, test: test);

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);
}

class MockPostgrestFilterBuilder<T> extends MockPostgrestBuilder<T, T, T>
    implements PostgrestFilterBuilder<T> {
  @override
  PostgrestBuilder<U, U, T> withConverter<U>(
      PostgrestConverter<U, T> converter) {
    final mock = MockPostgrestBuilder<U, U, T>();
    mock.completeWith(_future.then((value) => converter(value)));
    return mock;
  }
}

class MockPostgrestTransformBuilder<T> extends MockPostgrestBuilder<T, T, T>
    implements PostgrestTransformBuilder<T> {
  @override
  PostgrestBuilder<U, U, T> withConverter<U>(
      PostgrestConverter<U, T> converter) {
    final mock = MockPostgrestBuilder<U, U, T>();
    mock.completeWith(_future.then((value) => converter(value)));
    return mock;
  }
}

class MockUser extends Mock implements User {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockSession extends Mock implements Session {}

class FakeUri extends Fake implements Uri {}

void registerSupabaseFallbacks() {
  registerFallbackValue(FakeUri());
  registerFallbackValue((List<Map<String, dynamic>> data) => data);
}
