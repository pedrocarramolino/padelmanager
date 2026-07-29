import 'package:flutter/material.dart';

/// Estado de error para StreamBuilders/FutureBuilders.
/// Traduce los errores más comunes de Firestore a un mensaje entendible.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.error});

  final Object? error;

  String _message() {
    final text = error?.toString() ?? '';
    if (text.contains('permission-denied')) {
      return 'No tienes permisos para ver estos datos. '
          'Cierra sesión y vuelve a entrar; si sigue pasando, '
          'contacta con el administrador.';
    }
    if (text.contains('unavailable') || text.contains('network')) {
      return 'No hay conexión con el servidor. '
          'Comprueba tu conexión a internet.';
    }
    return 'Ha ocurrido un error cargando los datos. Inténtalo de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 52, color: colorScheme.error),
            const SizedBox(height: 16),
            const Text(
              'Algo ha ido mal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _message(),
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
