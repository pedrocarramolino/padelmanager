import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/match_reminder_service.dart';
import '../../../core/providers.dart';

class HomeShell extends ConsumerWidget {
  final StatefulNavigationShell shell;

  const HomeShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(myUpcomingMatchesProvider, (previous, next) {
      final matches = next.valueOrNull;
      if (matches != null) {
        MatchReminderService.instance.syncReminders(matches);
      }
    });

    return Scaffold(
      body: Column(
        children: [
          const _OfflineBanner(),
          Expanded(child: shell),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: NavigationBar(
              height: 72,
              selectedIndex: shell.currentIndex,
              onDestinationSelected: (index) {
                shell.goBranch(
                  index,
                  initialLocation: index == shell.currentIndex,
                );
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.sports_tennis_outlined),
                  selectedIcon: Icon(Icons.sports_tennis),
                  label: 'Partidos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups),
                  label: 'Jugadores',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso persistente cuando Firestore no consigue sincronizar con el
/// servidor. Espera un momento antes de mostrarse para no parpadear en
/// el instante inicial de cada conexión (siempre llega primero un dato
/// de caché antes de confirmar con el servidor, incluso online).
class _OfflineBanner extends ConsumerStatefulWidget {
  const _OfflineBanner();

  @override
  ConsumerState<_OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<_OfflineBanner> {
  bool _visible = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(isOfflineProvider, (previous, next) {
      final offline = next.valueOrNull ?? false;
      _timer?.cancel();
      if (offline) {
        _timer = Timer(const Duration(milliseconds: 1200), () {
          if (mounted) setState(() => _visible = true);
        });
      } else if (_visible) {
        setState(() => _visible = false);
      }
    });

    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final banner = Material(
      color: colorScheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.wifi_off,
                size: 18,
                color: colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sin conexión. Viendo datos guardados; se actualizará solo.',
                  style: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (reduceMotion) {
      return _visible ? banner : const SizedBox.shrink();
    }

    // El aviso "se materializa": crece y aparece a la vez, en vez de
    // saltar de golpe. Misma curva de entrada y salida para que el
    // camino de vuelta se sienta simétrico al de llegada.
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        opacity: _visible ? 1 : 0,
        child: _visible ? banner : const SizedBox(width: double.infinity),
      ),
    );
  }
}
