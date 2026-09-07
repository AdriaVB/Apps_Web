import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/configuracion_usuario.dart';
import '../theme/tema_controlador.dart';
import 'inicio_screen.dart';
import 'onboarding_screen.dart';

/// Decide, al arrancar la app, si mostrar la bienvenida (primera vez) o
/// entrar directamente a la pantalla principal. También aplica el modo
/// oscuro/claro guardado, antes de mostrar nada.
class ArranqueScreen extends StatefulWidget {
  const ArranqueScreen({super.key, AppDatabase? db}) : _dbInyectada = db;

  /// Solo para tests: permite inyectar una base de datos aislada.
  final AppDatabase? _dbInyectada;

  @override
  State<ArranqueScreen> createState() => _ArranqueScreenState();
}

class _ArranqueScreenState extends State<ArranqueScreen> {
  late final AppDatabase _db = widget._dbInyectada ?? AppDatabase.instancia;
  late final Future<ConfiguracionUsuario> _configuracionFuture = _cargar();

  Future<ConfiguracionUsuario> _cargar() async {
    final config = await _db.obtenerConfiguracion();
    temaControlador.value = config.modoOscuro
        ? ThemeMode.dark
        : ThemeMode.light;
    return config;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConfiguracionUsuario>(
      future: _configuracionFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!.onboardingCompletado
            ? InicioScreen(db: _db)
            : OnboardingScreen(db: _db);
      },
    );
  }
}
