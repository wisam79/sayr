import 'package:equatable/equatable.dart';

import '../value_objects/ids.dart';

/// A university or educational institution.
class Institution extends Equatable {
  const Institution({
    required this.id,
    required this.name,
    this.city,
    this.createdAt,
  });

  /// Unique institution ID.
  final InstitutionId id;

  /// Institution name (e.g., "جامعة بغداد").
  final String name;

  /// City where the institution is located.
  final String? city;

  /// When the institution was added.
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, name, city, createdAt];
}
