import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/date_format.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/error_state.dart';
import '../data/match_model.dart';

class MatchDetailPage extends ConsumerWidget {
  final String matchId;
  const MatchDetailPage({super.key, required this.matchId});

  Future<void> _togglePayment(
    WidgetRef ref,
    MatchModel match,
    String playerId,
  ) async {
    final payments = Map<String, bool>.from(match.payments);
    payments[playerId] = !(payments[playerId] ?? false);
    // El haptic dispara en el mismo gesto que el cambio visual, para
    // que se sientan como una sola cosa (causalidad + armonía).
    HapticFeedback.selectionClick();
    await ref.read(matchRepositoryProvider).updatePayments(match.id, payments);
  }

  Future<void> _deleteMatch(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar partido'),
        content: const Text('¿Seguro que quieres eliminar este partido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(matchRepositoryProvider).deleteMatch(matchId);
    if (!context.mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final matchAsync = ref.watch(matchProvider(matchId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del partido')),
      body: matchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(error: error),
        data: (match) {
          if (match == null) {
            return const Center(child: Text('Este partido ya no existe.'));
          }

          final pricePerPlayer = match.players.isEmpty
              ? 0
              : match.totalPrice / match.players.length;
          final paidPlayers =
              match.payments.values.where((paid) => paid).length;
          final totalPlayers = match.players.length;
          final pendingPlayers = totalPlayers - paidPlayers;
          final pendingAmount = pendingPlayers * pricePerPlayer;
          final progress =
              totalPlayers == 0 ? 0.0 : paidPlayers / totalPlayers;
          final dateLabel = humanDate(match.date);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
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
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${match.clubAddress}, ${match.clubCity}',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            icon: Icons.calendar_month,
                            label: dateLabel,
                          ),
                          _InfoChip(icon: Icons.access_time, label: match.time),
                          _InfoChip(
                            icon: Icons.sports_tennis,
                            label: 'Pista ${match.courtNumber}',
                          ),
                          _InfoChip(
                            icon: Icons.euro,
                            label:
                                '${match.totalPrice.toStringAsFixed(2)} total · '
                                '${pricePerPlayer.toStringAsFixed(2)}/jugador',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Estado de pagos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          tween: Tween(begin: progress, end: progress),
                          builder: (context, value, _) =>
                              LinearProgressIndicator(
                            value: value,
                            minHeight: 10,
                            valueColor:
                                AlwaysStoppedAnimation(colorScheme.primary),
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'Pagados',
                              value: '$paidPlayers/$totalPlayers',
                              color: colorScheme.primary,
                              background: colorScheme.primaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              label: 'Pendiente',
                              value: '${pendingAmount.toStringAsFixed(2)} €',
                              color: colorScheme.tertiary,
                              background: colorScheme.tertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Jugadores',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ...match.players.map((player) {
                final playerId = player['id'] ?? '';
                final name = player['name'] ?? '';
                final isPaid = match.payments[playerId] ?? false;
                final initials = name.trim().isEmpty
                    ? '?'
                    : name.trim()[0].toUpperCase();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: isAdmin
                          ? () => _togglePayment(ref, match, playerId)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isPaid
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceContainerHighest,
                              ),
                              alignment: Alignment.center,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isPaid
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurfaceVariant,
                                ),
                                child: Text(initials),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isPaid
                                          ? colorScheme.primary
                                          : colorScheme.tertiary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    child: Text(
                                      isPaid ? 'Pagado' : 'Pendiente de pago',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isAdmin)
                              Switch(
                                value: isPaid,
                                onChanged: (_) =>
                                    _togglePayment(ref, match, playerId),
                              )
                            else
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(
                                  scale: animation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                ),
                                child: Icon(
                                  isPaid
                                      ? Icons.check_circle
                                      : Icons.hourglass_bottom,
                                  key: ValueKey(isPaid),
                                  color: isPaid
                                      ? colorScheme.primary
                                      : colorScheme.tertiary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              if (isAdmin) ...[
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Acciones',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => context.push(
                            '/partidos/$matchId/editar',
                            extra: match,
                          ),
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar partido'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _deleteMatch(context, ref),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Eliminar partido'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            side: BorderSide(color: colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
