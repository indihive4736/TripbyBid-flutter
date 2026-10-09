import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/payments/domain/entities/checkout.dart';
import 'package:tripbybid/features/payments/domain/repositories/payments_repository.dart';
import 'package:tripbybid/features/payments/domain/usecases/payment_usecases.dart';
import 'package:tripbybid/features/trips/domain/entities/bid.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_detail.dart';
import 'package:tripbybid/features/trips/domain/usecases/trip_actions.dart';
import 'package:tripbybid/features/trips/domain/usecases/trip_queries.dart';
import 'package:tripbybid/features/trips/presentation/detail/trip_detail_cubit.dart';

import '../../trips_fakes.dart';

const checkoutSession = CheckoutSession(
  paymentId: 'pay-1',
  orderId: 'BID_pay-1',
  sessionId: 'session-1',
  amount: 17999,
);

/// In-memory [PaymentsRepository]; calls are recorded in [calls].
class FakePaymentsRepository implements PaymentsRepository {
  Result<PaymentSummary> summaryResult = const Ok(
    PaymentSummary(
      bidId: 'bid-1',
      total: 17999,
      baseFare: 17699,
      serviceCharge: 300,
    ),
  );
  Result<CheckoutSession> checkoutResult = const Ok(checkoutSession);
  Result<String> confirmResult = const Ok('booking-1');
  final calls = <String>[];

  @override
  Future<Result<PaymentSummary>> getSummary(String bidId) async {
    calls.add('getSummary:$bidId');
    return summaryResult;
  }

  @override
  Future<Result<CheckoutSession>> startCheckout(String bidId) async {
    calls.add('startCheckout:$bidId');
    return checkoutResult;
  }

  @override
  Future<Result<String>> confirmAndBook({
    required String paymentId,
    required String bidId,
  }) async {
    calls.add('confirmAndBook:$paymentId:$bidId');
    return confirmResult;
  }

  @override
  Future<Result<List<PaymentRecord>>> getHistory() async =>
      const Err(ServerFailure('not scripted'));
}

/// Scripted gateway checkout.
class FakePaymentGateway implements PaymentGateway {
  GatewayOutcome outcome = GatewayOutcome.completed;
  int opened = 0;

  @override
  Future<GatewayOutcome> pay(CheckoutSession session) async {
    opened++;
    return outcome;
  }
}

/// A [TripDetailCubit] on top of the fakes, without polling.
TripDetailCubit buildDetailCubit(
  FakeTripsRepository trips,
  FakePaymentsRepository payments,
  FakePaymentGateway gateway,
) => TripDetailCubit(
  getTripDetail: GetTripDetailUseCase(trips),
  getPaymentSummary: GetPaymentSummaryUseCase(payments),
  payForBid: PayForBidUseCase(payments, gateway),
  acceptBid: AcceptBidUseCase(trips),
  releaseBid: ReleaseBidUseCase(trips),
  cancelTrip: CancelTripUseCase(trips),
  updateTrip: UpdateTripUseCase(trips),
  getCancellationQuote: GetCancellationQuoteUseCase(trips),
  cancelBooking: CancelBookingUseCase(trips),
  verifyTicket: VerifyTicketUseCase(trips),
  requestCorrection: RequestCorrectionUseCase(trips),
  raiseSupportTicket: RaiseSupportTicketUseCase(trips),
  rateAgent: RateAgentUseCase(trips),
  pollInterval: null,
);

/// Trip details at each stage of the booking.
abstract final class DetailFixtures {
  static const requestId = 'a9c3e05f-0000-4000-8000-000000000001';

  static final airTrek = TripFixtures.bid();
  static final skyWays = TripFixtures.bid(
    id: 'bid-2',
    price: 18450,
    agentName: 'SkyWays Travel',
  );

  static TripDetail bidsIn() => TripDetail(
    request: TripFixtures.request(bidsCount: 2, bids: [airTrek, skyWays]),
    activeBids: [airTrek, skyWays],
  );

  static Bid accepted({DateTime? dueAt}) => TripFixtures.bid(
    status: BidStatus.accepted,
    paymentDueAt: dueAt ?? DateTime.now().add(const Duration(hours: 5)),
  );

  static TripDetail paymentDue({DateTime? dueAt}) => TripDetail(
    request: TripFixtures.request(
      status: 'payment_pending',
      bidsCount: 2,
      bids: [
        accepted(dueAt: dueAt),
        skyWays,
      ],
    ),
    activeBids: const [],
  );

  static TripDetail booked({String status = 'confirmed'}) {
    final booking = TripFixtures.booking(status: status);
    return TripDetail(
      request: TripFixtures.request(
        status: status,
        bidsCount: 2,
        bids: [
          TripFixtures.bid(status: BidStatus.selected),
          skyWays,
        ],
        booking: booking,
      ),
      activeBids: const [],
      booking: booking,
    );
  }

  static TripDetail completed() => booked(status: 'completed');

  static const quote = CancellationQuote(
    fare: 17999,
    charge: 3000,
    platformFee: 300,
    platformFeeKept: true,
    refund: 14699,
  );
}
