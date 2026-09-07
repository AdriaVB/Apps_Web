/// Objetivo de ahorro a largo plazo (p. ej. "iPhone, 800€ en 6 meses").
/// Puramente informativo: no genera movimientos ni resta nada del balance,
/// solo compara lo que ya ahorras (el balance real de cada ciclo) con lo que
/// haría falta para llegar a tiempo.
class MetaAhorro {
  final int? id;
  final String nombre;
  final double importeObjetivo;
  final int mesesPlazo;

  /// Ciclo-mes (yyyy-MM-dd) en el que se creó la meta — desde ahí se cuentan
  /// los meses transcurridos y el ahorro acumulado.
  final String cicloInicio;

  const MetaAhorro({
    this.id,
    required this.nombre,
    required this.importeObjetivo,
    required this.mesesPlazo,
    required this.cicloInicio,
  });

  factory MetaAhorro.fromMap(Map<String, Object?> map) {
    return MetaAhorro(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      importeObjetivo: (map['importeObjetivo'] as num).toDouble(),
      mesesPlazo: map['mesesPlazo'] as int,
      cicloInicio: map['cicloInicio'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'importeObjetivo': importeObjetivo,
      'mesesPlazo': mesesPlazo,
      'cicloInicio': cicloInicio,
    };
  }

  /// El inicio no se puede editar — el nombre, el importe o el plazo sí.
  MetaAhorro copyWith({
    String? nombre,
    double? importeObjetivo,
    int? mesesPlazo,
  }) {
    return MetaAhorro(
      id: id,
      nombre: nombre ?? this.nombre,
      importeObjetivo: importeObjetivo ?? this.importeObjetivo,
      mesesPlazo: mesesPlazo ?? this.mesesPlazo,
      cicloInicio: cicloInicio,
    );
  }
}
