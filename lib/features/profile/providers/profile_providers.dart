import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina/features/profile/data/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return const ProfileRepository();
});

final myProfileProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(profileRepositoryProvider).fetchMyProfile();
});
