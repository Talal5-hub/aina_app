/// Mirrors the `salons` table. A hand-written model (no freezed/json_serializable
/// codegen) so it works immediately without a `build_runner` step.
class Salon {
  final String id;
  // Nullable: salons imported from Google Maps have no owner until a real
  // business owner signs up and claims the listing (see `isClaimed`).
  final String? ownerId;
  final String name;
  final String? description;
  final String? address;
  final String? city;
  final String? area;
  final double? latitude;
  final double? longitude;
  final String? coverImageUrl;
  final String? phone;
  final bool isVerified;
  final bool isClaimed;
  final double ratingAvg;
  final int ratingCount;
  final DateTime createdAt;

  const Salon({
    required this.id,
    this.ownerId,
    required this.name,
    this.description,
    this.address,
    this.city,
    this.area,
    this.latitude,
    this.longitude,
    this.coverImageUrl,
    this.phone,
    required this.isVerified,
    this.isClaimed = true,
    required this.ratingAvg,
    required this.ratingCount,
    required this.createdAt,
  });

  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      area: json['area'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      coverImageUrl: json['cover_image_url'] as String?,
      phone: json['phone'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      // Older rows (created before the Google Maps import) won't have this
      // column populated in every query shape, so default to true/"claimed".
      isClaimed: json['is_claimed'] as bool? ?? true,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}