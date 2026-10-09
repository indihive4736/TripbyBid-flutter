import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/payments/domain/entities/checkout.dart';
import 'package:tripbybid/features/trips/domain/entities/bid.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_detail.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_stage.dart';
import 'package:tripbybid/features/trips/presentation/detail/trip_detail_cubit.dart';

import '../../trips_fakes.dart';
import 'detail_fakes.dart';

const _id = DetailFixtures.requestId;

TypeMatcher<TripDetailLoaded> _loaded() => isA<TripDetailLoaded>();

void main() {
  late FakeTripsRepository trips;
  late FakePaymentsRepository payments;
  late FakePaymentGateway gateway;

  setUp(() {
    trips = FakeTripsRepository();
    payments = FakePaymentsRepository();
    gateway = FakePaymentGateway();
  });

  TripDetailCubit build() => buildDetailCubit(trips, payments, gateway);

  TripDetailLoaded loadedOf(TripDetailCubit cubit) =>
      cubit.state as TripDetailLoaded;

  group('load', () {
    blocTest<TripDetailCubit, TripDetailState>(
      'opens Bids with the cheapest offer selected while bids are in',
      setUp: () => trips.detailResult = Ok(DetailFixtures.bidsIn()),
      build: build,
      act: (c) => c.load(_id),
      expect: () => [
        const TripDetailLoading(),
        _loaded()
            .having((s) => s.tab, 'tab', DetailTab.bids)
            .having((s) => s.selectedBidId, 'selected', 'bid-1')
            .having((s) => s.stage, 'stage', TripStage.bidsIn),
      ],
    );

    blocTest<TripDetailCubit, TripDetailState>(
      'honours the initial tab',
      setUp: () => trips.detailResult = Ok(DetailFixtures.booked()),
      build: build,
      act: (c) => c.load(_id, initialTab: 'docs'),
      skip: 1,
      expect: () => [
        _loaded()
            .having((s) => s.tab, 'tab', DetailTab.docs)
            .having((s) => s.selectedBidId, 'selected', isNull),
      ],
    );

    blocTest<TripDetailCubit, TripDetailState>(
      'fetches the price breakdown when payment is due',
      setUp: () => trips.detailResult = Ok(DetailFixtures.paymentDue()),
      build: build,
      act: (c) => c.load(_id),
      skip: 1,
      expect: () => [
        _loaded()
            .having((s) => s.tab, 'tab', DetailTab.overview)
            .having((s) => s.summary, 'summary', isNull),
        _loaded().having((s) => s.summary?.serviceCharge, 'fee', 300),
      ],
      verify: (_) => expect(payments.calls, ['getSummary:bid-1']),
    );

    blocTest<TripDetailCubit, TripDetailState>(
      'reports a failure',
      setUp: () => trips.detailResult = const Err(NetworkFailure()),
      build: build,
      act: (c) => c.load(_id),
      expect: () => [
        const TripDetailLoading(),
        const TripDetailFailure(
          'Could not reach the server. Check your connection.',
        ),
      ],
    );
  });

  test('refresh keeps the tab and the selected bid', () async {
    trips.detailResult = Ok(DetailFixtures.bidsIn());
    final cubit = build();
    await cubit.load(_id);
    cubit
      ..selectBid('bid-2')
      ..selectTab(DetailTab.timeline);

    await cubit.refresh();

    expect(loadedOf(cubit).selectedBidId, 'bid-2');
    expect(loadedOf(cubit).tab, DetailTab.timeline);
    expect(
      trips.calls.where((c) => c.startsWith('getTripDetail')),
      hasLength(2),
    );
    await cubit.close();
  });

  group('accept (bids in)', () {
    test('accepts the selected bid, reloads and holds the fare', () async {
      trips.detailResult = Ok(DetailFixtures.bidsIn());
      final cubit = build();
      await cubit.load(_id);
      cubit.selectBid('bid-2');
      final due = DateTime(2026, 10, 2, 11, 2);
      trips
        ..acceptResult = Ok(
          TripFixtures.bid(
            id: 'bid-2',
            status: BidStatus.accepted,
            paymentDueAt: due,
          ),
        )
        ..detailResult = Ok(DetailFixtures.paymentDue(dueAt: due));

      final outcome = await cubit.accept();

      expect(outcome, isA<ActionDone>());
      expect(trips.calls, [
        'getTripDetail:$_id',
        'acceptBid:bid-2',
        'getTripDetail:$_id',
      ]);
      final state = loadedOf(cubit);
      expect(state.stage, TripStage.paymentDue);
      expect(state.tab, DetailTab.overview);
      expect(state.busy, isNull);
      expect(
        state.notice?.message,
        'Bid accepted — fare held until 2 Oct, 11:02',
      );
      await cubit.close();
    });

    blocTest<TripDetailCubit, TripDetailState>(
      'shows the error and stays on the bids',
      setUp: () {
        trips
          ..detailResult = Ok(DetailFixtures.bidsIn())
          ..acceptResult = const Err(ServerFailure('Bid is no longer active'));
      },
      build: build,
      act: (c) async {
        await c.load(_id);
        await c.accept();
      },
      skip: 2,
      expect: () => [
        _loaded().having((s) => s.busy, 'busy', DetailAction.accept),
        _loaded()
            .having((s) => s.busy, 'busy', isNull)
            .having((s) => s.stage, 'stage', TripStage.bidsIn)
            .having(
              (s) => s.notice?.message,
              'notice',
              'Bid is no longer active',
            ),
      ],
    );
  });

  group('pay (payment due)', () {
    setUp(() => trips.detailResult = Ok(DetailFixtures.paymentDue()));

    test('booked: reloads to the booking and confirms', () async {
      final cubit = build();
      await cubit.load(_id);
      trips.detailResult = Ok(DetailFixtures.booked());

      final outcome = await cubit.pay();

      expect(outcome, isA<ActionDone>());
      expect(payments.calls, [
        'getSummary:bid-1',
        'startCheckout:bid-1',
        'confirmAndBook:pay-1:bid-1',
      ]);
      final state = loadedOf(cubit);
      expect(state.stage, TripStage.awaitingTicket);
      expect(state.detail.booking?.id, 'booking-1');
      expect(state.tab, DetailTab.overview);
      expect(state.busy, isNull);
      expect(
        state.notice?.message,
        'Payment successful — agent will issue your ticket',
      );
      await cubit.close();
    });

    test('abandoned: nothing is booked and the traveler is told', () async {
      gateway.outcome = GatewayOutcome.cancelled;
      final cubit = build();
      await cubit.load(_id);

      final outcome = await cubit.pay();

      expect(outcome, isA<ActionAbandoned>());
      expect(payments.calls, isNot(contains(startsWith('confirmAndBook'))));
      expect(trips.calls, ['getTripDetail:$_id']);
      expect(loadedOf(cubit).notice?.message, 'Payment cancelled');
      expect(loadedOf(cubit).busy, isNull);
      await cubit.close();
    });

    test('error: returns the message for the sheet', () async {
      payments.checkoutResult = const Err(
        ServerFailure('The payment deadline for this bid has passed'),
      );
      final cubit = build();
      await cubit.load(_id);

      final outcome = await cubit.pay();

      expect(
        outcome,
        isA<ActionFailed>().having(
          (o) => o.message,
          'message',
          'The payment deadline for this bid has passed',
        ),
      );
      expect(loadedOf(cubit).busy, isNull);
      expect(loadedOf(cubit).notice, isNull);
      expect(loadedOf(cubit).stage, TripStage.paymentDue);
      await cubit.close();
    });
  });

  test('release gives up the accepted offer and goes back to bids', () async {
    trips
      ..detailResult = Ok(DetailFixtures.paymentDue())
      ..releaseResult = Ok(TripFixtures.bid());
    final cubit = build();
    await cubit.load(_id);
    trips.detailResult = Ok(DetailFixtures.bidsIn());

    expect(await cubit.release(), isA<ActionDone>());
    expect(trips.calls, contains('releaseBid:bid-1'));
    expect(loadedOf(cubit).tab, DetailTab.bids);
    await cubit.close();
  });

  test('cancelRequest withdraws the request', () async {
    trips.detailResult = Ok(DetailFixtures.bidsIn());
    final cubit = build();
    await cubit.load(_id);

    expect(await cubit.cancelRequest(), isA<ActionDone>());
    expect(trips.calls, contains('cancelTrip:$_id'));
    await cubit.close();
  });

  group('cancel booking', () {
    setUp(() => trips.detailResult = Ok(DetailFixtures.booked()));

    test('cancels at the quoted refund', () async {
      trips.cancelBookingResult = Ok(TripFixtures.booking(status: 'cancelled'));
      final cubit = build();
      await cubit.load(_id);

      final outcome = await cubit.cancelBooking(
        quote: DetailFixtures.quote,
        reason: 'Plans changed',
      );

      expect(outcome, isA<ActionDone>());
      expect(trips.calls, contains('cancelBooking:booking-1:14699.0'));
      expect(loadedOf(cubit).tab, DetailTab.timeline);
      await cubit.close();
    });

    test('a changed refund re-quotes instead of cancelling', () async {
      const fresh = CancellationQuote(
        fare: 17999,
        charge: 6000,
        platformFee: 300,
        platformFeeKept: true,
        refund: 11699,
      );
      trips
        ..cancelBookingResult = const Err(
          ServerFailure(
            'The refund for this booking has changed; please review the new '
            'quote',
            statusCode: 409,
          ),
        )
        ..quoteResult = const Ok(fresh);
      final cubit = build();
      await cubit.load(_id);

      final outcome = await cubit.cancelBooking(quote: DetailFixtures.quote);

      expect(
        outcome,
        isA<RefundChanged>().having((o) => o.quote.refund, 'refund', 11699),
      );
      expect(trips.calls.last, 'getCancellationQuote:booking-1');
      expect(
        loadedOf(cubit).notice?.message,
        'The refund changed — please review',
      );
      expect(loadedOf(cubit).busy, isNull);
      await cubit.close();
    });
  });

  group('rate (completed)', () {
    setUp(() => trips.detailResult = Ok(DetailFixtures.completed()));

    blocTest<TripDetailCubit, TripDetailState>(
      'marks the agent rated',
      build: build,
      act: (c) async {
        await c.load(_id);
        await c.rate(rating: 5, comment: 'On time');
      },
      skip: 2,
      expect: () => [
        _loaded().having((s) => s.busy, 'busy', DetailAction.rate),
        _loaded()
            .having((s) => s.rated, 'rated', isTrue)
            .having((s) => s.busy, 'busy', isNull),
      ],
      verify: (_) => expect(trips.calls.last, 'rateAgent:booking-1:5'),
    );

    test('an already-reviewed booking counts as rated', () async {
      trips.rateResult = const Err(
        ServerFailure(
          'You have already reviewed this booking',
          statusCode: 409,
        ),
      );
      final cubit = build();
      await cubit.load(_id);

      expect(await cubit.rate(rating: 4), isA<ActionDone>());
      expect(loadedOf(cubit).rated, isTrue);
      await cubit.close();
    });

    test('other errors are returned and nothing is marked', () async {
      trips.rateResult = const Err(
        ServerFailure('A booking can be reviewed once it is completed'),
      );
      final cubit = build();
      await cubit.load(_id);

      expect(await cubit.rate(rating: 4), isA<ActionFailed>());
      expect(loadedOf(cubit).rated, isFalse);
      await cubit.close();
    });
  });

  test('selecting a bid is ignored once bids are closed', () async {
    trips.detailResult = Ok(DetailFixtures.paymentDue());
    final cubit = build();
    await cubit.load(_id);

    cubit.selectBid('bid-2');

    expect(loadedOf(cubit).selectedBidId, isNull);
    await cubit.close();
  });

  test('sorting by rating puts the best-rated agent first', () async {
    final detail = TripDetail(
      request: TripFixtures.request(bidsCount: 2),
      activeBids: [
        DetailFixtures.airTrek,
        Bid(
          id: 'bid-3',
          requestId: _id,
          agentId: 'a3',
          price: 25000,
          status: BidStatus.active,
          agentName: 'Top Agent',
          agentRating: 5,
          createdAt: DateTime(2026, 10, 1),
        ),
      ],
    );
    trips.detailResult = Ok(detail);
    final cubit = build();
    await cubit.load(_id);

    expect(loadedOf(cubit).sortedBids.first.id, 'bid-1');
    cubit.setSort(BidSort.rating);
    expect(loadedOf(cubit).sortedBids.first.id, 'bid-3');
    await cubit.close();
  });
}
