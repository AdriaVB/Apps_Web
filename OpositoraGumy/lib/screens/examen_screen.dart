import 'package:flutter/material.dart';

import '../models/configuracion_puntuacion.dart';
import '../utils/generar_examen.dart';
import 'resultado_screen.dart';

/// Examen en curso. Se puede ir hacia delante y hacia atrás libremente,
/// cambiar una respuesta ya dada o dejarla en blanco — nada se corrige
/// hasta pulsar "Finalizar". El grupo de números de arriba funciona como
/// un calendario: azul si esa pregunta ya tiene respuesta, en blanco si no.
class ExamenScreen extends StatefulWidget {
  const ExamenScreen({
    super.key,
    required this.titulo,
    required this.preguntas,
    required this.configuracionPuntuacion,
  });

  final String titulo;
  final List<PreguntaExamen> preguntas;
  final ConfiguracionPuntuacion configuracionPuntuacion;

  @override
  State<ExamenScreen> createState() => _ExamenScreenState();
}

class _ExamenScreenState extends State<ExamenScreen> {
  int _indice = 0;

  PreguntaExamen get _actual => widget.preguntas[_indice];

  void _elegir(int indiceRespuesta) {
    setState(() {
      _actual.respuestaElegida = _actual.respuestaElegida == indiceRespuesta
          ? null
          : indiceRespuesta;
    });
  }

  void _irA(int indice) => setState(() => _indice = indice);

  void _anterior() {
    if (_indice > 0) setState(() => _indice--);
  }

  void _siguiente() {
    if (_indice < widget.preguntas.length - 1) setState(() => _indice++);
  }

  Future<void> _finalizar() async {
    final sinResponder = [
      for (var i = 0; i < widget.preguntas.length; i++)
        if (!widget.preguntas[i].respondida) i + 1,
    ];

    if (sinResponder.isNotEmpty) {
      final decision = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Preguntas sin responder'),
          content: Text(
            'Te faltan ${sinResponder.length} pregunta'
            '${sinResponder.length == 1 ? '' : 's'} por responder: '
            '${sinResponder.join(', ')}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('revisar'),
              child: const Text('Revisar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('finalizar'),
              child: const Text('Finalizar igualmente'),
            ),
          ],
        ),
      );

      if (decision != 'finalizar') {
        if (decision == 'revisar' && mounted) {
          setState(() => _indice = sinResponder.first - 1);
        }
        return;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultadoScreen(
          titulo: widget.titulo,
          preguntas: widget.preguntas,
          configuracionPuntuacion: widget.configuracionPuntuacion,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pregunta = _actual;
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.titulo),
          automaticallyImplyLeading: false,
          actions: [
            TextButton(onPressed: _finalizar, child: const Text('Finalizar')),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < widget.preguntas.length; i++)
                    _ChipPregunta(
                      numero: i + 1,
                      respondida: widget.preguntas[i].respondida,
                      actual: i == _indice,
                      onTap: () => _irA(i),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Pregunta ${_indice + 1} de ${widget.preguntas.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pregunta.pregunta.enunciado,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  for (var i = 0; i < pregunta.respuestasMostradas.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OpcionRespuesta(
                        texto: pregunta.respuestasMostradas[i],
                        seleccionada: pregunta.respuestaElegida == i,
                        onTap: () => _elegir(i),
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _indice > 0 ? _anterior : null,
                        child: const Text('Anterior'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _indice < widget.preguntas.length - 1
                            ? _siguiente
                            : null,
                        child: const Text('Siguiente'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipPregunta extends StatelessWidget {
  const _ChipPregunta({
    required this.numero,
    required this.respondida,
    required this.actual,
    required this.onTap,
  });

  final int numero;
  final bool respondida;
  final bool actual;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: respondida ? colores.primary : Colors.transparent,
          border: Border.all(
            color: actual
                ? colores.primary
                : (respondida ? colores.primary : colores.outlineVariant),
            width: actual ? 2.5 : 1.5,
          ),
        ),
        child: Text(
          '$numero',
          style: TextStyle(
            color: respondida ? colores.onPrimary : colores.onSurface,
            fontWeight: actual ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _OpcionRespuesta extends StatelessWidget {
  const _OpcionRespuesta({
    required this.texto,
    required this.seleccionada,
    required this.onTap,
  });

  final String texto;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Material(
      color: seleccionada
          ? colores.primaryContainer
          : colores.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: seleccionada ? colores.primary : colores.outlineVariant,
              width: seleccionada ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(child: Text(texto)),
              if (seleccionada)
                Icon(Icons.check_circle, color: colores.primary),
            ],
          ),
        ),
      ),
    );
  }
}
