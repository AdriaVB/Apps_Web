import 'package:flutter_test/flutter_test.dart';

import 'package:balance_mensual_web/models/movimiento.dart';
import 'package:balance_mensual_web/utils/comparacion_categoria.dart';

Movimiento _gasto(String ciclo, int categoriaId, double importe) {
  return Movimiento(
    tipo: TipoMovimiento.gasto,
    origen: OrigenMovimiento.variable,
    nombre: 'x',
    importe: importe,
    categoriaId: categoriaId,
    cicloMes: ciclo,
  );
}

void main() {
  group('compararCategorias', () {
    test('una categoría sin otros ciclos no aparece en el resultado', () {
      final resultado = compararCategorias(
        cicloActual: '2026-03-01',
        movimientosPorCiclo: {
          '2026-03-01': [_gasto('2026-03-01', 1, 100)],
        },
        tipo: TipoMovimiento.gasto,
      );

      expect(resultado.containsKey(1), false);
    });

    test('calcula la media con el resto de ciclos, de cualquier año', () {
      final resultado = compararCategorias(
        cicloActual: '2026-03-01',
        movimientosPorCiclo: {
          '2025-01-01': [_gasto('2025-01-01', 1, 200)],
          '2026-01-01': [_gasto('2026-01-01', 1, 300)],
          '2026-03-01': [_gasto('2026-03-01', 1, 400)],
        },
        tipo: TipoMovimiento.gasto,
      );

      // Media de 200 y 300 (se excluye el propio ciclo actual) = 250.
      expect(resultado[1]!.media, closeTo(250, 0.001));
    });

    test(
      'es récord del año si es el máximo entre los ciclos del mismo año',
      () {
        final resultado = compararCategorias(
          cicloActual: '2026-03-01',
          movimientosPorCiclo: {
            '2026-01-01': [_gasto('2026-01-01', 1, 100)],
            '2026-02-01': [_gasto('2026-02-01', 1, 150)],
            '2026-03-01': [_gasto('2026-03-01', 1, 200)],
          },
          tipo: TipoMovimiento.gasto,
        );

        expect(resultado[1]!.esRecordDelAnio, true);
      },
    );

    test('no es récord si otro ciclo del mismo año gastó más', () {
      final resultado = compararCategorias(
        cicloActual: '2026-03-01',
        movimientosPorCiclo: {
          '2026-01-01': [_gasto('2026-01-01', 1, 500)],
          '2026-03-01': [_gasto('2026-03-01', 1, 200)],
        },
        tipo: TipoMovimiento.gasto,
      );

      expect(resultado[1]!.esRecordDelAnio, false);
    });

    test(
      'los ciclos de otros años cuentan para la media pero no para el récord',
      () {
        final resultado = compararCategorias(
          cicloActual: '2026-01-01',
          movimientosPorCiclo: {
            '2025-01-01': [_gasto('2025-01-01', 1, 900)],
            '2026-01-01': [_gasto('2026-01-01', 1, 100)],
          },
          tipo: TipoMovimiento.gasto,
        );

        expect(resultado[1]!.esRecordDelAnio, false);
        expect(resultado[1]!.media, closeTo(900, 0.001));
      },
    );

    test('solo compara movimientos del tipo pedido', () {
      final resultado = compararCategorias(
        cicloActual: '2026-02-01',
        movimientosPorCiclo: {
          '2026-01-01': [
            _gasto('2026-01-01', 1, 100),
            Movimiento(
              tipo: TipoMovimiento.ingreso,
              origen: OrigenMovimiento.variable,
              nombre: 'y',
              importe: 999,
              categoriaId: 1,
              cicloMes: '2026-01-01',
            ),
          ],
          '2026-02-01': [_gasto('2026-02-01', 1, 150)],
        },
        tipo: TipoMovimiento.gasto,
      );

      expect(resultado[1]!.media, closeTo(100, 0.001));
    });
  });
}
