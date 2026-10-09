part of 'trips_list_cubit.dart';

enum TripSegment {
  /// Still in progress.
  active,

  /// Completed, cancelled or expired.
  past,
  all;

  bool includes(TripRequest trip) => switch (this) {
    active => trip.stage.isActive,
    past => trip.stage.isClosed,
    all => true,
  };
}

sealed class TripsListState extends Equatable {
  const TripsListState();

  @override
  List<Object?> get props => [];
}

final class TripsListLoading extends TripsListState {
  const TripsListLoading();
}

final class TripsListFailure extends TripsListState {
  const TripsListFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class TripsListLoaded extends TripsListState {
  const TripsListLoaded({
    required this.trips,
    required this.segment,
    this.type,
  });

  /// Every trip, newest first.
  final List<TripRequest> trips;
  final TripSegment segment;

  /// Type filter; null shows every type.
  final TripType? type;

  List<TripRequest> get _ofType =>
      type == null ? trips : trips.where((t) => t.type == type).toList();

  /// The trips the list shows.
  List<TripRequest> get visible => _ofType.where(segment.includes).toList();

  /// Trips in [s] (respecting the type filter).
  int count(TripSegment s) => _ofType.where(s.includes).length;

  /// Types offered by the filter: the three request types, plus packages
  /// when the traveler has any (booked on the web).
  List<TripType> get filterTypes => [
    TripType.flight,
    TripType.train,
    TripType.hotel,
    if (trips.any((t) => t.type == TripType.package)) TripType.package,
  ];

  @override
  List<Object?> get props => [trips, segment, type];
}
