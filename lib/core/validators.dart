/// Validadores compartidos para los formularios de la app.
class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]{2,}$');

  static String? requiredField(String? value, [String label = 'Este campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$label es obligatorio';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es obligatorio';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Introduce un email válido';
    }
    return null;
  }

  static String? optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return email(value);
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es obligatorio';
    }
    final digits = value.trim().replaceAll(RegExp(r'[\s()+-]'), '');
    if (digits.length < 9 || int.tryParse(digits) == null) {
      return 'Introduce un teléfono válido';
    }
    return null;
  }

  static String? optionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return phone(value);
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    return null;
  }
}
