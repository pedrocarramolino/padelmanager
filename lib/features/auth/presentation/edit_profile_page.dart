import 'package:flutter/material.dart';
import '../../../core/validators.dart';
import '../data/auth_service.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final formKey = GlobalKey<FormState>();
  final auth = AuthService();
  final name = TextEditingController();
  final surname = TextEditingController();
  final phone = TextEditingController();
  bool loading = true;
  bool saving = false;
  double level = 3.0;
  String position = 'Derecha';
  final picker = ImagePicker();
  Uint8List? imageBytes;
  String photoUrl = '';

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final data = await auth.getCurrentPlayerData();
    if (data != null) {
      name.text = data['name'] ?? '';
      surname.text = data['surname'] ?? '';
      phone.text = data['phone'] ?? '';
      level = (data['level'] as num?)?.toDouble() ?? 3.0;
      position = data['position'] ?? 'Derecha';
      photoUrl = data['photoUrl'] ?? '';
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> pickImage() async {
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;
    imageBytes = await file.readAsBytes();
    setState(() {});
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      saving = true;
    });
    try {
      if (imageBytes != null) {
        await auth.uploadProfileImage(imageBytes!);
      }
      await auth.updateProfile(
        name: name.text.trim(),
        surname: surname.text.trim(),
        phone: phone.text.trim(),
        level: level,
        position: position,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) {
      setState(() {
        saving = false;
      });
    }
  }
  @override
  void dispose() {
    name.dispose();
    surname.dispose();
    phone.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
          children: [
            Semantics(
              button: true,
              label: 'Cambiar foto de perfil',
              child: GestureDetector(
                onTap: pickImage,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundImage: imageBytes != null
                          ? MemoryImage(imageBytes!)
                          : (photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null),
                      child: imageBytes == null && photoUrl.isEmpty
                          ? const Icon(Icons.camera_alt, size: 35)
                          : null,
                    ),
                    if (imageBytes != null || photoUrl.isNotEmpty)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            TextFormField(
              controller: name,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) => Validators.requiredField(v, 'El nombre'),
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 15),

            TextFormField(
              controller: surname,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (v) => Validators.requiredField(v, 'Los apellidos'),
              decoration: const InputDecoration(
                labelText: 'Apellidos',
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: phone,
              keyboardType: TextInputType.phone,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: Validators.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 25),
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
                                    level = (level - 0.5).clamp(1.0, 7.0);
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
                                    level = (level + 0.5).clamp(1.0, 7.0);
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: position,
              decoration: const InputDecoration(
                labelText: 'Posición',
                prefixIcon: Icon(Icons.sports_tennis),
              ),
              items: const [
                DropdownMenuItem(value: 'Derecha', child: Text('Derecha')),
                DropdownMenuItem(value: 'Revés', child: Text('Revés')),
                DropdownMenuItem(
                  value: 'Indiferente',
                  child: Text('Indiferente'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    position = value;
                  });
                }
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: saving ? null : save,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text("Guardar cambios"),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}