import 'package:flutter_test/flutter_test.dart';
import 'package:balance_mensual_web/utils/ciclo_mes.dart';

void main() {
  group('inicioDeCiclo', () {
    test('mes natural (día 1) devuelve el propio mes', () {
      final inicio = inicioDeCiclo(DateTime(2026, 3, 20), 1);
      expect(inicio, DateTime(2026, 3, 1));
    });

    test(
      'ciclo de nómina (día 25), antes del corte cae en el mes anterior',
      () {
        final inicio = inicioDeCiclo(DateTime(2026, 3, 20), 25);
        expect(inicio, DateTime(2026, 2, 25));
      },
    );

    test(
      'ciclo de nómina (día 25), después del corte cae en el mes actual',
      () {
        final inicio = inicioDeCiclo(DateTime(2026, 3, 26), 25);
        expect(inicio, DateTime(2026, 3, 25));
      },
    );

    test(
      'cruce de año: enero antes del corte cae en diciembre del año anterior',
      () {
        final inicio = inicioDeCiclo(DateTime(2026, 1, 10), 25);
        expect(inicio, DateTime(2025, 12, 25));
      },
    );

    test(
      'día de inicio mayor que los días del mes se ajusta al último día',
      () {
        final inicio = inicioDeCiclo(DateTime(2026, 2, 27), 31);
        expect(inicio, DateTime(2026, 1, 31));
      },
    );
  });

  group('claveCiclo', () {
    test('formatea como yyyy-MM-dd', () {
      expect(claveCiclo(DateTime(2026, 3, 20), 1), '2026-03-01');
      expect(claveCiclo(DateTime(2026, 3, 20), 25), '2026-02-25');
    });
  });

  group('finDeCiclo', () {
    test('mes natural: último día del propio mes', () {
      final fin = finDeCiclo(DateTime(2026, 2, 10), 1);
      expect(fin, DateTime(2026, 2, 28)); // 2026 no es bisiesto
    });

    test('ciclo de nómina (día 25): el día antes del siguiente inicio', () {
      final fin = finDeCiclo(DateTime(2026, 3, 20), 25);
      expect(fin, DateTime(2026, 3, 24));
    });

    test('ciclo de nómina cruzando de mes', () {
      // 19 de agosto, con corte el 25, todavía pertenece al ciclo jul-ago.
      final fin = finDeCiclo(DateTime(2026, 8, 19), 25);
      expect(fin, DateTime(2026, 8, 24));
    });
  });

  group('fechaTransicionCiclo', () {
    test('el día nuevo todavía no ha pasado: se aplica este mismo mes', () {
      final fecha = fechaTransicionCiclo(DateTime(2026, 8, 15), 20);
      expect(fecha, DateTime(2026, 8, 20));
    });

    test('el día nuevo ya pasó: se aplica el mes que viene', () {
      final fecha = fechaTransicionCiclo(DateTime(2026, 8, 20), 15);
      expect(fecha, DateTime(2026, 9, 15));
    });

    test('el día nuevo es hoy mismo: se aplica hoy', () {
      final fecha = fechaTransicionCiclo(DateTime(2026, 8, 20), 20);
      expect(fecha, DateTime(2026, 8, 20));
    });

    test('cruce de año: diciembre con el día ya pasado va a enero del año siguiente', () {
      final fecha = fechaTransicionCiclo(DateTime(2026, 12, 20), 15);
      expect(fecha, DateTime(2027, 1, 15));
    });

    test('día nuevo mayor que los días del mes se ajusta al último día', () {
      // Febrero de 2026 (no bisiesto) solo tiene 28 días.
      final fecha = fechaTransicionCiclo(DateTime(2026, 2, 20), 31);
      expect(fecha, DateTime(2026, 2, 28));
    });
  });
}
