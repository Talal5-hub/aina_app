import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina/features/owner/data/repositories/owner_repository.dart';

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  return const OwnerRepository();
});

final myOwnedSalonsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(ownerRepositoryProvider).fetchMyOwnedSalons();
});

final salonBookingsProvider = FutureProvider.autoDispose.family((ref, String salonId) {
  return ref.watch(ownerRepositoryProvider).fetchBookingsForSalon(salonId);
});
