import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'ink_backdrop.dart';

// Static marketing art for the three intro slides. The routes, agents and
// prices are illustrative, like on the web landing page — not user data.

/// The 390×400 stage behind every slide: a soft orange glow, a dashed and a
/// solid ring, then the slide's cards and floating chips on top.
class IntroStage extends StatelessWidget {
  const IntroStage({super.key, required this.children});

  static const size = Size(390, 400);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Decorative art: hidden from screen readers and drawn at a fixed text
    // scale so the cards keep their shape (the stage scales as a whole).
    return ExcludeSemantics(
      child: MediaQuery.withNoTextScaling(
        child: SizedBox.fromSize(
          size: size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 330,
                height: 330,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.16),
                      AppColors.accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              const SizedBox.square(
                dimension: 300,
                child: CustomPaint(painter: _DashedCirclePainter()),
              ),
              Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x140D1B2A)),
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Slide 1: a new DEL → GOI request with its budget meter.
class PostTripArt extends StatelessWidget {
  const PostTripArt({super.key});

  @override
  Widget build(BuildContext context) {
    return const IntroStage(
      children: [
        Positioned(left: 70, top: 70, child: _Tilted(-4, _RequestCard())),
        Positioned(
          right: 44,
          top: 50,
          child: Floating(
            child: _Chip(
              icon: Symbols.bolt_rounded,
              iconColor: AppColors.accentSoft,
              label: 'Takes 30 sec',
              background: AppColors.ink,
              foreground: AppColors.onInk,
              shadow: _inkChipShadow,
            ),
          ),
        ),
        Positioned(
          left: 40,
          bottom: 46,
          child: Floating(
            delay: Duration(milliseconds: 200),
            period: Duration(milliseconds: 3500),
            child: _Chip(
              icon: Symbols.lock_rounded,
              iconColor: AppColors.successOnTint,
              label: 'Free for travelers',
              background: AppColors.successTint,
              foreground: AppColors.successOnTint,
            ),
          ),
        ),
      ],
    );
  }
}

/// Slide 2: three agents' bids stacked, the lowest on top.
class AgentsCompeteArt extends StatelessWidget {
  const AgentsCompeteArt({super.key});

