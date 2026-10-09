import '../../domain/entities/trip_request.dart';

/// The budget slider's scale for a trip type (from the design).
final class BudgetRange {
  const BudgetRange({
    required this.min,
    required this.max,
    required this.step,
    required this.initial,
  });

  final double min;
  final double max;
  final double step;
  final double initial;

  /// Below a quarter of the range agents are less likely to bid.
  bool isTight(double budget) => budget < min + (max - min) * 0.25;

  /// Snaps [value] to the slider's step inside the range.
  double snap(double value) {
    final clamped = value.clamp(min, max).toDouble();
    return (min + ((clamped - min) / step).round() * step)
        .clamp(min, max)
        .toDouble();
  }

  /// A hotel's budget covers the whole stay, so its scale grows with nights.
  BudgetRange forNights(int nights) {
    final n = nights < 1 ? 1 : nights;
    return BudgetRange(
      min: min,
      max: max * n,
      step: step,
      initial: initial * n,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BudgetRange &&
      other.min == min &&
      other.max == max &&
      other.step == step &&
      other.initial == initial;

  @override
  int get hashCode => Object.hash(min, max, step, initial);
}

/// A selectable chip: what the traveler reads and what the API stores.
final class FormOption<T> {
  const FormOption(this.value, this.label);

  final T value;
  final String label;
}

/// Labels, scales and choices that differ by trip type.
abstract final class RequestFormOptions {
  static const types = [TripType.flight, TripType.train, TripType.hotel];

  /// The biggest budget a traveler can type (₹1 crore).
  static const maxBudget = 10000000.0;
  static const maxCount = 9;

  static BudgetRange budget(TripType type) => switch (type) {
    TripType.train => const BudgetRange(
      min: 500,
      max: 15000,
      step: 100,
      initial: 4500,
    ),
    TripType.hotel => const BudgetRange(
      min: 1000,
      max: 20000,
      step: 250,
      initial: 4000,
    ),
    TripType.flight || TripType.package => const BudgetRange(
      min: 5000,
      max: 60000,
      step: 500,
      initial: 20000,
    ),
  };

  static String fromLabel(TripType type) => switch (type) {
    TripType.train => 'From station',
    TripType.hotel => 'City',
    _ => 'From',
  };

  static String toLabel(TripType type) => switch (type) {
    TripType.train => 'To station',
    TripType.hotel => 'Area',
    _ => 'To',
  };

  static String fromPlaceholder(TripType type) => switch (type) {
    TripType.train => 'Choose a station',
    TripType.hotel => 'Choose a city',
    _ => 'Choose an airport',
  };

  static String toPlaceholder(TripType type) => switch (type) {
    TripType.train => 'Choose a station',
    TripType.hotel => 'Any area (optional)',
    _ => 'Choose an airport',
  };

  static String paxLabel(TripType type) => switch (type) {
    TripType.train => 'Passengers',
    TripType.hotel => 'Guests',
    _ => 'Travellers',
  };

  static String budgetUnit(TripType type) =>
      type == TripType.hotel ? 'total stay' : 'total, all travellers';

  static String? defaultClass(TripType type) => switch (type) {
    TripType.flight || TripType.package => 'economy',
    TripType.train => 'sleeper',
    TripType.hotel => null,
  };

  static const flightClasses = [
    FormOption('economy', 'Economy'),
    FormOption('premium-economy', 'Premium economy'),
    FormOption('business', 'Business'),
    FormOption('first-class', 'First'),
  ];

  static const trainClasses = [
    FormOption('sleeper', 'Sleeper'),
    FormOption('ac-3-tier', 'AC 3-tier'),
    FormOption('ac-2-tier', 'AC 2-tier'),
    FormOption('ac-1-tier', 'AC 1st'),
    FormOption('second-class', 'Second class'),
    FormOption('general', 'General'),
  ];

  static const quotas = [
    FormOption('general', 'General'),
    FormOption('tatkal', 'Tatkal'),
    FormOption('premium-tatkal', 'Premium tatkal'),
    FormOption('ladies', 'Ladies'),
    FormOption('senior-citizen', 'Senior citizen'),
  ];

  static const berths = [
    FormOption('lower', 'Lower'),
    FormOption('middle', 'Middle'),
    FormOption('upper', 'Upper'),
    FormOption('side-lower', 'Side lower'),
    FormOption('side-upper', 'Side upper'),
  ];

  static const roomTypes = [
    FormOption('standard', 'Standard'),
    FormOption('deluxe', 'Deluxe'),
    FormOption('premium', 'Premium'),
    FormOption('executive', 'Executive'),
    FormOption('suite', 'Suite'),
  ];

  static const starRatings = [
    FormOption(3, '3★'),
    FormOption(4, '4★'),
    FormOption(5, '5★'),
  ];

  static String? label<T>(List<FormOption<T>> options, T? value) =>
      options.where((o) => o.value == value).firstOrNull?.label;
}
