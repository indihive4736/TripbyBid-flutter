import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/utils/indian_phone.dart';
import '../../domain/entities/new_trip_request.dart';
import '../../domain/entities/trip_request.dart';
import '../../domain/usecases/post_trip_request.dart';
import 'new_request_state.dart';
import 'request_form_options.dart';

export 'new_request_state.dart';

/// The two-step "new request" form: route, dates, travellers and budget,
/// then class, preferences and contact — and posting it.
class NewRequestCubit extends Cubit<NewRequestState> {
  NewRequestCubit({
    required PostTripRequestUseCase postTrip,
    DateTime Function()? clock,
  }) : _postTrip = postTrip,
       _clock = clock ?? DateTime.now,
       super(NewRequestState());

  final PostTripRequestUseCase _postTrip;
  final DateTime Function() _clock;

  DateTime get today {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }

  /// Prefills the contact details and the trip type the form opened with.
  void start({TripType? type, required String email, String? phone}) {
    final normalized = phone == null ? null : IndianPhone.normalize(phone);
    emit(
      _fresh(type ?? TripType.flight).copyWith(
        email: email,
        phone: normalized == null
            ? (phone ?? '')
            : IndianPhone.local(normalized),
      ),
    );
  }

  /// A blank form for [type] that keeps the dates, adults and contact.
  NewRequestState _fresh(TripType type) {
    final keep = state;
    final keepType = type == TripType.package ? TripType.flight : type;
    return NewRequestState(
      type: keepType,
      departDate: keep.departDate,
      adults: keep.adults,
      travelClass: RequestFormOptions.defaultClass(keepType),
      phone: keep.phone,
      email: keep.email,
      notes: keep.notes,
    );
  }

  /// Switching type starts over with that type's places and budget.
  void selectType(TripType type) {
    if (type == state.type) return;
    final next = _fresh(type);
    // A hotel needs a check-out, so give a fresh one the next morning.
    final checkIn = next.departDate;
    emit(
      next.isHotel && checkIn != null
          ? _withNightsBudget(
              next.copyWith(returnDate: checkIn.add(const Duration(days: 1))),
            )
          : next,
    );
  }

  void setFrom(Place place) => emit(
    state.copyWith(
      from: place,
      errors: _without({RequestField.from, RequestField.to}),
    ),
  );

  void setTo(Place place) => emit(
    state.copyWith(
      to: place,
      errors: _without({RequestField.from, RequestField.to}),
    ),
  );

  void setArea(String area) => emit(state.copyWith(area: area));

  /// Flips origin and destination (not for hotels).
  void swap() {
    if (state.isHotel) return;
    emit(
      state.copyWith(
        from: state.to,
        to: state.from,
        errors: _without({RequestField.from, RequestField.to}),
      ),
    );
  }

