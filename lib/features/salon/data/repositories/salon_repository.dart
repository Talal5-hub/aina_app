import 'package:aina/core/services/supabase_service.dart';
import 'package:aina/features/salon/data/models/salon.dart';
import 'package:aina/features/salon/data/models/service.dart';

class SalonRepository {
  const SalonRepository();

  /// Public read - RLS allows anyone to select from `salons`, so this
  /// works whether or not a session is active.
  Future<List<Salon>> fetchSalons() async {
    final response = await SupabaseService.client
        .from('salons')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => Salon.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<Salon> fetchSalonById(String salonId) async {
    final response =
        await SupabaseService.client.from('salons').select().eq('id', salonId).single();

    return Salon.fromJson(response);
  }

  Future<List<Service>> fetchServicesForSalon(String salonId) async {
    final response = await SupabaseService.client
        .from('services')
        .select()
        .eq('salon_id', salonId)
        .order('created_at');

    return (response as List)
        .map((row) => Service.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
