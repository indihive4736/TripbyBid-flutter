import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/headings.dart';
import 'new_request_cubit.dart';
import 'widgets/details_step.dart';
import 'widgets/route_step.dart';

/// The new-request flow, given a [NewRequestCubit] (and a `PlaceSearchCubit`
/// for the place picker) above it.
class NewRequestView extends StatefulWidget {
  const NewRequestView({super.key, this.onPosted});

  /// Where to go once posted; defaults to replacing this screen with the
  /// new request's booking detail.
  final void Function(BuildContext context, String requestId)? onPosted;

  @override
  State<NewRequestView> createState() => _NewRequestViewState();
}

class _NewRequestViewState extends State<NewRequestView> {
  final _scroll = ScrollController();
  late final TextEditingController _area;
  late final TextEditingController _phone;
  late final TextEditingController _notes;
  late final TextEditingController _airline;

  @override
  void initState() {
    super.initState();
    final s = context.read<NewRequestCubit>().state;
    _area = TextEditingController(text: s.area);
    _phone = TextEditingController(text: s.phone);
    _notes = TextEditingController(text: s.notes);
    _airline = TextEditingController(text: s.preferredAirline);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _area.dispose();
    _phone.dispose();
    _notes.dispose();
    _airline.dispose();
    super.dispose();
  }

  void _toTop() {
    if (!_scroll.hasClients) return;
    unawaited(
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _posted(String id) {
    showAppToast(
      context,
      'Request posted — agents are bidding',
      icon: Symbols.gavel_rounded,
    );
    final onPosted = widget.onPosted;
    if (onPosted != null) {
      onPosted(context, id);
    } else {
      context.pushReplacement(AppRoutes.trip(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NewRequestCubit>();
    final (step, submitting) = context.select(
      (NewRequestCubit c) => (c.state.step, c.state.submitting),
    );

    return MultiBlocListener(
      listeners: [
        BlocListener<NewRequestCubit, NewRequestState>(
          listenWhen: (a, b) => b.createdId != null && a.createdId == null,
          listener: (context, state) => _posted(state.createdId!),
        ),
        BlocListener<NewRequestCubit, NewRequestState>(
          listenWhen: (a, b) => a.type != b.type,
          listener: (context, state) {
            _area.text = state.area;
            _airline.text = state.preferredAirline;
          },
        ),
        BlocListener<NewRequestCubit, NewRequestState>(
          listenWhen: (a, b) => a.step != b.step,
          listener: (context, state) => _toTop(),
        ),
      ],
      child: PopScope(
        canPop: step == 1 && !submitting,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && step == 2 && !submitting) cubit.backToRoute();
        },
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    controller: _scroll,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 150),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(
                          step: step,
                          onClose: _close,
                          onBack: submitting ? null : cubit.backToRoute,
                        ),
                        const SizedBox(height: 18),
                        DisplayHeading(
                          lead: step == 1 ? 'Where to ' : 'A few ',
                          accent: step == 1 ? 'next?' : 'details.',
                          size: 34,
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          child: step == 1
                              ? RouteStep(
                                  key: const ValueKey(1),
                                  areaController: _area,
                                )
                              : DetailsStep(
                                  key: const ValueKey(2),
                                  phoneController: _phone,
                                  notesController: _notes,
                                  airlineController: _airline,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _BottomBar(
                    step: step,
                    submitting: submitting,
                    onContinue: () {
                      FocusScope.of(context).unfocus();
                      if (!cubit.continueToDetails()) _toTop();
                    },
                    onPost: () {
                      FocusScope.of(context).unfocus();
                      unawaited(cubit.submit());
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.step, required this.onClose, this.onBack});

  final int step;
  final VoidCallback onClose;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        step == 1
            ? AppIconButton(
                icon: Symbols.close_rounded,
                tooltip: 'Close',
                onPressed: onClose,
              )
            : AppIconButton(
                icon: Symbols.arrow_back_rounded,
                tooltip: 'Back to route and budget',
                onPressed: onBack,
              ),
        Expanded(
          child: Text(
            'STEP $step OF 2',
            textAlign: TextAlign.center,
            style: AppTypography.eyebrow(
              size: 12,
              tracking: 0.12,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.step,
    required this.submitting,
    required this.onContinue,
    required this.onPost,
  });

  final int step;
  final bool submitting;
  final VoidCallback onContinue;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    final message = context.select((NewRequestCubit c) => c.state.message);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottom > 0 ? bottom : 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00F3EDE3), AppColors.paper],
          stops: [0, 0.3],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (step == 2 && message != null) ...[
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.dangerTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Symbols.error_rounded,
                      size: 18,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: AppTypography.body(
                          13,
                          color: AppColors.accentOnTint,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (step == 1)
            AppButton(
              key: const Key('new-request-continue'),
              label: 'Continue',
              icon: Symbols.arrow_forward_rounded,
              onPressed: onContinue,
            )
          else
            AppButton(
              key: const Key('new-request-post'),
              label: 'Post request',
              icon: Symbols.send_rounded,
              loading: submitting,
              onPressed: onPost,
            ),
        ],
      ),
    );
  }
}
