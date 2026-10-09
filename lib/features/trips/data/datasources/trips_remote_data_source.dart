import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../../../core/network/parse.dart';
import '../../domain/entities/bid.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/new_trip_request.dart';
import '../../domain/entities/trip_detail.dart';
import '../../domain/entities/trip_request.dart';
import '../models/trip_json.dart';

/// Booking requests, bids and bookings on the NestJS API. Throws
/// `AppException`s.
abstract interface class TripsRemoteDataSource {
  Future<List<TripRequest>> getMyTrips();
  Future<TripRequest> getRequest(String requestId);
  Future<List<Bid>> getActiveBids(String requestId);
  Future<Booking?> getBookingForRequest(String requestId);
  Future<TripRequest> createRequest(NewTripRequest request);
  Future<TripRequest> updateRequest(
    String requestId, {
    double? budget,
    String? requirements,
  });
  Future<void> deleteRequest(String requestId);
  Future<Bid> acceptBid(String bidId);
  Future<Bid> releaseBid(String bidId);
  Future<CancellationQuote> getCancellationQuote(String bookingId);
  Future<Booking> cancelBooking(
    String bookingId, {
    required double expectedRefund,
    String? reason,
  });
  Future<void> verifyTicket(String bookingId);
  Future<void> requestCorrection(
    String bookingId, {
    required List<String> reasons,
    String? details,
  });
  Future<void> raiseSupportTicket(
    String bookingId, {
    required String description,
  });
  Future<void> createReview({
    required String bookingId,
    required String agentId,
    required int rating,
    String? comment,
  });
}

class TripsRemoteDataSourceImpl implements TripsRemoteDataSource {
  const TripsRemoteDataSourceImpl(this._api);

  final ApiClient _api;

  @override
  Future<List<TripRequest>> getMyTrips() async {
    final json = await _api.get('/booking-requests', query: {'limit': '100'});
    return parseResponse(
      () => [for (final r in readList(json)) TripJson.request(r)],
    );
  }

  @override
  Future<TripRequest> getRequest(String requestId) async {
    final json = await _api.get('/booking-requests/$requestId');
    return parseResponse(() => TripJson.request(JsonReader.of(json)));
  }

  @override
  Future<List<Bid>> getActiveBids(String requestId) async {
    final json = await _api.get(
      '/bids/request/$requestId',
      query: {'limit': '50'},
    );
    return parseResponse(
      () => [for (final b in readList(json)) TripJson.bid(b)],
    );
  }

  @override
  Future<Booking?> getBookingForRequest(String requestId) async {
    final json = await _api.get('/bookings/request/$requestId');
    if (json == null) return null;
    return parseResponse(() => TripJson.booking(JsonReader.of(json)));
  }

  @override
  Future<TripRequest> createRequest(NewTripRequest request) async {
    final json = await _api.post(
      '/booking-requests',
      body: TripJson.create(request),
    );
    return parseResponse(() => TripJson.request(JsonReader.of(json)));
  }

  @override
  Future<TripRequest> updateRequest(
    String requestId, {
    double? budget,
    String? requirements,
  }) async {
    final json = await _api.patch(
      '/booking-requests/$requestId',
      body: {
        if (budget != null) 'budget': budget,
        if (requirements != null)
          'requirements': requirements.trim().isEmpty ? null : requirements,
      },
    );
    return parseResponse(() => TripJson.request(JsonReader.of(json)));
  }

  @override
  Future<void> deleteRequest(String requestId) =>
      _api.delete('/booking-requests/$requestId');

  @override
  Future<Bid> acceptBid(String bidId) async {
    final json = await _api.post('/bids/$bidId/accept');
    return parseResponse(() => TripJson.bid(JsonReader.of(json)));
  }

  @override
  Future<Bid> releaseBid(String bidId) async {
    final json = await _api.post('/bids/$bidId/release');
    return parseResponse(() => TripJson.bid(JsonReader.of(json)));
  }

  @override
  Future<CancellationQuote> getCancellationQuote(String bookingId) async {
    final json = await _api.get('/bookings/$bookingId/cancellation-quote');
    return parseResponse(() => TripJson.quote(JsonReader.of(json)));
  }

  @override
  Future<Booking> cancelBooking(
    String bookingId, {
    required double expectedRefund,
    String? reason,
  }) async {
    final json = await _api.patch(
      '/bookings/$bookingId/status',
      body: {
        'status': 'cancelled',
        'expectedRefund': (expectedRefund * 100).round() / 100,
        if (reason != null && reason.trim().isNotEmpty)
          'cancellationReason': reason.trim(),
      },
    );
    return parseResponse(() => TripJson.booking(JsonReader.of(json)));
  }

  @override
  Future<void> verifyTicket(String bookingId) =>
      _api.post('/verification/bookings/$bookingId/verify-ticket');

  @override
  Future<void> requestCorrection(
    String bookingId, {
    required List<String> reasons,
    String? details,
  }) => _api.post(
    '/verification/bookings/$bookingId/correction-request',
    body: {
      'reasons': reasons,
      if (details != null && details.trim().isNotEmpty)
        'additionalDetails': details.trim(),
    },
  );

  @override
  Future<void> raiseSupportTicket(
    String bookingId, {
    required String description,
  }) => _api.post(
    '/verification/bookings/$bookingId/support-ticket',
    body: {
      'subject': 'Help with my booking',
      'description': description,
      'priority': 'medium',
    },
  );

  @override
  Future<void> createReview({
    required String bookingId,
    required String agentId,
    required int rating,
    String? comment,
  }) => _api.post(
    '/reviews',
    body: {
      'bookingId': bookingId,
      'agentId': agentId,
      'rating': rating,
      if (comment != null) 'comment': comment,
    },
  );
}
