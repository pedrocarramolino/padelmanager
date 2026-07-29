import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:padel_manager/core/router.dart';
import 'package:padel_manager/core/theme_provider.dart';
import 'package:flutter/cupertino.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es');
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const PadelApp(),
    ),
  );
}

class PadelApp extends ConsumerWidget {
  const PadelApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      // La key fuerza a remontar el árbol al cambiar de tema: algunos
      // widgets de Material cachean su estilo y no se refrescan solos.
      // La ruta actual no se pierde (el estado vive en GoRouter).
      key: ValueKey(themeMode),
      debugShowCheckedModeBanner: false,
      title: 'Padel Manager',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final background = isDark ? const Color(0xFF0F1712) : const Color(0xFFF6F8F6);
  final surface = isDark ? const Color(0xFF17211C) : Colors.white;
  final onSurface = isDark ? const Color(0xFFE3EDE7) : const Color(0xFF163028);
  final onSurfaceVariant = isDark ? const Color(0xFFA9BAB2) : const Color(0xFF56675F);
  final borderColor = isDark ? const Color(0xFF2A3A32) : const Color(0xFFE5ECE7);
  final inputFill = isDark ? const Color(0xFF1C2822) : Colors.white;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF009966),
    brightness: brightness,
    surface: surface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    textTheme: GoogleFonts.poppinsTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ).apply(bodyColor: onSurface, displayColor: onSurface),
    scaffoldBackgroundColor: background,
    colorScheme: colorScheme.copyWith(
      onSurfaceVariant: onSurfaceVariant,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: background,
      titleTextStyle: TextStyle(
        color: onSurface,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: onSurface),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black26,
      margin: EdgeInsets.zero,
      surfaceTintColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF009966), width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 2,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: surface,
      indicatorColor: isDark
          ? const Color(0xFF244436)
          : const Color(0xFFD7F2E6),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          fontSize: 13,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    dividerTheme: DividerThemeData(
      thickness: 1,
      color: borderColor,
    ),
  );
}
