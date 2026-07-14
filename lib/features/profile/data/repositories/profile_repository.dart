import 'package:aina/core/services/supabase_service.dart';
import 'package:aina/features/profile/data/models/profile.dart';

class ProfileRepository {
  const ProfileRepository();

  Future<Profile> fetchMyProfile() async {
    final userId = SupabaseService.currentUser!.id;

    final response = await SupabaseService.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return Profile.fromJson(response);
  }

  Future<Profile> updateMyProfile({String? fullName, String? phone}) async {
    final userId = SupabaseService.currentUser!.id;

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;

    final response = await SupabaseService.client
        .from('profiles')
        .update(updates)
        .eq('id', userId)
        .select()
        .single();

    return Profile.fromJson(response);
  }
}
