enum NivelSaludFinanciera { excelente, saludable, ajustada, alerta }

class SaludFinanciera {
  /// Ahorro medio ÷ ingreso medio de los ciclos ya cerrados. Puede ser
  /// negativo (gastas más de lo que ingresas de media).
  final double tasaAhorro;
  final NivelSaludFinanciera nivel;

  const SaludFinanciera({required this.tasaAhorro, required this.nivel});
}

/// Umbrales de la regla del 20% de ahorro, una referencia común en
/// asesoría financiera — no un corte inventado para esta app.
NivelSaludFinanciera _nivelParaTasa(double tasa) {
  if (tasa < 0) return NivelSaludFinanciera.alerta;
  if (tasa < 0.10) return NivelSaludFinanciera.ajustada;
  if (tasa < 0.20) return NivelSaludFinanciera.saludable;
  return NivelSaludFinanciera.excelente;
}

/// Calcula la salud financiera a partir de los ingresos y el balance de
/// cada ciclo ya cerrado (sin el ciclo actual, que va a medias y sesgaría
/// la media). Nulo si todavía no hay ningún ciclo cerrado con ingresos.
SaludFinanciera? calcularSaludFinanciera({
  required List<double> ingresosPorCiclo,
  required List<double> balancesPorCiclo,
}) {
  assert(ingresosPorCiclo.length == balancesPorCiclo.length);
  if (ingresosPorCiclo.isEmpty) return null;

  final ingresoMedio =
      ingresosPorCiclo.reduce((a, b) => a + b) / ingresosPorCiclo.length;
  if (ingresoMedio <= 0) return null;

  final balanceMedio =
      balancesPorCiclo.reduce((a, b) => a + b) / balancesPorCiclo.length;

  final tasa = balanceMedio / ingresoMedio;
  return SaludFinanciera(tasaAhorro: tasa, nivel: _nivelParaTasa(tasa));
}

String etiquetaSaludFinanciera(NivelSaludFinanciera nivel) {
  switch (nivel) {
    case NivelSaludFinanciera.excelente:
      return 'Excelente';
    case NivelSaludFinanciera.saludable:
      return 'Saludable';
    case NivelSaludFinanciera.ajustada:
      return 'Ajustada';
    case NivelSaludFinanciera.alerta:
      return 'Alerta';
  }
}