  @override
  Widget build(BuildContext context) {
    return const IntroStage(
      children: [
        Positioned(
          left: 50,
          top: 66,
          child: _Tilted(
            -5,
            _BidCard(
              initials: 'AT',
              name: 'AirTrek India',
              rating: '4.9',
              price: '₹5,420',
              color: Color(0xFFFFB199),
              lowest: true,
            ),
          ),
        ),
        Positioned(
          left: 66,
          top: 170,
          child: _Tilted(
            2,
            _BidCard(
              initials: 'SK',
              name: 'SkyWays Travel',
              rating: '4.8',
              price: '₹5,690',
              color: Color(0xFFB9C4F5),
            ),
          ),
        ),
        Positioned(
          left: 82,
          top: 272,
          child: _Tilted(
            -2,
            _BidCard(
              initials: 'ND',
              name: 'Nomad Desk',
              rating: '4.7',
              price: '₹5,850',
              color: Color(0xFF9ED9C9),
            ),
          ),
        ),
        Positioned(
          right: 30,
          top: 36,
          child: Floating(
            child: _Chip(
              icon: Symbols.gavel_rounded,
              iconColor: AppColors.ink,
              label: '3 new bids',
              background: AppColors.accent,
              foreground: AppColors.ink,
              weight: FontWeight.w800,
              shadow: [
                BoxShadow(
                  color: Color(0xCCFF5A1F),
                  offset: Offset(0, 16),
                  blurRadius: 30,
                  spreadRadius: -12,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Slide 3: a confirmed e-ticket.
class TravelHappyArt extends StatelessWidget {
  const TravelHappyArt({super.key});

  @override
  Widget build(BuildContext context) {
    return const IntroStage(
      children: [
        Positioned(left: 65, top: 78, child: _Tilted(3, _TicketCard())),
        Positioned(
          left: 36,
          top: 52,
          child: Floating(
            child: _Chip(
              icon: Symbols.check_circle_rounded,
              iconColor: AppColors.successOnTint,
              iconFill: true,
              label: 'Confirmed',
              background: AppColors.successTint,
              foreground: AppColors.successOnTint,
              weight: FontWeight.w800,
            ),
          ),
        ),
        Positioned(
          right: 34,
          bottom: 62,
          child: Floating(
            delay: Duration(milliseconds: 200),
            period: Duration(milliseconds: 3500),
            child: _Chip(
              icon: Symbols.savings_rounded,
              iconColor: AppColors.mint,
              label: 'You saved ₹580',
              background: AppColors.ink,
              foreground: AppColors.onInk,
              shadow: _inkChipShadow,
            ),
          ),
        ),
      ],
    );
  }
}

const _inkChipShadow = [
  BoxShadow(
    color: Color(0xB30D1B2A),
    offset: Offset(0, 16),
    blurRadius: 30,
    spreadRadius: -14,
  ),
];

class _Tilted extends StatelessWidget {
  const _Tilted(this.degrees, this.child);

  final double degrees;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Transform.rotate(angle: degrees * math.pi / 180, child: child);
}

/// Cream art card: radius 24, hairline border, deep soft shadow.
class _ArtCard extends StatelessWidget {
  const _ArtCard({required this.width, required this.child, this.padding});

  final double width;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x730D1B2A),
            offset: Offset(0, 30),
            blurRadius: 50,
            spreadRadius: -28,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.background,
    required this.foreground,
    this.iconFill = false,
    this.weight = FontWeight.w700,
    this.shadow,
  });

  final IconData icon;
  final Color iconColor;
  final bool iconFill;
  final String label;
  final Color background;
  final Color foreground;
  final FontWeight weight;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        boxShadow: shadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: iconColor, fill: iconFill ? 1 : 0),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.body(13, color: foreground, weight: weight),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard();

  @override
  Widget build(BuildContext context) {
    final small = AppTypography.body(11, color: AppColors.textTertiary);
    return _ArtCard(
      width: 250,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.flight_rounded,
                size: 15,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'NEW REQUEST',
                  style: AppTypography.eyebrow(
                    color: AppColors.textTertiary,
                    tracking: 0,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Live',
                  style: AppTypography.body(
                    11,
                    color: AppColors.accentOnTint,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DEL', style: AppTypography.number(30)),
                  Text('Delhi', style: small),
                ],
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Icon(
                  Symbols.arrow_forward_rounded,
                  size: 20,
                  color: AppColors.accentDeep,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('GOI', style: AppTypography.number(30)),
                  Text('Goa', style: small),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment(-0.5, -1),
                end: Alignment(0.5, 1),
                colors: [AppColors.inkRaised, AppColors.ink],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your budget',
                  style: AppTypography.body(11, color: AppColors.onInkTertiary),
                ),
                Text(
                  '₹6,000',
                  style: AppTypography.number(26, color: AppColors.onInk),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: const SizedBox(
                    height: 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: Color(0x24FFFFFF)),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.42,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.all(
                                Radius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BidCard extends StatelessWidget {
  const _BidCard({
    required this.initials,
    required this.name,
    required this.rating,
    required this.price,
    required this.color,
    this.lowest = false,
  });

  final String initials;
  final String name;
  final String rating;
  final String price;
  final Color color;
  final bool lowest;

  @override
  Widget build(BuildContext context) {
    return _ArtCard(
      width: 256,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              initials,
              style: AppTypography.body(14, weight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    name,
                    maxLines: 1,
                    style: AppTypography.body(14, weight: FontWeight.w700),
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Symbols.star_rounded,
                      size: 13,
                      fill: 1,
                      color: AppColors.star,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        rating,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: AppTypography.body(
                          12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: AppTypography.number(20)),
              if (lowest)
                Text(
                  'LOWEST',
                  style: AppTypography.body(
                    10,
                    color: AppColors.successOnTint,
                    weight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard();

  @override
  Widget build(BuildContext context) {
    final mono = AppTypography.eyebrow(size: 10, color: AppColors.accentSoft);
    return _ArtCard(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.5, -1),
                end: Alignment(0.5, 1),
                colors: [AppColors.inkRaised, AppColors.ink],
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('E-TICKET', style: mono),
                    Text('PNR X7K2QP', style: mono),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DEL',
                      style: AppTypography.number(30, color: AppColors.onInk),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Transform.rotate(
                        angle: math.pi / 2,
                        child: const Icon(
                          Symbols.flight_rounded,
                          size: 22,
                          color: AppColors.accentLight,
                        ),
                      ),
                    ),
                    Text(
                      'GOI',
                      style: AppTypography.number(30, color: AppColors.onInk),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 2, child: _Perforation()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                for (final (label, value) in const [
                  ('Date', '05 Sept'),
                  ('Seat', '14A'),
                  ('Paid', '₹5,420'),
                ])
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: AppTypography.body(
                            10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        Text(
                          value,
                          style: AppTypography.number(14, tracking: 0),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed tear line with paper-coloured notches at both edges.
class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _PerforationPainter());
  }
}

class _PerforationPainter extends CustomPainter {
  const _PerforationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dash = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 2;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, y), Offset(x + 5, y), dash);
    }
    final notch = Paint()..color = AppColors.paper;
    canvas
      ..drawCircle(Offset(-1, y), 11, notch)
      ..drawCircle(Offset(size.width + 1, y), 11, notch);
  }

  @override
  bool shouldRepaint(_PerforationPainter oldDelegate) => false;
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x240D1B2A);
    final radius = size.shortestSide / 2;
    final center = size.center(Offset.zero);
    const dashes = 96;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweep,
        sweep * 0.55,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) => false;
}
