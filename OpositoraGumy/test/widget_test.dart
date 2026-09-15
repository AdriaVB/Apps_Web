import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:opositoragumy/models/pregunta.dart';
import 'package:opositoragumy/utils/generar_examen.dart';

Pregunta _pregunta(int id) => Pregunta(
  id: id,
  temaId: 1,
  enunciado: 'Pregunta $id',
  tipo: TipoPregunta.opcionMultiple,
  respuestas: const ['A', 'B', 'C', 'D'],
  indiceCorrecta: 2,
);

void main() {
  group('generarExamen', () {
    test('usa todas las disponibles si se piden más de las que hay', () {
      final disponibles = [for (var i = 1; i <= 3; i++) _pregunta(i)];
      final examen = generarExamen(
        disponibles: disponibles,
        cantidad: 10,
        random: Random(1),
      );
      expect(examen, hasLength(3));
    });

    test('respeta la cantidad pedida cuando hay suficientes', () {
      final disponibles = [for (var i = 1; i <= 20; i++) _pregunta(i)];
      final examen = generarExamen(
        disponibles: disponibles,
        cantidad: 5,
        random: Random(1),
      );
      expect(examen, hasLength(5));
      expect(examen.map((p) => p.pregunta.id).toSet(), hasLength(5));
    });

    test('la posición correcta sigue apuntando a la respuesta correcta '
        'aunque el orden se baraje', () {
      final examen = generarExamen(
        disponibles: [_pregunta(1)],
        cantidad: 1,
        random: Random(42),
      );
      final preguntaExamen = examen.single;
      expect(
        preguntaExamen.respuestasMostradas[preguntaExamen.posicionCorrecta],
        preguntaExamen.pregunta.respuestaCorrecta,
      );
    });

    test('esCorrecta solo es verdadera si se elige la posición correcta', () {
      final examen = generarExamen(
        disponibles: [_pregunta(1)],
        cantidad: 1,
        random: Random(7),
      );
      final preguntaExamen = examen.single;
      expect(preguntaExamen.respondida, isFalse);

      preguntaExamen.respuestaElegida = preguntaExamen.posicionCorrecta;
      expect(preguntaExamen.esCorrecta, isTrue);

      final otra = (preguntaExamen.posicionCorrecta + 1) % 4;
      preguntaExamen.respuestaElegida = otra;
      expect(preguntaExamen.esCorrecta, isFalse);
    });
  });
}
