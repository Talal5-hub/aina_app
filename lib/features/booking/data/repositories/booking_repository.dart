import 'package:aina/core/services/supabase_service.dart';
import 'package:aina/features/booking/data/models/booking.dart';

class BookingRepository {
  const BookingRepository();

  /// Creates a booking for the currently signed-in user. RLS requires
  /// `customer_id = auth.uid()`, so this throws (via Postgrest) if called
  /// without an active session - callers should only reach this screen
  /// while authenticated, which [RouteGuards] already enforces.
  Future<Booking> createBooking({
    required String salonId,
    required String serviceId,
    required DateTime bookingDate,
    required String bookingTime, // "HH:mm:ss"
    String? notes,
  }) async {
    final customerId = SupabaseService.currentUser!.id;

    final response = await SupabaseService.client
        .from('bookings')
        .insert({
      'customer_id': customerId,
      'salon_id': salonId,
      'service_id': serviceId,
      'booking_date': bookingDate.toIso8601String().split('T').first,
      'booking_time': bookingTime,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    })
        .select()
        .single();

    return Booking.fromJson(response);
  }

  /// Fetches the current user's bookings along with the salon and service
  /// details needed to display them, in a single round trip via Postgrest's
  /// embedded-resource syntax (requires the FKs bookings.salon_id ->
  /// salons.id and bookings.service_id -> services.id, which already exist).
  Future<List<Booking>> fetchMyBookings() async {
    final customerId = SupabaseService.currentUser!.id;

    final response = await SupabaseService.client
        .from('bookings')
        .select('*, salons(name, cover_image_url, address), services(name, price, duration_minutes)')
        .eq('customer_id', customerId)
        .order('booking_date', ascending: false)
        .order('booking_time', ascending: false);

    return (response as List)
        .map((row) => Booking.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Cancels a booking via the `cancel_booking` Postgres RPC rather than a
  /// direct table UPDATE. That function re-validates ownership and the
  /// "at least 2 days' notice" rule server-side (SECURITY DEFINER), so the
  /// rule can't be bypassed by calling the API directly - the client-side
  /// check in [Booking.isCancellable] only controls what the UI shows.
  ///
  /// Throws a [PostgrestException] (via the underlying client) with a
  /// human-readable message if the booking isn't the caller's, is already
  /// cancelled, or is within the no-cancellation window.
  Future<void> cancelBooking(String bookingId) async {
    await SupabaseService.client.rpc(
      'cancel_booking',
      params: {'p_booking_id': bookingId},
    );
  }
}