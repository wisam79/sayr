import 'package:equatable/equatable.dart';

sealed class RoutesEvent extends Equatable {
  const RoutesEvent();

  @override
  List<Object?> get props => [];
}

class RoutesLoadRequested extends RoutesEvent {
  const RoutesLoadRequested();
}

class RoutesSearchRequested extends RoutesEvent {
  const RoutesSearchRequested(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}