  void setDepartDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    var returnDate = state.returnDate;
    if (state.isHotel) {
      if (returnDate == null || !returnDate.isAfter(day)) {
        returnDate = day.add(const Duration(days: 1));
      }
    } else if (returnDate != null && returnDate.isBefore(day)) {
      returnDate = null;
    }
    emit(
      _withNightsBudget(
        state.copyWith(
          departDate: day,
          returnDate: returnDate,
          errors: _without({RequestField.depart, RequestField.ret}),
        ),
      ),
    );
  }

  void setReturnDate(DateTime date) => emit(
    _withNightsBudget(
      state.copyWith(
        returnDate: DateTime(date.year, date.month, date.day),
        errors: _without({RequestField.ret}),
      ),
    ),
  );

  void setRoundTrip(bool roundTrip) => emit(
    state.copyWith(
      roundTrip: roundTrip,
      returnDate: roundTrip ? state.returnDate : null,
      errors: _without({RequestField.ret}),
    ),
  );

  /// Bounds: adults and rooms 1–9, others 0–9; infants never outnumber
  /// adults (each sits on an adult's lap).
  (int, int) bounds(Counter counter) => switch (counter) {
    Counter.adults || Counter.rooms => (1, RequestFormOptions.maxCount),
    Counter.infants => (0, state.adults),
    Counter.children || Counter.seniors => (0, RequestFormOptions.maxCount),
  };

  void changeCount(Counter counter, int delta) {
    final (min, max) = bounds(counter);
    final value = (state.count(counter) + delta).clamp(min, max);
    if (value == state.count(counter)) return;
    emit(switch (counter) {
      Counter.adults => state.copyWith(
        adults: value,
        infants: state.infants > value ? value : state.infants,
      ),
      Counter.children => state.copyWith(children: value),
      Counter.infants => state.copyWith(infants: value),
      Counter.seniors => state.copyWith(seniors: value),
      Counter.rooms => state.copyWith(rooms: value),
    });
  }

  /// From the slider: snapped to its step.
  void setBudget(double value) => emit(
    state.copyWith(
      budget: state.budgetRange.snap(value),
      budgetEdited: true,
      errors: _without({RequestField.budget}),
    ),
  );

  /// A typed amount, which may sit outside the slider's scale.
  void setExactBudget(double value) => emit(
    state.copyWith(
      budget: value.roundToDouble().clamp(1, RequestFormOptions.maxBudget),
      budgetEdited: true,
      errors: _without({RequestField.budget}),
    ),
  );

  void setTravelClass(String value) => emit(state.copyWith(travelClass: value));
  void setDirectOnly(bool value) => emit(state.copyWith(directOnly: value));
  void setFlexibleDates(bool value) =>
      emit(state.copyWith(flexibleDates: value));
  void setPreferredAirline(String value) =>
      emit(state.copyWith(preferredAirline: value));

  /// Optional chips: tapping the selected one clears it.
  void toggleQuota(String value) =>
      emit(state.copyWith(quota: state.quota == value ? null : value));
  void toggleBerth(String value) =>
      emit(state.copyWith(berth: state.berth == value ? null : value));
  void toggleRoomType(String value) =>
      emit(state.copyWith(roomType: state.roomType == value ? null : value));
  void toggleStarRating(int value) => emit(
    state.copyWith(starRating: state.starRating == value ? null : value),
  );
  void setBreakfast(bool value) => emit(state.copyWith(breakfast: value));

  void setPhone(String value) => emit(
    state.copyWith(phone: value, errors: _without({RequestField.phone})),
  );

  void setNotes(String value) => emit(state.copyWith(notes: value));

  /// Validates step 1 and moves on; returns whether it did.
  bool continueToDetails() {
    final errors = _stepOneErrors();
    if (errors.isNotEmpty) {
      emit(state.copyWith(errors: errors));
      return false;
    }
    emit(state.copyWith(step: 2, errors: const {}, message: null));
    return true;
  }

  void backToRoute() => emit(state.copyWith(step: 1, message: null));

  Map<RequestField, String> _stepOneErrors() {
    final s = state;
    final errors = <RequestField, String>{};
    if (s.from == null) {
      errors[RequestField.from] = switch (s.type) {
        TripType.hotel => 'Choose the city you are staying in.',
        TripType.train => 'Choose your boarding station.',
        _ => 'Choose where you are flying from.',
      };
    }
    if (!s.isHotel) {
      if (s.to == null) {
        errors[RequestField.to] = s.isTrain
            ? 'Choose your destination station.'
            : 'Choose where you are flying to.';
      } else if (s.from != null && s.from == s.to) {
        errors[RequestField.to] =
            'Pick a destination different from the origin.';
      }
    }
    final depart = s.departDate;
    if (depart == null) {
      errors[RequestField.depart] = s.isHotel
          ? 'Pick a check-in date.'
          : 'Pick your travel date.';
    } else if (depart.isBefore(today)) {
      errors[RequestField.depart] = 'That date has passed — pick another.';
    }
    final ret = s.returnDate;
    if (s.isHotel) {
      if (ret == null) {
        errors[RequestField.ret] = 'Pick a check-out date.';
      } else if (depart != null && !ret.isAfter(depart)) {
        errors[RequestField.ret] = 'Check-out must be after check-in.';
      }
    } else if (s.isFlight && s.roundTrip) {
      if (ret == null) {
        errors[RequestField.ret] = 'Pick your return date.';
      } else if (depart != null && ret.isBefore(depart)) {
        errors[RequestField.ret] = 'Return cannot be before departure.';
      }
    }
    if (s.budget <= 0) errors[RequestField.budget] = 'Set a budget above ₹0.';
    return errors;
  }

  /// Posts the request. On success [NewRequestState.createdId] is set.
  Future<void> submit() async {
    if (state.submitting) return;
    final phone = IndianPhone.normalize(state.phone);
    if (phone == null) {
      emit(
        state.copyWith(
          errors: {
            ...state.errors,
            RequestField.phone: 'Enter a valid 10-digit Indian mobile number.',
          },
        ),
      );
      return;
    }
    emit(state.copyWith(submitting: true, message: null));
    final result = await _postTrip(_toRequest(state, phone));
    if (isClosed) return;
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(submitting: false, createdId: value.id));
      case Err(:final failure):
        emit(state.copyWith(submitting: false, message: failure.message));
    }
  }

  static NewTripRequest _toRequest(NewRequestState s, String phone) {
    final notes = s.notes.trim();
    final airline = s.preferredAirline.trim();
    return NewTripRequest(
      type: s.type,
      from: s.from ?? const Place(name: ''),
      to: s.isHotel
          ? Place(name: s.area.trim())
          : s.to ?? const Place(name: ''),
      departDate: s.departDate ?? DateTime(0),
      returnDate: switch (s.type) {
        TripType.hotel => s.returnDate,
        TripType.flight when s.roundTrip => s.returnDate,
        _ => null,
      },
      budget: s.budget,
      contactEmail: s.email,
      contactPhone: phone,
      adults: s.adults,
      children: s.children,
      infants: s.isFlight ? s.infants : 0,
      seniors: s.isTrain ? s.seniors : 0,
      rooms: s.isHotel ? s.rooms : 1,
      tripType: s.isFlight && s.roundTrip ? 'round-trip' : 'one-way',
      travelClass: s.isHotel ? null : s.travelClass,
      directOnly: s.isFlight && s.directOnly,
      flexibleDates: s.isFlight && s.flexibleDates,
      preferredAirline: s.isFlight && airline.isNotEmpty ? airline : null,
      quota: s.isTrain ? s.quota : null,
      berthPreference: s.isTrain ? s.berth : null,
      roomType: s.isHotel ? s.roomType : null,
      starRating: s.isHotel ? s.starRating : null,
      breakfastIncluded: s.isHotel && s.breakfast,
      requirements: notes.isEmpty ? null : notes,
    );
  }

  /// Hotels: until the traveler sets a budget, follow the nights.
  NewRequestState _withNightsBudget(NewRequestState s) {
    if (!s.isHotel || s.budgetEdited) return s;
    return s.copyWith(budget: s.budgetRange.initial);
  }

  Map<RequestField, String> _without(Set<RequestField> fields) => {
    for (final e in state.errors.entries)
      if (!fields.contains(e.key)) e.key: e.value,
  };
}
