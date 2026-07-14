import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina/features/salon/data/models/salon.dart';
import 'package:aina/features/salon/data/models/service.dart';
import 'package:aina/features/salon/data/repositories/salon_repository.dart';

final salonRepositoryProvider = Provider<SalonRepository>((ref) {
  return const SalonRepository();
});

final salonListProvider = FutureProvider.autoDispose<List<Salon>>((ref) {
  return ref.watch(salonRepositoryProvider).fetchSalons();
});

/// Family provider keyed by salonId - used by the salon details screen.
final salonDetailsProvider =
    FutureProvider.autoDispose.family<Salon, String>((ref, salonId) {
  return ref.watch(salonRepositoryProvider).fetchSalonById(salonId);
});

final salonServicesProvider =
    FutureProvider.autoDispose.family<List<Service>, String>((ref, salonId) {
  return ref.watch(salonRepositoryProvider).fetchServicesForSalon(salonId);
});
