import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/configuracion_usuario.dart';
import 'inicio_screen.dart';

/// Pantalla de bienvenida, solo la primera vez que se abre la app. Su único
/// propósito es fijar el día de inicio de mes antes de empezar a registrar
/// nada — el resto de la configuración (gastos fijos, anuales) se puede
/// hacer luego, cuando haga falta, desde el engranaje.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.db});

  /// Solo para tests: permite inyectar una base de datos aislada.
  final AppDatabase? db;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final AppDatabase _db = widget.db ?? AppDatabase.instancia;
  int _diaSeleccionado = 1;
  bool _guardando = false;

  Future<void> _empezar() async {
    setState(() => _guardando = true);
    await _db.guardarConfiguracion(
      ConfiguracionUsuario(
        diaInicioMes: _diaSeleccionado,
        onboardingCompletado: true,
      ),
    );
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => InicioScreen(db: widget.db)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bienvenido a Balance Mensual',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '¿Cuándo empieza tu mes? Elige el día 1 para el mes '
                'natural, o el de tu nómina.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              DropdownButtonFormField<int>(
                initialValue: _diaSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Día de inicio de mes',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (var dia = 1; dia <= 31; dia++)
                    DropdownMenuItem(
                      value: dia,
                      child: Text(
                        dia == 1 ? '1 (mes natural)' : dia.toString(),
                      ),
                    ),
                ],
                onChanged: (valor) {
                  if (valor != null) setState(() => _diaSeleccionado = valor);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _guardando ? null : _empezar,
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Empezar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
