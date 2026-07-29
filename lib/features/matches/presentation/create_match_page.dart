import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/text_utils.dart';
import '../../../core/widgets/error_state.dart';
import '../../clubs/data/club_model.dart';
import '../../players/data/player_model.dart';
import '../../players/presentation/widgets/player_avatar.dart';
import '../data/match_model.dart';

class CreateMatchPage extends ConsumerStatefulWidget {
  final MatchModel? match;

  const CreateMatchPage({super.key, this.match});

  @override
  ConsumerState<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends ConsumerState<CreateMatchPage> {
  final courtController = TextEditingController();
  final priceController = TextEditingController();
  String? selectedClubId;
  ClubModel? selectedClub;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  List<Map<String, dynamic>> selectedPlayers = [];
  String playerSearch = '';
  bool loading = false;
  bool get isEditing => widget.match != null;

  @override
  void initState() {
    super.initState();
    final match = widget.match;
    if (match == null) return;
    courtController.text = match.courtNumber;
    priceController.text = match.totalPrice.toString();
    selectedDate = match.date;
    selectedTime = _timeFromText(match.time);
    selectedPlayers = List<Map<String, dynamic>>.from(match.players);
    selectedClub = ClubModel(
      id: '',
      name: match.club,
      address: match.clubAddress,
      city: match.clubCity,
      defaultPrice: match.totalPrice,
    );
  }

  @override
  void dispose() {
    courtController.dispose();
    priceController.dispose();
    super.dispose();
  }

  TimeOfDay _timeFromText(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return TimeOfDay.now();

    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: isEditing ? DateTime(2020) : DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: selectedDate,
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  Future<void> saveMatch() async {
    if (!ref.read(isAdminProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para crear partidos'),
        ),
      );
      return;
    }

    if (selectedClub == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona un club')));
      return;
    }

    if (selectedPlayers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona jugadores')));
      return;
    }

    if (courtController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica el número de pista')),
      );
      return;
    }

    final price = double.tryParse(
      priceController.text.trim().replaceAll(',', '.'),
    );
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce un precio válido')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      loading = true;
    });

    final payments = <String, bool>{};
    for (final player in selectedPlayers) {
      payments[player['id']] = widget.match?.payments[player['id']] ?? false;
    }

    final match = MatchModel(
      id: widget.match?.id ?? '',
      creatorId: widget.match?.creatorId ?? user.uid,
      date: selectedDate,
      time:
          '${selectedTime.hour.toString().padLeft(2, '0')}:'
          '${selectedTime.minute.toString().padLeft(2, '0')}',
      club: selectedClub!.name,
      clubAddress: selectedClub!.address,
      clubCity: selectedClub!.city,
      courtNumber: courtController.text.trim(),
      totalPrice: price,
      players: selectedPlayers,
      payments: payments,
    );

    if (isEditing) {
      await ref.read(matchRepositoryProvider).updateMatch(match);
    } else {
      await ref.read(matchRepositoryProvider).createMatch(match);
    }

    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${selectedDate.day.toString().padLeft(2, '0')}/'
        '${selectedDate.month.toString().padLeft(2, '0')}/'
        '${selectedDate.year}';
    final timeLabel =
        '${selectedTime.hour.toString().padLeft(2, '0')}:'
        '${selectedTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar partido' : 'Crear partido'),
      ),
      body: StreamBuilder<List<PlayerModel>>(
        stream: ref.watch(playerRepositoryProvider).getPlayers(),
        builder: (context, playerSnapshot) {
          if (playerSnapshot.hasError) {
            return ErrorState(error: playerSnapshot.error);
          }
          if (!playerSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final players = playerSnapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _SectionCard(
                title: 'Club y pista',
                icon: Icons.location_on,
                child: Column(
                  children: [
                    StreamBuilder<List<ClubModel>>(
                      stream: ref.watch(clubRepositoryProvider).getClubs(),
                      builder: (context, clubSnapshot) {
                        if (clubSnapshot.hasError) {
                          return Text(
                            'Error cargando los clubes',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                        if (!clubSnapshot.hasData) {
                          return const LinearProgressIndicator();
                        }

                        final clubs = clubSnapshot.data!;
                        if (isEditing && selectedClubId == null) {
                          final matches = clubs.where(
                            (club) =>
                                club.name == widget.match!.club &&
                                club.address == widget.match!.clubAddress &&
                                club.city == widget.match!.clubCity,
                          );

                          if (matches.isNotEmpty) {
                            selectedClub = matches.first;
                            selectedClubId = matches.first.id;
                          }
                        }

                        return DropdownButtonFormField<String>(
                          initialValue: selectedClubId,
                          decoration: const InputDecoration(
                            labelText: 'Club',
                            prefixIcon: Icon(Icons.business),
                          ),
                          items: clubs.map((club) {
                            return DropdownMenuItem<String>(
                              value: club.id,
                              child: Text(club.name),
                            );
                          }).toList(),
                          onChanged: (clubId) {
                            if (clubId == null) return;
                            setState(() {
                              selectedClubId = clubId;
                              selectedClub = clubs.firstWhere(
                                (club) => club.id == clubId,
                              );
                              priceController.text = selectedClub!.defaultPrice
                                  .toString();
                            });
                          },
                        );
                      },
                    ),
                    if (selectedClub != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${selectedClub!.address}\n${selectedClub!.city}',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: courtController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Numero de pista',
                        prefixIcon: Icon(Icons.sports_tennis),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Precio total',
                        prefixIcon: Icon(Icons.euro),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Fecha y hora',
                icon: Icons.event,
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: pickDate,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(dateLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: pickTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(timeLabel),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Jugadores',
                icon: Icons.people,
                child: _PlayerPicker(
                  players: players,
                  selectedPlayers: selectedPlayers,
                  searchText: playerSearch,
                  onSearchChanged: (value) =>
                      setState(() => playerSearch = value),
                  onToggle: (player) {
                    setState(() {
                      final selected = selectedPlayers.any(
                        (p) => p['id'] == player.id,
                      );
                      if (selected) {
                        selectedPlayers.removeWhere(
                          (p) => p['id'] == player.id,
                        );
                      } else if (selectedPlayers.length < 6) {
                        selectedPlayers.add({
                          'id': player.id,
                          'name': '${player.name} ${player.surname}',
                        });
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: loading ? null : saveMatch,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(isEditing ? 'Guardar cambios' : 'Guardar partido'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerPicker extends StatelessWidget {
  const _PlayerPicker({
    required this.players,
    required this.selectedPlayers,
    required this.searchText,
    required this.onSearchChanged,
    required this.onToggle,
  });

  final List<PlayerModel> players;
  final List<Map<String, dynamic>> selectedPlayers;
  final String searchText;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<PlayerModel> onToggle;

  static const _maxPlayers = 6;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final query = normalizeForSearch(searchText.trim());
    final filtered = query.isEmpty
        ? players
        : players.where((player) {
            final fullName = normalizeForSearch(
              '${player.name} ${player.surname}',
            );
            return fullName.contains(query);
          }).toList();
    final atLimit = selectedPlayers.length >= _maxPlayers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: atLimit
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${selectedPlayers.length}/$_maxPlayers seleccionados',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: atLimit
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Buscar jugador...',
            prefixIcon: const Icon(Icons.search),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Ningún jugador coincide con la búsqueda',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          ...filtered.map((player) {
            final selected = selectedPlayers.any((p) => p['id'] == player.id);
            final disabled = !selected && atLimit;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Opacity(
                opacity: disabled ? 0.45 : 1,
                child: Material(
                  color: selected
                      ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: disabled ? null : () => onToggle(player),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? colorScheme.primary
                              : Colors.transparent,
                          width: 1.4,
                        ),
                      ),
                      child: Row(
                        children: [
                          PlayerAvatar(player: player, radius: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${player.name} ${player.surname}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Nivel ${player.level.toStringAsFixed(1)} · ${player.position}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: selected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}