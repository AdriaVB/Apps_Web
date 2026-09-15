enum TipoPregunta { opcionMultiple, verdaderoFalso }

/// Las dos respuestas fijas de una pregunta de verdadero/falso — no se
/// escriben, siempre son estas dos.
const respuestasVerdaderoFalso = ['Verdadero', 'Falso'];

/// Una pregunta dentro de un tema: un enunciado, sus respuestas posibles y
/// cuál de ellas es la correcta. En opción múltiple las respuestas las
/// escribe quien la crea (normalmente 4); en verdadero/falso son fijas.
class Pregunta {
  final int id;
  final int temaId;
  final String enunciado;
  final TipoPregunta tipo;
  final List<String> respuestas;
  final int indiceCorrecta;

  const Pregunta({
    required this.id,
    required this.temaId,
    required this.enunciado,
    required this.tipo,
    required this.respuestas,
    required this.indiceCorrecta,
  });

  factory Pregunta.fromMap(int id, Map<dynamic, dynamic> map) {
    return Pregunta(
      id: id,
      temaId: map['temaId'] as int,
      enunciado: map['enunciado'] as String,
      tipo: TipoPregunta.values.byName(map['tipo'] as String),
      respuestas: (map['respuestas'] as List).cast<String>(),
      indiceCorrecta: map['indiceCorrecta'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
    'temaId': temaId,
    'enunciado': enunciado,
    'tipo': tipo.name,
    'respuestas': respuestas,
    'indiceCorrecta': indiceCorrecta,
  };

  String get respuestaCorrecta => respuestas[indiceCorrecta];
}
