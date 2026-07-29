import 'package:cloud_firestore/cloud_firestore.dart';
import 'player_model.dart';

class PlayerRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Jugadores por orden alfabético. [limit] acota cuántos se traen de
  /// Firestore; pásalo a null para obtener la colección completa (por
  /// ejemplo, al buscar por nombre).
  Stream<List<PlayerModel>> getPlayers({int? limit}) {
    Query<Map<String, dynamic>> query = firestore
        .collection('players')
        .orderBy('name');
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PlayerModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> createPlayer(PlayerModel player) async {
    await firestore.collection('players').doc().set({
      ...player.toMap(),
      'userId': null,
      'createdAt': Timestamp.now(),
    });
  }

  // players/{id} es la única fuente del perfil (nombre, foto, nivel...);
  // users/{uid} solo guarda datos de cuenta, así que no hace falta
  // sincronizar nada más al editar un jugador.
  Future<void> updatePlayer(PlayerModel player) async {
    await firestore.collection('players').doc(player.id).update(player.toMap());
  }

  Future<void> deletePlayer(String playerId) async {
    final doc = await firestore.collection('players').doc(playerId).get();

    if (!doc.exists) return;

    final data = doc.data()!;

    if (data['userId'] != null) {
      await firestore.collection('users').doc(data['userId']).delete();
    }

    await firestore.collection('players').doc(playerId).delete();
  }
}
