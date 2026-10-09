part of 'home_cubit.dart';

/// A request with bids in, and its cheapest live offer when it could be
/// loaded.
final class LiveBidSummary extends Equatable {
  const LiveBidSummary({
    required this.trip,
    this.bestOffer,
    this.savingsPercent,
  });

  final TripRequest trip;

  /// Null when the offers could not be loaded.
  final double? bestOffer;

  /// Saving of [bestOffer] against the budget, when it is below it.
  final int? savingsPercent;

  @override
  List<Object?> get props => [trip, bestOffer, savingsPercent];
}

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeFailure extends HomeState {
  const HomeFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.highlight,
    required this.liveBids,
    required this.unreadCount,
    required this.bookedCount,
    required this.totalSpent,
  });

  /// The featured trip; null when there is nothing to feature yet.
  final TripHighlight? highlight;

  /// At most [HomeCubit.maxLiveBids] requests with bids in, newest first.
  final List<LiveBidSummary> liveBids;
  final int unreadCount;
  final int bookedCount;

  /// Sum of fares paid for booked and completed trips, in INR.
  final double totalSpent;

  @override
  List<Object?> get props => [
    highlight,
    liveBids,
    unreadCount,
    bookedCount,
    totalSpent,
  ];
}
