import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sayr_core/sayr_core.dart';

/// Manages loading of route details for trip tracking page.
class TripDetailsCubit extends Cubit<TripDetailsState> {
  /// Creates a [TripDetailsCubit] with the given [routeRepository]
  /// and [tripRepository].
  TripDetailsCubit({
    required RouteRepository routeRepository,
    required TripRepository tripRepository,
  })  : _routeRepository = routeRepository,
        _tripRepository = tripRepository,
        super(const TripDetailsInitial());

  final RouteRepository _routeRepository;
  final TripRepository _tripRepository;

  /// Loads the route and driver details for the given [routeId],
  /// [driverId], and [tripId].
  Future<void> loadTripDetails({
    required RouteId routeId,
    required DriverId driverId,
    required TripId tripId,
  }) async {
    final current = state;
    if (current is TripDetailsLoaded &&
        current.route.id == routeId &&
        current.tripRating != null) {
      return;
    }

    emit(const TripDetailsLoading());

    // Load route, driver details, and rating in parallel
    final results = await Future.wait([
      _routeRepository.getById(routeId),
      _tripRepository.getDriverById(driverId),
      _tripRepository.getTripRating(tripId),
    ]);

    final routeResult = results[0] as Either<Failure, Route>;
    final driverResult = results[1] as Either<Failure, Driver>;
    final ratingResult = results[2] as Either<Failure, Rating?>;

    if (routeResult.isLeft()) {
      final msg = routeResult.fold((f) => f.message, (_) => null) ??
          'فشل تحميل تفاصيل الرحلة';
      emit(TripDetailsError(msg));
      return;
    }

    final route = routeResult.getOrElse((_) => throw StateError('Unreachable'));

    Driver? driver;
    User? driverProfile;

    if (driverResult.isRight()) {
      driver = driverResult.getOrElse((_) => throw StateError('Unreachable'));
      // Fetch the driver's profile info (avatar, name, phone)
      final profileResult =
          await _tripRepository.getDriverProfile(driver.userId);
      if (profileResult.isRight()) {
        driverProfile =
            profileResult.getOrElse((_) => throw StateError('Unreachable'));
      }
    }

    final tripRating = ratingResult.getOrElse((_) => null);

    emit(
      TripDetailsLoaded(
        route: route,
        driver: driver,
        driverProfile: driverProfile,
        tripRating: tripRating,
      ),
    );
  }

  /// Submits a rating for the trip.
  Future<bool> submitTripRating({
    required TripId tripId,
    required DriverId driverId,
    required int rating,
    String? comment,
  }) async {
    final current = state;
    if (current is! TripDetailsLoaded) return false;

    final result = await _tripRepository.submitRating(
      tripId: tripId,
      driverId: driverId,
      rating: rating,
      comment: comment,
    );

    return result.fold(
      (failure) => false,
      (newRating) {
        emit(current.copyWith(tripRating: newRating));
        return true;
      },
    );
  }
}

/// Base state class for trip details.
sealed class TripDetailsState {
  /// Constructor for [TripDetailsState].
  const TripDetailsState();
}

/// Initial state when trip details are not loaded.
class TripDetailsInitial extends TripDetailsState {
  /// Constructor for [TripDetailsInitial].
  const TripDetailsInitial();
}

/// State when trip details are loading.
class TripDetailsLoading extends TripDetailsState {
  /// Constructor for [TripDetailsLoading].
  const TripDetailsLoading();
}

/// State when trip details have loaded successfully.
class TripDetailsLoaded extends TripDetailsState {
  /// Constructor for [TripDetailsLoaded].
  const TripDetailsLoaded({
    required this.route,
    this.driver,
    this.driverProfile,
    this.tripRating,
  });

  /// The loaded route details.
  final Route route;

  /// The loaded driver details.
  final Driver? driver;

  /// The loaded driver's user profile (avatar, phone, etc.).
  final User? driverProfile;

  /// The student's rating for this trip, if any.
  final Rating? tripRating;

  /// Copy with helper.
  TripDetailsLoaded copyWith({
    Route? route,
    Driver? driver,
    User? driverProfile,
    Rating? tripRating,
  }) {
    return TripDetailsLoaded(
      route: route ?? this.route,
      driver: driver ?? this.driver,
      driverProfile: driverProfile ?? this.driverProfile,
      tripRating: tripRating ?? this.tripRating,
    );
  }
}

/// State when loading trip details fails.
class TripDetailsError extends TripDetailsState {
  /// Constructor for [TripDetailsError].
  const TripDetailsError(this.message);

  /// The error message.
  final String message;
}
