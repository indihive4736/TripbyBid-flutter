import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/headings.dart';
import '../../../../core/widgets/ink_panel.dart';
import '../bloc/intro_cubit.dart';
import '../widgets/intro_illustrations.dart';

/// A2–A4 — three intro slides, shown once per device.
class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<IntroCubit>(),
      child: const IntroView(),
    );
  }
}

final class _Slide {
  const _Slide({
    required this.step,
    required this.lead,
    required this.accent,
    required this.trail,
    required this.body,
    required this.art,
  });

  final String step;
  final String lead;
  final String accent;
  final String trail;
  final String body;
  final Widget art;
}

const _slides = [
  _Slide(
    step: 'Step 01',
    lead: 'Post your trip, ',
    accent: 'set',
    trail: ' your price.',
    body:
        'Tell us where you’re going and what you want to pay. '
        'Flights, trains or hotels.',
    art: PostTripArt(),
  ),
  _Slide(
    step: 'Step 02',
    lead: 'Verified agents ',
    accent: 'compete',
    trail: ' for you.',
    body:
        'Compare offers side by side — price, rating and what’s included. '
        'Pick the best one.',
    art: AgentsCompeteArt(),
  ),
  _Slide(
    step: 'Step 03',
    lead: 'Pay securely, ',
    accent: 'travel',
    trail: ' happy.',
    body:
        'Pay only after you accept a bid. Tickets land in the app, your '
        'email and WhatsApp.',
    art: TravelHappyArt(),
  ),
];

/// The intro slides, given an [IntroCubit] above it.
class IntroView extends StatefulWidget {
  const IntroView({super.key});

  @override
  State<IntroView> createState() => _IntroViewState();
}

class _IntroViewState extends State<IntroView> {
  final _pages = PageController();

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    final cubit = context.read<IntroCubit>();
    if (cubit.isLastPage) {
      cubit.finish();
      return;
    }
    final target = cubit.state.page + 1;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(target);
    } else {
      _pages.animateToPage(
        target,
        duration: const Duration(milliseconds: 380),
        curve: const Cubic(0.2, 0.9, 0.2, 1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IntroCubit, IntroState>(
      listenWhen: (previous, current) => !previous.finished && current.finished,
      listener: (context, _) => context.go(AppRoutes.welcome),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 12, 0),
                child: Row(
                  children: [
                    const BrandMark(),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.read<IntroCubit>().finish(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        minimumSize: const Size(56, 44),
                        textStyle: AppTypography.body(
                          15,
                          weight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _slides.length,
                  onPageChanged: context.read<IntroCubit>().pageChanged,
                  itemBuilder: (context, index) =>
                      _SlideView(slide: _slides[index]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                child: BlocBuilder<IntroCubit, IntroState>(
                  builder: (context, state) {
                    final last = state.page == IntroCubit.pageCount - 1;
                    return Row(
                      children: [
                        _PageDots(
                          count: IntroCubit.pageCount,
                          current: state.page,
                        ),
                        const Spacer(),
                        if (last)
                          AppButton(
                            key: const Key('intro_get_started'),
                            label: 'Get started',
                            icon: Symbols.arrow_forward_rounded,
                            height: 60,
                            expand: false,
                            onPressed: _next,
                          )
                        else
                          _NextButton(onPressed: _next),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: FittedBox(fit: BoxFit.scaleDown, child: slide.art),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(slide.step, size: 12),
                    const SizedBox(height: 12),
                    DisplayHeading(
                      lead: slide.lead,
                      accent: slide.accent,
                      trail: slide.trail,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      slide.body,
                      style: AppTypography.body(
                        16,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Slide ${current + 1} of $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: i == current ? 26 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == current
                    ? AppColors.accent
                    : const Color(0x2E0D1B2A),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The 64 px navy arrow button.
class _NextButton extends StatelessWidget {
  const _NextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return Tooltip(
      message: 'Next',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0xCC0D1B2A),
              offset: Offset(0, 14),
              blurRadius: 26,
              spreadRadius: -12,
            ),
          ],
        ),
        child: Material(
          color: AppColors.ink,
          borderRadius: radius,
          child: InkWell(
            key: const Key('intro_next'),
            borderRadius: radius,
            onTap: onPressed,
            child: const SizedBox.square(
              dimension: 64,
              child: Icon(
                Symbols.arrow_forward_rounded,
                size: 24,
                color: AppColors.onInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
