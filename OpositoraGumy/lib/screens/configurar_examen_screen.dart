import 'package:flutter/material.dart';

import '../models/configuracion_puntuacion.dart';
import '../models/pregunta.dart';
import '../utils/generar_examen.dart';
import 'examen_screen.dart';

const _opcionesCantidad = [5, 10, 20];

/// Paso previo a un examen: elegir cuántas preguntas (de entre las
/// disponibles) y cómo se puntúa — si los fallos restan y cuánto.
class ConfigurarExamenScreen extends StatefulWidget {
  const ConfigurarExamenScreen({
    super.key,
    required this.titulo,
    required this.preguntasDisponibles,
  });

  final String titulo;
  final List<Pregunta> preguntasDisponibles;

  @override
  State<ConfigurarExamenScreen> createState() => _ConfigurarExamenScreenState();
}

class _ConfigurarExamenScreenState extends State<ConfigurarExamenScreen> {
  late int _cantidadElegida = _opcionesCantidad.firstWhere(
    (opcion) => opcion <= widget.preguntasDisponibles.length,
    orElse: () => _opcionesCantidad.first,
  );

  bool _restarErrores = false;
  final _puntosAciertoController = TextEditingController(text: '1');
  final _puntosFalloController = TextEditingController(text: '0.33');

  int get _totalDisponibles => widget.preguntasDisponibles.length;

  @override
  void dispose() {
    _puntosAciertoController.dispose();
    _puntosFalloController.dispose();
    super.dispose();
  }

  void _empezar() {
    final cantidad = _cantidadElegida.clamp(1, _totalDisponibles);
    final examen = generarExamen(
      disponibles: widget.preguntasDisponibles,
      cantidad: cantidad,
    );

    final configuracion = ConfiguracionPuntuacion(
      restarErrores: _restarErrores,
      puntosPorAcierto:
          double.tryParse(_puntosAciertoController.text.replaceAll(',', '.')) ??
          1,
      puntosPorFallo:
          double.tryParse(_puntosFalloController.text.replaceAll(',', '.')) ??
          0,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ExamenScreen(
          titulo: widget.titulo,
          preguntas: examen,
          configuracionPuntuacion: configuracion,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Hay $_totalDisponibles pregunta${_totalDisponibles == 1 ? '' : 's'} '
            'disponible${_totalDisponibles == 1 ? '' : 's'}.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Text(
            '¿Cuántas preguntas quieres?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              for (final opcion in _opcionesCantidad)
                ChoiceChip(
                  label: Text('$opcion'),
                  selected: _cantidadElegida == opcion,
                  onSelected: opcion > _totalDisponibles
                      ? null
                      : (_) => setState(() => _cantidadElegida = opcion),
                ),
            ],
          ),
          if (_cantidadElegida > _totalDisponibles ||
              _opcionesCantidad.every((o) => o > _totalDisponibles))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Solo hay $_totalDisponibles disponibles: el examen '
                'usará todas.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Restar puntos por fallo'),
            subtitle: const Text('Como en un examen oficial tipo test'),
            value: _restarErrores,
            onChanged: (valor) => setState(() => _restarErrores = valor),
          ),
          if (_restarErrores)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _puntosAciertoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Puntos por acierto',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _puntosFalloController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Puntos que resta un fallo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _totalDisponibles == 0 ? null : _empezar,
            child: const Text('Empezar examen'),
          ),
        ],
      ),
    );
  }
}
