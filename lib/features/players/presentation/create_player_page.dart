import 'package:flutter/material.dart';
import '../../../core/validators.dart';
import '../data/player_model.dart';
import '../data/player_repository.dart';

class CreatePlayerPage extends StatefulWidget {
  const CreatePlayerPage({super.key, this.player});

  final PlayerModel? player;

  @override
  State<CreatePlayerPage> createState() => _CreatePlayerPageState();
}

class _CreatePlayerPageState extends State<CreatePlayerPage> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final surname = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();

  final repository = PlayerRepository();

  double level = 3.0;
  String position = 'Derecha';

  bool loading = false;

  bool get isEditing => widget.player != null;

  @override
  void initState() {
    super.initState();

    final player = widget.player;

    if (player == null) return;

    name.text = player.name;
    surname.text = player.surname;
    email.text = player.email;
    phone.text = player.phone;
    level = player.level;

    position = ['Derecha', 'Revés', 'Indiferente'].contains(player.position)
        ? player.position
        : 'Derecha';
  }

  @override
  void dispose() {
    name.dispose();
    surname.dispose();
    email.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> savePlayer() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      loading = true;
    });
    final player = PlayerModel(
      id: widget.player?.id ?? '',
      userId: widget.player?.userId ?? '',
      name: name.text.trim(),
      surname: surname.text.trim(),
      email: email.text.trim(),
      phone: phone.text.trim(),
      level: level,
      position: position,
      photoUrl: widget.player?.photoUrl ?? '',
    );
    try {
      if (isEditing) {
        await repository.updatePlayer(player);
      } else {
        await repository.createPlayer(player);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar jugador' : 'Nuevo jugador'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: name,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) =>
                          Validators.requiredField(v, 'El nombre'),
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: surname,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) =>
                          Validators.requiredField(v, 'Los apellidos'),
                      decoration: const InputDecoration(
                        labelText: 'Apellidos',
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: Validators.optionalEmail,
                      decoration: const InputDecoration(
                        labelText: 'Email (opcional)',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: Validators.optionalPhone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono (opcional)',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              'Nivel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton.filled(
                                  tooltip: 'Bajar nivel',
                                  onPressed: level > 1.0
                                      ? () {
                                          setState(() {
                                            level = (level - 0.5).clamp(
                                              1.0,
                                              7.0,
                                            );
                                          });
                                        }
                                      : null,
                                  icon: const Icon(Icons.remove),
                                ),
                                const SizedBox(width: 30),
                                Text(
                                  level.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 30),
                                IconButton.filled(
                                  tooltip: 'Subir nivel',
                                  onPressed: level < 7.0
                                      ? () {
                                          setState(() {
                                            level = (level + 0.5).clamp(
                                              1.0,
                                              7.0,
                                            );
                                          });
                                        }
                                      : null,
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Pulsa los botones para modificar tu nivel',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: position,
                      decoration: const InputDecoration(
                        labelText: 'Posición',
                        prefixIcon: Icon(Icons.swap_horiz),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Derecha',
                          child: Text('Derecha'),
                        ),
                        DropdownMenuItem(value: 'Revés', child: Text('Revés')),
                        DropdownMenuItem(
                          value: 'Indiferente',
                          child: Text('Indiferente'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          position = value ?? 'Derecha';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: loading ? null : savePlayer,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(isEditing ? 'Guardar cambios' : 'Guardar jugador'),
          ),
        ],
      ),
    );
  }
}
