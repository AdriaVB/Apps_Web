import 'movimiento.dart';

/// Etiquetas legibles para cada periodicidad admitida (en meses).
const Map<int, String> etiquetasPeriodicidad = {
  1: 'Mensual',
  3: 'Trimestral',
  4: 'Cuatrimestral',
  6: 'Semestral',
  12: 'Anual',
};

/// Plantilla recurrente: gasto o ingreso fijo (alquiler, luz, IBI, nómina...).
class GastoFijo {
  final int? id;
  final String nombre;
  final TipoMovimiento tipo;
  final int categoriaId;
  final double importe;

  /// Cada cuántos meses se paga: 1 = mensual, 3 = trimestral, 4 =
  /// cuatrimestral, 6 = semestral, 12 = anual.
  final int periodicidadMeses;

  /// Mes (1-12) del primer/próximo pago del ciclo. Solo se usa cuando
  /// [periodicidadMeses] > 1.
  final int? mesDePago;

  /// Si se reparte el importe entre los meses del periodo en vez de
  /// golpear completo cada mes de pago. Solo se usa cuando
  /// [periodicidadMeses] > 1.
  final bool prorratear;

  /// Día del mes (1-31) en que se cobra/paga de verdad, para Recordatorios.
  /// Opcional y ajeno al prorrateo: aunque se reparta en la vista mensual,
  /// el cobro real sigue ocurriendo un día concreto de un mes concreto.
  final int? diaDelMes;

  final bool activo;

  const GastoFijo({
    this.id,
    required this.nombre,
    this.tipo = TipoMovimiento.gasto,
    required this.categoriaId,
    required this.importe,
    this.periodicidadMeses = 1,
    this.mesDePago,
    this.prorratear = false,
    this.diaDelMes,
    this.activo = true,
  });

  factory GastoFijo.fromMap(Map<String, Object?> map) {
    return GastoFijo(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      tipo: TipoMovimiento.values.byName(map['tipo'] as String),
      categoriaId: map['categoriaId'] as int,
      importe: (map['importe'] as num).toDouble(),
      periodicidadMeses: map['periodicidadMeses'] as int,
      mesDePago: map['mesDePago'] as int?,
      prorratear: (map['prorratear'] as int) == 1,
      diaDelMes: map['diaDelMes'] as int?,
      activo: (map['activo'] as int) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'tipo': tipo.name,
      'categoriaId': categoriaId,
      'importe': importe,
      'periodicidadMeses': periodicidadMeses,
      'mesDePago': mesDePago,
      'prorratear': prorratear ? 1 : 0,
      'diaDelMes': diaDelMes,
      'activo': activo ? 1 : 0,
    };
  }

  GastoFijo copyWith({
    String? nombre,
    TipoMovimiento? tipo,
    int? categoriaId,
    double? importe,
    int? periodicidadMeses,
    int? mesDePago,
    bool? prorratear,
    int? diaDelMes,
    bool? activo,
  }) {
    return GastoFijo(
      id: id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      categoriaId: categoriaId ?? this.categoriaId,
      importe: importe ?? this.importe,
      periodicidadMeses: periodicidadMeses ?? this.periodicidadMeses,
      mesDePago: mesDePago ?? this.mesDePago,
      prorratear: prorratear ?? this.prorratear,
      diaDelMes: diaDelMes ?? this.diaDelMes,
      activo: activo ?? this.activo,
    );
  }

  /// Importe que corresponde a un mes concreto:
  /// - mensual (periodicidadMeses == 1): el importe completo, todos los
  ///   meses.
  /// - resto: si prorratea, el importe repartido entre los meses del
  ///   periodo; si no, el importe completo solo en los meses de pago
  ///   (mesDePago y cada periodicidadMeses después), 0 el resto.
  double importeParaMes(int mes) {
    if (periodicidadMeses <= 1) return importe;
    if (prorratear) return importe / periodicidadMeses;
    final diferencia = (mes - mesDePago!) % periodicidadMeses;
    return diferencia == 0 ? importe : 0;
  }

  /// Si de verdad se cobra/paga en [mes] — a diferencia de [importeParaMes],
  /// ignora [prorratear]: un gasto repartido en la vista mensual igualmente
  /// se cobra de golpe un mes concreto en la vida real. Para Recordatorios.
  bool aplicaEnMes(int mes) {
    if (periodicidadMeses <= 1) return true;
    return (mes - mesDePago!) % periodicidadMeses == 0;
  }
}
