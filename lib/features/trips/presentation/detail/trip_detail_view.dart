import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/format/formatters.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/segmented_tabs.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/trip_stage.dart';
import 'detail_labels.dart';
import 'sheets/cancel_booking_sheet.dart';
import 'sheets/pay_sheet.dart';
import 'sheets/rate_sheet.dart';
import 'sheets/request_sheets.dart';
import 'sheets/sheet_common.dart';
import 'sheets/ticket_sheets.dart';
import 'trip_detail_cubit.dart';
import 'widgets/action_bar.dart';
import 'widgets/bids_tab.dart';
import 'widgets/detail_header.dart';
import 'widgets/docs_tab.dart';
import 'widgets/overview_tab.dart';
import 'widgets/progress_card.dart';
import 'widgets/timeline_tab.dart';

/// The booking detail: one screen that adapts to the trip's stage.
class TripDetailView extends StatelessWidget {
  const TripDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripDetailCubit, TripDetailState>(
      listenWhen: (previous, current) {
        if (current is! TripDetailLoaded || current.notice == null) {
          return false;
        }
        return previous is! TripDetailLoaded ||
            previous.notice != current.notice;
      },
      listener: (context, state) {
        final notice = (state as TripDetailLoaded).notice!;
        showAppToast(context, notice.message, icon: noticeIcon(notice.icon));
      },
      builder: (context, state) => switch (state) {
        TripDetailLoading() => const _Bare(child: LoadingView()),
        TripDetailFailure(:final message) => _Bare(
          child: StateMessage.error(
            message: message,
            onRetry: () => context.read<TripDetailCubit>().refresh(),
          ),
        ),
        TripDetailLoaded() => _LoadedView(state: state),
      },
    );
  }
}

void _back(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.trips);
  }
}

