import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/ids.dart';
import '../utils/json_converters.dart';

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
