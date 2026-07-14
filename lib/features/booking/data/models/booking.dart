enum BookingStatus { pending, confirmed, completed, cancelled }

BookingStatus _statusFromString(String value) {
  return BookingStatus.values.firstWhere(
        (s) => s.name == value,
    orElse: () => BookingStatus.pending,
  );
}

/// Cancellations are only allowed this many days (or more) before the
/// appointment. Mirrored server-side by the `cancel_booking` Postgres
/// function - this client-side copy is only used to decide what the UI
/// shows (enabled/disabled button, messaging); the server is the source
/// of truth and re-checks the same rule.
const int kMinCancellationNoticeDays = 2;

class Booking {
  final String id;
  final String customerId;
  final String salonId;
  final String serviceId;
  final DateTime bookingDate;
  final String bookingTime; // stored as "HH:mm:ss" text from Postgres `time`
  final BookingStatus status;
  final String? notes;
  final DateTime createdAt;

  // Populated when fetched via the joined query (fetchMyBookings). Absent
  // (null) on the plain insert response from createBooking, which doesn't
  // select these related tables.
  final String? salonName;
  final String? salonCoverImageUrl;
  final String? salonAddress;
  final String? serviceName;
  final double? servicePrice;
  final int? serviceDurationMinutes;

  const Booking({
    required this.id,
    required this.customerId,
    required this.salonId,
    required this.serviceId,
    required this.bookingDate,
    required this.bookingTime,
    required this.status,
    this.notes,
    required this.createdAt,
    this.salonName,
    this.salonCoverImageUrl,
    this.salonAddress,
    this.serviceName,
    this.servicePrice,
    this.serviceDurationMinutes,
  });

  /// Postgrest embeds a to-one related row as a Map (or occasionally a
  /// single-element List, depending on how the relationship was inferred)
  /// keyed by the related table's name - handle both shapes defensively.
  static Map<String, dynamic>? _embedded(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
      return value.first as Map<String, dynamic>;
    }
    return null;
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    final salon = _embedded(json, 'salons');
    final service = _embedded(json, 'services');

    return Booking(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      salonId: json['salon_id'] as String,
      serviceId: json['service_id'] as String,
      bookingDate: DateTime.parse(json['booking_date'] as String),
      bookingTime: json['booking_time'] as String,
      status: _statusFromString(json['status'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      salonName: salon?['name'] as String?,
      salonCoverImageUrl: salon?['cover_image_url'] as String?,
      salonAddress: salon?['address'] as String?,
      serviceName: service?['name'] as String?,
      servicePrice: (service?['price'] as num?)?.toDouble(),
      serviceDurationMinutes: service?['duration_minutes'] as int?,
    );
  }

  /// Combines `booking_date` + `booking_time` into a single local DateTime
  /// representing the actual appointment moment.
  DateTime get appointmentDateTime {
    final parts = bookingTime.split(':');
    final hour = int.tryParse(parts.elementAt(0)) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts.elementAt(1)) ?? 0 : 0;
    final second = parts.length > 2 ? int.tryParse(parts.elementAt(2)) ?? 0 : 0;
    return DateTime(
      bookingDate.year,
      bookingDate.month,
      bookingDate.day,
      hour,
      minute,
      second,
    );
  }

  /// Whether this booking is currently eligible to be cancelled: not
  /// already cancelled/completed, and at least [kMinCancellationNoticeDays]
  /// full days remain before the appointment.
  bool get isCancellable {
    if (status == BookingStatus.cancelled || status == BookingStatus.completed) {
      return false;
    }
    final notice = appointmentDateTime.difference(DateTime.now());
    return notice >= const Duration(days: kMinCancellationNoticeDays);
  }
}