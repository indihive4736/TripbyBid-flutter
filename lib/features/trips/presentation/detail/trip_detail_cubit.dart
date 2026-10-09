import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/format/formatters.dart';
import '../../../payments/domain/entities/checkout.dart';
import '../../../payments/domain/usecases/payment_usecases.dart';
import '../../domain/entities/bid.dart';
import '../../domain/entities/trip_detail.dart';
import '../../domain/entities/trip_stage.dart';
import '../../domain/usecases/trip_actions.dart';
import '../../domain/usecases/trip_queries.dart';

part 'trip_detail_state.dart';

/// State of the booking-detail screen: the trip, the selected tab and bid,
/// and every action the traveler can take on it at its current stage.
class TripDetailCubit extends Cubit<TripDetailState> {
  TripDetailCubit({
    required GetTripDetailUseCase getTripDetail,
    required GetPaymentSummaryUseCase getPaymentSummary,
    required PayForBidUseCase payForBid,
    required AcceptBidUseCase acceptBid,
    required ReleaseBidUseCase releaseBid,
    required CancelTripUseCase cancelTrip,
    required UpdateTripUseCase updateTrip,
    required GetCancellationQuoteUseCase getCancellationQuote,
    required CancelBookingUseCase cancelBooking,
    required VerifyTicketUseCase verifyTicket,
    required RequestCorrectionUseCase requestCorrection,
    required RaiseSupportTicketUseCase raiseSupportTicket,
    required RateAgentUseCase rateAgent,
    this.pollInterval = const Duration(seconds: 30),
  }) : _getTripDetail = getTripDetail,
       _getPaymentSummary = getPaymentSummary,
       _payForBid = payForBid,
       _acceptBid = acceptBid,
       _releaseBid = releaseBid,
       _cancelTrip = cancelTrip,
       _updateTrip = updateTrip,
       _getCancellationQuote = getCancellationQuote,
       _cancelBooking = cancelBooking,
       _verifyTicket = verifyTicket,
       _requestCorrection = requestCorrection,
       _raiseSupportTicket = raiseSupportTicket,
       _rateAgent = rateAgent,
       super(const TripDetailLoading());

  final GetTripDetailUseCase _getTripDetail;
  final GetPaymentSummaryUseCase _getPaymentSummary;
  final PayForBidUseCase _payForBid;
  final AcceptBidUseCase _acceptBid;
  final ReleaseBidUseCase _releaseBid;
  final CancelTripUseCase _cancelTrip;
  final UpdateTripUseCase _updateTrip;
  final GetCancellationQuoteUseCase _getCancellationQuote;
  final CancelBookingUseCase _cancelBooking;
  final VerifyTicketUseCase _verifyTicket;
  final RequestCorrectionUseCase _requestCorrection;
  final RaiseSupportTicketUseCase _raiseSupportTicket;
  final RateAgentUseCase _rateAgent;

  /// How often to re-fetch while bidding or payment is due; null disables.
  final Duration? pollInterval;

  String? _requestId;
  String? _initialTab;
  Timer? _poll;
  Future<void>? _refreshing;
  int _seq = 0;

  Future<void> load(String requestId, {String? initialTab}) async {
    _requestId = requestId;
    _initialTab = initialTab;
    emit(const TripDetailLoading());
    final result = await _getTripDetail(requestId);
    if (isClosed) return;
    switch (result) {
      case Err(:final failure):
        emit(TripDetailFailure(failure.message));
      case Ok(:final value):
        emit(
          TripDetailLoaded(
            detail: value,
            tab: DetailTab.parse(initialTab) ?? _defaultTab(value),
            selectedBidId: _selection(value, null),
          ),
        );
        await _afterLoad(value);
    }
  }

  /// Re-fetches the trip, keeping the tab and selection. [silent] skips the
  /// error toast (background polling).
  Future<void> refresh({bool silent = false}) {
    final id = _requestId;
    if (id == null) return Future.value();
    if (state is! TripDetailLoaded) return load(id, initialTab: _initialTab);
    return _refreshing ??= _refresh(
      id,
      silent,
    ).whenComplete(() => _refreshing = null);
  }

