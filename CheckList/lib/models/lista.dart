/// Una lista creada por el usuario (p. ej. "Videojuegos", "Tareas de casa").
/// Sin categorías predefinidas: el nombre lo elige la propia persona.
class Lista {
  final int id;
  final String nombre;

  const Lista({required this.id, required this.nombre});

  factory Lista.fromMap(int id, Map<dynamic, dynamic> map) {
    return Lista(id: id, nombre: map['nombre'] as String);
  }

  Map<String, dynamic> toMap() => {'nombre': nombre};

  Lista copyWith({String? nombre}) {
    return Lista(id: id, nombre: nombre ?? this.nombre);
  }
}
