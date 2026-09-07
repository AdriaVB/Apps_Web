/// Un elemento dentro de una [Lista]: un texto y si está completado o no.
class ElementoLista {
  final int id;
  final int listaId;
  final String texto;
  final bool completado;

  const ElementoLista({
    required this.id,
    required this.listaId,
    required this.texto,
    this.completado = false,
  });

  factory ElementoLista.fromMap(int id, Map<dynamic, dynamic> map) {
    return ElementoLista(
      id: id,
      listaId: map['listaId'] as int,
      texto: map['texto'] as String,
      completado: map['completado'] as bool,
    );
  }

  Map<String, dynamic> toMap() => {
    'listaId': listaId,
    'texto': texto,
    'completado': completado,
  };

  ElementoLista copyWith({String? texto, bool? completado}) {
    return ElementoLista(
      id: id,
      listaId: listaId,
      texto: texto ?? this.texto,
      completado: completado ?? this.completado,
    );
  }
}
