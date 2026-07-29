import 'package:flutter/material.dart';
import '../../data/player_model.dart';

/// Avatar circular con la foto del jugador o, si no tiene, sus
/// iniciales sobre un color derivado de su id (siempre el mismo color
/// para el mismo jugador).
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.player, this.radius = 28});

  final PlayerModel player;
  final double radius;

  static const _colors = [
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.cyan,
    Colors.deepOrange,
  ];

  Color get _color => _colors[player.id.hashCode.abs() % _colors.length];

  String get _initials {
    final first = player.name.isEmpty ? '' : player.name[0];
    final second = player.surname.isEmpty ? '' : player.surname[0];
    final initials = '$first$second'.trim();
    return initials.isEmpty ? '?' : initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _color,
      backgroundImage: player.photoUrl.isNotEmpty
          ? NetworkImage(player.photoUrl)
          : null,
      child: player.photoUrl.isNotEmpty
          ? null
          : Text(
              _initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.64,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
