/// Indian mobile numbers, normalised like the web client.
abstract final class IndianPhone {
  static final _mobile = RegExp(r'^[6-9]\d{9}$');

  /// Returns `+91XXXXXXXXXX`, or null when [input] is not a valid 10-digit
  /// Indian mobile number. Accepts spaces/dashes and a `+91`, `0091`, `91`
  /// or `0` prefix.
  static String? normalize(String input) {
    var digits = input.replaceAll(RegExp(r'[\s\-()]'), '');
    for (final prefix in ['+91', '0091']) {
      if (digits.startsWith(prefix)) {
        digits = digits.substring(prefix.length);
        break;
      }
    }
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return _mobile.hasMatch(digits) ? '+91$digits' : null;
  }

  /// `+919810043210` → `98100 43210` (for display and editing).
  static String local(String normalized) {
    final digits = normalized.startsWith('+91')
        ? normalized.substring(3)
        : normalized;
    if (digits.length != 10) return digits;
    return '${digits.substring(0, 5)} ${digits.substring(5)}';
  }
}
