import 'package:aina/features/booking/data/models/booking.dart';

/// A booking as seen from the salon owner's side: the base [Booking]
/// plus the customer's name/phone, resolved separately from `profiles`
/// since `bookings.customer_id` and `profiles.id` both reference
/// `auth.users.id` independently - there's no direct FK between them
/// for Postgrest to auto-embed, so [OwnerRepository] joins them
/// client-side after two queries.
class OwnerBooking {
  final Booking booking;
  final String? customerName;
  final String? customerPhone;

  const OwnerBooking({
    required this.booking,
    this.customerName,
    this.customerPhone,
  });
}
