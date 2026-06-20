import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sayr_data/src/datasources/auth_remote_datasource.dart';
import 'package:sayr_data/src/datasources/boarding_remote_datasource.dart';
import 'package:sayr_data/src/datasources/chat_remote_datasource.dart';
import 'package:sayr_data/src/datasources/emergency_remote_datasource.dart';
import 'package:sayr_data/src/datasources/notification_remote_datasource.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/datasources/route_remote_datasource.dart';
import 'package:sayr_data/src/datasources/subscription_remote_datasource.dart';
import 'package:sayr_data/src/datasources/trip_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockAuth extends Mock implements AuthRemoteDatasource {}

class MockChat extends Mock implements ChatRemoteDatasource {}

class MockEmergency extends Mock implements EmergencyRemoteDatasource {}

class MockNotifications extends Mock implements NotificationRemoteDatasource {}

class MockRoutes extends Mock implements RouteRemoteDatasource {}

class MockSubscriptions extends Mock implements SubscriptionRemoteDatasource {}

class MockTrips extends Mock implements TripRemoteDatasource {}

class MockBoarding extends Mock implements BoardingRemoteDatasource {}

class MockUser extends Mock implements supabase.User {}

class MockAuthResponse extends Mock implements supabase.AuthResponse {}

void main() {
  late MockAuth mockAuth;
  late MockChat mockChat;
  late MockEmergency mockEmergency;
  late MockNotifications mockNotifications;
  late MockRoutes mockRoutes;
  late MockSubscriptions mockSubscriptions;
  late MockTrips mockTrips;
  late MockBoarding mockBoarding;
  late RemoteDatasourceImpl datasource;

  setUp(() {
    mockAuth = MockAuth();
    mockChat = MockChat();
    mockEmergency = MockEmergency();
    mockNotifications = MockNotifications();
    mockRoutes = MockRoutes();
    mockSubscriptions = MockSubscriptions();
    mockTrips = MockTrips();
    mockBoarding = MockBoarding();

    datasource = RemoteDatasourceImpl(
      auth: mockAuth,
      chat: mockChat,
      emergency: mockEmergency,
      notifications: mockNotifications,
      routes: mockRoutes,
      subscriptions: mockSubscriptions,
      trips: mockTrips,
      boarding: mockBoarding,
    );
  });

  group('RemoteDatasourceImpl Auth Delegation', () {
    test('currentUser delegates to auth', () {
      final mockUser = MockUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      expect(datasource.currentUser, equals(mockUser));
    });

    test('signInWithPassword delegates to auth', () async {
      final response = MockAuthResponse();
      when(() => mockAuth.signInWithPassword(
          email: 'test@test.com',
          password: 'password')).thenAnswer((_) async => response);
      final result = await datasource.signInWithPassword(
          email: 'test@test.com', password: 'password');
      expect(result, equals(response));
    });

    test('signOut delegates to auth', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
      await datasource.signOut();
      verify(() => mockAuth.signOut()).called(1);
    });
  });

  group('RemoteDatasourceImpl Chat Delegation', () {
    test('getMyConversations delegates to chat', () async {
      when(() => mockChat.getMyConversations('user1'))
          .thenAnswer((_) async => []);
      final result = await datasource.getMyConversations('user1');
      expect(result, equals([]));
    });

    test('sendMessage delegates to chat', () async {
      when(() => mockChat.sendMessage(
          conversationId: 'c1',
          senderId: 's1',
          body: 'hi')).thenAnswer((_) async => {'id': 'm1'});
      final result = await datasource.sendMessage(
          conversationId: 'c1', senderId: 's1', body: 'hi');
      expect(result, equals({'id': 'm1'}));
    });
  });

  group('RemoteDatasourceImpl Emergency Delegation', () {
    test('triggerEmergency delegates to emergency', () async {
      when(
        () => mockEmergency.triggerEmergency(
          tripId: 't1',
          routeId: 'r1',
          studentId: 's1',
          lat: 1,
          lng: 1,
          description: 'desc',
        ),
      ).thenAnswer((_) async => 'report1');
      final result = await datasource.triggerEmergency(
        tripId: 't1',
        routeId: 'r1',
        studentId: 's1',
        lat: 1,
        lng: 1,
        description: 'desc',
      );
      expect(result, equals('report1'));
    });
  });

  group('RemoteDatasourceImpl Other Delegation', () {
    test('getMyNotifications delegates', () async {
      when(() => mockNotifications.getMyNotifications(userId: 'u1'))
          .thenAnswer((_) async => []);
      final result = await datasource.getMyNotifications(userId: 'u1');
      expect(result, equals([]));
    });

    test('getActiveRoutes delegates', () async {
      when(() => mockRoutes.getActiveRoutes()).thenAnswer((_) async => []);
      final result = await datasource.getActiveRoutes();
      expect(result, equals([]));
    });

    test('getMySubscriptions delegates', () async {
      when(() => mockSubscriptions.getMySubscriptions('u1'))
          .thenAnswer((_) async => []);
      final result = await datasource.getMySubscriptions('u1');
      expect(result, equals([]));
    });

    test('getActiveTrips delegates', () async {
      when(() => mockTrips.getActiveTrips()).thenAnswer((_) async => []);
      final result = await datasource.getActiveTrips();
      expect(result, equals([]));
    });

    test('getActiveTripForSubscription delegates', () async {
      when(() => mockBoarding.getActiveTripForSubscription())
          .thenAnswer((_) async => 'trip1');
      final result = await datasource.getActiveTripForSubscription();
      expect(result, equals('trip1'));
    });
  });
}
