/// Un tema dentro de un examen general (p. ej. "Tema 3 — La Constitución
/// Española"). Pertenece a un único examen general.
class Tema {
  final int id;
  final int examenGeneralId;
  final String nombre;

  const Tema({
    required this.id,
    required this.examenGeneralId,
    required this.nombre,
  });

  factory Tema.fromMap(int id, Map<dynamic, dynamic> map) {
    return Tema(
      id: id,
      examenGeneralId: map['examenGeneralId'] as int,
      nombre: map['nombre'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'examenGeneralId': examenGeneralId,
    'nombre': nombre,
  };
}
