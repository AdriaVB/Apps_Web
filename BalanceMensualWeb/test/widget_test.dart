import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:balance_mensual_web/data/app_database.dart';
import 'package:balance_mensual_web/screens/arranque_screen.dart';
import 'package:balance_mensual_web/screens/inicio_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final bases = <AppDatabase>[];

  AppDatabase nuevaBase() {
    final db = AppDatabase.paraPruebas();
    bases.add(db);
    return db;
  }

  tearDown(() async {
    // Sin cerrar, cada base de datos de prueba se queda abierta y se van
    // acumulando conexiones a lo largo del archivo.
    for (final db in bases) {
      await db.cerrar();
    }
    bases.clear();
  });

  /// sqflite_common_ffi hace E/S real: la operación que la dispara
  /// ([accion]) tiene que ejecutarse dentro de runAsync para que sus
  /// continuaciones lleguen a resolverse. Dentro de runAsync solo se hace
  /// pump() simple, nunca pump(duración) — eso provoca un bloqueo.
  ///
  /// En vez de esperar siempre el máximo fijo, sondea y sale en cuanto
  /// desaparece el spinner de carga — normalmente en 1-2 vueltas, no en
  /// las 40 del límite de seguridad.
  Future<void> ejecutarYEsperar(
    WidgetTester tester,
    Future<void> Function() accion,
  ) async {
    await tester.runAsync(() async {
      await accion();
      for (var i = 0; i < 40; i++) {
        await tester.pump();
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
  }

  testWidgets(
    'la pantalla de inicio carga el engranaje, el botón de añadir y el historial',
    (tester) async {
      await ejecutarYEsperar(
        tester,
        () =>
            tester.pumpWidget(MaterialApp(home: InicioScreen(db: nuevaBase()))),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.text('Añadir gasto/ingreso'), findsOneWidget);
      expect(find.text('Historial'), findsOneWidget);
    },
  );

  testWidgets(
    'la primera vez muestra la bienvenida con el selector de día y el botón',
    (tester) async {
      await ejecutarYEsperar(
        tester,
        () => tester.pumpWidget(
          MaterialApp(home: ArranqueScreen(db: nuevaBase())),
        ),
      );

      expect(find.text('Bienvenido a Balance Mensual'), findsOneWidget);
      expect(find.text('Añadir gasto/ingreso'), findsNothing);
      expect(find.text('Día de inicio de mes'), findsOneWidget);
      expect(find.text('Empezar'), findsOneWidget);

      // El toque real del botón (guarda y navega a inicio) se verifica en el
      // emulador, no aquí: dispara E/S real de sqflite dentro del gesto de
      // tap, que en este entorno de test se cuelga de forma intermitente.
    },
  );

  testWidgets('si el onboarding ya está completo, entra directo a inicio', (
    tester,
  ) async {
    final db = nuevaBase();
    await tester.runAsync(() async {
      await db.guardarConfiguracion(
        (await db.obtenerConfiguracion()).copyWith(onboardingCompletado: true),
      );
    });
    await ejecutarYEsperar(
      tester,
      () => tester.pumpWidget(MaterialApp(home: ArranqueScreen(db: db))),
    );

    expect(find.text('Bienvenido a Balance Mensual'), findsNothing);
    expect(find.text('Añadir gasto/ingreso'), findsOneWidget);
  });
}
