import 'package:flutter/material.dart';

/// Paleta y tipografía de la app: fondo casi negro en oscuro, tarjetas
/// limpias sin bordes pesados, acento verde usado también como color de
/// "positivo" (como hacen las apps de finanzas al estilo Trade Republic).
class AppTheme {
  AppTheme._();

  static const _acento = Color(0xFF17E08A);
  static const _acentoClaro = Color(0xFF0E8F5C);

  static const positivoClaro = Color(0xFF1E8E3E);
  static const negativoClaro = Color(0xFFD93025);
  static const positivoOscuro = Color(0xFF17E08A);
  static const negativoOscuro = Color(0xFFFF6259);

  static Color positivo(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? positivoOscuro
      : positivoClaro;

  static Color negativo(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? negativoOscuro
      : negativoClaro;

  /// Paleta de verdes para el donut de ingresos por categoría: [cantidad]
  /// tonos distinguibles dentro de la misma familia de color.
  static List<Color> paletaIngresos(int cantidad) =>
      _paletaDesdeHue(hueBase: 152, cantidad: cantidad);

  /// Paleta de rojos/naranjas para el donut de gastos por categoría.
  static List<Color> paletaGastos(int cantidad) =>
      _paletaDesdeHue(hueBase: 6, cantidad: cantidad);

  static List<Color> _paletaDesdeHue({
    required double hueBase,
    required int cantidad,
  }) {
    if (cantidad <= 0) return const [];
    if (cantidad == 1) {
      return [HSLColor.fromAHSL(1, hueBase, 0.62, 0.42).toColor()];
    }
    return List.generate(cantidad, (i) {
      final desplazamiento = (i / (cantidad - 1) - 0.5) * 34;
      var hue = hueBase + desplazamiento;
      if (hue < 0) hue += 360;
      if (hue >= 360) hue -= 360;
      final luminosidad = i.isEven ? 0.40 : 0.52;
      return HSLColor.fromAHSL(1, hue, 0.62, luminosidad).toColor();
    });
  }

  static ThemeData get claro {
    final esquema = ColorScheme.fromSeed(
      seedColor: _acentoClaro,
      brightness: Brightness.light,
    );
    return _base(esquema, const Color(0xFFF6F7F6), Colors.white);
  }

  static ThemeData get oscuro {
    final esquema = ColorScheme.fromSeed(
      seedColor: _acento,
      brightness: Brightness.dark,
    ).copyWith(surface: const Color(0xFF141416));
    return _base(esquema, Colors.black, const Color(0xFF141416));
  }

  static ThemeData _base(ColorScheme esquema, Color fondo, Color superficie) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: fondo,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: fondo,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: esquema.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: superficie,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: esquema.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(iconColor: esquema.onSurfaceVariant),
      dividerTheme: DividerThemeData(
        color: esquema.outlineVariant.withValues(alpha: 0.3),
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: superficie,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: esquema.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: esquema.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: esquema.error, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: esquema.primary,
        foregroundColor: esquema.onPrimary,
        shape: const CircleBorder(),
      ),
    );
  }
}
