# Padel Manager

App Flutter (web/PWA + Android) para gestionar los partidos, jugadores y pagos de un grupo de pádel: quién juega, en qué club y pista, quién ha pagado y quién no.

## Funcionalidades

- **Partidos**: crear, editar y borrar (solo admin); próximos ordenados por fecha, jugados con seguimiento de pagos pendientes; los partidos con todos los pagos completados se ocultan automáticamente de "Próximos" salvo los 3 últimos.
- **Jugadores**: alta/edición/baja (admin), ficha con nivel, posición y foto, buscador por nombre.
- **Pagos**: marcar quién ha pagado cada partido, con resumen visual de pendiente/cobrado.
- **Perfil**: editar tus propios datos y foto, elegir tema claro/oscuro/sistema.
- **Aviso de partido**: notificación local 2h antes de cada partido (solo Android/iOS nativo, no en la PWA).
- **PWA**: instalable, con indicador de "sin conexión" cuando Firestore no puede sincronizar.

## Stack

- **Flutter** (Dart) — web, Android, iOS
- **Riverpod** — gestión de estado
- **go_router** — navegación con URLs reales
- **Firebase**: Auth (email/contraseña + Google), Firestore, Hosting, Cloud Functions (opcional, requiere plan Blaze)

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal estable)
- [Node.js](https://nodejs.org/) 18+ (para las Cloud Functions y los tests de reglas)
- [Firebase CLI](https://firebase.google.com/docs/cli): `npm install -g firebase-tools`
- Java 21+ si vas a correr el emulador de Firestore (`java -version`)

## Puesta en marcha

```bash
flutter pub get
flutterfire configure   # solo si necesitas regenerar firebase_options.dart para tu propio proyecto Firebase
flutter run -d chrome    # o -d <dispositivo-android>
```

La app espera un proyecto Firebase con Auth (email/contraseña y Google), Firestore y Hosting activados. El primer usuario registrado tendrá `role: "user"`; para convertir a alguien en admin, cambia el campo `role` a `"admin"` en `users/{uid}` desde la consola de Firebase (por diseño, no se puede hacer desde la app ni desde el cliente).

## Estructura del proyecto

```
lib/
  core/            # providers de Riverpod, router, tema, utilidades compartidas
  features/
    auth/          # login, registro, perfil
    matches/       # partidos
    players/       # jugadores
    clubs/         # clubes (solo lectura desde la app)
    home/          # shell de navegación
firestore.rules     # reglas de seguridad de Firestore
firestore-tests/    # tests de las reglas (emulador)
functions/           # Cloud Functions (borrado de usuario; requiere plan Blaze)
```

## Tests

Reglas de seguridad de Firestore, contra el emulador local:

```bash
cd firestore-tests
npm install
cd ..
firebase emulators:exec --only firestore "cd firestore-tests && npm test"
```

Análisis estático de Dart:

```bash
flutter analyze
```

## Despliegue

```bash
flutter build web --release
firebase deploy --only hosting
```

Las reglas de Firestore se despliegan aparte:

```bash
firebase deploy --only firestore:rules
```

## Seguridad

- Todas las operaciones requieren usuario autenticado.
- El campo `role` de `users/{uid}` es inmutable desde el cliente: solo se cambia desde la consola de Firebase o el Admin SDK.
- Cada usuario solo puede editar su propia ficha en `players/{uid}`; el admin gestiona partidos, clubes y el resto de jugadores.
- Ver `firestore.rules` y `firestore-tests/rules.test.mjs` para el detalle completo.
