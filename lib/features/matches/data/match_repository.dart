import 'package:cloud_firestore/cloud_firestore.dart';
import 'match_model.dart';

class MatchRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Partidos desde [from] (inclusive) en adelante, del más cercano al
  /// más lejano. [limit] acota cuántos se traen de Firestore.
  Stream<List<MatchModel>> getUpcomingMatches({
    required DateTime from,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = firestore
        .collection('matches')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .orderBy('date');
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map(_mapDocs);
  }

  /// Partidos anteriores a [before], del más reciente al más antiguo.
  /// [limit] acota cuántos se traen de Firestore.
  Stream<List<MatchModel>> getPlayedMatches({
    required DateTime before,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = firestore
        .collection('matches')
        .where('date', isLessThan: Timestamp.fromDate(before))
        .orderBy('date', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map(_mapDocs);
  }

  List<MatchModel> _mapDocs(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => MatchModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<MatchModel?> watchMatch(String matchId) {
    return firestore.collection('matches').doc(matchId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return MatchModel.fromMap(data, doc.id);
    });
  }

  Future<void> createMatch(MatchModel match) async {
    await firestore.collection('matches').add(match.toMap());
  }

  Future<void> updateMatch(MatchModel match) async {
    await firestore.collection('matches').doc(match.id).update(match.toMap());
  }

  Future<void> deleteMatch(String matchId) async {
    await firestore.collection('matches').doc(matchId).delete();
  }

  Future<void> updatePayments(
    String matchId,
    Map<String, bool> payments,
  ) async {
    await firestore.collection('matches').doc(matchId).update({
      'payments': payments,
    });
  }
}
