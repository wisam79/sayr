import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_state.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const ConversationId('fallback'));
    registerFallbackValue(const MessageId('fallback'));
  });

  late MockChatRepository mockRepo;
  late ChatBloc bloc;
  late StreamController<List<Message>> messageStreamController;

  setUp(() {
    mockRepo = MockChatRepository();
    messageStreamController = StreamController<List<Message>>();
    when(() => mockRepo.watchMessages(any())).thenAnswer(
      (_) => messageStreamController.stream,
    );
    bloc = ChatBloc(chatRepository: mockRepo);
  });

  tearDown(() {
    messageStreamController.close();
    bloc.close();
  });

  final testMessages = [
    Message(
      id: const MessageId('msg-1'),
      conversationId: const ConversationId('conv-1'),
      senderId: const UserId('user-1'),
      body: 'Hello',
      isRead: false,
      createdAt: DateTime.now(),
    ),
  ];

  group('ChatBloc', () {
    test('initial state is ChatInitial', () {
      expect(bloc.state, isA<ChatInitial>());
    });

    blocTest<ChatBloc, ChatState>(
      'emits [Loading, Loaded] on ChatStarted success',
      build: () {
        when(() => mockRepo.getMessages(any())).thenAnswer(
          (_) async => Right<Failure, List<Message>>(testMessages),
        );
        return ChatBloc(chatRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const ChatStarted(ConversationId('conv-1'))),
      expect: () => [
        isA<ChatLoading>(),
        isA<ChatLoaded>(),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits [Loading, Error] on ChatStarted failure',
      build: () {
        when(() => mockRepo.getMessages(any())).thenAnswer(
          (_) async => const Left<Failure, List<Message>>(
            ServerFailure(message: 'Failed to load'),
          ),
        );
        return ChatBloc(chatRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const ChatStarted(ConversationId('conv-1'))),
      expect: () => [
        isA<ChatLoading>(),
        isA<ChatError>(),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits Loaded(isSending:true) then SendCompleted on success',
      build: () {
        when(() => mockRepo.getMessages(any())).thenAnswer(
          (_) async => Right<Failure, List<Message>>(testMessages),
        );
        when(() => mockRepo.sendMessage(
              conversationId: any(named: 'conversationId'),
              body: any(named: 'body'),
            )).thenAnswer(
          (_) async => Right<Failure, Message>(
            Message(
              id: const MessageId('msg-2'),
              conversationId: const ConversationId('conv-1'),
              senderId: const UserId('user-1'),
              body: 'New message',
              isRead: false,
              createdAt: DateTime.now(),
            ),
          ),
        );
        return ChatBloc(chatRepository: mockRepo);
      },
      seed: () => const ChatLoaded(
        conversationId: ConversationId('conv-1'),
        messages: [],
      ),
      act: (bloc) => bloc.add(const ChatMessageSent('New message')),
      expect: () => [
        isA<ChatLoaded>(),
        isA<ChatLoaded>(),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits Loaded then Error on send failure',
      build: () {
        when(() => mockRepo.getMessages(any())).thenAnswer(
          (_) async => Right<Failure, List<Message>>(testMessages),
        );
        when(() => mockRepo.sendMessage(
              conversationId: any(named: 'conversationId'),
              body: any(named: 'body'),
            )).thenAnswer(
          (_) async => const Left<Failure, Message>(
            ServerFailure(message: 'Send failed'),
          ),
        );
        return ChatBloc(chatRepository: mockRepo);
      },
      seed: () => const ChatLoaded(
        conversationId: ConversationId('conv-1'),
        messages: [],
      ),
      act: (bloc) => bloc.add(const ChatMessageSent('Failed message')),
      expect: () => [
        isA<ChatLoaded>(),
        isA<ChatLoaded>(),
        isA<ChatError>(),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'does not send if trimmed body is empty',
      build: () {
        when(() => mockRepo.getMessages(any())).thenAnswer(
          (_) async => Right<Failure, List<Message>>(testMessages),
        );
        return ChatBloc(chatRepository: mockRepo);
      },
      seed: () => const ChatLoaded(
        conversationId: ConversationId('conv-1'),
        messages: [],
      ),
      act: (bloc) => bloc.add(const ChatMessageSent('   ')),
      verify: (_) => verifyNever(() => mockRepo.sendMessage(
            conversationId: any(named: 'conversationId'),
            body: any(named: 'body'),
          )),
    );

    blocTest<ChatBloc, ChatState>(
      'ChatClosed emits ChatInitial and cancels subscription',
      build: () {
        when(() => mockRepo.getMessages(any())).thenAnswer(
          (_) async => Right<Failure, List<Message>>(testMessages),
        );
        return ChatBloc(chatRepository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const ChatStarted(ConversationId('conv-1')));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ChatClosed());
      },
      expect: () => [
        isA<ChatLoading>(),
        isA<ChatLoaded>(),
        isA<ChatInitial>(),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'realtime stream updates messages in Loaded state',
      build: () {
        when(() => mockRepo.getMessages(any())).thenAnswer(
          (_) async => Right<Failure, List<Message>>([]),
        );
        return ChatBloc(chatRepository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const ChatStarted(ConversationId('conv-1')));
        await Future<void>.delayed(Duration.zero);
        messageStreamController.add(testMessages);
      },
      expect: () => [
        isA<ChatLoading>(),
        isA<ChatLoaded>(),
        isA<ChatLoaded>(),
      ],
    );
  });
}
