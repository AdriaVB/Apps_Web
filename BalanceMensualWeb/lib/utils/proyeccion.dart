import '../models/movimiento.dart';

/// Proyecta el balance con el que terminarías el ciclo actual si el ritmo de
/// ingresos/gastos variables se mantiene igual el resto del ciclo.
///
/// Los movimientos fijos ya están completos en [balanceActual] desde el
/// primer día (el motor de cierre los aplica todos de golpe al abrir el
/// ciclo, sin importar su día real de cobro/pago) — lo único que puede
/// cambiar de aquí a que acabe el ciclo es lo variable, así que solo eso se
/// extrapola: (variable acumulado ÷ días transcurridos) × días que quedan.
///
/// Nulo cuando no queda ningún día del ciclo por delante (nada que
/// proyectar, [balanceActual] ya es el resultado final).
double? proyectarFinDeCiclo({
  required double balanceActual,
  required List<Movimiento> movimientosDelCiclo,
  required DateTime inicioCiclo,
  required DateTime finCiclo,
  required DateTime ahora,
}) {
  final diasTotales = finCiclo.difference(inicioCiclo).inDays + 1;
  final diasTranscurridos = (ahora.difference(inicioCiclo).inDays + 1).clamp(
    1,
    diasTotales,
  );
  final diasRestantes = diasTotales - diasTranscurridos;
  if (diasRestantes <= 0) return null;

  final netoVariable = movimientosDelCiclo
      .where((m) => m.origen == OrigenMovimiento.variable)
      .fold(0.0, (total, m) => total + m.importeConSigno);

  final ritmoDiario = netoVariable / diasTranscurridos;
  return balanceActual + ritmoDiario * diasRestantes;
}
