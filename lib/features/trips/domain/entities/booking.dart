/// The paid booking that follows a selected bid.
final class Booking {
  const Booking({
    required this.id,
    required this.requestId,
    required this.status,
    required this.price,
    required this.createdAt,
    this.platformFee = 0,
    this.paymentStatus,
    this.paymentId,
    this.paymentDate,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.referenceNumber,
    this.agent,
    this.documents = const [],
  });

  final String id;
  final String requestId;

  /// Raw booking status (`confirmed`, `ticket_uploaded`, `completed`…).
  final String status;

  /// Amount paid in INR.
  final double price;

  /// Platform service charge included in [price].
  final double platformFee;

  /// `pending`, `paid` or `refunded`.
  final String? paymentStatus;
  final String? paymentId;
  final DateTime? paymentDate;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  /// e.g. `TBB-X7K2-9QPM`.
  final String? referenceNumber;
  final AgentProfile? agent;
  final List<TripDocument> documents;
  final DateTime createdAt;

  /// The latest ticket uploaded by the agent.
  TripDocument? get ticket => documents
      .where((d) => d.type == 'ticket')
      .fold<TripDocument?>(
        null,
        (latest, d) => latest == null || d.uploadedAt.isAfter(latest.uploadedAt)
            ? d
            : latest,
      );
}

/// The agent behind a booking or bid, as far as the traveler can see.
final class AgentProfile {
  const AgentProfile({
    required this.name,
    this.id,
    this.rating = 0,
    this.totalBookings,
    this.agencyName,
    this.verified = false,
    this.avatarUrl,
  });

  final String? id;
  final String name;
  final double rating;
  final int? totalBookings;
  final String? agencyName;
  final bool verified;
  final String? avatarUrl;

  /// Agency name when set, otherwise the person.
  String get displayName =>
      agencyName?.trim().isNotEmpty ?? false ? agencyName! : name;
}

/// A file attached to a booking (e-ticket, payment proof…).
final class TripDocument {
  const TripDocument({
    required this.id,
    required this.type,
    required this.fileName,
    required this.status,
    required this.uploadedAt,
    this.url,
  });

  final String id;

  /// `ticket`, `payment_proof`, `id_document`, `other`.
  final String type;
  final String fileName;

  /// `pending`, `verified`, `rejected`.
  final String status;
  final DateTime uploadedAt;

  /// Short-lived signed download URL, when available.
  final String? url;
}
