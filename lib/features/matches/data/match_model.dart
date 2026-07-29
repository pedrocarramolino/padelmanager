class MatchModel {
  final String id;
  final String creatorId;
  final DateTime date;
  final String time;
  final String club;
  final String clubAddress;
  final String clubCity;
  final String courtNumber;
  final double totalPrice;
  final List<Map<String, dynamic>> players;
  final Map<String, bool> payments;

  MatchModel({
    required this.id,
    required this.creatorId,
    required this.date,
    required this.time,
    required this.club,
    required this.clubAddress,
    required this.clubCity,
    required this.courtNumber,
    required this.totalPrice,
    required this.players,
    required this.payments,
  });

  factory MatchModel.fromMap(Map<String, dynamic> map, String id) {
    return MatchModel(
      id: id,
      creatorId: map['creatorId'] ?? '',
      date: (map['date'] as dynamic).toDate(),
      time: map['time'] ?? '',
      club: map['club'] ?? '',
      clubAddress: map['clubAddress'] ?? '',
      clubCity: map['clubCity'] ?? '',
      courtNumber: map['courtNumber'] ?? '',
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      players: List<Map<String, dynamic>>.from(map['players'] ?? []),
      payments: Map<String, bool>.from(map['payments'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'date': date,
      'time': time,
      'club': club,
      'clubAddress': clubAddress,
      'clubCity': clubCity,
      'courtNumber': courtNumber,
      'totalPrice': totalPrice,
      'players': players,
      'payments': payments,
    };
  }
}
