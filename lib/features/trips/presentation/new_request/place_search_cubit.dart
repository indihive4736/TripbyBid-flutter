import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/new_trip_request.dart';
import '../../domain/entities/trip_request.dart';
import '../../domain/usecases/search_places.dart';

enum PlaceSearchStatus { loading, ready, failure }

final class PlaceSearchState extends Equatable {
  const PlaceSearchState({
    this.type = TripType.flight,
    this.query = '',
    this.status = PlaceSearchStatus.loading,
    this.results = const [],
    this.message,
  });

  final TripType type;
  final String query;
  final PlaceSearchStatus status;

  /// Best match first; popular places while [query] is empty. Kept while a
  /// newer search loads so the list does not flicker.
  final List<Place> results;
  final String? message;

  bool get showingPopular => query.trim().isEmpty;

  PlaceSearchState copyWith({
    String? query,
    PlaceSearchStatus? status,
    List<Place>? results,
    String? message,
  }) => PlaceSearchState(
    type: type,
    query: query ?? this.query,
    status: status ?? this.status,
    results: results ?? this.results,
    message: message,
  );

  @override
  List<Object?> get props => [type, query, status, results, message];
}

/// Drives the place picker: debounced search over airports, stations or
/// cities depending on the trip type.
class PlaceSearchCubit extends Cubit<PlaceSearchState> {
  PlaceSearchCubit({
    required SearchPlacesUseCase searchPlaces,
    this.debounce = const Duration(milliseconds: 150),
  }) : _searchPlaces = searchPlaces,
       super(const PlaceSearchState());

  final SearchPlacesUseCase _searchPlaces;
  final Duration debounce;
  Timer? _timer;
  int _generation = 0;

  /// Starts a fresh search for [type], showing popular places.
  Future<void> open(TripType type) {
    _timer?.cancel();
    emit(PlaceSearchState(type: type));
    return _run();
  }

  /// Searches [text] once typing pauses for [debounce].
  void search(String text) {
    if (text == state.query) return;
    _timer?.cancel();
    emit(state.copyWith(query: text, status: PlaceSearchStatus.loading));
    _timer = Timer(debounce, _run);
  }

  Future<void> retry() => _run();

  Future<void> _run() async {
    final generation = ++_generation;
    final query = state.query;
    if (state.status != PlaceSearchStatus.loading) {
      emit(state.copyWith(status: PlaceSearchStatus.loading));
    }
    final result = await _searchPlaces(PlaceQuery(state.type, query));
    // A newer search started (or the picker closed) while this one ran.
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(status: PlaceSearchStatus.ready, results: value));
      case Err(:final failure):
        emit(
          state.copyWith(
            status: PlaceSearchStatus.failure,
            message: failure.message,
          ),
        );
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
