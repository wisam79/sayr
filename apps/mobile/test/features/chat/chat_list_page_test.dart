import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_list_bloc.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_list_state.dart';
import 'package:sayr_mobile/features/chat/presentation/pages/chat_list_page.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

class MockChatListBloc extends MockBloc<ChatListEvent, ChatListState>
    implements ChatListBloc {}

void main() {
  late MockChatListBloc mockBloc;

  final testConversations = [
    Conversation(
      id: const ConversationId('conv-1'),
      routeId: const RouteId('route-1'),
      studentId: const UserId('student-1'),
      driverUserId: const UserId('driver-1'),
      createdAt: DateTime.parse('2026-06-07T08:00:00Z'),
      updatedAt: DateTime.parse('2026-06-07T09:00:00Z'),
      lastMessageAt: DateTime.parse('2026-06-07T09:00:00Z'),
      lastMessagePreview: 'Hello there!',
      routeName: 'Baghdad - Basra',
      otherUserName: 'Ahmed',
    ),
  ];

  setUp(() {
    mockBloc = MockChatListBloc();
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ar'),
      home: BlocProvider<ChatListBloc>.value(
        value: mockBloc,
        child: child,
      ),
    );
  }

  testWidgets('shows loading skeleton when state is ChatListLoading',
      (tester) async {
    when(() => mockBloc.state).thenReturn(const ChatListState.loading());

    await tester.pumpWidget(wrap(const ChatListPage()));
    await tester.pump();

    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('shows empty state when no conversations', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const ChatListState.loaded(conversations: []),
    );

    await tester.pumpWidget(wrap(const ChatListPage()));
    await tester.pump();

    expect(find.text('لا توجد محادثات بعد'), findsOneWidget);
  });

  testWidgets('shows conversation list when loaded', (tester) async {
    when(() => mockBloc.state).thenReturn(
      ChatListState.loaded(conversations: testConversations),
    );

    await tester.pumpWidget(wrap(const ChatListPage()));
    await tester.pump();

    expect(find.text('Ahmed'), findsOneWidget);
    expect(find.text('Hello there!'), findsOneWidget);
  });

  testWidgets('shows error body with retry button', (tester) async {
    when(() => mockBloc.state).thenReturn(
      ChatListState.error(
        failure: const ServerFailure(message: 'Failed to load'),
      ),
    );

    await tester.pumpWidget(wrap(const ChatListPage()));
    await tester.pump();

    expect(find.text('Failed to load'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
