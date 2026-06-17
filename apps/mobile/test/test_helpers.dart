import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:sayr_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

/// Base pump widget for tests
Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget widget, {
  Size? size,
}) async {
  await tester.binding.setSurfaceSize(size ?? const Size(1080, 1920));
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ar'),
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
Future<void> pumpWithBloc<B extends StateStreamableSource<S>, S>(
  WidgetTester tester,
  B bloc,
  Widget widget,
) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ar'),
      home: BlocProvider<B>.value(
        value: bloc,
        child: widget,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
