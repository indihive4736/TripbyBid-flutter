import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/failures.dart';
import 'package:tripbybid/core/error/result.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_request.dart';
import 'package:tripbybid/features/trips/domain/usecases/post_trip_request.dart';
import 'package:tripbybid/features/trips/presentation/new_request/new_request_cubit.dart';

import '../../trips_fakes.dart';
import 'new_request_fakes.dart';

void main() {
  final now = DateTime(2026, 10, 10, 15);
  late FakeTripsRepository trips;

  setUp(() => trips = FakeTripsRepository());

  NewRequestCubit build() {
    final cubit = NewRequestCubit(
      postTrip: PostTripRequestUseCase(trips, clock: () => now),
      clock: () => now,
    );
    cubit.start(email: 'asha@example.com', phone: '+919810043210');
    return cubit;
  }

  /// A flight form filled in up to the budget.
  NewRequestCubit filledFlight() => build()
    ..setFrom(FakePlacesRepository.mumbai)
    ..setTo(FakePlacesRepository.dubai)
    ..setDepartDate(DateTime(2026, 11, 12));

  test('starts as a flight with the design defaults and the contact', () {
    final state = build().state;
    expect(state.type, TripType.flight);
    expect(state.budget, 20000);
    expect(state.travelClass, 'economy');
    expect(state.phone, '98100 43210');
    expect(state.email, 'asha@example.com');
    expect(state.step, 1);
  });

  test('opens on the requested type', () {
    final cubit = NewRequestCubit(
      postTrip: PostTripRequestUseCase(trips),
      clock: () => now,
    )..start(type: TripType.train, email: 'a@b.co');
    expect(cubit.state.type, TripType.train);
    expect(cubit.state.budget, 4500);
    expect(cubit.state.travelClass, 'sleeper');
  });

  test('switching type resets places, budget and class to its defaults', () {
    final cubit = filledFlight()..setBudget(42000);
    expect(cubit.state.budget, 42000);

    cubit.selectType(TripType.train);

    final s = cubit.state;
    expect(s.type, TripType.train);
    expect(s.from, isNull);
    expect(s.to, isNull);
    expect(s.budget, 4500);
    expect(s.travelClass, 'sleeper');
    // The date and contact carry over.
    expect(s.departDate, DateTime(2026, 11, 12));
    expect(s.phone, '98100 43210');
  });

  test('a hotel gets a check-out and its budget follows the nights', () {
    final cubit = filledFlight()..selectType(TripType.hotel);
    expect(cubit.state.returnDate, DateTime(2026, 11, 13));
    expect(cubit.state.nights, 1);
    expect(cubit.state.budget, 4000);

    cubit.setReturnDate(DateTime(2026, 11, 15));
    expect(cubit.state.nights, 3);
    expect(cubit.state.budgetRange.max, 60000);
    expect(cubit.state.budget, 12000);

    // Once the traveler sets it, it stays put.
    cubit
      ..setBudget(9000)
      ..setReturnDate(DateTime(2026, 11, 16));
    expect(cubit.state.budget, 9000);
  });

  blocTest<NewRequestCubit, NewRequestState>(
    'swap flips origin and destination',
    build: filledFlight,
    act: (cubit) => cubit.swap(),
    verify: (cubit) {
      expect(cubit.state.from, FakePlacesRepository.dubai);
      expect(cubit.state.to, FakePlacesRepository.mumbai);
    },
  );

  test('travellers stay within 1–9 and infants never outnumber adults', () {
    final cubit = build()..changeCount(Counter.adults, -1);
    expect(cubit.state.adults, 1);

    for (var i = 0; i < 12; i++) {
      cubit.changeCount(Counter.adults, 1);
    }
    expect(cubit.state.adults, 9);

    cubit
      ..changeCount(Counter.infants, 3)
      ..changeCount(Counter.adults, -7);
    expect(cubit.state.adults, 2);
    expect(cubit.state.infants, 2);
  });

  test('the slider snaps to the step and stays in range', () {
    final cubit = build()..setBudget(20260);
    expect(cubit.state.budget, 20500);
    cubit.setBudget(1);
    expect(cubit.state.budget, 5000);
    cubit.setExactBudget(123456);
    expect(cubit.state.budget, 123456);
  });

  test('step 1 explains every missing field and does not advance', () {
    final cubit = build();
    expect(cubit.continueToDetails(), isFalse);
    expect(cubit.state.step, 1);
    expect(
      cubit.state.errors.keys,
      containsAll([RequestField.from, RequestField.to, RequestField.depart]),
    );

    cubit.setFrom(FakePlacesRepository.mumbai);
    expect(cubit.state.errors.containsKey(RequestField.from), isFalse);
  });

  test('step 1 rejects the same origin and destination', () {
    final cubit = filledFlight()..setTo(FakePlacesRepository.mumbai);
    expect(cubit.continueToDetails(), isFalse);
    expect(cubit.state.errors[RequestField.to], contains('different'));
  });

  test('round trips need a return date', () {
    final cubit = filledFlight()..setRoundTrip(true);
    expect(cubit.continueToDetails(), isFalse);
    expect(cubit.state.errors.keys, [RequestField.ret]);
    cubit.setReturnDate(DateTime(2026, 11, 20));
    expect(cubit.continueToDetails(), isTrue);
    expect(cubit.state.step, 2);
  });

  blocTest<NewRequestCubit, NewRequestState>(
    'posting emits the created id',
    setUp: () =>
        trips.createResult = Ok(TripFixtures.request(id: 'new-trip-1')),
    build: filledFlight,
    act: (cubit) async {
      cubit
        ..continueToDetails()
        ..setNotes('  Window seat please ');
      await cubit.submit();
    },
    verify: (cubit) {
      expect(cubit.state.createdId, 'new-trip-1');
      expect(cubit.state.submitting, isFalse);
      final sent = trips.lastCreated!;
      expect(sent.contactPhone, '+919810043210');
      expect(sent.contactEmail, 'asha@example.com');
      expect(sent.budget, 20000);
      expect(sent.requirements, 'Window seat please');
      expect(sent.travelClass, 'economy');
      expect(sent.tripType, 'one-way');
      expect(sent.returnDate, isNull);
    },
  );

  blocTest<NewRequestCubit, NewRequestState>(
    'a failed post shows the message and keeps everything entered',
    setUp: () => trips.createResult = const Err(
      ServerFailure('Budget is too low for this route'),
    ),
    build: filledFlight,
    act: (cubit) async {
      cubit.continueToDetails();
      await cubit.submit();
    },
    verify: (cubit) {
      final s = cubit.state;
      expect(s.message, 'Budget is too low for this route');
      expect(s.createdId, isNull);
      expect(s.submitting, isFalse);
      expect(s.step, 2);
      expect(s.from, FakePlacesRepository.mumbai);
      expect(s.to, FakePlacesRepository.dubai);
    },
  );

  test('an invalid phone is flagged without calling the API', () async {
    final cubit = filledFlight()
      ..continueToDetails()
      ..setPhone('12345');
    await cubit.submit();
    expect(cubit.state.errors[RequestField.phone], isNotNull);
    expect(trips.calls, isEmpty);
  });

  test('the use case validation message is shown', () async {
    final cubit = build()
      ..setPhone('98100 43210')
      ..selectType(TripType.hotel);
    await cubit.submit();
    expect(cubit.state.message, 'Choose a city.');
    expect(trips.calls, isEmpty);
  });

  test('hotel requests send the area, rooms and stay total', () async {
    trips.createResult = Ok(TripFixtures.request(type: TripType.hotel));
    final cubit = build()
      ..selectType(TripType.hotel)
      ..setFrom(FakePlacesRepository.goa)
      ..setArea(' Calangute ')
      ..setDepartDate(DateTime(2026, 12, 14))
      ..setReturnDate(DateTime(2026, 12, 17))
      ..changeCount(Counter.rooms, 1)
      ..toggleStarRating(4);
    expect(cubit.continueToDetails(), isTrue);
    await cubit.submit();

    final sent = trips.lastCreated!;
    expect(sent.type, TripType.hotel);
    expect(sent.to.name, 'Calangute');
    expect(sent.rooms, 2);
    expect(sent.budget, 12000);
    expect(sent.returnDate, DateTime(2026, 12, 17));
    expect(sent.starRating, 4);
    expect(sent.travelClass, isNull);
  });
}
