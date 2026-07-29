class ClubModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final double defaultPrice;

  ClubModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.defaultPrice,
  });

  factory ClubModel.fromMap(Map<String, dynamic> map, String id) {
    return ClubModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      defaultPrice: (map['defaultPrice'] ?? 0).toDouble(),
    );
  }
}
