import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../notifications/domain/usecases/notification_usecases.dart';
import '../../domain/entities/trip_request.dart';
import '../../domain/entities/trip_summaries.dart';
import '../../domain/usecases/get_active_bids_usecase.dart';
import '../../domain/usecases/trip_queries.dart';

part 'home_state.dart';

/// The home dashboard: featured trip, live bids, stats and unread count.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required GetMyTripsUseCase getMyTrips,
    required GetActiveBidsUseCase getActiveBids,
    required GetUnreadCountUseCase getUnreadCount,
    DateTime Function() now = DateTime.now,
  }) : _getMyTrips = getMyTrips,
       _getActiveBids = getActiveBids,
       _getUnreadCount = getUnreadCount,
       _now = now,
       super(const HomeLoading());

  /// Live-bid cards shown (and offer lookups made) at most.
  static const maxLiveBids = 5;

  final GetMyTripsUseCase _getMyTrips;
  final GetActiveBidsUseCase _getActiveBids;
  final GetUnreadCountUseCase _getUnreadCount;
  final DateTime Function() _now;

  Future<void>? _inFlight;

  /// Loads everything. Once loaded, later calls refresh in place and keep
  /// the current content if the refresh fails.
  Future<void> load() =>
      _inFlight ??= _load().whenComplete(() => _inFlight = null);

  Future<void> _load() async {
    if (state is HomeFailure) emit(const HomeLoading());

    final tripsFuture = _getMyTrips(const NoParams());
    final unreadFuture = _getUnreadCount(const NoParams());
    final tripsResult = await tripsFuture;
    final unreadResult = await unreadFuture;

    switch (tripsResult) {
      case Err(:final failure):
        if (state is! HomeLoaded && !isClosed) {
          emit(HomeFailure(failure.message));
        }
      case Ok(value: final trips):
        final liveBids = await _liveBids(trips);
        if (isClosed) return;
        emit(
          HomeLoaded(
            highlight: TripSummaries.highlight(trips, today: _now()),
            liveBids: liveBids,
            unreadCount: switch (unreadResult) {
              Ok(:final value) => value,
              Err() => switch (state) {
                HomeLoaded(:final unreadCount) => unreadCount,
                _ => 0,
              },
            },
            bookedCount: TripSummaries.bookedCount(trips),
            totalSpent: TripSummaries.totalSpent(trips),
          ),
        );
    }
  }

  /// Looks up the best offer of each request with bids in, in parallel.
  Future<List<LiveBidSummary>> _liveBids(List<TripRequest> trips) {
    final requests = TripSummaries.liveBidRequests(trips).take(maxLiveBids);
    return Future.wait([
      for (final trip in requests)
        _getActiveBids(trip.id).then((result) {
          final best = switch (result) {
            Ok(:final value) => TripSummaries.bestOffer(value),
            Err() => null,
          };
          return LiveBidSummary(
            trip: trip,
            bestOffer: best,
            savingsPercent: best == null
                ? null
                : TripSummaries.savingsPercent(best: best, budget: trip.budget),
          );
        }),
    ]);
  }
}
