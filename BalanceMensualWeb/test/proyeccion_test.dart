import 'package:flutter_test/flutter_test.dart';

import 'package:balance_mensual_web/models/movimiento.dart';
import 'package:balance_mensual_web/utils/proyeccion.dart';

Movimiento _variable(
  double importe, {
  TipoMovimiento tipo = TipoMovimiento.gasto,
}) {
  return Movimiento(
    tipo: tipo,
    origen: OrigenMovimiento.variable,
    nombre: 'x',
    importe: importe,
    categoriaId: 1,
    cicloMes: '2026-08-01',
  );
}

Movimiento _fijo(double importe) {
  return Movimiento(
    tipo: TipoMovimiento.gasto,
    origen: OrigenMovimiento.fijo,
    nombre: 'x',
    importe: importe,
    categoriaId: 1,
    cicloMes: '2026-08-01',
  );
}

void main() {
  group('proyectarFinDeCiclo', () {
    final inicioCiclo = DateTime(2026, 8, 1);
    final finCiclo = DateTime(2026, 8, 31);

    test('extrapola el ritmo de gasto variable a los días que quedan', () {
      // Día 11 de 31: 11 días transcurridos, 20 por delante.
      final ahora = DateTime(2026, 8, 11);
      final movimientos = [
        _fijo(1000), // ya completo, no debe afectar a la proyección
        _variable(110), // gasto variable acumulado: -110 en 11 días
      ];

      final resultado = proyectarFinDeCiclo(
        balanceActual: 500,
        movimientosDelCiclo: movimientos,
        inicioCiclo: inicioCiclo,
        finCiclo: finCiclo,
        ahora: ahora,
      );

      // Ritmo diario: -110 / 11 = -10 €/día × 20 días restantes = -200.
      expect(resultado, closeTo(300, 0.001));
    });

    test(
      'sin movimientos variables, la proyección coincide con el balance actual',
      () {
        final ahora = DateTime(2026, 8, 15);
        final resultado = proyectarFinDeCiclo(
          balanceActual: 250,
          movimientosDelCiclo: [_fijo(400)],
          inicioCiclo: inicioCiclo,
          finCiclo: finCiclo,
          ahora: ahora,
        );

        expect(resultado, closeTo(250, 0.001));
      },
    );

    test('en el último día del ciclo no hay nada que proyectar', () {
      final resultado = proyectarFinDeCiclo(
        balanceActual: 500,
        movimientosDelCiclo: [_variable(50)],
        inicioCiclo: inicioCiclo,
        finCiclo: finCiclo,
        ahora: finCiclo,
      );

      expect(resultado, isNull);
    });

    test(
      'los ingresos variables suman a la proyección, no solo los gastos',
      () {
        final ahora = DateTime(2026, 8, 11);
        final movimientos = [_variable(220, tipo: TipoMovimiento.ingreso)];

        final resultado = proyectarFinDeCiclo(
          balanceActual: 1000,
          movimientosDelCiclo: movimientos,
          inicioCiclo: inicioCiclo,
          finCiclo: finCiclo,
          ahora: ahora,
        );

        // Ritmo diario: +220 / 11 = +20 €/día × 20 días restantes = +400.
        expect(resultado, closeTo(1400, 0.001));
      },
    );
  });
}
