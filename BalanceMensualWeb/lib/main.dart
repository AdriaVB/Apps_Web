import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'screens/arranque_screen.dart';
import 'theme/app_theme.dart';
import 'theme/tema_controlador.dart';

void main() {
  // sqflite (el motor por defecto) es un plugin nativo — no existe en un
  // navegador. En web se sustituye por una copia de SQLite compilada a
  // WebAssembly que guarda sus datos en IndexedDB, sin tocar el resto del
  // código: AppDatabase usa la misma API (openDatabase, Database...) sin
  // enterarse de cuál de los dos motores hay debajo.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  runApp(const BalanceMensualApp());
}

class BalanceMensualApp extends StatelessWidget {
  const BalanceMensualApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaControlador,
      builder: (context, modo, _) {
        return MaterialApp(
          title: 'Balance Mensual',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.claro,
          darkTheme: AppTheme.oscuro,
          themeMode: modo,
          home: const ArranqueScreen(),
        );
      },
    );
  }
}
