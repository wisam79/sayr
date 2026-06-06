import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/utils/json_converters.dart';
import 'package:sayr_core/src/value_objects/ids.dart';

part 'institution.freezed.dart';
part 'institution.g.dart';

/// A university or educational institution.
@freezed
abstract class Institution with _$Institution {
  const factory Institution({
    @JsonKey(fromJson: institutionIdFromJson, toJson: institutionIdToJson)
    required InstitutionId id,
    required String name,
    String? city,
    DateTime? createdAt,
  }) = _Institution;

  factory Institution.fromJson(Map<String, dynamic> json) =>
      _$InstitutionFromJson(json);
}
