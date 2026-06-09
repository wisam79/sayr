import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/remote_datasource.dart';
import 'package:sayr_data/src/models/notification_model.dart';
import 'package:sayr_data/src/repositories/base_repository.dart';

/// Concrete implementation of NotificationsRepository using Remote data source.
@LazySingleton(as: NotificationsRepository)
class NotificationsRepositoryImpl extends BaseRepository
    implements NotificationsRepository {
  NotificationsRepositoryImpl({
    required RemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;
  final RemoteDatasource _remoteDatasource;

  @override
  Future<Either<Failure, List<AppNotification>>> getMyNotifications({
    int limit = 50,
  }) async {
    return guard(() async {
      final currentUserId = _remoteDatasource.currentUser?.id;
      if (currentUserId == null) {
        throw const UnauthorizedFailure();
      }

      final response = await _remoteDatasource.getMyNotifications(
        userId: currentUserId,
        limit: limit,
      );

      return response
          .map((json) => NotificationModel.fromJson(json).toEntity())
          .toList();
    });
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    return guard(() async {
      final currentUserId = _remoteDatasource.currentUser?.id;
      if (currentUserId == null) {
        throw const UnauthorizedFailure();
      }

      return _remoteDatasource.getUnreadNotificationCount(currentUserId);
    });
  }

  @override
  Future<Either<Failure, Unit>> markAsRead(NotificationId id) async {
    return guard(() async {
      await _remoteDatasource.markNotificationAsRead(
        id: id.value,
        readAt: DateTime.now().toUtc().toIso8601String(),
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> markAllAsRead() async {
    return guard(() async {
      final currentUserId = _remoteDatasource.currentUser?.id;
      if (currentUserId == null) {
        throw const UnauthorizedFailure();
      }

      await _remoteDatasource.markAllNotificationsAsRead(
        userId: currentUserId,
        readAt: DateTime.now().toUtc().toIso8601String(),
      );
      return unit;
    });
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
    return guard(() async {
      await _remoteDatasource.registerPushToken(
        fcmToken: fcmToken,
        platform: platform,
        deviceId: deviceId,
      );
      return unit;
    });
  }
}
