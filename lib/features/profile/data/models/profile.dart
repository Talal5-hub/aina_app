/// Mirrors the `profiles` table. `email` isn't stored here - it comes
/// from the Supabase auth user object instead, since that's the single
/// source of truth for it and keeping a duplicate copy risks drifting
/// out of sync after an email change.
class Profile {
  final String id;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String role; // 'customer' or 'salon_owner' - informational only,
                      // doesn't gate anything (see activeView)
  final String activeView; // 'customer' or 'business' - which experience
                            // is currently shown; synced across devices
  final DateTime createdAt;

  const Profile({
    required this.id,
    this.fullName,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.activeView,
    required this.createdAt,
  });

  bool get isOwner => role == 'salon_owner';
  bool get isBusinessView => activeView == 'business';

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'customer',
      activeView: json['active_view'] as String? ?? 'customer',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
