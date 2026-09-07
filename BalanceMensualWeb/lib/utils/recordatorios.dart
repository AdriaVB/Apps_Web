import '../models/gasto_fijo.dart';

/// Días que faltan para el próximo cobro/pago de [fijo] dentro de [hoy].
/// Nulo si no se conoce el día, o si [fijo] no aplica en el mes de [hoy].
/// Puede ser negativo si ya pasó este mes.
int? diasHastaProximoCobro(GastoFijo fijo, DateTime hoy) {
  if (fijo.diaDelMes == null || !fijo.aplicaEnMes(hoy.month)) return null;
  final objetivo = DateTime(hoy.year, hoy.month, fijo.diaDelMes!);
  final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
  return objetivo.difference(hoySinHora).inDays;
}

/// De [fijos], los que aplican este mes y todavía no han pasado, ordenados
/// por cuánto falta (los que no tienen día configurado van al final).
/// Compartido entre la pantalla de Recordatorios y el widget de pantalla de
/// inicio.
List<GastoFijo> proximosPagosDelMes(List<GastoFijo> fijos, DateTime hoy) {
  final esteMes = fijos.where((f) => f.aplicaEnMes(hoy.month)).toList()
    ..removeWhere((f) => (diasHastaProximoCobro(f, hoy) ?? 0) < 0)
    ..sort((a, b) {
      final diasA = diasHastaProximoCobro(a, hoy);
      final diasB = diasHastaProximoCobro(b, hoy);
      if (diasA == null && diasB == null) return a.nombre.compareTo(b.nombre);
      if (diasA == null) return 1;
      if (diasB == null) return -1;
      return diasA.compareTo(diasB);
    });
  return esteMes;
}
