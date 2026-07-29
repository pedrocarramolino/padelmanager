import 'package:flutter/material.dart';
import '../../../core/validators.dart';
import '../data/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final surname = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final auth = AuthService();
  bool loading = false;
  bool hidePassword = true;
  bool hideConfirmPassword = true;
  double level = 3.0;
  String position = 'Derecha';

  @override
  void dispose() {
    name.dispose();
    surname.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
    });

    try {
      await auth.register(
        name: name.text.trim(),
        surname: surname.text.trim(),
        email: email.text.trim(),
        phone: phone.text.trim(),
        level: level.toString(),
        position: position,
        password: password.text.trim(),
      );
      // Al registrarse queda logueado; el router redirige a /partidos.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                  children: [
                    TextFormField(
                      controller: name,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) => Validators.requiredField(v, 'El nombre'),
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
                      validator: Validators.email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: position,
                      decoration: const InputDecoration(
                        labelText: 'Posición',
                        prefixIcon: Icon(Icons.sports_tennis),
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
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => position = v);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: password,
                      obscureText: hidePassword,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: Validators.password,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          tooltip: hidePassword
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              hidePassword = !hidePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPassword,
                      obscureText: hideConfirmPassword,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Confirma la contraseña';
                        }
                        if (v != password.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: hideConfirmPassword
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          icon: Icon(
                            hideConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              hideConfirmPassword = !hideConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: loading ? null : register,
                        icon: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.person_add),
                        label: const Text('Crear cuenta'),
                      ),
                    ),
                  ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}