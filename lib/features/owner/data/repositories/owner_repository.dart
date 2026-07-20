import 'package:supabase_flutter/supabase_flutter.dart';
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
        .eq('is_active', true)
        .order('name');

    return (response as List)
        .map((row) => Salon.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  // ---------- Registering a brand-new salon ----------

  /// Creates a brand-new salon (as opposed to claiming an existing
  /// Google-Maps-imported listing) via the `create_owner_salon`
  /// function. That function enforces server-side that a second+ salon
  /// must share the exact name of one the caller already owns, and a
  /// database-level unique index on `lower(name)` rejects the name
  /// outright if it's already taken by anyone else - that index is the
  /// real anti-squatting protection, not this call itself.
  ///
  /// Throws a [PostgrestException] with a human-readable message on
  /// name conflicts or the "must match existing name" rule.
  Future<void> createOwnerSalon({
    required String name,
    required String address,
    required String city,
    String? area,
    String? phone,
    String? description,
  }) async {
    await SupabaseService.client.rpc('create_owner_salon', params: {
      'p_name': name,
      'p_address': address,
      'p_city': city,
      'p_area': area,
      'p_phone': phone,
      'p_description': description,
    });
  }

  // ---------- Ownership verification (for a 2nd+ salon) ----------

  /// Sends a 6-digit one-time code to the signed-in owner's own account
  /// email via Supabase's built-in email-OTP flow - no separate email
  /// provider needed. `shouldCreateUser: false` guards against ever
  /// creating a duplicate account; this is purely a re-verification of
  /// an existing session.
  ///
  /// Worth being clear about what this does and doesn't prove: it
  /// confirms the caller controls their own login email, which is a
  /// reasonable "are you sure / prove it's really you" step before
  /// registering another location. It does NOT independently verify
  /// that they're the legitimate owner of an existing real-world brand
  /// if that name belongs to someone else's account - the database's
  /// unique name index is what actually blocks that.
  Future<void> sendOwnershipVerificationOtp() async {
    final email = SupabaseService.currentUser!.email;
    if (email == null) {
      throw Exception('Your account has no email on file to verify.');
    }
    await SupabaseService.auth.signInWithOtp(email: email, shouldCreateUser: false);
  }

  /// Verifies the code from [sendOwnershipVerificationOtp]. Throws if
  /// the code is wrong or expired - Supabase's own server checks this,
  /// so it can't be bypassed by a modified client skipping the call.
  Future<void> verifyOwnershipOtp(String code) async {
    final email = SupabaseService.currentUser!.email;
    if (email == null) {
      throw Exception('Your account has no email on file to verify.');
    }
    await SupabaseService.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.email,
    );
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

  /// Closes/removes a salon from listings via the `delete_owner_salon`
  /// function - a soft delete (is_active = false), not a hard row
  /// delete, so past bookings and services stay intact for record
  /// purposes. Any of the salon's pending/confirmed bookings get
  /// cancelled as part of the same server-side operation. Re-validates
  /// ownership server-side, so it can't be spoofed by calling the API
  /// directly with someone else's salon id.
  Future<void> deleteSalon(String salonId) async {
    await SupabaseService.client.rpc('delete_owner_salon', params: {'p_salon_id': salonId});
  }

  // ---------- Salon info ----------

  /// Updates any subset of a salon's info fields. Renaming to a name
  /// that's already taken (by anyone) will throw a unique-violation
  /// [PostgrestException] via the database's name-protection index -
  /// callers should catch that and show a friendly message.
  Future<Salon> updateSalonInfo({
    required String salonId,
    String? name,
    String? address,
    String? city,
    String? area,
    String? description,
    String? phone,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (address != null) updates['address'] = address;
    if (city != null) updates['city'] = city;
    if (area != null) updates['area'] = area;
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
