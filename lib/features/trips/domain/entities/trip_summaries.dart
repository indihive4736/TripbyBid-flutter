import 'bid.dart';
import 'trip_request.dart';
import 'trip_stage.dart';

/// Why a trip is the one featured on the home screen.
enum HighlightKind {
  /// An accepted bid is waiting for payment.
  paymentDue,

  /// The next booked trip that has not departed yet.
  upcoming,

  /// Agents have bid; the traveler should compare.
  bidsIn,
}

/// The trip the home screen features, and why.
final class TripHighlight {
  const TripHighlight(this.kind, this.trip);

  final HighlightKind kind;
  final TripRequest trip;

  @override
  bool operator ==(Object other) =>
      other is TripHighlight &&
      other.kind == kind &&
      identical(other.trip, trip);

  @override
  int get hashCode => Object.hash(kind, identityHashCode(trip));
}

/// Pure summaries over the traveler's trips for the home screen.
abstract final class TripSummaries {
  // UTC midnight, so daylight-saving shifts never skew a day count.
  static DateTime _day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  /// Calendar days from [today] until [date] (negative once passed).
  static int daysUntil(DateTime date, {required DateTime today}) =>
      _day(date).difference(_day(today)).inDays;

  /// The most relevant trip: a payment that is due (soonest departure first),
  /// else the next booked trip, else the newest request with bids in.
  static TripHighlight? highlight(
    List<TripRequest> trips, {
    required DateTime today,
  }) {
    int byDeparture(TripRequest a, TripRequest b) =>
        a.departDate.compareTo(b.departDate);

    final due = trips.where((t) => t.stage == TripStage.paymentDue).toList()
      ..sort(byDeparture);
    if (due.isNotEmpty) {
      return TripHighlight(HighlightKind.paymentDue, due.first);
    }

    final upcoming =
        trips
            .where(
              (t) =>
                  t.stage.isBooked &&
                  !t.stage.isClosed &&
                  daysUntil(t.departDate, today: today) >= 0,
            )
            .toList()
          ..sort(byDeparture);
    if (upcoming.isNotEmpty) {
      return TripHighlight(HighlightKind.upcoming, upcoming.first);
    }

    final bidding = liveBidRequests(trips);
    if (bidding.isNotEmpty) {
      return TripHighlight(HighlightKind.bidsIn, bidding.first);
    }
    return null;
  }

  /// Requests with live bids to compare, in the given (newest-first) order.
  static List<TripRequest> liveBidRequests(List<TripRequest> trips) =>
      trips.where((t) => t.stage == TripStage.bidsIn).toList();

  /// Trips the traveler paid for (booked, in progress or completed).
  static int bookedCount(List<TripRequest> trips) =>
      trips.where((t) => t.stage.isBooked).length;

  /// Sum of the fares paid for booked and completed trips.
  static double totalSpent(List<TripRequest> trips) => trips
      .where((t) => t.stage.isBooked)
      .fold(0, (sum, t) => sum + (t.booking?.price ?? 0));

  /// The cheapest live offer, if any.
  static double? bestOffer(List<Bid> bids) => bids.isEmpty
      ? null
      : bids.map((b) => b.price).reduce((a, b) => a < b ? a : b);

  /// Whole-percent saving of [best] against [budget], when it is below it.
  static int? savingsPercent({required double best, required double budget}) {
    if (budget <= 0 || best >= budget) return null;
    final percent = ((budget - best) / budget * 100).round();
    return percent > 0 ? percent : null;
  }
}
