import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/text_utils.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/player_model.dart';
import '../data/player_repository.dart';
import 'widgets/player_avatar.dart';

final _playerSearchProvider = StateProvider.autoDispose<String>((ref) => '');
const _pageSize = 20;
final _playersLimitProvider = StateProvider.autoDispose<int>(
  (ref) => _pageSize,
);

class PlayersPage extends ConsumerWidget {
  const PlayersPage({super.key});
  Future<void> _confirmDelete(
    BuildContext context,
    PlayerRepository repository,
    PlayerModel player,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_outline,
                size: 40,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              const Text(
                'Borrar jugador',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                '¿Quieres borrar a ${player.name} ${player.surname}?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      child: const Text('Borrar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldDelete != true) return;

    try {
      await repository.deletePlayer(player.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jugador borrado correctamente')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error borrando jugador: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(playerRepositoryProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final searchText = ref.watch(_playerSearchProvider).trim();
    // Mientras se busca, se trae la colección completa: la búsqueda es
    // por subcadena en el cliente y no tendría sentido limitarla a la
    // página que esté cargada en ese momento.
    final isSearching = searchText.isNotEmpty;
    final limit = ref.watch(_playersLimitProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Jugadores')),
      body: StreamBuilder<List<PlayerModel>>(
        stream: repository.getPlayers(limit: isSearching ? null : limit),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(error: snapshot.error);
          }
          if (!snapshot.hasData) {
            return const SkeletonList(itemBuilder: _buildPlayerSkeleton);
          }
          final players = snapshot.data!;
          if (players.isEmpty && !isSearching) {
            return _EmptyPlayers(
              isAdmin: isAdmin,
              onCreate: () => _openCreatePlayer(context),
            );
          }
          final query = normalizeForSearch(searchText);
          final filtered = query.isEmpty
              ? players
              : players.where((player) {
                  final fullName = normalizeForSearch(
                    '${player.name} ${player.surname}',
                  );
                  return fullName.contains(query);
                }).toList();
          // Si se han traído tantos como el límite pedido, probablemente
          // haya más jugadores por cargar.
          final hasMore = !isSearching && players.length >= limit;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: TextField(
                  onChanged: (value) =>
                      ref.read(_playerSearchProvider.notifier).state = value,
                  decoration: InputDecoration(
                    hintText: 'Buscar jugador...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'Ningún jugador coincide con la búsqueda',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                    itemCount: filtered.length + (hasMore ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == filtered.length) {
                        return Center(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                ref
                                        .read(_playersLimitProvider.notifier)
                                        .state +=
                                    _pageSize,
                            icon: const Icon(Icons.expand_more),
                            label: const Text('Cargar más'),
                          ),
                        );
                      }
                      final player = filtered[index];
                      final colorScheme = Theme.of(context).colorScheme;
                      return Card(
                        elevation: 3,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              PlayerAvatar(player: player),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${player.name} ${player.surname}',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            'Nivel ${player.level}',
                                            style: TextStyle(
                                              color: colorScheme
                                                  .onPrimaryContainer,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Icon(
                                          Icons.sports_tennis,
                                          size: 16,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            player.position,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isAdmin) ...[
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    tooltip: 'Editar',
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                    onPressed: () => context.push(
                                      '/jugadores/${player.id}/editar',
                                      extra: player,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    tooltip: 'Borrar',
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: colorScheme.onErrorContainer,
                                    ),
                                    onPressed: () => _confirmDelete(
                                      context,
                                      repository,
                                      player,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),

      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'crear_jugador',
              onPressed: () => _openCreatePlayer(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Jugador'),
            )
          : null,
    );
  }

  void _openCreatePlayer(BuildContext context) {
    context.push('/jugadores/nuevo');
  }
}

class _EmptyPlayers extends StatelessWidget {
  const _EmptyPlayers({required this.isAdmin, required this.onCreate});
  final bool isAdmin;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_add,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay jugadores',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Añade jugadores para poder seleccionarlos en tus partidos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.person_add),
                label: const Text('Crear jugador'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _buildPlayerSkeleton(BuildContext context) => const PlayerCardSkeleton();
