import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/platform/hard_reload.dart';
import '../../../core/providers.dart';
import '../../../core/theme_provider.dart';
import '../../../core/widgets/error_state.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerData = ref.watch(myPlayerDataProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: playerData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(error: error),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('No se encontró el perfil.'));
          }
          final photoUrl = (data['photoUrl'] ?? '').toString();
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.75),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: colorScheme.onPrimary.withValues(
                          alpha: 0.2,
                        ),
                        backgroundImage: photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: colorScheme.onPrimary,
                              )
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "${data['name']} ${data['surname']}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Nivel ${data['level']} · ${data['position'] ?? ''}',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _InfoTile(
                  icon: Icons.email_outlined,
                  title: "Email",
                  value: data['email'] ?? '',
                ),
                _InfoTile(
                  icon: Icons.phone_outlined,
                  title: "Teléfono",
                  value: data['phone'] ?? '',
                ),
                _InfoTile(
                  icon: Icons.star_outline,
                  title: "Nivel",
                  value: data['level'].toString(),
                ),
                _InfoTile(
                  icon: Icons.sports_tennis,
                  title: "Posición",
                  value: data['position'] ?? '',
                ),
                const _ThemeSelector(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/perfil/editar'),
                    icon: const Icon(Icons.edit),
                    label: const Text("Editar perfil"),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authServiceProvider).logout();
                      // En web, recarga completa: el SDK JS de Firestore
                      // queda inconsistente si el usuario cambia con
                      // listeners activos (assertion ca9/b815).
                      hardReload();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Cerrar sesión"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.brightness_6_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tema',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Sistema'),
                    icon: Icon(Icons.settings_suggest_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Claro'),
                    icon: Icon(Icons.light_mode_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Oscuro'),
                    icon: Icon(Icons.dark_mode_outlined, size: 18),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (selection) =>
                    ref.read(themeModeProvider.notifier).set(selection.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isEmpty ? '—' : value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
