import 'package:flutter/material.dart';

import '../models/configuracion_puntuacion.dart';
import '../utils/calcular_resultado.dart';
import '../utils/generar_examen.dart';

/// Pantalla final: nota y repaso completo de cada pregunta, con la
/// respuesta elegida (o "sin responder") y la correcta.
class ResultadoScreen extends StatelessWidget {
  const ResultadoScreen({
    super.key,
    required this.titulo,
    required this.preguntas,
    required this.configuracionPuntuacion,
  });

  final String titulo;
  final List<PreguntaExamen> preguntas;
  final ConfiguracionPuntuacion configuracionPuntuacion;

  @override
  Widget build(BuildContext context) {
    final resultado = calcularResultado(
      preguntas: preguntas,
      configuracion: configuracionPuntuacion,
    );

    return Scaffold(
      appBar: AppBar(title: Text(titulo), automaticallyImplyLeading: false),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  resultado.nota.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${resultado.aciertos} aciertos · ${resultado.fallos} fallos '
                  '· ${resultado.enBlanco} en blanco',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (configuracionPuntuacion.restarErrores)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${resultado.puntuacion.toStringAsFixed(2)} / '
                      '${resultado.puntuacionMaxima.toStringAsFixed(2)} puntos',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: preguntas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _FilaRepaso(
                preguntaExamen: preguntas[index],
                numero: index + 1,
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((ruta) => ruta.isFirst),
                child: const Text('Volver al inicio'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaRepaso extends StatelessWidget {
  const _FilaRepaso({required this.preguntaExamen, required this.numero});

  final PreguntaExamen preguntaExamen;
  final int numero;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final Color fondo;
    final Color acento;
    final IconData icono;
    final String etiquetaRespuesta;

    if (!preguntaExamen.respondida) {
      fondo = colores.surfaceContainerHighest;
      acento = colores.onSurfaceVariant;
      icono = Icons.remove_circle_outline;
      etiquetaRespuesta = 'Sin responder';
    } else if (preguntaExamen.esCorrecta) {
      fondo = colores.primaryContainer;
      acento = colores.primary;
      icono = Icons.check_circle;
      etiquetaRespuesta = preguntaExamen.textoRespuestaElegida;
    } else {
      fondo = colores.errorContainer;
      acento = colores.error;
      icono = Icons.cancel;
      etiquetaRespuesta = preguntaExamen.textoRespuestaElegida;
    }

    return Card(
      color: fondo,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, color: acento),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$numero. ${preguntaExamen.pregunta.enunciado}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Tu respuesta: $etiquetaRespuesta'),
            if (!preguntaExamen.esCorrecta)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Correcta: ${preguntaExamen.pregunta.respuestaCorrecta}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
