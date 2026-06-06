import 'package:sayr_core/src/enums/license_status.dart';
import 'package:sayr_core/src/enums/payout_status.dart';
import 'package:sayr_core/src/enums/subscription_status.dart';
import 'package:sayr_core/src/enums/support_status.dart';
import 'package:sayr_core/src/enums/trip_status.dart';
import 'package:sayr_core/src/enums/user_role.dart';
import 'package:sayr_core/src/value_objects/coordinates.dart';
import 'package:sayr_core/src/value_objects/ids.dart';
import 'package:sayr_core/src/value_objects/license_code.dart';
import 'package:sayr_core/src/value_objects/money.dart';

// UserId
UserId userIdFromJson(String json) => UserId(json);
String userIdToJson(UserId id) => id.value;

UserId? nullableUserIdFromJson(String? json) =>
    json != null ? UserId(json) : null;
String? nullableUserIdToJson(UserId? id) => id?.value;

// RouteId
RouteId routeIdFromJson(String json) => RouteId(json);
String routeIdToJson(RouteId id) => id.value;

RouteId? nullableRouteIdFromJson(String? json) =>
    json != null ? RouteId(json) : null;
String? nullableRouteIdToJson(RouteId? id) => id?.value;

// TripId
TripId tripIdFromJson(String json) => TripId(json);
String tripIdToJson(TripId id) => id.value;

TripId? nullableTripIdFromJson(String? json) =>
    json != null ? TripId(json) : null;
String? nullableTripIdToJson(TripId? id) => id?.value;

// SubscriptionId
SubscriptionId subscriptionIdFromJson(String json) => SubscriptionId(json);
String subscriptionIdToJson(SubscriptionId id) => id.value;

SubscriptionId? nullableSubscriptionIdFromJson(String? json) =>
    json != null ? SubscriptionId(json) : null;
String? nullableSubscriptionIdToJson(SubscriptionId? id) => id?.value;

// LicenseId
LicenseId licenseIdFromJson(String json) => LicenseId(json);
String licenseIdToJson(LicenseId id) => id.value;

LicenseId? nullableLicenseIdFromJson(String? json) =>
    json != null ? LicenseId(json) : null;
String? nullableLicenseIdToJson(LicenseId? id) => id?.value;

// LicenseBatchId
LicenseBatchId licenseBatchIdFromJson(String json) => LicenseBatchId(json);
String licenseBatchIdToJson(LicenseBatchId id) => id.value;

LicenseBatchId? nullableLicenseBatchIdFromJson(String? json) =>
    json != null ? LicenseBatchId(json) : null;
String? nullableLicenseBatchIdToJson(LicenseBatchId? id) => id?.value;

// DriverId
DriverId driverIdFromJson(String json) => DriverId(json);
String driverIdToJson(DriverId id) => id.value;

DriverId? nullableDriverIdFromJson(String? json) =>
    json != null ? DriverId(json) : null;
String? nullableDriverIdToJson(DriverId? id) => id?.value;

// InstitutionId
InstitutionId institutionIdFromJson(String json) => InstitutionId(json);
String institutionIdToJson(InstitutionId id) => id.value;

InstitutionId? nullableInstitutionIdFromJson(String? json) =>
    json != null ? InstitutionId(json) : null;
String? nullableInstitutionIdToJson(InstitutionId? id) => id?.value;

// PayoutId
PayoutId payoutIdFromJson(String json) => PayoutId(json);
String payoutIdToJson(PayoutId id) => id.value;

PayoutId? nullablePayoutIdFromJson(String? json) =>
    json != null ? PayoutId(json) : null;
String? nullablePayoutIdToJson(PayoutId? id) => id?.value;

// RatingId
RatingId ratingIdFromJson(String json) => RatingId(json);
String ratingIdToJson(RatingId id) => id.value;

RatingId? nullableRatingIdFromJson(String? json) =>
    json != null ? RatingId(json) : null;
String? nullableRatingIdToJson(RatingId? id) => id?.value;

// ConversationId
ConversationId conversationIdFromJson(String json) => ConversationId(json);
String conversationIdToJson(ConversationId id) => id.value;

ConversationId? nullableConversationIdFromJson(String? json) =>
    json != null ? ConversationId(json) : null;
String? nullableConversationIdToJson(ConversationId? id) => id?.value;

// MessageId
MessageId messageIdFromJson(String json) => MessageId(json);
String messageIdToJson(MessageId id) => id.value;

