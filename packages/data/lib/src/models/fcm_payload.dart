import 'package:freezed_annotation/freezed_annotation.dart';

part 'fcm_payload.freezed.dart';

/// Type-safe payload union for incoming FCM messages.
@freezed
sealed class FcmPayload with _$FcmPayload {
  /// Payload indicating a trip notification.
  const factory FcmPayload.trip({
    required String tripId,
  }) = FcmTripPayload;

  /// Payload indicating a new chat message.
  const factory FcmPayload.chat({
    required String conversationId,
  }) = FcmChatPayload;

  /// Payload indicating a route notification.
  const factory FcmPayload.route({
    required String routeId,
  }) = FcmRoutePayload;

  /// Unknown payload type (fallback).
  const factory FcmPayload.unknown() = FcmUnknownPayload;

  /// Parses a raw map payload from Firebase Cloud Messaging.
  factory FcmPayload.fromMap(Map<String, dynamic> data) {
    final tripId = data['trip_id']?.toString();
    if (tripId != null && tripId.isNotEmpty) {
      return FcmPayload.trip(tripId: tripId);
    }
    final conversationId = data['conversation_id']?.toString();
    if (conversationId != null && conversationId.isNotEmpty) {
      return FcmPayload.chat(conversationId: conversationId);
    }
    final routeId = data['route_id']?.toString();
    if (routeId != null && routeId.isNotEmpty) {
      return FcmPayload.route(routeId: routeId);
    }
    return const FcmPayload.unknown();
  }
}
