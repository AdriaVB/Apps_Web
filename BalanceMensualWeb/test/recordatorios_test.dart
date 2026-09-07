import 'package:flutter_test/flutter_test.dart';

import 'package:balance_mensual_web/models/gasto_fijo.dart';
import 'package:balance_mensual_web/models/movimiento.dart';
import 'package:balance_mensual_web/utils/recordatorios.dart';

void main() {
  group('GastoFijo.aplicaEnMes', () {
    test('un gasto mensual aplica en cualquier mes', () {
      final gasto = GastoFijo(nombre: 'Luz', categoriaId: 1, importe: 50);
      expect(gasto.aplicaEnMes(1), true);
      expect(gasto.aplicaEnMes(7), true);
      expect(gasto.aplicaEnMes(12), true);
    });

    test('un gasto trimestral aplica cada 3 meses desde el mes de pago, ignorando el prorrateo', () {
      final gasto = GastoFijo(
        nombre: 'Seguro hogar',
        categoriaId: 1,
        importe: 90,
        periodicidadMeses: 3,
        prorratear: true, // el prorrateo no debe afectar a aplicaEnMes
        mesDePago: 2,
      );
      expect(gasto.aplicaEnMes(2), true);
      expect(gasto.aplicaEnMes(5), true);
      expect(gasto.aplicaEnMes(8), true);
      expect(gasto.aplicaEnMes(11), true);
      expect(gasto.aplicaEnMes(1), false);
      expect(gasto.aplicaEnMes(3), false);
    });
  });

  group('diasHastaProximoCobro', () {
    test('devuelve null si no hay día del mes configurado', () {
      final gasto = GastoFijo(nombre: 'Luz', categoriaId: 1, importe: 50);
      expect(diasHastaProximoCobro(gasto, DateTime(2026, 8, 10)), null);
    });

    test('devuelve null si el gasto no aplica ese mes', () {
      final gasto = GastoFijo(
        nombre: 'IBI',
        categoriaId: 1,
        importe: 300,
        periodicidadMeses: 12,
        mesDePago: 6,
        diaDelMes: 15,
      );
      expect(diasHastaProximoCobro(gasto, DateTime(2026, 8, 10)), null);
    });

    test('cuenta los días que faltan dentro del mismo mes', () {
      final gasto = GastoFijo(
        nombre: 'Alquiler',
        categoriaId: 1,
        importe: 700,
        diaDelMes: 5,
      );
      expect(diasHastaProximoCobro(gasto, DateTime(2026, 8, 3)), 2);
      expect(diasHastaProximoCobro(gasto, DateTime(2026, 8, 5)), 0);
    });

    test('da un número negativo si ya pasó ese día este mes', () {
      final gasto = GastoFijo(
        nombre: 'Alquiler',
        categoriaId: 1,
        importe: 700,
        diaDelMes: 5,
      );
      expect(diasHastaProximoCobro(gasto, DateTime(2026, 8, 10)), -5);
    });
  });

  group('un ingreso fijo también puede tener día del mes', () {
    test('la nómina cuenta como aplicable con su día configurado', () {
      final nomina = GastoFijo(
        nombre: 'Nómina',
        tipo: TipoMovimiento.ingreso,
        categoriaId: 1,
        importe: 1500,
        diaDelMes: 28,
      );
      expect(nomina.aplicaEnMes(8), true);
      expect(diasHastaProximoCobro(nomina, DateTime(2026, 8, 20)), 8);
    });
  });
}
