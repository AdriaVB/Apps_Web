import 'package:flutter_test/flutter_test.dart';

import 'package:balance_mensual_web/utils/salud_financiera.dart';

void main() {
  group('calcularSaludFinanciera', () {
    test('sin ciclos cerrados, no hay nada que calcular', () {
      final resultado = calcularSaludFinanciera(
        ingresosPorCiclo: [],
        balancesPorCiclo: [],
      );
      expect(resultado, isNull);
    });

    test('ahorras un 20% o más de tu ingreso medio: excelente', () {
      final resultado = calcularSaludFinanciera(
        ingresosPorCiclo: [1000, 1000],
        balancesPorCiclo: [200, 300],
      );
      expect(resultado!.tasaAhorro, closeTo(0.25, 0.001));
      expect(resultado.nivel, NivelSaludFinanciera.excelente);
    });

    test('ahorras entre el 10% y el 20%: saludable', () {
      final resultado = calcularSaludFinanciera(
        ingresosPorCiclo: [1000, 1000],
        balancesPorCiclo: [150, 150],
      );
      expect(resultado!.tasaAhorro, closeTo(0.15, 0.001));
      expect(resultado.nivel, NivelSaludFinanciera.saludable);
    });

    test('ahorras entre el 0% y el 10%: ajustada', () {
      final resultado = calcularSaludFinanciera(
        ingresosPorCiclo: [1000],
        balancesPorCiclo: [50],
      );
      expect(resultado!.tasaAhorro, closeTo(0.05, 0.001));
      expect(resultado.nivel, NivelSaludFinanciera.ajustada);
    });

    test('gastas más de lo que ingresas de media: alerta', () {
      final resultado = calcularSaludFinanciera(
        ingresosPorCiclo: [1000, 1000],
        balancesPorCiclo: [-100, 50],
      );
      expect(resultado!.tasaAhorro, closeTo(-0.025, 0.001));
      expect(resultado.nivel, NivelSaludFinanciera.alerta);
    });

    test('sin ingresos registrados, no hay nada que calcular', () {
      final resultado = calcularSaludFinanciera(
        ingresosPorCiclo: [0],
        balancesPorCiclo: [-30],
      );
      expect(resultado, isNull);
    });
  });
}
