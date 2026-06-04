import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_core/sayr_core.dart';

import 'package:sayr_mobile/features/chat/presentation/bloc/chat_list_bloc.dart';
import 'package:sayr_mobile/features/chat/presentation/bloc/chat_list_state.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository mockRepo;
  late ChatListBloc bloc;
  late StreamController<List<Conversation>> conversationStreamController;

  setUp(() {
    mockRepo = MockChatRepository();
    conversationStreamController = StreamController<List<Conversation>>();
    when(() => mockRepo.watchMyConversations()).thenAnswer(
      (_) => conversationStreamController.stream,
    );
    bloc = ChatListBloc(chatRepository: mockRepo);
  });

  tearDown(() {
    conversationStreamController.close();
    bloc.close();
  });

  final testConversations = [
    Conversation(
      id: const ConversationId('conv-1'),
      routeId: const RouteId('route-1'),
      studentId: const UserId('user-1'),
      driverUserId: const UserId('driver-1'),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  group('ChatListBloc', () {
    test('initial state is ChatListInitial', () {
      expect(bloc.state, isA<ChatListInitial>());
    });

    blocTest<ChatListBloc, ChatListState>(
      'emits [Loading, Loaded] on load success',
      build: () {
        when(() => mockRepo.getMyConversations()).thenAnswer(
          (_) async => Right<Failure, List<Conversation>>(testConversations),
        );
        return ChatListBloc(chatRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const ChatListLoadRequested()),
      expect: () => [
        isA<ChatListLoading>(),
        isA<ChatListLoaded>(),
      ],
    );

    blocTest<ChatListBloc, ChatListState>(
      'emits [Loading, Error] on load failure',
      build: () {
        when(() => mockRepo.getMyConversations()).thenAnswer(
          (_) async => const Left<Failure, List<Conversation>>(
            ServerFailure(message: 'Failed'),
          ),
        );
        return ChatListBloc(chatRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const ChatListLoadRequested()),
      expect: () => [
        isA<ChatListLoading>(),
        isA<ChatListError>(),
      ],
    );

    blocTest<ChatListBloc, ChatListState>(
      'emits Loaded on refresh success',
      build: () {
        when(() => mockRepo.getMyConversations()).thenAnswer(
          (_) async => Right<Failure, List<Conversation>>(testConversations),
        );
        return ChatListBloc(chatRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const ChatListRefreshRequested()),
      expect: () => [isA<ChatListLoaded>()],
    );

    blocTest<ChatListBloc, ChatListState>(
      'emits Error on refresh failure',
      build: () {
        when(() => mockRepo.getMyConversations()).thenAnswer(
          (_) async => const Left<Failure, List<Conversation>>(
            ServerFailure(message: 'Refresh failed'),
          ),
        );
        return ChatListBloc(chatRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const ChatListRefreshRequested()),
      expect: () => [isA<ChatListError>()],
    );

    blocTest<ChatListBloc, ChatListState>(
      'ChatListClosed emits ChatListInitial',
      build: () {
        when(() => mockRepo.getMyConversations()).thenAnswer(
          (_) async => Right<Failure, List<Conversation>>(testConversations),
        );
        return ChatListBloc(chatRepository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const ChatListLoadRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ChatListClosed());
      },
      expect: () => [
        isA<ChatListLoading>(),
        isA<ChatListLoaded>(),
        isA<ChatListInitial>(),
      ],
    );

    blocTest<ChatListBloc, ChatListState>(
      'realtime stream updates conversations',
      build: () {
        when(() => mockRepo.getMyConversations()).thenAnswer(
          (_) async => Right<Failure, List<Conversation>>([]),
        );
        return ChatListBloc(chatRepository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(const ChatListLoadRequested());
        await Future<void>.delayed(Duration.zero);
        conversationStreamController.add(testConversations);
      },
      expect: () => [
        isA<ChatListLoading>(),
        isA<ChatListLoaded>(),
        isA<ChatListLoaded>(),
      ],
    );
  });
}
