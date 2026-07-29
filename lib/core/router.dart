import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/edit_profile_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/profile_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/matches/data/match_model.dart';
import '../features/matches/presentation/create_match_page.dart';
import '../features/matches/presentation/match_detail_page.dart';
import '../features/matches/presentation/matches_page.dart';
import '../features/players/data/player_model.dart';
import '../features/players/presentation/create_player_page.dart';
import '../features/players/presentation/players_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (previous, next) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/partidos',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final location = state.uri.toString();
      final isSplash = state.matchedLocation == '/splash';

      // Mientras Firebase resuelve la sesión, esperar en el splash
      // recordando a dónde quería ir el usuario.
      if (auth.isLoading) {
        if (isSplash) return null;
        return '/splash?from=${Uri.encodeComponent(location)}';
      }

      final loggedIn = auth.valueOrNull != null;
      final isAuthPage =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/registro';

      if (isSplash) {
        if (!loggedIn) return '/login';
        final from = state.uri.queryParameters['from'];
        return (from != null && from.isNotEmpty && !from.startsWith('/splash'))
            ? from
            : '/partidos';
      }

      if (!loggedIn) return isAuthPage ? null : '/login';
      if (isAuthPage) return '/partidos';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/registro',
        builder: (context, state) => const RegisterPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/partidos',
                builder: (context, state) => const MatchesPage(),
                routes: [
                  GoRoute(
                    path: 'nuevo',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const CreateMatchPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, state) =>
                        MatchDetailPage(matchId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'editar',
                        parentNavigatorKey: _rootNavigatorKey,
                        // El partido llega por extra; si falta (recarga
                        // directa de la URL) volvemos al detalle.
                        redirect: (context, state) => state.extra == null
                            ? '/partidos/${state.pathParameters['id']}'
                            : null,
                        builder: (_, state) =>
                            CreateMatchPage(match: state.extra as MatchModel),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/jugadores',
                builder: (context, state) => const PlayersPage(),
                routes: [
                  GoRoute(
                    path: 'nuevo',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const CreatePlayerPage(),
                  ),
                  GoRoute(
                    path: ':id/editar',
                    parentNavigatorKey: _rootNavigatorKey,
                    redirect: (context, state) =>
                        state.extra == null ? '/jugadores' : null,
                    builder: (_, state) =>
                        CreatePlayerPage(player: state.extra as PlayerModel),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/perfil',
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'editar',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const EditProfilePage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
