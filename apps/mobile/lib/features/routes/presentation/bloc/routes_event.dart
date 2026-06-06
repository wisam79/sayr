import 'package:equatable/equatable.dart';

/// Base class for all route-related events.
sealed class RoutesEvent extends Equatable {
  /// Constructor for [RoutesEvent].
  const RoutesEvent();

  @override
  List<Object?> get props => [];
}

/// Event requesting active routes to be loaded.
class RoutesLoadRequested extends RoutesEvent {
  /// Creates a [RoutesLoadRequested] event.
  const RoutesLoadRequested();
}

/// Event requesting routes to be searched by [query].
class RoutesSearchRequested extends RoutesEvent {
  /// Creates a [RoutesSearchRequested] event.
  const RoutesSearchRequested(this.query);

  /// Search query text.
  final String query;

  @override
  List<Object?> get props => [query];
}
