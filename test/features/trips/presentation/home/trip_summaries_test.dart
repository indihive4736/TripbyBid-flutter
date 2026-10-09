import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_summaries.dart';

import '../../trips_fakes.dart';

void main() {
  final today = DateTime(2026, 10, 10, 20, 30);

  final bidsIn = TripFixtures.request(id: 'bids', bidsCount: 2);
  final upcomingSoon = TripFixtures.request(
    id: 'soon',
    status: 'confirmed',
    departDate: DateTime(2026, 10, 13),
    booking: TripFixtures.booking(price: 6998),
  );
  final upcomingLater = TripFixtures.request(
    id: 'later',
    status: 'ticket_uploaded',
    departDate: DateTime(2026, 12, 1),
    booking: TripFixtures.booking(price: 10000),
  );
  final departed = TripFixtures.request(
    id: 'gone',
    status: 'confirmed',
    departDate: DateTime(2026, 10, 1),
    booking: TripFixtures.booking(price: 3000),
  );
  final completed = TripFixtures.request(
    id: 'done',
    status: 'completed',
    booking: TripFixtures.booking(price: 1000),
  );
  final due = TripFixtures.request(id: 'due', status: 'payment_pending');

  group('highlight', () {
    test('prefers a payment that is due', () {
      final h = TripSummaries.highlight([
        bidsIn,
        upcomingSoon,
        due,
      ], today: today);
      expect(h, TripHighlight(HighlightKind.paymentDue, due));
    });

    test('then the next booked trip that has not departed', () {
      final h = TripSummaries.highlight([
        bidsIn,
        upcomingLater,
        departed,
        upcomingSoon,
      ], today: today);
      expect(h, TripHighlight(HighlightKind.upcoming, upcomingSoon));
    });

    test('then the newest request with bids in', () {
      final h = TripSummaries.highlight([departed, bidsIn], today: today);
      expect(h, TripHighlight(HighlightKind.bidsIn, bidsIn));
    });

    test('is null when nothing stands out', () {
      expect(
        TripSummaries.highlight([
          TripFixtures.request(status: 'pending'),
        ], today: today),
        isNull,
      );
    });
  });

  test('daysUntil counts calendar days', () {
    expect(TripSummaries.daysUntil(DateTime(2026, 10, 13), today: today), 3);
    expect(TripSummaries.daysUntil(DateTime(2026, 10, 10), today: today), 0);
    expect(TripSummaries.daysUntil(DateTime(2026, 10, 9), today: today), -1);
  });

  test('booked count and total spent cover booked and completed trips', () {
    final trips = [bidsIn, due, upcomingSoon, departed, completed];
    expect(TripSummaries.bookedCount(trips), 3);
    expect(TripSummaries.totalSpent(trips), 6998 + 3000 + 1000);
  });

  test('best offer and savings', () {
    expect(TripSummaries.bestOffer([]), isNull);
    expect(
      TripSummaries.bestOffer([
        TripFixtures.bid(price: 18450),
        TripFixtures.bid(id: 'b2', price: 17999),
      ]),
      17999,
    );
    expect(TripSummaries.savingsPercent(best: 18000, budget: 20000), 10);
    expect(TripSummaries.savingsPercent(best: 21000, budget: 20000), isNull);
    expect(TripSummaries.savingsPercent(best: 19990, budget: 20000), isNull);
  });
}
