enum TipoMovimiento { ingreso, gasto }

enum OrigenMovimiento { fijo, variable }

class Movimiento {
  final int? id;
  final TipoMovimiento tipo;
  final OrigenMovimiento origen;
  final String nombre;
  final double importe;
  final int categoriaId;

  /// Fecha de inicio del ciclo-mes al que pertenece (yyyy-MM-dd).
  final String cicloMes;

  final int? gastoFijoId;

  const Movimiento({
    this.id,
    required this.tipo,
    required this.origen,
    required this.nombre,
    required this.importe,
    required this.categoriaId,
    required this.cicloMes,
    this.gastoFijoId,
  });

  factory Movimiento.fromMap(Map<String, Object?> map) {
    return Movimiento(
      id: map['id'] as int?,
      tipo: TipoMovimiento.values.byName(map['tipo'] as String),
      origen: OrigenMovimiento.values.byName(map['origen'] as String),
      nombre: map['nombre'] as String,
      importe: (map['importe'] as num).toDouble(),
      categoriaId: map['categoriaId'] as int,
      cicloMes: map['cicloMes'] as String,
      gastoFijoId: map['gastoFijoId'] as int?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'tipo': tipo.name,
      'origen': origen.name,
      'nombre': nombre,
      'importe': importe,
      'categoriaId': categoriaId,
      'cicloMes': cicloMes,
      'gastoFijoId': gastoFijoId,
    };
  }

  /// Ingreso suma, gasto resta.
  double get importeConSigno =>
      tipo == TipoMovimiento.ingreso ? importe : -importe;
}
