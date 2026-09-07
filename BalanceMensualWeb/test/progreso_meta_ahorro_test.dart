import 'package:flutter_test/flutter_test.dart';

import 'package:balance_mensual_web/models/meta_ahorro.dart';
import 'package:balance_mensual_web/utils/progreso_meta_ahorro.dart';

MetaAhorro _meta({
  double importeObjetivo = 800,
  int mesesPlazo = 6,
  String cicloInicio = '2026-08-01',
}) {
  return MetaAhorro(
    nombre: 'iPhone',
    importeObjetivo: importeObjetivo,
    mesesPlazo: mesesPlazo,
    cicloInicio: cicloInicio,
  );
}

void main() {
  group('calcularProgresoMetaAhorro', () {
    test('la aportación mensual es el importe entre el plazo', () {
      final progreso = calcularProgresoMetaAhorro(
        meta: _meta(importeObjetivo: 600, mesesPlazo: 6),
        cicloActual: '2026-08-01',
        balancePorCiclo: {'2026-08-01': 0},
      );

      expect(progreso.aportacionMensual, closeTo(100, 0.001));
    });

    test('en el primer mes, si ahorras justo lo necesario, vas al día', () {
      final progreso = calcularProgresoMetaAhorro(
        meta: _meta(importeObjetivo: 600, mesesPlazo: 6),
        cicloActual: '2026-08-01',
        balancePorCiclo: {'2026-08-01': 100},
      );

      expect(progreso.mesesTranscurridos, 1);
      expect(progreso.vaAlDia, true);
    });

    test('si ahorras menos de lo necesario, vas por detrás', () {
      final progreso = calcularProgresoMetaAhorro(
        meta: _meta(importeObjetivo: 600, mesesPlazo: 6),
        cicloActual: '2026-09-01',
        balancePorCiclo: {'2026-08-01': 100, '2026-09-01': 20},
      );

      // Esperado a los 2 meses: 200. Real: 120. Vas 80 por detrás.
      expect(progreso.mesesTranscurridos, 2);
      expect(progreso.vaAlDia, false);
      expect(
        progreso.aportacionEsperadaAcumulada - progreso.ahorroAcumulado,
        closeTo(80, 0.001),
      );
    });

    test('un mes malo (balance negativo) también resta del ahorro real', () {
      final progreso = calcularProgresoMetaAhorro(
        meta: _meta(importeObjetivo: 600, mesesPlazo: 6),
        cicloActual: '2026-09-01',
        balancePorCiclo: {'2026-08-01': 100, '2026-09-01': -50},
      );

      expect(progreso.ahorroAcumulado, closeTo(50, 0.001));
      expect(progreso.vaAlDia, false);
    });

    test('está completada cuando el ahorro acumulado alcanza el objetivo', () {
      final progreso = calcularProgresoMetaAhorro(
        meta: _meta(importeObjetivo: 600, mesesPlazo: 6),
        cicloActual: '2026-08-01',
        balancePorCiclo: {'2026-08-01': 600},
      );

      expect(progreso.completada, true);
      expect(progreso.vaAlDia, true);
    });

    test('solo cuenta los ciclos entre el inicio de la meta y el actual', () {
      final progreso = calcularProgresoMetaAhorro(
        meta: _meta(cicloInicio: '2026-08-01'),
        cicloActual: '2026-08-01',
        balancePorCiclo: {
          '2026-07-01': 1000, // antes de la meta: no cuenta
          '2026-08-01': 100,
          '2026-09-01': 1000, // futuro: no cuenta
        },
      );

      expect(progreso.ahorroAcumulado, closeTo(100, 0.001));
    });

    test(
      'estima los meses totales al ritmo medio real cuando vas por detrás',
      () {
        final progreso = calcularProgresoMetaAhorro(
          meta: _meta(importeObjetivo: 600, mesesPlazo: 6),
          cicloActual: '2026-09-01',
          // Ritmo medio real: 30€/mes. 600 / 30 = 20 meses.
          balancePorCiclo: {'2026-08-01': 30, '2026-09-01': 30},
        );

        expect(progreso.mesesEstimadosAlRitmoActual, 20);
      },
    );

    test('sin ahorro real, no se puede estimar cuándo se llegaría', () {
      final progreso = calcularProgresoMetaAhorro(
        meta: _meta(),
        cicloActual: '2026-08-01',
        balancePorCiclo: {'2026-08-01': 0},
      );

      expect(progreso.mesesEstimadosAlRitmoActual, isNull);
    });
  });
}
