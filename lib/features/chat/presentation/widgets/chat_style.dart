import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chat.dart';

/// Icon and tint for a conversation's trip type (`flight`, `train`,
/// `hotel`, `package`).
extension ConversationStyle on Conversation {
  IconData get tripIcon => switch (tripType) {
    'train' => Symbols.train_rounded,
    'hotel' => Symbols.hotel_rounded,
    'package' => Symbols.beach_access_rounded,
    _ => Symbols.flight_rounded,
  };

  Color get tripTint => switch (tripType) {
    'train' => AppColors.trainTint,
    'hotel' => AppColors.hotelTint,
    'package' => AppColors.yellowTint,
    _ => AppColors.flightTint,
  };

  /// Short booking reference: `#9A21C0D3`.
  String get shortRef => shortBookingRef(bookingId);
}

String shortBookingRef(String bookingId) {
  final compact = bookingId.replaceAll('-', '');
  return '#${(compact.length > 8 ? compact.substring(0, 8) : compact).toUpperCase()}';
}
