/// Un examen general (p. ej. "Auxiliar Administrativo 2026"). Puede haber
/// varios en paralelo, cada uno con sus propios temas y preguntas.
class ExamenGeneral {
  final int id;
  final String nombre;

  const ExamenGeneral({required this.id, required this.nombre});

  factory ExamenGeneral.fromMap(int id, Map<dynamic, dynamic> map) {
    return ExamenGeneral(id: id, nombre: map['nombre'] as String);
  }

  Map<String, dynamic> toMap() => {'nombre': nombre};
}
