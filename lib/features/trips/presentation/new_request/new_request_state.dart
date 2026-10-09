import 'package:equatable/equatable.dart';

import '../../domain/entities/new_trip_request.dart';
import '../../domain/entities/trip_request.dart';
import 'request_form_options.dart';

/// Fields that can show an inline message.
enum RequestField { from, to, depart, ret, budget, phone }

/// Steppers on the form.
enum Counter { adults, children, infants, seniors, rooms }

const _unset = Object();

/// Everything the traveler has entered so far, plus submission progress.
final class NewRequestState extends Equatable {
  NewRequestState({
    this.step = 1,
    this.type = TripType.flight,
    this.from,
    this.to,
    this.area = '',
    this.departDate,
    this.returnDate,
    this.roundTrip = false,
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
    this.seniors = 0,
    this.rooms = 1,
    double? budget,
    this.budgetEdited = false,
    this.travelClass = 'economy',
    this.directOnly = false,
    this.flexibleDates = false,
    this.preferredAirline = '',
    this.quota,
    this.berth,
    this.roomType,
    this.starRating,
    this.breakfast = false,
    this.phone = '',
    this.email = '',
    this.notes = '',
    this.submitting = false,
    this.errors = const {},
    this.message,
    this.createdId,
  }) : budget = budget ?? RequestFormOptions.budget(type).initial;

  /// 1 = route, dates, travellers and budget; 2 = details and contact.
  final int step;
  final TripType type;

  /// Airport, station or (for hotels) city.
  final Place? from;

  /// Airport or station; unused for hotels (see [area]).
  final Place? to;

  /// Hotels: the area or landmark, optional.
  final String area;

  /// Departure, journey or check-in.
  final DateTime? departDate;

  /// Flight return (round trips) or hotel check-out.
  final DateTime? returnDate;

  /// Flights only.
  final bool roundTrip;
  final int adults;
  final int children;
  final int infants;
  final int seniors;
  final int rooms;

  /// Total in INR (the whole stay for hotels).
  final double budget;

  /// The traveler moved the slider or typed an amount, so stop rescaling it.
  final bool budgetEdited;

  final String? travelClass;
  final bool directOnly;
  final bool flexibleDates;
  final String preferredAirline;
  final String? quota;
  final String? berth;
  final String? roomType;
  final int? starRating;
  final bool breakfast;

  /// As typed; normalised on submit.
  final String phone;
  final String email;
  final String notes;

  final bool submitting;

  /// Inline messages for invalid fields.
  final Map<RequestField, String> errors;

  /// Why the last post failed.
  final String? message;

  /// The new request's id once posted.
  final String? createdId;

  bool get isHotel => type == TripType.hotel;
  bool get isFlight => type == TripType.flight;
  bool get isTrain => type == TripType.train;

  /// Hotel nights, or 0 until both dates are set.
  int get nights {
    final checkIn = departDate;
    final checkOut = returnDate;
    if (!isHotel || checkIn == null || checkOut == null) return 0;
    return checkOut.difference(checkIn).inDays.clamp(0, 365);
  }

  BudgetRange get budgetRange {
    final base = RequestFormOptions.budget(type);
    return isHotel ? base.forNights(nights) : base;
  }

  bool get budgetIsTight => budgetRange.isTight(budget);

  int count(Counter counter) => switch (counter) {
    Counter.adults => adults,
    Counter.children => children,
    Counter.infants => infants,
    Counter.seniors => seniors,
    Counter.rooms => rooms,
  };

  NewRequestState copyWith({
    int? step,
    TripType? type,
    Object? from = _unset,
    Object? to = _unset,
    String? area,
    Object? departDate = _unset,
    Object? returnDate = _unset,
    bool? roundTrip,
    int? adults,
    int? children,
    int? infants,
    int? seniors,
    int? rooms,
    double? budget,
    bool? budgetEdited,
    Object? travelClass = _unset,
    bool? directOnly,
    bool? flexibleDates,
    String? preferredAirline,
    Object? quota = _unset,
    Object? berth = _unset,
    Object? roomType = _unset,
    Object? starRating = _unset,
    bool? breakfast,
    String? phone,
    String? email,
    String? notes,
    bool? submitting,
    Map<RequestField, String>? errors,
    Object? message = _unset,
    Object? createdId = _unset,
  }) {
    T pick<T>(Object? value, T current) =>
        identical(value, _unset) ? current : value as T;
    return NewRequestState(
      step: step ?? this.step,
      type: type ?? this.type,
      from: pick<Place?>(from, this.from),
      to: pick<Place?>(to, this.to),
      area: area ?? this.area,
      departDate: pick<DateTime?>(departDate, this.departDate),
      returnDate: pick<DateTime?>(returnDate, this.returnDate),
      roundTrip: roundTrip ?? this.roundTrip,
      adults: adults ?? this.adults,
      children: children ?? this.children,
      infants: infants ?? this.infants,
      seniors: seniors ?? this.seniors,
      rooms: rooms ?? this.rooms,
      budget: budget ?? this.budget,
      budgetEdited: budgetEdited ?? this.budgetEdited,
      travelClass: pick<String?>(travelClass, this.travelClass),
      directOnly: directOnly ?? this.directOnly,
      flexibleDates: flexibleDates ?? this.flexibleDates,
      preferredAirline: preferredAirline ?? this.preferredAirline,
      quota: pick<String?>(quota, this.quota),
      berth: pick<String?>(berth, this.berth),
      roomType: pick<String?>(roomType, this.roomType),
      starRating: pick<int?>(starRating, this.starRating),
      breakfast: breakfast ?? this.breakfast,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      submitting: submitting ?? this.submitting,
      errors: errors ?? this.errors,
      message: pick<String?>(message, this.message),
      createdId: pick<String?>(createdId, this.createdId),
    );
  }

  @override
  List<Object?> get props => [
    step,
    type,
    from,
    to,
    area,
    departDate,
    returnDate,
    roundTrip,
    adults,
    children,
    infants,
    seniors,
    rooms,
    budget,
    budgetEdited,
    travelClass,
    directOnly,
    flexibleDates,
    preferredAirline,
    quota,
    berth,
    roomType,
    starRating,
    breakfast,
    phone,
    email,
    notes,
    submitting,
    errors,
    message,
    createdId,
  ];
}
