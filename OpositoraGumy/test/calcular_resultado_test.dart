import 'package:flutter_test/flutter_test.dart';
import 'package:opositoragumy/models/configuracion_puntuacion.dart';
import 'package:opositoragumy/models/pregunta.dart';
import 'package:opositoragumy/utils/calcular_resultado.dart';
import 'package:opositoragumy/utils/generar_examen.dart';

Pregunta _pregunta(int id) => Pregunta(
  id: id,
  temaId: 1,
  enunciado: 'Pregunta $id',
  tipo: TipoPregunta.opcionMultiple,
  respuestas: const ['A', 'B', 'C', 'D'],
  indiceCorrecta: 0,
);

/// Una pregunta ya "colocada" en un examen, sin barajar (orden identidad),
/// para poder decidir a mano si se acierta, falla o se deja en blanco.
PreguntaExamen _sinBarajar(int id) => PreguntaExamen(
  pregunta: _pregunta(id),
  ordenRespuestas: const [0, 1, 2, 3],
);

void main() {
  group('calcularResultado', () {
    test(
      'sin penalización: nota es aciertos/total x 10, blancos no cuentan',
      () {
        final preguntas = [
          _sinBarajar(1)..respuestaElegida = 0, // acierto
          _sinBarajar(2)..respuestaElegida = 1, // fallo
          _sinBarajar(3), // en blanco
          _sinBarajar(4)..respuestaElegida = 0, // acierto
        ];

        final resultado = calcularResultado(
          preguntas: preguntas,
          configuracion: const ConfiguracionPuntuacion(),
        );

        expect(resultado.aciertos, 2);
        expect(resultado.fallos, 1);
        expect(resultado.enBlanco, 1);
        expect(resultado.nota, closeTo(5.0, 0.001));
      },
    );

    test('con penalización: cada fallo resta los puntos configurados', () {
      final preguntas = [
        _sinBarajar(1)..respuestaElegida = 0, // acierto: +1
        _sinBarajar(2)..respuestaElegida = 1, // fallo: -0.33
        _sinBarajar(3)..respuestaElegida = 2, // fallo: -0.33
        _sinBarajar(4), // en blanco: no afecta
      ];

      final resultado = calcularResultado(
        preguntas: preguntas,
        configuracion: const ConfiguracionPuntuacion(
          restarErrores: true,
          puntosPorAcierto: 1,
          puntosPorFallo: 0.33,
        ),
      );

      expect(resultado.puntuacion, closeTo(0.34, 0.001));
      expect(resultado.puntuacionMaxima, 4);
      expect(resultado.nota, closeTo(0.85, 0.01));
    });

    test('la puntuación nunca baja de 0 aunque los fallos pesen más que los aciertos', () {
      final preguntas = [
        _sinBarajar(1)..respuestaElegida = 0, // acierto: +1
        _sinBarajar(2)..respuestaElegida = 1, // fallo: -1
        _sinBarajar(3)..respuestaElegida = 1, // fallo: -1
      ];

      final resultado = calcularResultado(
        preguntas: preguntas,
        configuracion: const ConfiguracionPuntuacion(
          restarErrores: true,
          puntosPorAcierto: 1,
          puntosPorFallo: 1,
        ),
      );

      expect(resultado.puntuacion, 0);
      expect(resultado.nota, 0);
    });

    test('todas en blanco: nota 0 sin dividir por cero ni fallar', () {
      final preguntas = [_sinBarajar(1), _sinBarajar(2)];

      final resultado = calcularResultado(
        preguntas: preguntas,
        configuracion: const ConfiguracionPuntuacion(),
      );

      expect(resultado.enBlanco, 2);
      expect(resultado.nota, 0);
    });
  });
}