/// Loading and error states: a plain page with a back button.
class _Bare extends StatelessWidget {
  const _Bare({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: AppIconButton(
                icon: Symbols.arrow_back_rounded,
                tooltip: 'Back',
                onPressed: () => _back(context),
              ),
            ),
            Expanded(
              child: Center(child: SingleChildScrollView(child: child)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});

  final TripDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripDetailCubit>();
    final detail = state.detail;
    final stage = detail.stage;
    final actions = _Actions(context, state);
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: cubit.refresh,
              edgeOffset: MediaQuery.paddingOf(context).top,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: 130 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  DetailHeader(
                    detail: detail,
                    onBack: () => _back(context),
                    onCopyId: actions.copyId,
                    onShare: actions.share,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: ProgressCard(
                      stage: stage,
                      holdUntil: detail.chosenBid?.paymentDueAt,
                      onHoldExpired: () => cubit.refresh(silent: true),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: SegmentedTabs<DetailTab>(
                      height: 38,
                      selected: state.tab,
                      onChanged: cubit.selectTab,
                      options: [
                        const SegmentOption(
                          value: DetailTab.overview,
                          label: 'Overview',
                        ),
                        SegmentOption(
                          value: DetailTab.bids,
                          label: 'Bids',
                          badge: stage == TripStage.bidsIn
                              ? detail.activeBids.length
                              : null,
                        ),
                        const SegmentOption(
                          value: DetailTab.timeline,
                          label: 'Timeline',
                        ),
                        const SegmentOption(
                          value: DetailTab.docs,
                          label: 'Docs',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: KeyedSubtree(
                        key: ValueKey(state.tab),
                        child: _tab(context, actions),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _actionBar(actions),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, _Actions actions) {
    final cubit = context.read<TripDetailCubit>();
    return switch (state.tab) {
      DetailTab.overview => OverviewTab(
        state: state,
        onChat: actions.chat,
        onCancel: actions.cancel,
        onEdit: actions.edit,
        onRelease: actions.release,
        onHelp: actions.help,
        onUnavailable: actions.info,
      ),
      DetailTab.bids => BidsTab(
        state: state,
        onSelect: cubit.selectBid,
        onSort: cubit.setSort,
        onLocked: actions.info,
      ),
      DetailTab.timeline => TimelineTab(detail: state.detail),
      DetailTab.docs => DocsTab(
        detail: state.detail,
        onOpenTicket: actions.openUrl,
        onSummary: actions.summary,
        onLocked: (why) => actions.info(why, Symbols.lock_rounded),
      ),
    };
  }

  Widget _actionBar(_Actions actions) {
    final detail = state.detail;
    final stage = detail.stage;
    final booked = detail.booking != null && stage != TripStage.cancelled;
    final agent = detail.agentFirstName ?? 'agent';
    final (icon, label, style, onPressed, loading) = switch (stage) {
      TripStage.awaitingBids => (
        Symbols.edit_rounded,
        'Edit request',
        AppButtonStyle.accent,
        actions.edit,
        false,
      ),
      TripStage.bidsIn => _accept(actions),
      TripStage.paymentDue => (
        Symbols.lock_rounded,
        'Pay ${Fmt.inr(state.summary?.total ?? detail.fare ?? 0)}',
        AppButtonStyle.accent,
        actions.pay,
        false,
      ),
      TripStage.awaitingConfirmation ||
      TripStage.awaitingTicket ||
      TripStage.needsAttention => (
        Symbols.chat_rounded,
        'Message agent',
        AppButtonStyle.ink,
        actions.chat,
        false,
      ),
      TripStage.ticketReady => (
        Symbols.fact_check_rounded,
        'Check ticket',
        AppButtonStyle.accent,
        actions.ticket,
        false,
      ),
      TripStage.completed when state.rated => (
        Symbols.replay_rounded,
        'Book this trip again',
        AppButtonStyle.ink,
        actions.newRequest,
        false,
      ),
      TripStage.completed => (
        Symbols.star_rounded,
        'Rate $agent',
        AppButtonStyle.accent,
        actions.rate,
        false,
      ),
      TripStage.cancelled || TripStage.expired => (
        Symbols.add_rounded,
        'Post a similar request',
        AppButtonStyle.ink,
        actions.newRequest,
        false,
      ),
    };
    return DetailActionBar(
      secondaryIcon: booked ? Symbols.chat_rounded : Symbols.ios_share_rounded,
      secondaryTooltip: booked ? 'Message agent' : 'Share trip',
      onSecondary: booked ? actions.chat : actions.share,
      icon: icon,
      label: label,
      style: style,
      onPrimary: onPressed,
      loading: loading,
    );
  }

  (IconData, String, AppButtonStyle, VoidCallback?, bool) _accept(
    _Actions actions,
  ) {
    final bid = state.selectedBid;
    final busy = state.busy == DetailAction.accept;
    if (bid == null) {
      return (
        Symbols.handshake_rounded,
        'Pick a bid to accept',
        AppButtonStyle.accent,
        null,
        false,
      );
    }
    final first = bid.agentName.trim().split(RegExp(r'\s+')).first;
    return (
      Symbols.handshake_rounded,
      'Accept $first · ${Fmt.inr(bid.price)}',
      AppButtonStyle.accent,
      actions.accept,
      busy,
    );
  }
}

/// What the buttons, tiles and sheets of the loaded screen do.
class _Actions {
  _Actions(this.context, this.state);

  final BuildContext context;
  final TripDetailLoaded state;

  TripDetailCubit get _cubit => context.read<TripDetailCubit>();

  void info(String message, [IconData icon = Symbols.info_rounded]) =>
      showAppToast(context, message, icon: icon);

  void copyId() {
    Clipboard.setData(ClipboardData(text: state.detail.reference));
    info('Booking ID copied', Symbols.content_copy_rounded);
  }

  void share() {
    Clipboard.setData(ClipboardData(text: state.detail.shareText));
    info('Trip details copied — paste to share', Symbols.link_rounded);
  }

  void chat() {
    final booking = state.detail.booking;
    if (booking == null) {
      info("Chat opens once you've paid", Symbols.chat_rounded);
      return;
    }
    context.push(AppRoutes.chat(booking.id));
  }

  void newRequest() =>
      context.push(AppRoutes.newRequestOf(state.detail.requestType));

  void accept() => _cubit.accept();

  void pay() => showDetailSheet<void>(context, const PaySheet());

  void edit() => showDetailSheet<void>(
    context,
    EditRequestSheet(
      request: state.detail.request,
      budgetEditable: state.stage == TripStage.awaitingBids,
    ),
  );

  void summary() => showDetailSheet<void>(
    context,
    RequestSummarySheet(request: state.detail.request),
  );

  void rate() => showDetailSheet<void>(
    context,
    RateSheet(agentName: state.detail.agentName ?? 'your agent'),
  );

  Future<void> ticket() async {
    final result = await showDetailSheet<String>(
      context,
      TicketSheet(onOpen: openUrl),
    );
    if (result == ticketSheetReportProblem && context.mounted) {
      await showDetailSheet<void>(context, const CorrectionSheet());
    }
  }

  Future<void> cancel() async {
    final stage = state.stage;
    if (state.detail.booking != null && stage.isBooked) {
      await showDetailSheet<void>(context, const CancelBookingSheet());
      return;
    }
    final confirmed = await confirmSheet(
      context,
      title: 'Cancel this request?',
      message: stage == TripStage.paymentDue
          ? 'The held fare is released and nothing is charged.'
          : 'Agents stop bidding and nothing is charged.',
      confirmLabel: 'Yes, cancel',
      cancelLabel: 'Keep request',
    );
    if (confirmed && context.mounted) await _cubit.cancelRequest();
  }

  Future<void> release() async {
    final confirmed = await confirmSheet(
      context,
      title: 'Release this offer?',
      message:
          'The fare hold ends and you can accept another bid. The agent may '
          'not hold this price again.',
      confirmLabel: 'Release',
      cancelLabel: 'Keep offer',
    );
    if (confirmed && context.mounted) await _cubit.release();
  }

  void help() {
    if (state.detail.booking != null && state.stage.isBooked) {
      showDetailSheet<void>(context, const SupportSheet());
    } else {
      info(
        'Support tickets open once you have paid — see Help in your profile',
        Symbols.support_agent_rounded,
      );
    }
  }

  Future<void> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    final opened =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      info('Could not open the ticket', Symbols.error_rounded);
    }
  }
}
