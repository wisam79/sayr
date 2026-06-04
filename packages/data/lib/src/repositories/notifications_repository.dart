import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';

import '../datasources/remote_datasource.dart';
import '../datasources/local_datasource.dart';
import '../models/notification_model.dart';

/// Concrete implementation of NotificationsRepository using Remote and Local data sources.
@LazySingleton(as: NotificationsRepository)
class NotificationsRepositoryImpl implements NotificationsRepository {
  final RemoteDatasource _remoteDatasource;
  final LocalDatasource _localDatasource;

  NotificationsRepositoryImpl({
    required RemoteDatasource remoteDatasource,
    required LocalDatasource localDatasource,
  })  : _remoteDatasource = remoteDatasource,
        _localDatasource = localDatasource;

  @override
  Future<Either<Failure, List<AppNotification>>> getMyNotifications({
    int limit = 50,
  }) async {
    try {
      final currentUserId = _remoteDatasource.currentUser?.id;
      if (currentUserId == null) {
        return const Left<Failure, List<AppNotification>>(
          UnauthorizedFailure(),
        );
      }

      final response = await _remoteDatasource.getMyNotifications(
        userId: currentUserId,
        limit: limit,
      );

      final notifications = response
          .map((json) => NotificationModel.fromJson(json).toEntity())
          .toList();
      return Right<Failure, List<AppNotification>>(notifications);
    } catch (e) {
      return Left<Failure, List<AppNotification>>(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final currentUserId = _remoteDatasource.currentUser?.id;
      if (currentUserId == null) {
        return const Left<Failure, int>(UnauthorizedFailure());
      }

      final count =
          await _remoteDatasource.getUnreadNotificationCount(currentUserId);
      return Right<Failure, int>(count);
    } catch (e) {
      return Left<Failure, int>(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAsRead(NotificationId id) async {
    try {
      await _remoteDatasource.markNotificationAsRead(
        id: id.value,
        readAt: DateTime.now().toUtc().toIso8601String(),
      );
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAllAsRead() async {
    try {
      final currentUserId = _remoteDatasource.currentUser?.id;
      if (currentUserId == null) {
        return const Left<Failure, Unit>(UnauthorizedFailure());
      }

      await _remoteDatasource.markAllNotificationsAsRead(
        userId: currentUserId,
        readAt: DateTime.now().toUtc().toIso8601String(),
      );
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<AppNotification>> watchMyNotifications() {
    final currentUserId = _remoteDatasource.currentUser?.id;
    if (currentUserId == null) {
      return Stream<List<AppNotification>>.error(
        const UnauthorizedFailure(),
      );
    }

    return _remoteDatasource.watchMyNotifications(currentUserId).map(
          (rows) => rows
              .map((json) => NotificationModel.fromJson(json).toEntity())
              .toList(),
        );
  }

  @override
  Future<Either<Failure, Unit>> registerPushToken({
    required String fcmToken,
    required String platform,
    String? deviceId,
  }) async {
    try {
      await _remoteDatasource.registerPushToken(
        fcmToken: fcmToken,
        platform: platform,
        deviceId: deviceId,
      );
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(ServerFailure(message: e.toString()));
    }
  }
}
