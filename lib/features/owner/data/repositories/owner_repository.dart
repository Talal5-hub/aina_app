import 'package:aina/core/services/supabase_service.dart';
import 'package:aina/features/booking/data/models/booking.dart';
import 'package:aina/features/owner/data/models/owner_booking.dart';
import 'package:aina/features/salon/data/models/salon.dart';
import 'package:aina/features/salon/data/models/service.dart';

class OwnerRepository {
  const OwnerRepository();

  // ---------- Claiming ----------

  /// Claims an unclaimed salon for the current user via the
  /// `claim_salon` Postgres function, which re-validates server-side
  /// that the salon is actually unclaimed before assigning ownership -
  /// this can't be spoofed by calling the API directly. The caller
  /// should invalidate `salonDetailsProvider` afterwards to pick up the
  /// change rather than relying on a parsed return value here.
  Future<void> claimSalon(String salonId) async {
    await SupabaseService.client.rpc('claim_salon', params: {'p_salon_id': salonId});
  }

  Future<List<Salon>> fetchMyOwnedSalons() async {
    final userId = SupabaseService.currentUser!.id;

    final response = await SupabaseService.client
        .from('salons')
        .select()
        .eq('owner_id', userId)
        .order('name');

    return (response as List)
        .map((row) => Salon.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  // ---------- Bookings ----------

  /// Fetches bookings for [salonId] along with the booked service and
  /// the customer's name/phone. RLS on `bookings` only allows this to
  /// return rows if the caller actually owns the salon.
  Future<List<OwnerBooking>> fetchBookingsForSalon(String salonId) async {
    final bookingRows = await SupabaseService.client
        .from('bookings')
        .select('*, services(name, price, duration_minutes)')
        .eq('salon_id', salonId)
        .order('booking_date', ascending: false)
        .order('booking_time', ascending: false);

    final bookings = (bookingRows as List)
        .map((row) => Booking.fromJson(row as Map<String, dynamic>))
        .toList();

    if (bookings.isEmpty) return [];

    final customerIds = bookings.map((b) => b.customerId).toSet().toList();
    final profileRows = await SupabaseService.client
        .from('profiles')
        .select('id, full_name, phone')
        .inFilter('id', customerIds);

    final profilesById = {
      for (final row in (profileRows as List))
        (row as Map<String, dynamic>)['id'] as String: row,
    };

    return bookings.map((b) {
      final profile = profilesById[b.customerId];
      return OwnerBooking(
        booking: b,
        customerName: profile?['full_name'] as String?,
        customerPhone: profile?['phone'] as String?,
      );
    }).toList();
  }

  /// Updates a booking's status via the `update_booking_status`
  /// function, which enforces server-side that the caller owns the
  /// salon, the status is a valid value, and the booking isn't already
  /// in a terminal state (cancelled/completed).
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    await SupabaseService.client.rpc(
      'update_booking_status',
      params: {'p_booking_id': bookingId, 'p_new_status': status.name},
    );
  }

  // ---------- Services ----------

  Future<Service> addService({
    required String salonId,
    required String name,
    String? description,
    required double price,
    required int durationMinutes,
    String? category,
  }) async {
    final response = await SupabaseService.client
        .from('services')
        .insert({
          'salon_id': salonId,
          'name': name,
          if (description != null && description.isNotEmpty) 'description': description,
          'price': price,
          'duration_minutes': durationMinutes,
          if (category != null && category.isNotEmpty) 'category': category,
        })
        .select()
        .single();
    return Service.fromJson(response);
  }

  Future<Service> updateService({
    required String serviceId,
    required String name,
    String? description,
    required double price,
    required int durationMinutes,
    String? category,
  }) async {
    final response = await SupabaseService.client
        .from('services')
        .update({
          'name': name,
          'description': description,
          'price': price,
          'duration_minutes': durationMinutes,
          'category': category,
        })
        .eq('id', serviceId)
        .select()
        .single();
    return Service.fromJson(response);
  }

  Future<void> deleteService(String serviceId) async {
    await SupabaseService.client.from('services').delete().eq('id', serviceId);
  }

  // ---------- Salon info ----------

  Future<Salon> updateSalonInfo({
    required String salonId,
    String? description,
    String? phone,
  }) async {
    final updates = <String, dynamic>{};
    if (description != null) updates['description'] = description;
    if (phone != null) updates['phone'] = phone;

    final response = await SupabaseService.client
        .from('salons')
        .update(updates)
        .eq('id', salonId)
        .select()
        .single();
    return Salon.fromJson(response);
  }
}
