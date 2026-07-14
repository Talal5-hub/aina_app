import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina/features/booking/data/models/booking.dart';
import 'package:aina/features/booking/data/repositories/booking_repository.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return const BookingRepository();
});

final myBookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) {
  return ref.watch(bookingRepositoryProvider).fetchMyBookings();
});
