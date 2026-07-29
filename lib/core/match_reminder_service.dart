import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../features/matches/data/match_model.dart';

/// Avisa con una notificación local del dispositivo 2 horas antes de
/// cada partido en el que participa el usuario. No necesita servidor
/// ni plan de pago. Solo Android/iOS: la web no tiene notificaciones
/// programadas del sistema operativo.
class MatchReminderService {
  MatchReminderService._();
  static final instance = MatchReminderService._();

  static const _reminderOffset = Duration(hours: 2);
  static const _scheduledIdsKey = 'scheduled_match_reminder_ids';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(_guessLocalLocation());

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  /// Localiza la zona horaria del dispositivo comparando el offset
  /// actual con el de la base de datos tz, sin depender de un plugin
  /// adicional solo para eso.
  tz.Location _guessLocalLocation() {
    final offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
    for (final location in tz.timeZoneDatabase.locations.values) {
      if (location.currentTimeZone.offset == offsetMs) {
        return location;
      }
    }
    return tz.UTC;
  }

  int _notificationId(String matchId) => matchId.hashCode & 0x7fffffff;

  DateTime? _reminderTime(MatchModel match) {
    final parts = match.time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    final matchStart = DateTime(
      match.date.year,
      match.date.month,
      match.date.day,
      hour,
      minute,
    );
    return matchStart.subtract(_reminderOffset);
  }

  /// Programa el aviso de los partidos en [myUpcomingMatches] (ya
  /// filtrados a los del usuario actual) y cancela los que ya no
  /// correspondan: partido pasado, borrado, o el usuario ya no está
  /// entre los jugadores.
  Future<void> syncReminders(List<MatchModel> myUpcomingMatches) async {
    if (!_supported) return;
    await _ensureInitialized();

    final prefs = await SharedPreferences.getInstance();
    final previouslyScheduled = (
      prefs.getStringList(_scheduledIdsKey) ?? const <String>[]
    ).toSet();

    final now = DateTime.now();
    final relevant = myUpcomingMatches.where((match) {
      final reminderTime = _reminderTime(match);
      return reminderTime != null && reminderTime.isAfter(now);
    }).toList();
    final relevantIds = relevant.map((m) => m.id).toSet();

    for (final staleId in previouslyScheduled.difference(relevantIds)) {
      await _plugin.cancel(_notificationId(staleId));
    }

    for (final match in relevant) {
      final reminderTime = _reminderTime(match)!;
      await _plugin.zonedSchedule(
        _notificationId(match.id),
        'Partido en 2 horas',
        '${match.club} · Pista ${match.courtNumber} a las ${match.time}',
        tz.TZDateTime.from(reminderTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'match_reminders',
            'Recordatorios de partido',
            channelDescription:
                'Aviso 2 horas antes de un partido en el que participas',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    await prefs.setStringList(_scheduledIdsKey, relevantIds.toList());
  }
}
