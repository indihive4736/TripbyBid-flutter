import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/trip_request.dart';
import '../../domain/usecases/trip_queries.dart';

part 'trips_list_state.dart';

/// "My trips": every request, split into Active / Past / All and optionally
/// filtered by type.
class TripsListCubit extends Cubit<TripsListState> {
  TripsListCubit({required GetMyTripsUseCase getMyTrips})
    : _getMyTrips = getMyTrips,
      super(const TripsListLoading());

  final GetMyTripsUseCase _getMyTrips;

  TripSegment _segment = TripSegment.active;
  TripType? _type;
  Future<void>? _inFlight;

  /// Loads the trips. Once loaded, later calls refresh in place and keep the
  /// current list if the refresh fails.
  Future<void> load() =>
      _inFlight ??= _load().whenComplete(() => _inFlight = null);

  Future<void> _load() async {
    if (state is TripsListFailure) emit(const TripsListLoading());
    final result = await _getMyTrips(const NoParams());
    if (isClosed) return;
    switch (result) {
      case Ok(:final value):
        emit(TripsListLoaded(trips: value, segment: _segment, type: _type));
      case Err(:final failure):
        if (state is! TripsListLoaded) emit(TripsListFailure(failure.message));
    }
  }

  void selectSegment(TripSegment segment) {
    _segment = segment;
    if (state case final TripsListLoaded s) {
      emit(TripsListLoaded(trips: s.trips, segment: segment, type: _type));
    }
  }

  /// Shows only [type] trips; null shows every type.
  void filterType(TripType? type) {
    _type = type;
    if (state case final TripsListLoaded s) {
      emit(TripsListLoaded(trips: s.trips, segment: _segment, type: type));
    }
  }
}
