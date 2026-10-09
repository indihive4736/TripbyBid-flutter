import '../../../../core/network/json_reader.dart';
import '../../domain/entities/bid.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/new_trip_request.dart';
import '../../domain/entities/trip_detail.dart';
import '../../domain/entities/trip_details.dart';
import '../../domain/entities/trip_request.dart';

/// Parses the backend's snake_case trip payloads into domain entities, and
/// builds the camelCase create payload. Throws [FormatException] on payloads
/// missing required fields.
abstract final class TripJson {
  /// `BookingRequestResponse` from list and detail endpoints.
  static TripRequest request(JsonReader json) {
    final bids = json.objects('bids');
    // The list embeds `bids: [{count}]`; the detail embeds the bid rows.
    final embeddedCount = bids.length == 1 && bids.first.has('count')
        ? bids.first.integer('count')
        : null;
    final bidRows = embeddedCount == null ? bids : const <JsonReader>[];
    return TripRequest(
      id: json.string('id'),
      type: TripType.parse(json.string('booking_type')),
      fromLocation: json.stringOrNull('from_location') ?? '',
      toLocation: json.stringOrNull('to_location') ?? '',
      departDate: json.date('depart_date'),
      returnDate: json.dateOrNull('return_date'),
      budget: json.number('budget'),
      requirements: json.stringOrNull('requirements'),
      status: json.string('status'),
      bidsCount:
          json.intOrNull('bids_count') ?? embeddedCount ?? bidRows.length,
      createdAt: json.date('created_at'),
      expiresAt: json.dateOrNull('expires_at'),
      details: switch (json.object('details')) {
        final d? => details(d),
        null => null,
      },
      booking: switch (json.object('booking')) {
        final b? => booking(b, requestId: json.string('id')),
        null => null,
      },
      bids: [for (final b in bidRows) bid(b)],
    );
  }

  static TripDetails details(JsonReader d) => TripDetails(
    adults: d.integer('adults', 1),
    children:
        d.integer('children') +
        d.integer('children_with_bed') +
        d.integer('children_no_bed'),
    infants: d.integer('infants'),
    seniors: d.integer('seniors'),
    rooms: d.intOrNull('number_of_rooms'),
    tripType: d.stringOrNull('trip_type'),
    travelClass: d.stringOrNull('class_name') ?? d.stringOrNull('train_class'),
    fromCode:
        d.stringOrNull('from_airport_code') ??
        d.stringOrNull('from_station_code'),
    toCode:
        d.stringOrNull('to_airport_code') ?? d.stringOrNull('to_station_code'),
    fromName:
        d.stringOrNull('from_airport_name') ??
        d.stringOrNull('from_station_name'),
    toName:
        d.stringOrNull('to_airport_name') ?? d.stringOrNull('to_station_name'),
    fromCity: d.stringOrNull('from_city'),
    toCity: d.stringOrNull('to_city'),
    preferredAirline: d.stringOrNull('preferred_airline'),
    directOnly: d.boolean('direct_flights_only'),
    flexibleDates: d.boolean('flexible_dates'),
    quota: d.stringOrNull('quota'),
    berthPreference: d.stringOrNull('berth_preference'),
    preferredDepartureTime: d.stringOrNull('preferred_departure_time'),
    destinationCity: d.stringOrNull('destination_city'),
    destinationArea: d.stringOrNull('destination_area'),
    destinationCountry: d.stringOrNull('destination_country'),
    roomType: d.stringOrNull('room_type'),
    starRating: d.intOrNull('star_rating'),
    breakfastIncluded: d.boolean('breakfast_included'),
  );

  /// `BidResponse`, optionally with the agent's `users` embed.
  static Bid bid(JsonReader b) {
    final agent = b.object('users');
    return Bid(
      id: b.string('id'),
      requestId: b.string('request_id'),
      agentId: b.stringOrNull('agent_id') ?? '',
      price: b.number('price'),
      status: BidStatus.parse(b.stringOrNull('status') ?? 'active'),
      agentName:
          b.stringOrNull('agent_name') ??
          agent?.stringOrNull('name') ??
          'Agent',
      agentRating:
          b.numberOrNull('agent_rating') ?? agent?.numberOrNull('rating') ?? 0,
      agentReviews: b.integer('agent_reviews'),
      agentTrips: agent?.intOrNull('total_bookings'),
      agentVerified: agent?.boolean('verified') ?? false,
      title: b.stringOrNull('title'),
      inclusions: b.strings('inclusions'),
      timeline: b.stringOrNull('timeline'),
      notes: b.stringOrNull('notes'),
      cancellationPolicy: b.stringOrNull('cancellation_policy'),
      refundTerms: b.stringOrNull('refund_terms'),
      expiresAt: b.dateOrNull('expires_at'),
      acceptedAt: b.dateOrNull('accepted_at'),
      paymentDueAt: b.dateOrNull('payment_due_at'),
      createdAt: b.date('created_at'),
    );
  }

