import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_service.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/clubs/data/club_repository.dart';
import '../features/matches/data/match_model.dart';
import '../features/matches/data/match_repository.dart';
import '../features/players/data/player_repository.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => MatchRepository(),
);

final playerRepositoryProvider = Provider<PlayerRepository>(
  (ref) => PlayerRepository(),
);

final clubRepositoryProvider = Provider<ClubRepository>(
  (ref) => ClubRepository(),
);

/// Documento users/{uid} del usuario autenticado, en tiempo real.
/// Solo datos de cuenta (rol, email) — para el perfil (nombre, foto,
/// nivel...) usa [myPlayerDataProvider], fuente única en players/{uid}.
final userDataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final auth = ref.watch(authStateProvider);
  final user = auth.valueOrNull;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.data());
});

/// Documento players/{uid} del usuario autenticado, en tiempo real:
/// nombre, foto, nivel, posición... fuente única del perfil.
final myPlayerDataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final auth = ref.watch(authStateProvider);
  final user = auth.valueOrNull;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('players')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.data());
});

final isAdminProvider = Provider<bool>((ref) {
  final data = ref.watch(userDataProvider).valueOrNull;
  return data?['role'] == 'admin';
});

/// Un partido concreto, en tiempo real. Emite null si se ha borrado.
final matchProvider = StreamProvider.family<MatchModel?, String>((ref, id) {
  return ref.watch(matchRepositoryProvider).watchMatch(id);
});

/// Próximos partidos en los que participa el usuario autenticado, sin
/// límite de página: se usa para programar los avisos locales, no
/// para pintar una lista.
final myUpcomingMatchesProvider = StreamProvider<List<MatchModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  final uid = auth.valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);

  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  return ref
      .watch(matchRepositoryProvider)
      .getUpcomingMatches(from: todayOnly)
      .map(
        (matches) =>
            matches.where((m) => m.players.any((p) => p['id'] == uid)).toList(),
      );
});

/// true cuando Firestore está sirviendo datos de la caché local porque
/// no consigue contactar con el servidor (sin conexión, o conexión
/// pobre). Reaprovecha un listener con permiso de lectura garantizado
/// (matches, para cualquier usuario autenticado) con
/// includeMetadataChanges: cuando el cliente reconecta, ese mismo
/// listener vuelve a emitir con isFromCache: false — no hace falta
/// ningún paquete de conectividad.
final isOfflineProvider = StreamProvider<bool>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.valueOrNull == null) return Stream.value(false);
  return FirebaseFirestore.instance
      .collection('matches')
      .limit(1)
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) => snapshot.metadata.isFromCache);
});
