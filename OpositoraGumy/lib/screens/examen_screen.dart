import 'package:flutter/material.dart';

import '../utils/generar_examen.dart';
import 'resultado_screen.dart';

/// Examen en curso: una pregunta a la vez, sin volver atrás. Al responder
/// la última se pasa directamente al resultado.
class ExamenScreen extends StatefulWidget {
  const ExamenScreen({
    super.key,
    required this.titulo,
    required this.preguntas,
  });

  final String titulo;
  final List<PreguntaExamen> preguntas;

  @override
  State<ExamenScreen> createState() => _ExamenScreenState();
}

class _ExamenScreenState extends State<ExamenScreen> {
  int _indice = 0;

  PreguntaExamen get _actual => widget.preguntas[_indice];
  bool get _esUltima => _indice == widget.preguntas.length - 1;

  void _elegir(int indiceRespuesta) {
    if (_actual.respondida) return;
    setState(() => _actual.respuestaElegida = indiceRespuesta);
  }

  void _siguiente() {
    if (_esUltima) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultadoScreen(
            titulo: widget.titulo,
            preguntas: widget.preguntas,
          ),
        ),
      );
    } else {
      setState(() => _indice++);
    }
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
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_indice + 1) / widget.preguntas.length,
              ),
              const SizedBox(height: 8),
              Text(
                'Pregunta ${_indice + 1} de ${widget.preguntas.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              Text(
                pregunta.pregunta.enunciado,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    for (
                      var i = 0;
                      i < pregunta.respuestasMostradas.length;
                      i++
                    )
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OpcionRespuesta(
                          texto: pregunta.respuestasMostradas[i],
                          seleccionada: pregunta.respuestaElegida == i,
                          respondida: pregunta.respondida,
                          esCorrecta: i == pregunta.posicionCorrecta,
                          onTap: () => _elegir(i),
                        ),
                      ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: pregunta.respondida ? _siguiente : null,
                child: Text(_esUltima ? 'Ver resultado' : 'Siguiente'),
              ),
            ],
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
    required this.respondida,
    required this.esCorrecta,
    required this.onTap,
  });

  final String texto;
  final bool seleccionada;
  final bool respondida;
  final bool esCorrecta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    Color? fondo;
    Color? borde;
    IconData? icono;

    if (respondida) {
      if (esCorrecta) {
        fondo = colores.primaryContainer;
        borde = colores.primary;
        icono = Icons.check_circle;
      } else if (seleccionada) {
        fondo = colores.errorContainer;
        borde = colores.error;
        icono = Icons.cancel;
      }
    }

    return Material(
      color: fondo ?? colores.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: respondida ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borde ?? colores.outlineVariant,
              width: seleccionada || (respondida && esCorrecta) ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(child: Text(texto)),
              if (icono != null) Icon(icono, color: borde),
            ],
          ),
        ),
      ),
    );
  }
}
