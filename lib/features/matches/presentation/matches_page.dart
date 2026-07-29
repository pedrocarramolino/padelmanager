import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/date_format.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/match_model.dart';

const _upcomingPageSize = 20;
// Cuántos partidos jugados y ya pagados por completo se muestran
// cuando no hay ninguno pendiente de cobro (para no dejar la sección
// vacía). Los pendientes de pago se muestran siempre TODOS, sin límite:
// son los que de verdad hace falta gestionar.
const _playedFallbackCount = 3;

final _upcomingLimitProvider = StateProvider.autoDispose<int>(
  (ref) => _upcomingPageSize,
);

class MatchesPage extends ConsumerWidget {
  const MatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(matchRepositoryProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final upcomingLimit = ref.watch(_upcomingLimitProvider);

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return Scaffold(
      appBar: AppBar(title: const Text('Partidos')),
      body: StreamBuilder<List<MatchModel>>(
        stream: repository.getUpcomingMatches(
          from: todayOnly,
          limit: upcomingLimit,
        ),
        builder: (context, upcomingSnapshot) {
          return StreamBuilder<List<MatchModel>>(
            // Sin límite: hace falta ver el histórico completo para
            // saber cuáles siguen pendientes de pago.
            stream: repository.getPlayedMatches(before: todayOnly),
            builder: (context, playedSnapshot) {
              if (upcomingSnapshot.hasError) {
                return ErrorState(error: upcomingSnapshot.error);
              }
              if (playedSnapshot.hasError) {
                return ErrorState(error: playedSnapshot.error);
              }
              if (!upcomingSnapshot.hasData || !playedSnapshot.hasData) {
                return const SkeletonList(
                  itemBuilder: _buildMatchSkeleton,
                );
              }

              // Los partidos con todos los jugadores pagados desaparecen
              // de la lista: ya no hay nada que gestionar en ellos.
              bool isFullyPaid(MatchModel m) =>
                  m.players.isNotEmpty &&
                  m.players.every((p) => m.payments[p['id']] ?? false);

              final upcomingRaw = upcomingSnapshot.data!;
              final playedRaw = playedSnapshot.data!;
              final upcoming = upcomingRaw
                  .where((m) => !isFullyPaid(m))
                  .toList();

              // Los partidos jugados pendientes de pago se muestran
              // siempre todos; si no queda ninguno, se enseñan los
              // últimos jugados aunque ya estén cobrados, para que la
              // sección no se quede vacía.
              final playedPending = playedRaw
                  .where((m) => !isFullyPaid(m))
                  .toList();
              final played = playedPending.isNotEmpty
                  ? playedPending
                  : playedRaw.take(_playedFallbackCount).toList();

              // Si Firestore devolvió tantos documentos como el límite
              // pedido, probablemente haya más por cargar.
              final hasMoreUpcoming = upcomingRaw.length >= upcomingLimit;

              if (upcomingRaw.isEmpty && playedRaw.isEmpty) {
                return _EmptyMatches(
                  isAdmin: isAdmin,
                  onCreate: () => _openCreateMatch(context),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                children: [
                  if (upcoming.isNotEmpty || hasMoreUpcoming) ...[
                    const _SectionHeader(
                      icon: Icons.upcoming_outlined,
                      title: 'Próximos',
                    ),
                    ...upcoming.map(
                      (match) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MatchCard(match: match),
                      ),
                    ),
                    if (hasMoreUpcoming)
                      _LoadMoreButton(
                        onPressed: () => ref
                            .read(_upcomingLimitProvider.notifier)
                            .state += _upcomingPageSize,
                      ),
                  ],
                  if (played.isNotEmpty) ...[
                    const _SectionHeader(
                      icon: Icons.history,
                      title: 'Jugados',
                    ),
                    ...played.map(
                      (match) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Opacity(
                          // Los que aún deben algo se ven a toda
                          // opacidad: siguen necesitando gestión.
                          opacity: isFullyPaid(match) ? 0.65 : 1,
                          child: _MatchCard(match: match),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'crear_partido',
              onPressed: () => _openCreateMatch(context),
              icon: const Icon(Icons.add),
              label: const Text('Partido'),
            )
          : null,
    );
  }

  void _openCreateMatch(BuildContext context) {
    context.push('/partidos/nuevo');
  }
}

Widget _buildMatchSkeleton(BuildContext context) => const MatchCardSkeleton();

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.expand_more),
          label: const Text('Cargar más'),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final paidPlayers = match.payments.values.where((paid) => paid).length;
    final totalPlayers = match.players.length;
    final progress = totalPlayers == 0 ? 0.0 : paidPlayers / totalPlayers;

    Color progressColor;
    if (progress == 1) {
      progressColor = colorScheme.primary;
    } else if (progress >= 0.5) {
      progressColor = colorScheme.tertiary;
    } else {
      progressColor = colorScheme.error;
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/partidos/${match.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.sports_tennis,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.club,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${match.clubCity} · Pista ${match.courtNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.calendar_month,
                    label: humanDate(match.date),
                  ),
                  _InfoChip(icon: Icons.access_time, label: match.time),
                  _InfoChip(
                    icon: Icons.euro,
                    label: match.totalPrice.toStringAsFixed(2),
                  ),
                  _InfoChip(
                    icon: Icons.people,
                    label: '${match.players.length} jugadores',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.payments_outlined, size: 18, color: progressColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(20),
                      valueColor: AlwaysStoppedAnimation(progressColor),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$paidPlayers/$totalPlayers',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyMatches extends StatelessWidget {
  const _EmptyMatches({required this.isAdmin, required this.onCreate});

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
              Icons.event_available,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay partidos pendientes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Los partidos con todos los pagos completados desaparecen '
              'de la lista. Crea un partido para empezar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Crear partido'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
