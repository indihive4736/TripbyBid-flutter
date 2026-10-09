import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Type styles from the design. Families are bundled in `assets/fonts`.
///
/// - Bricolage Grotesque: all UI text and display headings.
/// - Instrument Serif italic: the accent word in headlines ("in your *pocket*").
/// - JetBrains Mono: small uppercase eyebrow labels and ids.
/// - Poppins: numbers (prices, codes, times) with tabular figures.
abstract final class AppTypography {
  static const sans = 'Bricolage Grotesque';
  static const serif = 'Instrument Serif';
  static const mono = 'JetBrains Mono';
  static const numeric = 'Poppins';

  static const _tabular = [
    FontFeature.tabularFigures(),
    FontFeature.liningFigures(),
  ];

  /// Big screen titles: "Welcome back." (40), "My trips" (34).
  static TextStyle display(double size, {Color color = AppColors.ink}) =>
      TextStyle(
        fontFamily: sans,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.05 * size,
        height: 1,
        color: color,
      );

  /// The italic serif accent inside a display heading.
  static TextStyle accent(double size, {Color color = AppColors.accentDeep}) =>
      TextStyle(
        fontFamily: serif,
        fontStyle: FontStyle.italic,
        fontSize: size,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.02 * size,
        height: 1,
        color: color,
      );

  /// Section titles: "Live bids", "Fare breakdown".
  static TextStyle title(double size, {Color color = AppColors.ink}) =>
      TextStyle(
        fontFamily: sans,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * size,
        color: color,
      );

  static TextStyle body(
    double size, {
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w400,
    double? height,
  }) => TextStyle(
    fontFamily: sans,
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
  );

  /// Uppercase mono eyebrow: "NEXT TRIP · IN 3 DAYS".
  static TextStyle eyebrow({
    double size = 11,
    Color color = AppColors.accentDeep,
    double tracking = 0.14,
    FontWeight weight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: mono,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: tracking * size,
    color: color,
  );

  /// Prices, airport codes, times.
  static TextStyle number(
    double size, {
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w600,
    double tracking = -0.04,
  }) => TextStyle(
    fontFamily: numeric,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: tracking * size,
    height: 1.1,
    color: color,
    fontFeatures: _tabular,
  );
}