  Future<void> _refresh(String id, bool silent) async {
    final result = await _getTripDetail(id);
    if (isClosed) return;
    final current = state;
    if (current is! TripDetailLoaded) return;
    switch (result) {
      case Err(:final failure):
        if (!silent) _notify(failure.message, NoticeIcon.error);
      case Ok(:final value):
        final sameBid = current.summary?.bidId == value.chosenBid?.id;
        emit(
          current.copyWith(
            detail: value,
            selectedBidId: _selection(value, current.selectedBidId),
            summary: sameBid ? current.summary : null,
          ),
        );
        await _afterLoad(value);
    }
  }

  void selectTab(DetailTab tab) => _update((s) => s.copyWith(tab: tab));

  void selectBid(String bidId) {
    _update(
      (s) => s.stage == TripStage.bidsIn ? s.copyWith(selectedBidId: bidId) : s,
    );
  }

  void setSort(BidSort sort) => _update((s) => s.copyWith(sort: sort));

  /// Accepts the selected bid; its fare is then held until payment.
  Future<ActionOutcome> accept() async {
    final s = _loaded;
    final bidId = s?.selectedBidId;
    if (s == null || bidId == null) {
      return const ActionFailed('Pick a bid first.');
    }
    if (!_start(DetailAction.accept)) return const ActionIgnored();
    final result = await _acceptBid(bidId);
    switch (result) {
      case Err(:final failure):
        return _fail(failure.message, toast: true);
      case Ok(:final value):
        await refresh();
        final due =
            value.paymentDueAt ?? _loaded?.detail.chosenBid?.paymentDueAt;
        _finish(
          due == null
              ? 'Bid accepted — pay to confirm'
              : 'Bid accepted — fare held until ${Fmt.dateTime(due)}',
          NoticeIcon.accepted,
          tab: DetailTab.overview,
        );
        return const ActionDone();
    }
  }

  /// Pays for the accepted bid through the gateway checkout.
  Future<ActionOutcome> pay() async {
    final bid = _loaded?.detail.chosenBid;
    if (bid == null) return const ActionFailed('There is no offer to pay for.');
    if (!_start(DetailAction.pay)) return const ActionIgnored();
    final result = await _payForBid(bid.id);
    switch (result) {
      case Err(:final failure):
        return _fail(failure.message);
      case Ok(value: PaymentAbandoned()):
        _finish('Payment cancelled', NoticeIcon.payCancelled);
        return const ActionAbandoned();
      case Ok(value: PaymentBooked()):
        await refresh();
        _finish(
          'Payment successful — agent will issue your ticket',
          NoticeIcon.paid,
          tab: DetailTab.overview,
        );
        return const ActionDone();
    }
  }

  /// Gives up the accepted offer so another can be accepted.
  Future<ActionOutcome> release() async {
    final bid = _loaded?.detail.request.acceptedBid;
    if (bid == null) return const ActionFailed('There is no offer to release.');
    if (!_start(DetailAction.release)) return const ActionIgnored();
    final result = await _releaseBid(bid.id);
    switch (result) {
      case Err(:final failure):
        return _fail(failure.message, toast: true);
      case Ok():
        await refresh();
        _finish(
          'Offer released — you can pick another bid',
          NoticeIcon.released,
          tab: DetailTab.bids,
        );
        return const ActionDone();
    }
  }

  /// Withdraws the request (before anything is paid).
  Future<ActionOutcome> cancelRequest() async {
    final id = _requestId;
    if (id == null) return const ActionIgnored();
    if (!_start(DetailAction.cancelRequest)) return const ActionIgnored();
    final result = await _cancelTrip(id);
    switch (result) {
      case Err(:final failure):
        return _fail(failure.message, toast: true);
      case Ok():
        await refresh();
        _finish(
          'Request cancelled — nothing was charged',
          NoticeIcon.cancelled,
        );
        return const ActionDone();
    }
  }

