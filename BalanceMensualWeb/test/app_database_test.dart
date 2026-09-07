import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:balance_mensual_web/data/app_database.dart';
import 'package:balance_mensual_web/models/categoria.dart';
import 'package:balance_mensual_web/models/configuracion_usuario.dart';
import 'package:balance_mensual_web/models/gasto_fijo.dart';
import 'package:balance_mensual_web/models/meta_ahorro.dart';
import 'package:balance_mensual_web/models/movimiento.dart';
import 'package:balance_mensual_web/utils/ciclo_mes.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase appDb;

  setUp(() {
    // Base de datos en memoria, nueva e independiente para cada test.
    appDb = AppDatabase.paraPruebas();
  });

  tearDown(() async {
    await appDb.cerrar();
  });

  test(
    'el catálogo de categorías recurrentes se crea al abrir la base de datos',
    () async {
      final categorias = await appDb.listarCategoriasRecurrentes();
      expect(categorias.length, Categoria.catalogoRecurrente.length);
      expect(categorias.map((c) => c.nombre), contains('luz'));
      expect(categorias.map((c) => c.nombre), contains('hipoteca'));
      expect(categorias.map((c) => c.nombre), isNot(contains('comida')));
    },
  );

  test(
    'el catálogo de categorías variables se crea al abrir la base de datos',
    () async {
      final categorias = await appDb.listarCategoriasVariables();
      expect(categorias.length, Categoria.catalogoVariable.length);
      expect(categorias.map((c) => c.nombre), contains('salud/higiene'));
      expect(categorias.map((c) => c.nombre), isNot(contains('luz')));
    },
  );

  test(
    'el catálogo de categorías de ingreso se crea al abrir la base de datos',
    () async {
      final categorias = await appDb.listarCategoriasIngreso();
      expect(categorias.length, Categoria.catalogoIngreso.length);
      expect(categorias.map((c) => c.nombre), contains('nómina'));
      expect(categorias.map((c) => c.nombre), contains('bizum'));
      expect(categorias.map((c) => c.nombre), isNot(contains('luz')));
    },
  );

  test('la configuración por defecto tiene día de inicio de mes = 1 y onboarding pendiente', () async {
    final config = await appDb.obtenerConfiguracion();
    expect(config.diaInicioMes, 1);
    expect(config.onboardingCompletado, false);
  });

  test(
    'guardar la configuración marca el onboarding como completado',
    () async {
      await appDb.guardarConfiguracion(
        const ConfiguracionUsuario(
          diaInicioMes: 25,
          onboardingCompletado: true,
        ),
      );
      final config = await appDb.obtenerConfiguracion();
      expect(config.diaInicioMes, 25);
      expect(config.onboardingCompletado, true);
    },
  );

  test('crear, listar y editar un gasto fijo mensual (luz)', () async {
    final categorias = await appDb.listarCategoriasRecurrentes();
    final luz = categorias.firstWhere((c) => c.nombre == 'luz');

    final id = await appDb.crearGastoFijo(
      GastoFijo(nombre: 'Luz', categoriaId: luz.id!, importe: 58.0),
    );

    var fijos = await appDb.listarGastosFijos();
    var luzGuardada = fijos.firstWhere((g) => g.id == id);
    expect(luzGuardada.importe, 58.0);
    expect(luzGuardada.periodicidadMeses, 1);

    // Editar el importe (llega un recibo distinto) no debe crear una fila nueva.
    await appDb.actualizarGastoFijo(luzGuardada.copyWith(importe: 63.0));
    fijos = await appDb.listarGastosFijos();
    expect(fijos.where((g) => g.nombre == 'Luz').length, 1);
    expect(fijos.firstWhere((g) => g.id == id).importe, 63.0);
  });

  test('crear, listar, editar y borrar una meta de ahorro', () async {
    final id = await appDb.crearMetaAhorro(
      MetaAhorro(
        nombre: 'iPhone',
        importeObjetivo: 800,
        mesesPlazo: 6,
        cicloInicio: '2026-08-01',
      ),
    );

    var metas = await appDb.listarMetasAhorro();
    var meta = metas.firstWhere((m) => m.id == id);
    expect(meta.importeObjetivo, 800);
    expect(meta.mesesPlazo, 6);
    expect(meta.cicloInicio, '2026-08-01');

    await appDb.actualizarMetaAhorro(meta.copyWith(importeObjetivo: 900));
    metas = await appDb.listarMetasAhorro();
    expect(metas.firstWhere((m) => m.id == id).importeObjetivo, 900);
    // El ciclo de inicio no cambia al editar.
    expect(metas.firstWhere((m) => m.id == id).cicloInicio, '2026-08-01');

    await appDb.borrarMetaAhorro(id);
    metas = await appDb.listarMetasAhorro();
    expect(metas.where((m) => m.id == id), isEmpty);
  });

  test('un gasto fijo mensual siempre importa el importe completo', () {
    final gasto = GastoFijo(nombre: 'Luz', categoriaId: 1, importe: 58.0);
    expect(gasto.importeParaMes(1), 58.0);
    expect(gasto.importeParaMes(7), 58.0);
  });

  test('un gasto fijo anual prorrateado reparte el importe entre 12', () {
    final gasto = GastoFijo(
      nombre: 'IBI',
      categoriaId: 1,
      importe: 300,
      periodicidadMeses: 12,
      prorratear: true,
      mesDePago: 6,
    );
    expect(gasto.importeParaMes(1), 25.0);
    expect(gasto.importeParaMes(6), 25.0);
  });

  test('un gasto fijo anual sin prorratear solo aparece en su mes de pago', () {
    final gasto = GastoFijo(
      nombre: 'Seguro coche',
      categoriaId: 1,
      importe: 240,
      periodicidadMeses: 12,
      prorratear: false,
      mesDePago: 9,
    );
    expect(gasto.importeParaMes(9), 240.0);
    expect(gasto.importeParaMes(3), 0.0);
  });

  test('un gasto fijo trimestral sin prorratear aparece cada 3 meses desde el mes de pago', () {
    final gasto = GastoFijo(
      nombre: 'Seguro hogar',
      categoriaId: 1,
      importe: 90,
      periodicidadMeses: 3,
      prorratear: false,
      mesDePago: 2,
    );
    expect(gasto.importeParaMes(2), 90.0);
    expect(gasto.importeParaMes(5), 90.0);
    expect(gasto.importeParaMes(8), 90.0);
    expect(gasto.importeParaMes(11), 90.0);
    expect(gasto.importeParaMes(1), 0.0);
    expect(gasto.importeParaMes(3), 0.0);
  });

  test('el balance de un ciclo suma ingresos y resta gastos', () async {
    final categorias = await appDb.listarCategoriasVariables();
    final ocio = categorias.firstWhere((c) => c.nombre == 'ocio');
    const ciclo = '2026-08-01';

    await appDb.crearMovimiento(
      Movimiento(
        tipo: TipoMovimiento.ingreso,
        origen: OrigenMovimiento.variable,
        nombre: 'Nómina',
        importe: 1500,
        categoriaId: ocio.id!,
        cicloMes: ciclo,
      ),
    );
    await appDb.crearMovimiento(
      Movimiento(
        tipo: TipoMovimiento.gasto,
        origen: OrigenMovimiento.variable,
        nombre: 'Videojuego',
        importe: 70,
        categoriaId: ocio.id!,
        cicloMes: ciclo,
      ),
    );

    final balance = await appDb.balanceDeCiclo(ciclo);
    expect(balance, 1430);
  });

  test('borrar un movimiento lo quita del balance del ciclo', () async {
    final categorias = await appDb.listarCategoriasVariables();
    final comida = categorias.firstWhere((c) => c.nombre == 'comida');
    const ciclo = '2026-09-01';

    final id = await appDb.crearMovimiento(
      Movimiento(
        tipo: TipoMovimiento.gasto,
        origen: OrigenMovimiento.variable,
        nombre: 'Supermercado',
        importe: 40,
        categoriaId: comida.id!,
        cicloMes: ciclo,
      ),
    );

    expect(await appDb.balanceDeCiclo(ciclo), -40);
    await appDb.borrarMovimiento(id);
    expect(await appDb.balanceDeCiclo(ciclo), 0);
  });

  test('listarMovimientosDeAnio agrupa los 12 meses de un año y excluye otros años', () async {
    final categorias = await appDb.listarCategoriasVariables();
    final comida = categorias.firstWhere((c) => c.nombre == 'comida');

    for (var mes = 1; mes <= 12; mes++) {
      final mm = mes.toString().padLeft(2, '0');
      await appDb.crearMovimiento(
        Movimiento(
          tipo: TipoMovimiento.gasto,
          origen: OrigenMovimiento.variable,
          nombre: 'Gasto $mm',
          importe: 10,
          categoriaId: comida.id!,
          cicloMes: '2026-$mm-01',
        ),
      );
    }
    // Un movimiento de otro año no debe colarse.
    await appDb.crearMovimiento(
      Movimiento(
        tipo: TipoMovimiento.gasto,
        origen: OrigenMovimiento.variable,
        nombre: 'Gasto de 2027',
        importe: 999,
        categoriaId: comida.id!,
        cicloMes: '2027-01-01',
      ),
    );

    final movimientos2026 = await appDb.listarMovimientosDeAnio(2026);
    expect(movimientos2026.length, 12);
    expect(movimientos2026.every((m) => m.cicloMes.startsWith('2026-')), true);

    // 2026 tiene los 12 meses completos; 2027 solo tiene uno.
    expect(await appDb.listarAniosCompletos(), [2026]);
  });

  group('generarMovimientosDelCiclo', () {
    test(
      'genera un movimiento por cada gasto fijo activo, una sola vez',
      () async {
        final categorias = await appDb.listarCategoriasRecurrentes();
        final luz = categorias.firstWhere((c) => c.nombre == 'luz');
        await appDb.crearGastoFijo(
          GastoFijo(nombre: 'Luz', categoriaId: luz.id!, importe: 58.0),
        );
        const ciclo = '2026-08-01';

        await appDb.generarMovimientosDelCiclo(ciclo);
        await appDb.generarMovimientosDelCiclo(ciclo); // llamada repetida

        final movimientos = await appDb.listarMovimientosDeCiclo(ciclo);
        expect(movimientos.length, 1);
        expect(movimientos.first.nombre, 'Luz');
        expect(movimientos.first.importe, 58.0);
        expect(movimientos.first.origen, OrigenMovimiento.fijo);
      },
    );

    test('un gasto fijo desactivado no genera movimiento', () async {
      final categorias = await appDb.listarCategoriasRecurrentes();
      final luz = categorias.firstWhere((c) => c.nombre == 'luz');
      final id = await appDb.crearGastoFijo(
        GastoFijo(nombre: 'Luz', categoriaId: luz.id!, importe: 58.0),
      );
      final fijos = await appDb.listarGastosFijos();
      await appDb.actualizarGastoFijo(
        fijos.firstWhere((g) => g.id == id).copyWith(activo: false),
      );

      await appDb.generarMovimientosDelCiclo('2026-08-01');

      expect(await appDb.listarMovimientosDeCiclo('2026-08-01'), isEmpty);
    });

    test(
      'un gasto fijo anual prorrateado genera movimiento todos los meses',
      () async {
        final categorias = await appDb.listarCategoriasRecurrentes();
        final impuestos = categorias.firstWhere((c) => c.nombre == 'impuestos');
        await appDb.crearGastoFijo(
          GastoFijo(
            nombre: 'IBI',
            categoriaId: impuestos.id!,
            importe: 300,
            periodicidadMeses: 12,
            prorratear: true,
            mesDePago: 6,
          ),
        );

        await appDb.generarMovimientosDelCiclo('2026-01-01');
        await appDb.generarMovimientosDelCiclo('2026-06-01');

        expect(
          (await appDb.listarMovimientosDeCiclo('2026-01-01')).single.importe,
          25.0,
        );
        expect(
          (await appDb.listarMovimientosDeCiclo('2026-06-01')).single.importe,
          25.0,
        );
      },
    );

    test('un gasto fijo anual sin prorratear solo genera movimiento en su mes de pago', () async {
      final categorias = await appDb.listarCategoriasRecurrentes();
      final seguros = categorias.firstWhere((c) => c.nombre == 'seguros');
      await appDb.crearGastoFijo(
        GastoFijo(
          nombre: 'Seguro coche',
          categoriaId: seguros.id!,
          importe: 240,
          periodicidadMeses: 12,
          prorratear: false,
          mesDePago: 9,
        ),
      );

      await appDb.generarMovimientosDelCiclo('2026-03-01');
      await appDb.generarMovimientosDelCiclo('2026-09-01');

      expect(await appDb.listarMovimientosDeCiclo('2026-03-01'), isEmpty);
      expect(
        (await appDb.listarMovimientosDeCiclo('2026-09-01')).single.importe,
        240.0,
      );
    });

    test(
      'un ingreso fijo mensual (nómina) genera un movimiento de tipo ingreso',
      () async {
        final categorias = await appDb.listarCategoriasRecurrentes();
        await appDb.crearGastoFijo(
          GastoFijo(
            nombre: 'Nómina',
            tipo: TipoMovimiento.ingreso,
            categoriaId: categorias.first.id!,
            importe: 1500,
          ),
        );
        const ciclo = '2026-08-01';

        await appDb.generarMovimientosDelCiclo(ciclo);

        final movimientos = await appDb.listarMovimientosDeCiclo(ciclo);
        expect(movimientos.single.tipo, TipoMovimiento.ingreso);
        expect(movimientos.single.importe, 1500.0);
        expect(await appDb.balanceDeCiclo(ciclo), 1500.0);
      },
    );
  });

  group('sincronizar plantilla en ciclo actual', () {
    // El mes actual sigue "abierto": editar la plantilla debe verse
    // reflejado en el movimiento ya generado para hoy, sin tocar el pasado.
    late String cicloActual;

    setUp(() async {
      final config = await appDb.obtenerConfiguracion();
      cicloActual = claveCiclo(DateTime.now(), config.diaInicioMes);
    });

    test(
      'editar un gasto fijo mensual actualiza el importe ya generado este mes',
      () async {
        final categorias = await appDb.listarCategoriasRecurrentes();
        final luz = categorias.firstWhere((c) => c.nombre == 'luz');
        final id = await appDb.crearGastoFijo(
          GastoFijo(nombre: 'Luz', categoriaId: luz.id!, importe: 58.0),
        );
        await appDb.generarMovimientosDelCiclo(cicloActual);
        expect(
          (await appDb.listarMovimientosDeCiclo(cicloActual)).single.importe,
          58.0,
        );

        final editado = (await appDb.listarGastosFijos())
            .firstWhere((g) => g.id == id)
            .copyWith(importe: 63.0);
        await appDb.actualizarGastoFijo(editado);
        await appDb.sincronizarGastoFijoEnCicloActual(editado);

        final movimientos = await appDb.listarMovimientosDeCiclo(cicloActual);
        expect(movimientos.length, 1);
        expect(movimientos.single.importe, 63.0);
      },
    );

    test('desactivar el prorrateo de un anual borra el movimiento si no toca este mes', () async {
      final categorias = await appDb.listarCategoriasRecurrentes();
      final seguros = categorias.firstWhere((c) => c.nombre == 'seguros');
      final mesQueNoEsEsteMes = int.parse(cicloActual.substring(5, 7)) % 12 + 1;

      final id = await appDb.crearGastoFijo(
        GastoFijo(
          nombre: 'Seguro',
          categoriaId: seguros.id!,
          importe: 120,
          periodicidadMeses: 12,
          prorratear: true,
          mesDePago: mesQueNoEsEsteMes,
        ),
      );
      await appDb.generarMovimientosDelCiclo(cicloActual);
      expect(await appDb.listarMovimientosDeCiclo(cicloActual), isNotEmpty);

      final editado = (await appDb.listarGastosFijos()).firstWhere(
        (g) => g.id == id,
      );
      final sinProrratear = editado.copyWith(prorratear: false);
      await appDb.actualizarGastoFijo(sinProrratear);
      await appDb.sincronizarGastoFijoEnCicloActual(sinProrratear);

      expect(await appDb.listarMovimientosDeCiclo(cicloActual), isEmpty);
    });

    test('cambiar un gasto fijo a ingreso al editarlo actualiza el tipo del movimiento ya generado', () async {
      final categorias = await appDb.listarCategoriasRecurrentes();
      final id = await appDb.crearGastoFijo(
        GastoFijo(
          nombre: 'Alquiler cobrado',
          categoriaId: categorias.first.id!,
          importe: 600,
        ),
      );
      await appDb.generarMovimientosDelCiclo(cicloActual);
      expect(
        (await appDb.listarMovimientosDeCiclo(cicloActual)).single.tipo,
        TipoMovimiento.gasto,
      );

      final comoIngreso = (await appDb.listarGastosFijos())
          .firstWhere((g) => g.id == id)
          .copyWith(tipo: TipoMovimiento.ingreso);
      await appDb.actualizarGastoFijo(comoIngreso);
      await appDb.sincronizarGastoFijoEnCicloActual(comoIngreso);

      final movimientos = await appDb.listarMovimientosDeCiclo(cicloActual);
      expect(movimientos.length, 1);
      expect(movimientos.single.tipo, TipoMovimiento.ingreso);
    });

    test(
      'borrar un gasto fijo quita también su movimiento ya generado este mes',
      () async {
        final categorias = await appDb.listarCategoriasRecurrentes();
        final id = await appDb.crearGastoFijo(
          GastoFijo(
            nombre: 'Seguro coche',
            categoriaId: categorias.first.id!,
            importe: 240,
          ),
        );
        await appDb.generarMovimientosDelCiclo(cicloActual);
        expect(await appDb.listarMovimientosDeCiclo(cicloActual), isNotEmpty);

        final gasto = (await appDb.listarGastosFijos()).firstWhere(
          (g) => g.id == id,
        );
        await appDb.borrarGastoFijo(gasto);

        expect(await appDb.listarMovimientosDeCiclo(cicloActual), isEmpty);
        expect(
          (await appDb.listarGastosFijos()).any((g) => g.id == id),
          isFalse,
        );
      },
    );

    test(
      'borrar un gasto fijo no toca el movimiento de un ciclo ya cerrado',
      () async {
        final categorias = await appDb.listarCategoriasRecurrentes();
        const cicloCerrado = '2020-01-01';
        final id = await appDb.crearGastoFijo(
          GastoFijo(
            nombre: 'Seguro coche',
            categoriaId: categorias.first.id!,
            importe: 240,
          ),
        );
        await appDb.crearMovimiento(
          Movimiento(
            tipo: TipoMovimiento.gasto,
            origen: OrigenMovimiento.fijo,
            nombre: 'Seguro coche',
            importe: 240,
            categoriaId: categorias.first.id!,
            cicloMes: cicloCerrado,
            gastoFijoId: id,
          ),
        );

        final gasto = (await appDb.listarGastosFijos()).firstWhere(
          (g) => g.id == id,
        );
        await appDb.borrarGastoFijo(gasto);

        expect(await appDb.listarMovimientosDeCiclo(cicloCerrado), isNotEmpty);
      },
    );
  });
}
