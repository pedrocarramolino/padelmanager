class PlayerModel {
  final String id;
  final String userId;
  final String name;
  final String surname;
  final String email;
  final String phone;
  final double level;
  final String position;
  final String photoUrl;

  PlayerModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.surname,
    required this.email,
    required this.phone,
    required this.level,
    required this.position,
    required this.photoUrl,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map, String id) {
    return PlayerModel(
      id: id,
      userId: map['userId']?.toString() ?? id,
      name: map['name']?.toString() ?? '',
      surname: map['surname']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      level: _parseLevel(map['level']),
      position: map['position']?.toString() ?? 'Derecha',
      photoUrl: map['photoUrl']?.toString() ?? '',
    );
  }

  static double _parseLevel(dynamic value) {
    if (value == null) {
      return 1.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 1.0;
    }

    return 1.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'surname': surname,
      'email': email,
      'phone': phone,
      'level': level,
      'position': position,
      'photoUrl': photoUrl,
    };
  }
}