/// Live password strength from the signup design: one point each for
/// length ≥ 8, a capital, a number and a symbol.
final class PasswordStrength {
  const PasswordStrength._(this.score, {required this.longEnough});

  factory PasswordStrength.of(String password) {
    final longEnough = password.length >= 8;
    final score = [
      longEnough,
      RegExp('[A-Z]').hasMatch(password),
      RegExp(r'\d').hasMatch(password),
      RegExp('[^A-Za-z0-9]').hasMatch(password),
    ].where((met) => met).length;
    return PasswordStrength._(score, longEnough: longEnough);
  }

  /// 0–4.
  final int score;
  final bool longEnough;

  /// Long enough and at least two of capital / number / symbol.
  bool get isAcceptable => longEnough && score >= 3;

  String get label => switch (score) {
    0 || 1 => 'Weak',
    2 => 'Okay',
    3 => 'Good',
    _ => 'Strong password',
  };

  @override
  bool operator ==(Object other) =>
      other is PasswordStrength &&
      other.score == score &&
      other.longEnough == longEnough;

  @override
  int get hashCode => Object.hash(score, longEnough);
}
