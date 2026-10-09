import 'bid.dart';
import 'booking.dart';
import 'trip_request.dart';

/// Everything the booking-detail screen shows: the request, the live offers
/// and the booking once paid.
final class TripDetail {
  const TripDetail({
    required this.request,
    required this.activeBids,
    this.booking,
  });

  final TripRequest request;

  /// Live offers, cheapest first (empty once a bid is accepted or booked).
  final List<Bid> activeBids;
  final Booking? booking;

  /// Every bid the traveler can compare: live offers, plus the accepted or
  /// selected one (which drops out of [activeBids]), cheapest first.
  List<Bid> get comparableBids {
    final chosen = request.bids.where(
      (b) => b.status == BidStatus.accepted || b.status == BidStatus.selected,
    );
    final all = {
      for (final b in [...activeBids, ...chosen]) b.id: b,
    };
    return all.values.toList()..sort((a, b) => a.price.compareTo(b.price));
  }

  /// The cheapest live offer.
  Bid? get bestBid => activeBids.isEmpty
      ? null
      : activeBids.reduce((a, b) => a.price <= b.price ? a : b);

  /// The bid the trip is (or will be) booked on.
  Bid? get chosenBid => request.selectedBid ?? request.acceptedBid;
}

/// What the traveler gets back if they cancel a paid booking now.
final class CancellationQuote {
  const CancellationQuote({
    required this.fare,
    required this.charge,
    required this.platformFee,
    required this.platformFeeKept,
    required this.refund,
    this.policyTitle,
    this.appliesUntil,
  });

  final double fare;

  /// Cancellation charge taken from the fare.
  final double charge;
  final double platformFee;
  final bool platformFeeKept;

  /// Amount returned to the traveler.
  final double refund;
  final String? policyTitle;

  /// The quote holds until then (the next, costlier tier starts).
  final DateTime? appliesUntil;
}