  /// Edits the budget (only before bids arrive) and notes.
  Future<ActionOutcome> updateRequest({
    double? budget,
    String? requirements,
  }) async {
    final id = _requestId;
    if (id == null) return const ActionIgnored();
    if (!_start(DetailAction.update)) return const ActionIgnored();
    final result = await _updateTrip(
      UpdateTripParams(id, budget: budget, requirements: requirements),
    );
    switch (result) {
      case Err(:final failure):
        return _fail(failure.message);
      case Ok():
        await refresh();
        _finish('Request updated — agents see the changes', NoticeIcon.edited);
        return const ActionDone();
    }
  }

  /// The refund the traveler would get by cancelling now.
  Future<Result<CancellationQuote>> cancellationQuote() async {
    final bookingId = _loaded?.detail.booking?.id;
    if (bookingId == null) {
      return const Err(ValidationFailure('This trip is not booked.'));
    }
    return _getCancellationQuote(bookingId);
  }

  /// Cancels the paid booking at the refund in [quote]. If the refund has
  /// changed meanwhile, returns [RefundChanged] with the new quote.
  Future<ActionOutcome> cancelBooking({
    required CancellationQuote quote,
    String? reason,
  }) async {
    final bookingId = _bookingId;
    if (bookingId == null) return _notBooked;
    if (!_start(DetailAction.cancelBooking)) return const ActionIgnored();
    final result = await _cancelBooking(
      CancelBookingParams(
        bookingId: bookingId,
        expectedRefund: quote.refund,
        reason: reason,
      ),
    );
    switch (result) {
      case Err(:final failure) when _refundChanged(failure):
        final fresh = await _getCancellationQuote(bookingId);
        switch (fresh) {
          case Ok(:final value):
            _finish('The refund changed — please review', NoticeIcon.refund);
            return RefundChanged(value);
          case Err(failure: final again):
            return _fail(again.message);
        }
      case Err(:final failure):
        return _fail(failure.message);
      case Ok():
        await refresh();
        _finish(
          'Booking cancelled — refund initiated',
          NoticeIcon.cancelled,
          tab: DetailTab.timeline,
        );
        return const ActionDone();
    }
  }

  /// Confirms the uploaded ticket is correct.
  Future<ActionOutcome> verifyTicket() async {
    final bookingId = _bookingId;
    if (bookingId == null) return _notBooked;
    if (!_start(DetailAction.verify)) return const ActionIgnored();
    final result = await _verifyTicket(bookingId);
    switch (result) {
      case Err(:final failure):
        return _fail(failure.message);
      case Ok():
        await refresh();
        _finish('Ticket confirmed — have a great trip', NoticeIcon.success);
        return const ActionDone();
    }
  }

  /// Asks the agent to fix the ticket.
  Future<ActionOutcome> requestCorrection({
    required List<String> reasons,
    String? details,
  }) async {
    final bookingId = _bookingId;
    if (bookingId == null) return _notBooked;
    if (!_start(DetailAction.correction)) return const ActionIgnored();
    final trimmed = details?.trim();
    final result = await _requestCorrection(
      CorrectionParams(
        bookingId,
        reasons: reasons,
        details: trimmed == null || trimmed.isEmpty ? null : trimmed,
      ),
    );
    switch (result) {
      case Err(:final failure):
        return _fail(failure.message);
      case Ok():
        await refresh();
        _finish(
          'Correction requested — your agent will fix it',
          NoticeIcon.success,
        );
        return const ActionDone();
    }
  }

  /// Opens a support ticket on the booking.
  Future<ActionOutcome> raiseSupportTicket(String description) async {
    final bookingId = _bookingId;
    if (bookingId == null) return _notBooked;
    if (!_start(DetailAction.support)) return const ActionIgnored();
    final result = await _raiseSupportTicket(
      SupportTicketParams(bookingId, description: description),
    );
    switch (result) {
      case Err(:final failure):
        return _fail(failure.message);
      case Ok():
        await refresh();
        _finish(
          'Support ticket raised — we will get back to you',
          NoticeIcon.success,
        );
        return const ActionDone();
    }
  }

