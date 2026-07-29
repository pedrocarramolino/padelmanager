import 'package:cloud_firestore/cloud_firestore.dart';
import 'club_model.dart';

class ClubRepository {
  final firestore = FirebaseFirestore.instance;

  Stream<List<ClubModel>> getClubs() {
    return firestore.collection('clubs').orderBy('name').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return ClubModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}
