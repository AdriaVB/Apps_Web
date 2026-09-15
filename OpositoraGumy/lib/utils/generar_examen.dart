import 'dart:math';

import '../models/pregunta.dart';

/// Una pregunta ya lista para un examen concreto: con sus respuestas en un
/// orden barajado (guardado como los índices originales, en el nuevo
/// orden), y la respuesta que el usuario vaya eligiendo.
class PreguntaExamen {
  final Pregunta pregunta;

  /// ordenRespuestas[posiciónMostrada] = índice original en
  /// pregunta.respuestas. Así la pregunta guarda internamente cuál es la
  /// correcta aunque en pantalla cambie de sitio cada vez.
  final List<int> ordenRespuestas;

  /// Posición mostrada que eligió el usuario. Nulo si todavía no ha
  /// respondido.
  int? respuestaElegida;

  PreguntaExamen({required this.pregunta, required this.ordenRespuestas});

  List<String> get respuestasMostradas => [
    for (final i in ordenRespuestas) pregunta.respuestas[i],
  ];

  int get posicionCorrecta => ordenRespuestas.indexOf(pregunta.indiceCorrecta);

  bool get respondida => respuestaElegida != null;

  bool get esCorrecta => respondida && respuestaElegida == posicionCorrecta;

  String get textoRespuestaElegida =>
      respondida ? respuestasMostradas[respuestaElegida!] : '';
}

/// Genera un examen de [cantidad] preguntas, elegidas al azar de
/// [disponibles] (sin repetir ninguna). Si se piden más de las que hay
/// disponibles, se usan todas — nunca se bloquea ni se inventan preguntas.
/// Las respuestas de cada pregunta salen en un orden distinto cada vez.
List<PreguntaExamen> generarExamen({
  required List<Pregunta> disponibles,
  required int cantidad,
  Random? random,
}) {
  final rnd = random ?? Random();
  final elegidas = [...disponibles]..shuffle(rnd);
  final seleccionadas = elegidas.take(cantidad).toList();

  return [
    for (final pregunta in seleccionadas)
      PreguntaExamen(
        pregunta: pregunta,
        ordenRespuestas: List.generate(pregunta.respuestas.length, (i) => i)
          ..shuffle(rnd),
      ),
  ];
}