  /// Rates the agent after a completed trip. A booking that was already
  /// reviewed counts as rated.
  Future<ActionOutcome> rate({required int rating, String? comment}) async {
    final detail = _loaded?.detail;
    final booking = detail?.booking;
    final agentId = booking?.agent?.id ?? detail?.chosenBid?.agentId;
    if (booking == null || agentId == null) {
      return const ActionFailed('This booking has no agent to rate.');
    }
    if (!_start(DetailAction.rate)) return const ActionIgnored();
    final result = await _rateAgent(
      RateAgentParams(
        bookingId: booking.id,
        agentId: agentId,
        rating: rating,
        comment: comment,
      ),
    );
    switch (result) {
      case Err(:final failure)
          when failure.message.toLowerCase().contains('already'):
        _finish(
          'You have already rated this trip',
          NoticeIcon.rated,
          rated: true,
        );
        return const ActionDone();
      case Err(:final failure):
        return _fail(failure.message);
      case Ok():
        _finish(
          'Thanks! Your rating helps others',
          NoticeIcon.rated,
          rated: true,
        );
        return const ActionDone();
    }
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }

  // ---------------------------------------------------------------------------

  static const _notBooked = ActionFailed('This trip is not booked.');

  String? get _bookingId => _loaded?.detail.booking?.id;

  TripDetailLoaded? get _loaded {
    final s = state;
    return s is TripDetailLoaded ? s : null;
  }

  void _update(TripDetailLoaded Function(TripDetailLoaded) change) {
    final s = _loaded;
    if (s != null && !isClosed) emit(change(s));
  }

  /// Marks [action] as running; false when another one already is.
  bool _start(DetailAction action) {
    final s = _loaded;
    if (s == null || s.busy != null) return false;
    emit(s.copyWith(busy: action));
    return true;
  }

  void _finish(
    String message,
    NoticeIcon icon, {
    DetailTab? tab,
    bool? rated,
  }) => _update(
    (s) => s.copyWith(
      busy: null,
      tab: tab,
      rated: rated,
      notice: DetailNotice(message, icon, ++_seq),
    ),
  );

  ActionFailed _fail(String message, {bool toast = false}) {
    _update(
      (s) => s.copyWith(
        busy: null,
        notice: toast ? DetailNotice(message, NoticeIcon.error, ++_seq) : null,
      ),
    );
    return ActionFailed(message);
  }

  void _notify(String message, NoticeIcon icon) =>
      _update((s) => s.copyWith(notice: DetailNotice(message, icon, ++_seq)));

  static bool _refundChanged(Failure failure) =>
      failure is ServerFailure &&
      (failure.statusCode == 409 || failure.statusCode == null) &&
      failure.message.toLowerCase().contains('changed');

  static DetailTab _defaultTab(TripDetail detail) =>
      detail.request.stage == TripStage.bidsIn
      ? DetailTab.bids
      : DetailTab.overview;

  /// Keeps [current] while it is still a live offer, else the cheapest.
  static String? _selection(TripDetail detail, String? current) {
    if (detail.request.stage != TripStage.bidsIn) return null;
    if (detail.activeBids.any((b) => b.id == current)) return current;
    return detail.bestBid?.id;
  }

  Future<void> _afterLoad(TripDetail detail) async {
    _schedulePoll(detail.request.stage);
    final chosen = detail.chosenBid;
    final s = _loaded;
    if (detail.request.stage != TripStage.paymentDue ||
        chosen == null ||
        s?.summary?.bidId == chosen.id) {
      return;
    }
    final result = await _getPaymentSummary(chosen.id);
    if (isClosed) return;
    if (result case Ok(:final value)) {
      _update(
        (s) => s.detail.chosenBid?.id == value.bidId
            ? s.copyWith(summary: value)
            : s,
      );
    }
  }

  void _schedulePoll(TripStage stage) {
    final interval = pollInterval;
    final wanted =
        interval != null && (stage.isBidding || stage == TripStage.paymentDue);
    if (!wanted) {
      _poll?.cancel();
      _poll = null;
      return;
    }
    _poll ??= Timer.periodic(interval, (_) => refresh(silent: true));
  }
}
