import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';

/// Base pump widget for tests
Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget widget, {
  Size? size,
}) async {
  await tester.binding.setSurfaceSize(size ?? const Size(1080, 1920));
  await tester.pumpWidget(
    MaterialApp(
      home: widget,
    ),
  );
  await tester.pumpAndSettle();
}

/// Creates common mocks
void setupMocktail() {
  // Register fallback values
  registerFallbackValue(const AuthLoginRequested(email: '', password: ''));
  registerFallbackValue(const AuthLoading());
}

/// Pump with BLoC provider helper
Future<void> pumpWithBloc<B extends StateStreamable<S>, S>(
  WidgetTester tester,
  B bloc,
  Widget widget,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: widget,
    ),
  );
  await tester.pumpAndSettle();
}
