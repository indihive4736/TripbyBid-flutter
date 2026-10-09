import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/network/json_reader.dart';
import 'package:tripbybid/features/trips/data/models/trip_json.dart';
import 'package:tripbybid/features/trips/domain/entities/bid.dart';
import 'package:tripbybid/features/trips/domain/entities/new_trip_request.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_request.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_stage.dart';

Map<String, Object?> requestJson({Object? bids, Object? booking}) => {
  'id': 'a9c3e05f-1111-4000-8000-000000000001',
  'booking_type': 'flight',
  'from_location': 'Mumbai (BOM)',
  'to_location': 'Dubai (DXB)',
  'depart_date': '2026-11-12',
  'return_date': null,
  'budget': '20000.00',
  'requirements': null,
  'status': 'bidding',
  'bids_count': 3,
  'created_at': '2026-10-01T04:42:00.000Z',
  'details': {
    'trip_type': 'one-way',
    'from_airport_code': 'BOM',
    'to_airport_code': 'DXB',
    'adults': 2,
    'children': 0,
    'infants': 0,
    'class_name': 'economy',
  },
  'bids': ?bids,
  'booking': ?booking,
};

void main() {
  test('parses a request with typed details', () {
    final r = TripJson.request(JsonReader(requestJson()));

    expect(r.type, TripType.flight);
    expect(r.budget, 20000);
    expect(r.departDate, DateTime(2026, 11, 12));
    expect(r.stage, TripStage.bidsIn);
    expect(r.details!.adults, 2);
    expect(r.details!.fromCode, 'BOM');
    expect(r.details!.travelClass, 'economy');
    expect(r.shortId, '#A9C3E05F');
  });

  test('reads the list embed `bids: [{count}]` as a count', () {
    final json = requestJson(
      bids: [
        {'count': 5},
      ],
    )..remove('bids_count');

    final r = TripJson.request(JsonReader(json));

    expect(r.bidsCount, 5);
    expect(r.bids, isEmpty);
  });

  test('parses embedded bid rows with the agent', () {
    final r = TripJson.request(
      JsonReader(
        requestJson(
          bids: [
            {
              'id': 'b-1',
              'request_id': 'r-1',
              'agent_id': 'a-1',
              'price': 17999,
              'status': 'accepted',
              'agent_name': 'AirTrek India',
              'agent_rating': 4.9,
              'agent_reviews': 120,
              'inclusions': ['Non-stop'],
              'payment_due_at': '2026-10-03T08:35:00.000Z',
              'created_at': '2026-10-01T04:49:00.000Z',
              'users': {
                'name': 'Ravi',
                'total_bookings': 312,
                'verified': true,
              },
            },
          ],
        ),
      ),
    );

    final bid = r.acceptedBid!;
    expect(bid.status, BidStatus.accepted);
    expect(bid.agentName, 'AirTrek India');
    expect(bid.agentTrips, 312);
    expect(bid.agentVerified, isTrue);
    expect(bid.paymentDueAt, isNotNull);
  });

  test('parses the booking embed with its agent', () {
    final r = TripJson.request(
      JsonReader(
        requestJson(
          booking: {
            'id': 'bk-1',
            'status': 'confirmed',
            'price': 17999,
            'platform_fee': 300,
            'payment_status': 'paid',
            'created_at': '2026-10-01T05:35:00.000Z',
            'agent': {'name': 'Ravi', 'agency_name': 'AirTrek India'},
          },
        ),
      ),
    );

    expect(r.booking!.requestId, r.id);
    expect(r.booking!.agent!.displayName, 'AirTrek India');
  });

  test('a payload missing required fields throws FormatException', () {
    expect(
      () => TripJson.request(JsonReader({'id': 'x'})),
      throwsA(isA<FormatException>()),
    );
  });

  test('builds the flight create payload the backend validates', () {
    final body = TripJson.create(
      NewTripRequest(
        type: TripType.flight,
        from: const Place(name: 'Chhatrapati Shivaji Intl', code: 'BOM'),
        to: const Place(name: 'Dubai Intl', code: 'DXB'),
        departDate: DateTime(2026, 11, 12),
        budget: 20000,
        adults: 2,
        contactEmail: 'asha@example.com',
        contactPhone: '+919810043210',
        requirements: '  Window seats  ',
      ),
    );

    expect(body['bookingType'], 'flight');
    expect(body['fromLocation'], 'Chhatrapati Shivaji Intl (BOM)');
    expect(body['departDate'], '2026-11-12');
    expect(body['requirements'], 'Window seats');
    final details = body['details']! as Map<String, Object?>;
    expect(details['class'], 'economy');
    expect(details['passengers'], {'adults': 2, 'children': 0, 'infants': 0});
    expect(details['from'], {
      'airportCode': 'BOM',
      'airportName': 'Chhatrapati Shivaji Intl',
    });
    expect(details['contactInfo'], {
      'email': 'asha@example.com',
      'phone': '+919810043210',
    });
  });

  test('builds the hotel payload with destination and guests', () {
    final body = TripJson.create(
      NewTripRequest(
        type: TripType.hotel,
        from: const Place(name: 'Goa', country: 'IN'),
        to: const Place(name: 'Calangute'),
        departDate: DateTime(2026, 12, 14),
        returnDate: DateTime(2026, 12, 17),
        budget: 4000,
        rooms: 2,
        contactEmail: 'a@b.co',
        contactPhone: '+919810043210',
      ),
    );

    expect(body['fromLocation'], 'Goa');
    expect(body['toLocation'], 'Goa');
    expect(body['returnDate'], '2026-12-17');
    final details = body['details']! as Map<String, Object?>;
    expect(details['destination'], {
      'city': 'Goa',
      'country': 'IN',
      'area': 'Calangute',
    });
    expect(details['guests'], {'numberOfRooms': 2, 'adults': 1, 'children': 0});
  });
}
