import 'dart:math';

import '../models/movimiento.dart';

/// Cuánto llevas de [tipo] en una categoría este ciclo, frente a tu propia
/// media histórica de esa categoría, y si es tu máximo del año en curso.
class ComparacionCategoria {
  final double media;
  final bool esRecordDelAnio;

  const ComparacionCategoria({
    required this.media,
    required this.esRecordDelAnio,
  });
}

/// Para cada categoría con movimientos de [tipo] en [cicloActual], la
/// compara con la media de esa misma categoría en el resto de ciclos (de
/// cualquier año) y marca si es su máximo dentro de los ciclos del mismo año
/// que [cicloActual].
///
/// Solo devuelve categorías con al menos otro ciclo con el que comparar —
/// nada de "media" ni "récord" con un solo dato, ni la primera vez que se
/// usa una categoría.
Map<int, ComparacionCategoria> compararCategorias({
  required String cicloActual,
  required Map<String, List<Movimiento>> movimientosPorCiclo,
  required TipoMovimiento tipo,
}) {
  final totalesPorCiclo = <String, Map<int, double>>{};
  for (final entrada in movimientosPorCiclo.entries) {
    final totales = <int, double>{};
    for (final m in entrada.value) {
      if (m.tipo != tipo) continue;
      totales[m.categoriaId] = (totales[m.categoriaId] ?? 0) + m.importe;
    }
    totalesPorCiclo[entrada.key] = totales;
  }

  final anioActual = cicloActual.substring(0, 4);
  final categoriasActuales = totalesPorCiclo[cicloActual] ?? {};

  final resultado = <int, ComparacionCategoria>{};
  for (final entrada in categoriasActuales.entries) {
    final categoriaId = entrada.key;
    final importeActual = entrada.value;

    final otros = <double>[
      for (final ciclo in totalesPorCiclo.entries)
        if (ciclo.key != cicloActual && ciclo.value.containsKey(categoriaId))
          ciclo.value[categoriaId]!,
    ];
    if (otros.isEmpty) continue;

    final media = otros.reduce((a, b) => a + b) / otros.length;

    final otrosDelAnio = <double>[
      for (final ciclo in totalesPorCiclo.entries)
        if (ciclo.key != cicloActual &&
            ciclo.key.startsWith(anioActual) &&
            ciclo.value.containsKey(categoriaId))
          ciclo.value[categoriaId]!,
    ];
    final esRecordDelAnio =
        otrosDelAnio.isNotEmpty && importeActual >= otrosDelAnio.reduce(max);

    resultado[categoriaId] = ComparacionCategoria(
      media: media,
      esRecordDelAnio: esRecordDelAnio,
    );
  }
  return resultado;
}
