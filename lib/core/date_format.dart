import 'package:intl/intl.dart';

/// "Hoy", "Mañana", "Ayer" o "Mié 15 jul" (con año si no es el actual).
/// Requiere initializeDateFormatting('es') al arrancar la app.
String humanDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = day.difference(today).inDays;

  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Mañana';
  if (diff == -1) return 'Ayer';

  final pattern = date.year == now.year ? 'EEE d MMM' : 'EEE d MMM y';
  final formatted = DateFormat(pattern, 'es').format(date);
  return formatted[0].toUpperCase() + formatted.substring(1);
}
