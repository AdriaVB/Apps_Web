import 'dart:math';

import '../models/meta_ahorro.dart';

/// Índice absoluto de mes (año×12 + mes) — para comparar dos cicloMes sin
/// importar el día de inicio configurado, igual que ya hace GastoFijo para
/// su periodicidad.
int _indiceMes(String cicloMes) {
  final anio = int.parse(cicloMes.substring(0, 4));
  final mes = int.parse(cicloMes.substring(5, 7));
  return anio * 12 + mes;
}

class ProgresoMetaAhorro {
  /// Lo que haría falta ahorrar cada mes para llegar a tiempo.
  final double aportacionMensual;

  /// Balance real acumulado desde que se creó la meta hasta [cicloActual]
  /// (inclusive) — lo que de verdad te ha sobrado esos meses.
  final double ahorroAcumulado;

  final int mesesTranscurridos;

  /// Cuánto deberías llevar ahorrado a estas alturas si vas al ritmo previsto.
  final double aportacionEsperadaAcumulada;

  final bool completada;

  /// Si el ahorro real ya alcanza o supera lo esperado a estas alturas.
  final bool vaAlDia;

  /// Si sigues ahorrando al ritmo medio real de estos meses, cuántos meses
  /// en total tardarías en llegar al objetivo. Nulo si ese ritmo es 0 o
  /// negativo — a este paso no se llega nunca.
  final int? mesesEstimadosAlRitmoActual;

  const ProgresoMetaAhorro({
    required this.aportacionMensual,
    required this.ahorroAcumulado,
    required this.mesesTranscurridos,
    required this.aportacionEsperadaAcumulada,
    required this.completada,
    required this.vaAlDia,
    required this.mesesEstimadosAlRitmoActual,
  });
}

/// Calcula el progreso de [meta] a fecha de [cicloActual], sumando el
/// balance real (ingresos − gastos) de cada ciclo desde que se creó —
/// ese balance es lo único que la app sabe que "te ha sobrado" cada mes,
/// no hay ningún apartado de dinero real.
ProgresoMetaAhorro calcularProgresoMetaAhorro({
  required MetaAhorro meta,
  required String cicloActual,
  required Map<String, double> balancePorCiclo,
}) {
  final indiceInicio = _indiceMes(meta.cicloInicio);
  final indiceActual = _indiceMes(cicloActual);
  final mesesTranscurridos = max(indiceActual - indiceInicio + 1, 1);

  final ahorroAcumulado = balancePorCiclo.entries
      .where((entrada) {
        final indice = _indiceMes(entrada.key);
        return indice >= indiceInicio && indice <= indiceActual;
      })
      .fold<double>(0, (total, entrada) => total + entrada.value);

  final aportacionMensual = meta.importeObjetivo / meta.mesesPlazo;
  final aportacionEsperadaAcumulada = aportacionMensual * mesesTranscurridos;
  final completada = ahorroAcumulado >= meta.importeObjetivo;
  final vaAlDia = completada || ahorroAcumulado >= aportacionEsperadaAcumulada;

  final ritmoMedio = ahorroAcumulado / mesesTranscurridos;
  final mesesEstimados = ritmoMedio > 0
      ? (meta.importeObjetivo / ritmoMedio).ceil()
      : null;

  return ProgresoMetaAhorro(
    aportacionMensual: aportacionMensual,
    ahorroAcumulado: ahorroAcumulado,
    mesesTranscurridos: mesesTranscurridos,
    aportacionEsperadaAcumulada: aportacionEsperadaAcumulada,
    completada: completada,
    vaAlDia: vaAlDia,
    mesesEstimadosAlRitmoActual: mesesEstimados,
  );
}