  /// `BookingResponse` (detail) or the `booking` embed in request lists.
  static Booking booking(JsonReader b, {String? requestId}) {
    final agentJson = b.object('agent') ?? b.object('users');
    return Booking(
      id: b.string('id'),
      requestId: b.stringOrNull('request_id') ?? requestId ?? '',
      status: b.string('status'),
      price: b.number('price'),
      platformFee: b.number('platform_fee'),
      paymentStatus: b.stringOrNull('payment_status'),
      paymentId: b.stringOrNull('payment_id'),
      paymentDate: b.dateOrNull('payment_date'),
      completedAt: b.dateOrNull('completed_at'),
      cancelledAt: b.dateOrNull('cancelled_at'),
      cancellationReason: b.stringOrNull('cancellation_reason'),
      referenceNumber: b.stringOrNull('reference_number'),
      agent: agentJson == null
          ? null
          : AgentProfile(
              id: agentJson.stringOrNull('id') ?? b.stringOrNull('agent_id'),
              name: agentJson.stringOrNull('name') ?? 'Your agent',
              rating: agentJson.number('rating'),
              totalBookings: agentJson.intOrNull('total_bookings'),
              agencyName: agentJson.stringOrNull('agency_name'),
              verified: agentJson.boolean('verified'),
              avatarUrl: agentJson.stringOrNull('avatar_url'),
            ),
      documents: [
        for (final d in b.objects('documents'))
          TripDocument(
            id: d.string('id'),
            type: d.stringOrNull('type') ?? 'other',
            fileName: d.stringOrNull('file_name') ?? 'Document',
            status: d.stringOrNull('status') ?? 'pending',
            uploadedAt:
                d.dateOrNull('uploaded_at') ??
                d.dateOrNull('created_at') ??
                DateTime.fromMillisecondsSinceEpoch(0),
            url: d.stringOrNull('signed_url'),
          ),
      ],
      createdAt: b.date('created_at'),
    );
  }

  static CancellationQuote quote(JsonReader q) => CancellationQuote(
    fare: q.number('fare'),
    charge: q.number('charge'),
    platformFee: q.number('platform_fee'),
    platformFeeKept: q.boolean('platform_fee_kept', true),
    refund: q.number('refund'),
    policyTitle: q.object('policy')?.stringOrNull('title'),
    appliesUntil: q.object('tier')?.dateOrNull('applies_until'),
  );

  /// The `POST /booking-requests` body (camelCase, typed `details`).
  static Map<String, Object?> create(NewTripRequest r) {
    final contact = {'email': r.contactEmail, 'phone': r.contactPhone};
    final requirements = r.requirements?.trim();
    final hasNotes = requirements != null && requirements.isNotEmpty;
    return {
      'bookingType': r.type.apiValue,
      'fromLocation': r.from.label,
      'toLocation': r.type == TripType.hotel ? r.from.name : r.to.label,
      'departDate': _date(r.departDate),
      if (r.returnDate != null) 'returnDate': _date(r.returnDate!),
      'budget': r.budget,
      if (hasNotes) 'requirements': requirements,
      'details': switch (r.type) {
        TripType.flight || TripType.package => {
          'tripType': r.tripType,
          'from': _airport(r.from),
          'to': _airport(r.to),
          'passengers': {
            'adults': r.adults,
            'children': r.children,
            'infants': r.infants,
          },
          'class': r.travelClass ?? 'economy',
          if (r.preferredAirline?.trim().isNotEmpty ?? false)
            'preferredAirline': r.preferredAirline!.trim(),
          'directFlightsOnly': r.directOnly,
          'flexibleDates': r.flexibleDates,
          'contactInfo': contact,
        },
        TripType.train => {
          'from': {
            'stationCode': r.from.code ?? '',
            'stationName': r.from.name,
          },
          'to': {'stationCode': r.to.code ?? '', 'stationName': r.to.name},
          'journeyDate': _date(r.departDate),
          'passengers': {
            'adults': r.adults,
            'children': r.children,
            'seniors': r.seniors,
          },
          'class': r.travelClass ?? 'sleeper',
          if (r.quota != null) 'quota': r.quota,
          if (r.berthPreference != null) 'berthPreference': r.berthPreference,
          'contactInfo': contact,
        },
        TripType.hotel => {
          'destination': {
            'city': r.from.name,
            'country': r.from.country ?? 'IN',
            if (r.to.name.trim().isNotEmpty && r.to.name != r.from.name)
              'area': r.to.name.trim(),
          },
          'guests': {
            'numberOfRooms': r.rooms,
            'adults': r.adults,
            'children': r.children,
          },
          'preferences': {
            if (r.roomType != null) 'roomType': r.roomType,
            if (r.starRating != null) 'starRating': r.starRating,
          },
          if (hasNotes) 'specialRequests': requirements,
          'contactInfo': contact,
          'options': {'breakfastIncluded': r.breakfastIncluded},
        },
      },
    };
  }

  static Map<String, Object?> _airport(Place p) => {
    'airportCode': p.code ?? '',
    'airportName': p.name,
    if (p.city != null) 'city': p.city,
    if (p.country != null) 'country': p.country,
  };

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
