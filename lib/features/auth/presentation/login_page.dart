import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/google_logo.dart';
import '../data/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final auth = AuthService();
  bool loading = false;
  bool showPassword = false;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    if (email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce tu email primero.')),
      );
      return;
    }
    try {
      await auth.resetPassword(email.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Te hemos enviado un correo para restablecer la contraseña.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Ha ocurrido un error.';
      switch (e.code) {
        case 'user-not-found':
          message = 'No existe ningún usuario con ese email.';
          break;
        case 'invalid-email':
          message = 'El email no es válido.';
          break;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;
    try {
      setState(() {
        loading = true;
      });
      await auth.login(
        email: email.text.trim(),
        password: password.text.trim(),
      );
      // La redirección a /partidos la hace el router al cambiar la sesión.
    } on FirebaseAuthException catch (e) {
      String message = 'Error de autenticación';
      switch (e.code) {
        case 'user-not-found':
          message = 'Usuario no encontrado';
          break;
        case 'wrong-password':
          message = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          message = 'Email no válido';
          break;
        case 'invalid-credential':
          message = 'Email o contraseña incorrectos';
          break;
        case 'user-disabled':
          message = 'Usuario deshabilitado';
          break;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      setState(() {
        loading = true;
      });
      await auth.signInWithGoogle();
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.sports_tennis,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Padel Manager',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gestiona partidos, jugadores y pagos sin perder el ritmo.',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: formKey,
                        child: Column(
                        children: [
                          TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: Validators.email,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: password,
                            obscureText: !showPassword,
                            validator: (value) =>
                                Validators.requiredField(
                                  value,
                                  'La contraseña',
                                ),
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                tooltip: showPassword
                                    ? 'Ocultar contraseña'
                                    : 'Mostrar contraseña',
                                icon: Icon(
                                  showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showPassword = !showPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: loading ? null : resetPassword,
                              child: const Text('¿Has olvidado tu contraseña?'),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: loading ? null : login,
                              icon: loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.login),
                              label: const Text('Entrar'),
                            ),
                          ),
                        ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "o",
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: loading ? null : loginWithGoogle,
                      icon: const GoogleLogo(),
                      label: const Text("Continuar con Google"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.push('/registro'),
                    child: const Text('¿No tienes cuenta? Regístrate'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
