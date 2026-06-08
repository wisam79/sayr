import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_state.dart';
import 'package:sayr_mobile/features/chat/presentation/pages/chat_page.dart';
import 'package:sayr_mobile/features/chat/presentation/widgets/chat_input.dart';
import 'package:sayr_mobile/l10n/app_localizations.dart';

class MockChatBloc extends MockBloc<ChatEvent, ChatState> implements ChatBloc {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockChatBloc mockBloc;
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockBloc = MockChatBloc();
    mockAuthRepo = MockAuthRepository();
    registerFallbackValue(const ConversationId('fallback'));
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
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ChatBloc>.value(value: mockBloc),
          RepositoryProvider<AuthRepository>.value(value: mockAuthRepo),
        ],
        child: child,
      ),
    );
  }

  testWidgets('shows loading indicator when state is ChatLoading',
      (tester) async {
    when(() => mockBloc.state).thenReturn(const ChatState.loading());

    await tester.pumpWidget(
      wrap(const ChatPage(conversationId: ConversationId('conv-1'))),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message with failure text', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const ChatState.error(failure: ServerFailure(message: 'Network error')),
    );

    await tester.pumpWidget(
      wrap(const ChatPage(conversationId: ConversationId('conv-1'))),
    );
    await tester.pump();

    expect(find.text('Network error'), findsOneWidget);
  });

  testWidgets('shows empty chat state and chat input when loaded with no messages',
      (tester) async {
    when(() => mockBloc.state).thenReturn(
      const ChatState.loaded(
        conversationId: ConversationId('conv-1'),
        messages: [],
      ),
    );

    await tester.pumpWidget(
      wrap(const ChatPage(conversationId: ConversationId('conv-1'))),
    );
    await tester.pump();

    expect(find.byType(ChatInput), findsOneWidget);
  });

  testWidgets('shows message bubbles when loaded with messages',
      (tester) async {
    final messages = [
      Message(
        id: const MessageId('msg-1'),
        conversationId: const ConversationId('conv-1'),
        senderId: const UserId('driver-1'),
        body: 'Hello student',
        isRead: true,
        createdAt: DateTime.parse('2026-06-07T08:00:00Z'),
      ),
      Message(
        id: const MessageId('msg-2'),
        conversationId: const ConversationId('conv-1'),
        senderId: const UserId('student-1'),
        body: 'Hi driver',
        isRead: false,
        createdAt: DateTime.parse('2026-06-07T08:01:00Z'),
      ),
    ];

    when(() => mockBloc.state).thenReturn(
      ChatState.loaded(
        conversationId: const ConversationId('conv-1'),
        messages: messages,
      ),
    );

    await tester.pumpWidget(
      wrap(const ChatPage(conversationId: ConversationId('conv-1'))),
    );
    await tester.pump();

    expect(find.text('Hello student'), findsOneWidget);
    expect(find.text('Hi driver'), findsOneWidget);
  });
}
