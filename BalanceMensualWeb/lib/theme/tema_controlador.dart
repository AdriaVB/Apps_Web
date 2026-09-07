import 'package:flutter/material.dart';

/// Notifica a la app cuándo debe cambiar entre modo claro y oscuro. Se
/// inicializa desde la configuración guardada al arrancar (ver
/// ArranqueScreen) y se actualiza al vuelo desde el interruptor en
/// Configuración, sin tener que reiniciar la app.
final ValueNotifier<ThemeMode> temaControlador = ValueNotifier(ThemeMode.light);
