import '../models/configuracion_puntuacion.dart';
import 'generar_examen.dart';

/// Resultado final de un examen ya corregido: cuántas aciertos, fallos y
/// preguntas en blanco hubo, y la puntuación resultante según la
/// configuración elegida (con o sin resta por fallo).
class ResultadoExamen {
  final int totalPreguntas;
  final int aciertos;
  final int fallos;
  final int enBlanco;
  final double puntuacion;
  final double puntuacionMaxima;
  final double nota;

  const ResultadoExamen({
    required this.totalPreguntas,
    required this.aciertos,
    required this.fallos,
    required this.enBlanco,
    required this.puntuacion,
    required this.puntuacionMaxima,
    required this.nota,
  });
}

/// La corrección solo pasa aquí, al terminar el examen — nunca mientras se
/// responde. Las preguntas en blanco ni suman ni restan, solo cuentan aparte.
ResultadoExamen calcularResultado({
  required List<PreguntaExamen> preguntas,
  required ConfiguracionPuntuacion configuracion,
}) {
  var aciertos = 0;
  var fallos = 0;
  var enBlanco = 0;

  for (final pregunta in preguntas) {
    if (!pregunta.respondida) {
      enBlanco++;
    } else if (pregunta.esCorrecta) {
      aciertos++;
    } else {
      fallos++;
    }
  }

  final puntuacionMaxima = preguntas.length * configuracion.puntosPorAcierto;
  var puntuacion = aciertos * configuracion.puntosPorAcierto;
  if (configuracion.restarErrores) {
    puntuacion -= fallos * configuracion.puntosPorFallo;
  }
  if (puntuacion < 0) puntuacion = 0;

  final nota = puntuacionMaxima == 0
      ? 0.0
      : (puntuacion / puntuacionMaxima) * 10;

  return ResultadoExamen(
    totalPreguntas: preguntas.length,
    aciertos: aciertos,
    fallos: fallos,
    enBlanco: enBlanco,
    puntuacion: puntuacion,
    puntuacionMaxima: puntuacionMaxima,
    nota: nota,
  );
}
