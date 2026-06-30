import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/src/value_objects/ids.dart';

part 'institution.freezed.dart';
/// A university or educational institution.
@freezed
abstract class Institution with _$Institution {
  const factory Institution({
    required InstitutionId id,
    required String name,
    String? city,
    DateTime? createdAt,
  }) = _Institution;

  }
