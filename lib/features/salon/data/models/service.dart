class Service {
  final String id;
  final String salonId;
  final String name;
  final String? description;
  final double price;
  final int durationMinutes;
  final String? category;

  const Service({
    required this.id,
    required this.salonId,
    required this.name,
    this.description,
    required this.price,
    required this.durationMinutes,
    this.category,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      salonId: json['salon_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      durationMinutes: json['duration_minutes'] as int,
      category: json['category'] as String?,
    );
  }
}
