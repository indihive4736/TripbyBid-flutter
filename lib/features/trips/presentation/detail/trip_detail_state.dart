part of 'trip_detail_cubit.dart';

enum DetailTab {
  overview,
  bids,
  timeline,
  docs;

  static DetailTab? parse(String? value) =>
      values.where((t) => t.name == value).firstOrNull;
}

enum BidSort { price, rating }

/// The action currently running (buttons show a spinner / "Processing…").
enum DetailAction {
  accept,
  pay,
  release,
  cancelRequest,
  cancelBooking,
  update,
  verify,
  correction,
  support,
  rate,
}

/// Which icon a toast uses.
enum NoticeIcon {
  success,
  accepted,
  paid,
  payCancelled,
  released,
  cancelled,
  edited,
  rated,
  refund,
  error,
}

/// A one-shot message for a toast. [seq] makes repeats distinct.
final class DetailNotice extends Equatable {
  const DetailNotice(this.message, this.icon, this.seq);

  final String message;
  final NoticeIcon icon;
  final int seq;

  @override
  List<Object?> get props => [message, icon, seq];
}

/// How an action started from a sheet or button ended.
sealed class ActionOutcome {
  const ActionOutcome();
}

final class ActionDone extends ActionOutcome {
  const ActionDone();
}

final class ActionFailed extends ActionOutcome {
  const ActionFailed(this.message);

  final String message;
}

/// The traveler closed the payment checkout without paying.
final class ActionAbandoned extends ActionOutcome {
  const ActionAbandoned();
}

/// Another action was already running; nothing happened.
final class ActionIgnored extends ActionOutcome {
  const ActionIgnored();
}

/// The cancellation refund changed since it was quoted: show [quote].
final class RefundChanged extends ActionOutcome {
  const RefundChanged(this.quote);

  final CancellationQuote quote;
}

sealed class TripDetailState extends Equatable {
  const TripDetailState();

  @override
  List<Object?> get props => [];
}

final class TripDetailLoading extends TripDetailState {
  const TripDetailLoading();
}

final class TripDetailFailure extends TripDetailState {
  const TripDetailFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class TripDetailLoaded extends TripDetailState {
  const TripDetailLoaded({
    required this.detail,
    required this.tab,
    this.selectedBidId,
    this.sort = BidSort.price,
    this.rated = false,
    this.busy,
    this.notice,
    this.summary,
  });

  final TripDetail detail;
  final DetailTab tab;

  /// The offer the traveler picked to accept (while bids are in).
  final String? selectedBidId;
  final BidSort sort;

  /// The agent was rated during this session.
  final bool rated;
  final DetailAction? busy;
  final DetailNotice? notice;

  /// Price breakdown of the accepted bid, before payment.
  final PaymentSummary? summary;

  TripStage get stage => detail.request.stage;

  Bid? get selectedBid =>
      detail.activeBids.where((b) => b.id == selectedBidId).firstOrNull;

  /// [TripDetail.comparableBids] in the chosen order.
  List<Bid> get sortedBids {
    final bids = detail.comparableBids;
    if (sort == BidSort.rating) {
      bids.sort((a, b) {
        final byRating = b.agentRating.compareTo(a.agentRating);
        return byRating != 0 ? byRating : a.price.compareTo(b.price);
      });
    }
    return bids;
  }

  static const _keep = Object();

  TripDetailLoaded copyWith({
    TripDetail? detail,
    DetailTab? tab,
    Object? selectedBidId = _keep,
    BidSort? sort,
    bool? rated,
    Object? busy = _keep,
    Object? notice = _keep,
    Object? summary = _keep,
  }) => TripDetailLoaded(
    detail: detail ?? this.detail,
    tab: tab ?? this.tab,
    selectedBidId: identical(selectedBidId, _keep)
        ? this.selectedBidId
        : selectedBidId as String?,
    sort: sort ?? this.sort,
    rated: rated ?? this.rated,
    busy: identical(busy, _keep) ? this.busy : busy as DetailAction?,
    notice: identical(notice, _keep) ? this.notice : notice as DetailNotice?,
    summary: identical(summary, _keep)
        ? this.summary
        : summary as PaymentSummary?,
  );

  @override
  List<Object?> get props => [
    detail,
    tab,
    selectedBidId,
    sort,
    rated,
    busy,
    notice,
    summary,
  ];
}
