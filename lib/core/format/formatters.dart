import 'package:intl/intl.dart';

/// Display formatting shared by every screen (India: INR, en-IN grouping).
abstract final class Fmt {
  static final _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  static final _compact = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  /// ₹17,999
  static String inr(num amount) => _inr.format(amount);

  /// ₹18.2K — for tight stat tiles.
  static String inrCompact(num amount) =>
      amount < 10000 ? inr(amount) : _compact.format(amount);

  /// 12 Nov
  static String dayMonth(DateTime d) => DateFormat('d MMM').format(d);

  /// Thu, 12 Nov
  static String weekdayDayMonth(DateTime d) =>
      DateFormat('EEE, d MMM').format(d);

  /// 12 Nov 2026
  static String date(DateTime d) => DateFormat('d MMM y').format(d);

  /// 14:05
  static String time(DateTime d) => DateFormat('HH:mm').format(d);

  /// 7 Oct, 14:05
  static String dateTime(DateTime d) => DateFormat('d MMM, HH:mm').format(d);

  /// 10 SEPT · 10:12 — the mono timeline stamp.
  static String stamp(DateTime d) =>
      '${DateFormat('d MMM').format(d).toUpperCase()} · ${time(d)}';

  /// "Just now", "5 min ago", "3 h ago", "Yesterday", "22 Sep".
  static String relative(DateTime d, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final diff = ref.difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24 && ref.day == d.day) return '${diff.inHours} h ago';
    final yesterday = DateTime(ref.year, ref.month, ref.day - 1);
    if (d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day) {
      return 'Yesterday';
    }
    return dayMonth(d);
  }

  /// "Today", "Yesterday", "22 Sep" — chat day separators.
  static String dayLabel(DateTime d, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return d.year == ref.year ? dayMonth(d) : date(d);
  }

  /// 23:41:10 countdown.
  static String countdown(Duration d) {
    if (d.isNegative) return '00:00:00';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  /// "Good morning" / "Good afternoon" / "Good evening".
  static String greeting(DateTime now) => switch (now.hour) {
    < 12 => 'Good morning,',
    < 17 => 'Good afternoon,',
    _ => 'Good evening,',
  };

  /// `ac-2-tier` → `AC 2-tier`; `premium-economy` → `Premium economy`.
  static String travelClass(String? value) => switch (value) {
    null || '' => '—',
    'economy' => 'Economy',
    'premium-economy' => 'Premium economy',
    'business' => 'Business',
    'first-class' => 'First class',
    'sleeper' => 'Sleeper',
    'ac-3-tier' => 'AC 3-tier',
    'ac-2-tier' => 'AC 2-tier',
    'ac-1-tier' => 'AC 1st class',
    'second-class' => 'Second class',
    'general' => 'General',
    _ => value[0].toUpperCase() + value.substring(1).replaceAll('-', ' '),
  };

  /// "1 adult", "2 adults · 1 child".
  static String people({
    required int adults,
    int children = 0,
    int infants = 0,
    int seniors = 0,
  }) {
    String plural(int n, String one, String many) =>
        '$n ${n == 1 ? one : many}';
    return [
      plural(adults, 'adult', 'adults'),
      if (seniors > 0) plural(seniors, 'senior', 'seniors'),
      if (children > 0) plural(children, 'child', 'children'),
      if (infants > 0) plural(infants, 'infant', 'infants'),
    ].join(' · ');
  }
}
