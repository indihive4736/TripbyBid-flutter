import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/features/trips/domain/entities/new_trip_request.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_request.dart';
import 'package:tripbybid/features/trips/domain/usecases/post_trip_request.dart';

import '../trips_fakes.dart';

void main() {
  final today = DateTime(2026, 10, 10, 15);
  late FakeTripsRepository repository;
  late PostTripRequestUseCase post;

  setUp(() {
    repository = FakeTripsRepository();
    post = PostTripRequestUseCase(repository, clock: () => today);
  });

  NewTripRequest flight({
    Place from = const Place(name: 'Mumbai', code: 'BOM'),
    Place to = const Place(name: 'Dubai', code: 'DXB'),
    DateTime? depart,
    DateTime? returnDate,
    String tripType = 'one-way',
    double budget = 20000,
    String phone = '+919810043210',
  }) => NewTripRequest(
    type: TripType.flight,
    from: from,
    to: to,
    departDate: depart ?? DateTime(2026, 11, 12),
    returnDate: returnDate,
    tripType: tripType,
    budget: budget,
    contactEmail: 'asha@example.com',
    contactPhone: phone,
  );

  test('a valid request is posted', () {
    expect(post.validate(flight()), isNull);
  });

  test('travel today is allowed, yesterday is not', () {
    expect(post.validate(flight(depart: DateTime(2026, 10, 10))), isNull);
    expect(post.validate(flight(depart: DateTime(2026, 10, 9))), isNotNull);
  });

  test('rejects the same origin and destination', () {
    const bom = Place(name: 'Mumbai', code: 'BOM');
    expect(post.validate(flight(from: bom, to: bom)), isNotNull);
  });

  test('round trips need a return on or after departure', () {
    expect(post.validate(flight(tripType: 'round-trip')), isNotNull);
    expect(
      post.validate(
        flight(tripType: 'round-trip', returnDate: DateTime(2026, 11, 11)),
      ),
      isNotNull,
    );
    expect(
      post.validate(
        flight(tripType: 'round-trip', returnDate: DateTime(2026, 11, 15)),
      ),
      isNull,
    );
  });

  test('hotels need check-out after check-in', () {
    NewTripRequest hotel(DateTime? out) => NewTripRequest(
      type: TripType.hotel,
      from: const Place(name: 'Goa', country: 'IN'),
      to: const Place(name: 'Calangute'),
      departDate: DateTime(2026, 12, 14),
      returnDate: out,
      budget: 4000,
      contactEmail: 'a@b.co',
      contactPhone: '+919810043210',
    );
    expect(post.validate(hotel(null)), isNotNull);
    expect(post.validate(hotel(DateTime(2026, 12, 14))), isNotNull);
    expect(post.validate(hotel(DateTime(2026, 12, 17))), isNull);
  });

  test('needs a budget and a phone', () {
    expect(post.validate(flight(budget: 0)), isNotNull);
    expect(post.validate(flight(phone: ' ')), isNotNull);
  });

  test('invalid requests never reach the repository', () async {
    await post(flight(budget: 0));
    expect(repository.calls, isEmpty);
  });
}
