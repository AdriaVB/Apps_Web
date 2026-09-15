import 'package:flutter/material.dart';

import '../utils/generar_examen.dart';

/// Pantalla final: nota y repaso completo de cada pregunta, con la
/// respuesta elegida y la correcta.
class ResultadoScreen extends StatelessWidget {
  const ResultadoScreen({
    super.key,
    required this.titulo,
    required this.preguntas,
  });

  final String titulo;
  final List<PreguntaExamen> preguntas;

  int get _aciertos => preguntas.where((p) => p.esCorrecta).length;

  @override
  Widget build(BuildContext context) {
    final total = preguntas.length;
    final aciertos = _aciertos;
    final nota = total == 0 ? 0.0 : aciertos / total * 10;

    return Scaffold(
      appBar: AppBar(title: Text(titulo), automaticallyImplyLeading: false),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  nota.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '$aciertos de $total correctas',
                  style: Theme.of(context).textTheme.titleMedium,
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
    final correcta = preguntaExamen.esCorrecta;
    return Card(
      color: correcta ? colores.primaryContainer : colores.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  correcta ? Icons.check_circle : Icons.cancel,
                  color: correcta ? colores.primary : colores.error,
                ),
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
            Text('Tu respuesta: ${preguntaExamen.textoRespuestaElegida}'),
            if (!correcta)
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
