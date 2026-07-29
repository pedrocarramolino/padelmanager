// Este archivo solo se compila en web (ver hard_reload.dart).
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Recarga completa de la página. En web es necesaria tras cerrar sesión:
/// el SDK JS de Firestore queda en estado inconsistente si el usuario
/// cambia con listeners activos (bug conocido, assertion ca9/b815).
void hardReload() => html.window.location.reload();