MessageId? nullableMessageIdFromJson(String? json) =>
    json != null ? MessageId(json) : null;
String? nullableMessageIdToJson(MessageId? id) => id?.value;

// NotificationId
NotificationId notificationIdFromJson(String json) => NotificationId(json);
String notificationIdToJson(NotificationId id) => id.value;

NotificationId? nullableNotificationIdFromJson(String? json) =>
    json != null ? NotificationId(json) : null;
String? nullableNotificationIdToJson(NotificationId? id) => id?.value;

// EmergencyReportId
EmergencyReportId emergencyReportIdFromJson(String json) =>
    EmergencyReportId(json);
String emergencyReportIdToJson(EmergencyReportId id) => id.value;

EmergencyReportId? nullableEmergencyReportIdFromJson(String? json) =>
    json != null ? EmergencyReportId(json) : null;
String? nullableEmergencyReportIdToJson(EmergencyReportId? id) => id?.value;

// Coordinates
Coordinates coordinatesFromJson(Map<String, dynamic> json) => Coordinates(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
Map<String, dynamic> coordinatesToJson(Coordinates coords) => {
      'latitude': coords.latitude,
      'longitude': coords.longitude,
    };

Coordinates? nullableCoordinatesFromJson(Map<String, dynamic>? json) =>
    json != null ? coordinatesFromJson(json) : null;
Map<String, dynamic>? nullableCoordinatesToJson(Coordinates? coords) =>
    coords != null ? coordinatesToJson(coords) : null;

// Money
Money moneyFromJson(int json) => Money(json);
int moneyToJson(Money money) => money.amountInFils;

Money? nullableMoneyFromJson(int? json) => json != null ? Money(json) : null;
int? nullableMoneyToJson(Money? money) => money?.amountInFils;

// LicenseCode
LicenseCode licenseCodeFromJson(String json) => LicenseCode(json);
String licenseCodeToJson(LicenseCode code) => code.value;

LicenseCode? nullableLicenseCodeFromJson(String? json) =>
    json != null ? LicenseCode(json) : null;
String? nullableLicenseCodeToJson(LicenseCode? code) => code?.value;

// Enums
UserRole userRoleFromJson(String json) => UserRole.fromString(json);
String userRoleToJson(UserRole role) => role.name;

UserRole? nullableUserRoleFromJson(String? json) =>
    json != null ? UserRole.fromString(json) : null;
String? nullableUserRoleToJson(UserRole? role) => role?.name;

LicenseStatus licenseStatusFromJson(String json) =>
    LicenseStatus.fromString(json);
String licenseStatusToJson(LicenseStatus status) => status.name;

LicenseStatus? nullableLicenseStatusFromJson(String? json) =>
    json != null ? LicenseStatus.fromString(json) : null;
String? nullableLicenseStatusToJson(LicenseStatus? status) => status?.name;

PayoutStatus payoutStatusFromJson(String json) => PayoutStatus.fromString(json);
String payoutStatusToJson(PayoutStatus status) => status.name;

PayoutStatus? nullablePayoutStatusFromJson(String? json) =>
    json != null ? PayoutStatus.fromString(json) : null;
String? nullablePayoutStatusToJson(PayoutStatus? status) => status?.name;

SubscriptionStatus subscriptionStatusFromJson(String json) =>
    SubscriptionStatus.fromString(json);
String subscriptionStatusToJson(SubscriptionStatus status) => status.name;

SubscriptionStatus? nullableSubscriptionStatusFromJson(String? json) =>
    json != null ? SubscriptionStatus.fromString(json) : null;
String? nullableSubscriptionStatusToJson(SubscriptionStatus? status) =>
    status?.name;

SupportStatus supportStatusFromJson(String json) =>
    SupportStatus.fromString(json);
String supportStatusToJson(SupportStatus status) => status.name;

SupportStatus? nullableSupportStatusFromJson(String? json) =>
    json != null ? SupportStatus.fromString(json) : null;
String? nullableSupportStatusToJson(SupportStatus? status) => status?.name;

TripStatus tripStatusFromJson(String json) => TripStatus.fromString(json);
String tripStatusToJson(TripStatus status) => status.name;

TripStatus? nullableTripStatusFromJson(String? json) =>
    json != null ? TripStatus.fromString(json) : null;
String? nullableTripStatusToJson(TripStatus? status) => status?.name;
