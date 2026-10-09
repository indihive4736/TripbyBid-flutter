import 'package:flutter/painting.dart';

/// Colour tokens from the TripByBid traveler app design.
abstract final class AppColors {
  // Ink (navy) — text, dark surfaces, primary dark buttons.
  static const ink = Color(0xFF0D1B2A);
  static const inkRaised = Color(0xFF1C3450);
  static const inkDeep = Color(0xFF0A1522);

  // Paper (cream) — backgrounds and cards.
  static const paper = Color(0xFFF3EDE3);
  static const card = Color(0xFFFFFCF7);
  static const sunken = Color(0xFFE9E1D4);
  static const sheet = Color(0xFFF7F2EA);
  static const muted = Color(0xFFEAE4D9);
  static const disabled = Color(0xFFD9D1C4);

  // Text on paper.
  static const textSecondary = Color(0xFF4A5563);
  static const textTertiary = Color(0xFF5B6573);
  static const textFaint = Color(0xFF8A93A0);

  // Text on ink.
  static const onInk = paper;
  static const onInkSecondary = Color(0xFFC9D1DB);
  static const onInkTertiary = Color(0xFFAFB8C4);
  static const onInkFaint = Color(0xFF8A97A6);

  // Accent (orange).
  static const accent = Color(0xFFFF5A1F);
  static const accentDeep = Color(0xFFE8490F);
  static const accentLight = Color(0xFFFF7A42);
  static const accentSoft = Color(0xFFFF9A6A);
  static const accentTint = Color(0xFFFFE1D2);
  static const accentOnTint = Color(0xFFA8360A);

  // Success (green).
  static const success = Color(0xFF1F8A5B);
  static const successTint = Color(0xFFD6F0E3);
  static const successOnTint = Color(0xFF17694A);
  static const mint = Color(0xFF7FD6AE);
  static const online = Color(0xFF3FC37E);

  // Danger.
  static const danger = Color(0xFFC2410C);
  static const dangerTint = Color(0xFFF6D5CB);

  static const star = Color(0xFFE8A317);
  static const starBright = Color(0xFFF2A516);

  // Category tints.
  static const flightTint = Color(0xFFFFD3C2);
  static const trainTint = Color(0xFFCDEBDD);
  static const hotelTint = Color(0xFFDCE2FA);
  static const yellowTint = Color(0xFFFBEAB0);

  /// Avatar backgrounds for agents, picked by a stable hash of their id.
  static const avatarPalette = [
    Color(0xFFFFB199),
    Color(0xFFB9C4F5),
    Color(0xFF9ED9C9),
    Color(0xFFFBEAB0),
    Color(0xFFDCE2FA),
  ];

  static Color avatarFor(String seed) =>
      avatarPalette[seed.codeUnits.fold(0, (a, b) => a + b) %
          avatarPalette.length];

  /// Hairline borders on paper.
  static const hairline = Color(0x120D1B2A); // ink @ 7%
  static const divider = Color(0x1F0D1B2A); // ink @ 12%

  static const accentGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [accentLight, Color(0xFFFF5418)],
  );

  static const inkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [inkRaised, ink],
  );

  /// The navy panels (hero cards, headers): 155° from raised to deep.
  static const panelGradient = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [inkRaised, ink, inkDeep],
    stops: [0, 0.55, 1],
  );
}
