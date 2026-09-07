import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/categoria.dart';
import '../models/configuracion_usuario.dart';
import '../models/gasto_fijo.dart';
import '../models/meta_ahorro.dart';
import '../models/movimiento.dart';
import '../utils/ciclo_mes.dart';
import 'ruta_temporal_pruebas_stub.dart'
    if (dart.library.io) 'ruta_temporal_pruebas_io.dart';

/// Punto único de acceso a la base de datos local (SQLite vía sqflite).
/// Todo se guarda en el dispositivo, no hay servidor externo.
class AppDatabase {
  AppDatabase._(this._rutaOverride);

  final String? _rutaOverride;

  static final AppDatabase instancia = AppDatabase._(null);

  static int _contadorPruebas = 0;

  /// Instancia aislada para tests. Cada llamada usa un archivo temporal con
  /// nombre único — no se puede reutilizar la ruta especial ":memory:" para
  /// esto porque sqflite cachea la conexión por ruta, y varias instancias
  /// con ":memory:" acabarían compartiendo sin querer la misma base de datos.
  static AppDatabase paraPruebas() {
    final ruta = rutaTemporalUnica(
      'balance_mensual_test_${_contadorPruebas++}_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    return AppDatabase._(ruta);
  }

  Database? _db;

  Future<Database> get db async {
    return _db ??= await _abrir();
  }

  /// Solo para tests: cierra la conexión. Sin esto, cada instancia creada
  /// con [paraPruebas] deja su conexión abierta indefinidamente.
  Future<void> cerrar() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }

  Future<Database> _abrir() async {
    // En web no hay un directorio de documentos real — databaseFactoryFfiWeb
    // trata este valor solo como el nombre con el que guarda los datos en
    // IndexedDB, no como una ruta de archivo de verdad.
    final ruta =
        _rutaOverride ??
        (kIsWeb
            ? 'balance_mensual.db'
            : p.join(
                (await getApplicationDocumentsDirectory()).path,
                'balance_mensual.db',
              ));

    return openDatabase(
      ruta,
      version: 4,
      onCreate: _crearEsquema,
      onUpgrade: _actualizarEsquema,
    );
  }

  /// Migraciones reales, para no perder datos ya guardados en el
  /// dispositivo al añadir columnas nuevas (a diferencia de en desarrollo,
  /// donde hasta ahora bastaba con borrar los datos de la app).
  Future<void> _actualizarEsquema(
    Database db,
    int versionAnterior,
    int versionNueva,
  ) async {
    if (versionAnterior < 2) {
      await db.execute('ALTER TABLE gasto_fijo ADD COLUMN diaDelMes INTEGER');
    }
    if (versionAnterior < 3) {
      await db.execute(_creacionTablaMetaAhorro);
    }
    if (versionAnterior < 4) {
      await db.execute(
        'ALTER TABLE configuracion_usuario ADD COLUMN diaInicioMesPendiente INTEGER',
      );
      await db.execute(
        'ALTER TABLE configuracion_usuario ADD COLUMN fechaAplicacionPendiente TEXT',
      );
    }
  }

  Future<void> _crearEsquema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categoria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        tipo TEXT NOT NULL,
        UNIQUE(nombre, tipo)
      )
    ''');

    await db.execute('''
      CREATE TABLE configuracion_usuario (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        diaInicioMes INTEGER NOT NULL,
        onboardingCompletado INTEGER NOT NULL DEFAULT 0,
        modoOscuro INTEGER NOT NULL DEFAULT 0,
        diaInicioMesPendiente INTEGER,
        fechaAplicacionPendiente TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE gasto_fijo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        tipo TEXT NOT NULL DEFAULT 'gasto',
        categoriaId INTEGER NOT NULL REFERENCES categoria(id),
        importe REAL NOT NULL,
        periodicidadMeses INTEGER NOT NULL DEFAULT 1,
        mesDePago INTEGER,
        prorratear INTEGER NOT NULL DEFAULT 0,
        diaDelMes INTEGER,
        activo INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE movimiento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        origen TEXT NOT NULL,
        nombre TEXT NOT NULL,
        importe REAL NOT NULL,
        categoriaId INTEGER NOT NULL REFERENCES categoria(id),
        cicloMes TEXT NOT NULL,
        gastoFijoId INTEGER REFERENCES gasto_fijo(id)
      )
    ''');

    await db.execute(_creacionTablaMetaAhorro);

    await db.insert(
      'configuracion_usuario',
      ConfiguracionUsuario.porDefecto.toMap(),
    );

    for (final nombre in Categoria.catalogoRecurrente) {
      await db.insert(
        'categoria',
        Categoria(nombre: nombre, tipo: TipoCategoria.recurrente).toMap(),
      );
    }
    for (final nombre in Categoria.catalogoVariable) {
      await db.insert(
        'categoria',
        Categoria(nombre: nombre, tipo: TipoCategoria.variable).toMap(),
      );
    }
    for (final nombre in Categoria.catalogoIngreso) {
      await db.insert(
        'categoria',
        Categoria(nombre: nombre, tipo: TipoCategoria.ingreso).toMap(),
      );
    }
  }

  // ---------- Categoria ----------

  Future<List<Categoria>> listarCategorias({TipoCategoria? tipo}) async {
    final filas = await (await db).query(
      'categoria',
      where: tipo == null ? null : 'tipo = ?',
      whereArgs: tipo == null ? null : [tipo.name],
      orderBy: 'nombre',
    );
    return filas.map(Categoria.fromMap).toList();
  }

  /// Categorías para gastos fijos (luz, alquiler, seguros...).
  Future<List<Categoria>> listarCategoriasRecurrentes() =>
      listarCategorias(tipo: TipoCategoria.recurrente);

  /// Categorías para movimientos variables (comida, ocio...).
  Future<List<Categoria>> listarCategoriasVariables() =>
      listarCategorias(tipo: TipoCategoria.variable);

  /// Categorías para cualquier ingreso, fijo o variable (nómina, bizum...).
  Future<List<Categoria>> listarCategoriasIngreso() =>
      listarCategorias(tipo: TipoCategoria.ingreso);

  // ---------- ConfiguracionUsuario ----------

  Future<ConfiguracionUsuario> obtenerConfiguracion() async {
    final filas = await (await db).query('configuracion_usuario', limit: 1);
    if (filas.isEmpty) return ConfiguracionUsuario.porDefecto;
    final config = ConfiguracionUsuario.fromMap(filas.first);
    return _resolverCambioPendiente(config);
  }

  /// Si hay un cambio de día de inicio de mes en cola y ya le tocaba
  /// aplicarse (hoy es la fecha de transición, o ya ha pasado), lo aplica y
  /// lo guarda antes de devolver la configuración — así ningún ciclo ya
  /// abierto se ve alterado a media, pero tampoco hace falta que nadie
  /// recuerde comprobarlo a mano.
  Future<ConfiguracionUsuario> _resolverCambioPendiente(
    ConfiguracionUsuario config,
  ) async {
    final diaPendiente = config.diaInicioMesPendiente;
    final fechaPendiente = config.fechaAplicacionPendiente;
    if (diaPendiente == null || fechaPendiente == null) return config;

    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    if (hoySinHora.isBefore(DateTime.parse(fechaPendiente))) return config;

    final resuelta = config
        .copyWith(diaInicioMes: diaPendiente)
        .conCambioPendiente(null, null);
    await guardarConfiguracion(resuelta);
    return resuelta;
  }

  Future<void> guardarConfiguracion(ConfiguracionUsuario config) async {
    await (await db).insert(
      'configuracion_usuario',
      config.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------- GastoFijo ----------

  Future<int> crearGastoFijo(GastoFijo gasto) async {
    return (await db).insert('gasto_fijo', gasto.toMap());
  }

  Future<List<GastoFijo>> listarGastosFijos({bool soloActivos = false}) async {
    final filas = await (await db).query(
      'gasto_fijo',
      where: soloActivos ? 'activo = 1' : null,
      orderBy: 'nombre',
    );
    return filas.map(GastoFijo.fromMap).toList();
  }

  Future<void> actualizarGastoFijo(GastoFijo gasto) async {
    await (await db).update(
      'gasto_fijo',
      gasto.toMap(),
      where: 'id = ?',
      whereArgs: [gasto.id],
    );
  }

  /// Borra la plantilla y, si ya se había generado su movimiento en el
  /// ciclo actual (el mes sigue "abierto"), lo quita también — un fijo
  /// borrado no debe quedarse fantasma en el mes en curso. Los ciclos ya
  /// cerrados nunca se tocan, igual que en [sincronizarGastoFijoEnCicloActual].
  Future<void> borrarGastoFijo(GastoFijo gasto) async {
    await _sincronizarPlantillaEnCicloActual(
      gastoFijoId: gasto.id,
      tipo: gasto.tipo,
      nombre: gasto.nombre,
      importe: 0,
      categoriaId: gasto.categoriaId,
    );
    await (await db).delete(
      'gasto_fijo',
      where: 'id = ?',
      whereArgs: [gasto.id],
    );
  }

  // ---------- Movimiento ----------

  Future<int> crearMovimiento(Movimiento movimiento) async {
    return (await db).insert('movimiento', movimiento.toMap());
  }

  Future<List<Movimiento>> listarMovimientosDeCiclo(String cicloMes) async {
    final filas = await (await db).query(
      'movimiento',
      where: 'cicloMes = ?',
      whereArgs: [cicloMes],
    );
    return filas.map(Movimiento.fromMap).toList();
  }

  /// Todos los movimientos de los ciclos-mes que empiezan en [anio], para
  /// la burbuja de año.
  Future<List<Movimiento>> listarMovimientosDeAnio(int anio) async {
    final filas = await (await db).query(
      'movimiento',
      where: 'cicloMes LIKE ?',
      whereArgs: ['$anio-%'],
    );
    return filas.map(Movimiento.fromMap).toList();
  }

  /// Todos los cicloMes que tienen algún movimiento registrado, ordenados
  /// cronológicamente. Se usa para construir el historial de burbujas.
  Future<List<String>> listarCiclosConMovimientos() async {
    final filas = await (await db).query(
      'movimiento',
      columns: ['cicloMes'],
      distinct: true,
      orderBy: 'cicloMes',
    );
    return filas.map((f) => f['cicloMes'] as String).toList();
  }

  /// Años con los 12 ciclos-mes completos (los únicos que tienen burbuja de
  /// año y por tanto se pueden comparar entre sí), ordenados.
  Future<List<int>> listarAniosCompletos() async {
    final ciclos = await listarCiclosConMovimientos();
    final porAnio = <int, Set<String>>{};
    for (final ciclo in ciclos) {
      final anio = int.parse(ciclo.substring(0, 4));
      porAnio.putIfAbsent(anio, () => {}).add(ciclo);
    }
    return [
      for (final entrada in porAnio.entries)
        if (entrada.value.length == 12) entrada.key,
    ]..sort();
  }

  /// Motor de cierre: asegura que todo gasto fijo activo (mensual,
  /// trimestral, anual...) tenga su Movimiento generado para [cicloMes], si
  /// le corresponde importe ese mes. Es idempotente — si ya existe (por
  /// plantilla + ciclo), no crea uno duplicado. Pensado para llamarse cada
  /// vez que se entra a la pantalla principal, no como tarea en segundo
  /// plano.
  Future<void> generarMovimientosDelCiclo(String cicloMes) async {
    final mesDelCiclo = int.parse(cicloMes.substring(5, 7));

    for (final fijo in await listarGastosFijos(soloActivos: true)) {
      final importe = fijo.importeParaMes(mesDelCiclo);
      if (importe <= 0) continue;
      final yaExiste = await _existeMovimientoDePlantilla(
        cicloMes: cicloMes,
        gastoFijoId: fijo.id,
      );
      if (yaExiste) continue;
      await crearMovimiento(
        Movimiento(
          tipo: fijo.tipo,
          origen: OrigenMovimiento.fijo,
          nombre: fijo.nombre,
          importe: importe,
          categoriaId: fijo.categoriaId,
          cicloMes: cicloMes,
          gastoFijoId: fijo.id,
        ),
      );
    }
  }

  Future<bool> _existeMovimientoDePlantilla({
    required String cicloMes,
    required int? gastoFijoId,
  }) async {
    final filas = await (await db).query(
      'movimiento',
      where: 'gastoFijoId = ? AND cicloMes = ?',
      whereArgs: [gastoFijoId, cicloMes],
      limit: 1,
    );
    return filas.isNotEmpty;
  }

  /// Tras editar un gasto fijo, refleja el cambio en el movimiento ya
  /// generado para el ciclo actual (si existe) — el mes actual sigue
  /// "abierto", así que sí debe verse el cambio. Recalcula el importe que
  /// corresponde al mes actual según la periodicidad (0 si no prorratea y
  /// no es su mes de pago) y actualiza, crea o borra el movimiento
  /// generado en consecuencia. Los ciclos ya cerrados nunca se tocan aquí.
  Future<void> sincronizarGastoFijoEnCicloActual(GastoFijo fijo) async {
    final config = await obtenerConfiguracion();
    final cicloActual = claveCiclo(DateTime.now(), config.diaInicioMes);
    final mesActual = int.parse(cicloActual.substring(5, 7));

    await _sincronizarPlantillaEnCicloActual(
      gastoFijoId: fijo.id,
      tipo: fijo.tipo,
      nombre: fijo.nombre,
      importe: fijo.importeParaMes(mesActual),
      categoriaId: fijo.categoriaId,
    );
  }

  Future<void> _sincronizarPlantillaEnCicloActual({
    required int? gastoFijoId,
    required TipoMovimiento tipo,
    required String nombre,
    required double importe,
    required int categoriaId,
  }) async {
    final config = await obtenerConfiguracion();
    final cicloActual = claveCiclo(DateTime.now(), config.diaInicioMes);

    final filas = await (await db).query(
      'movimiento',
      where: 'gastoFijoId = ? AND cicloMes = ?',
      whereArgs: [gastoFijoId, cicloActual],
      limit: 1,
    );

    if (filas.isEmpty) {
      // Aún no se había generado (p. ej. un trimestral que este mes no
      // aplicaba y ahora, tras editarlo, sí). Si corresponde importe, se
      // crea.
      if (importe > 0) {
        await crearMovimiento(
          Movimiento(
            tipo: tipo,
            origen: OrigenMovimiento.fijo,
            nombre: nombre,
            importe: importe,
            categoriaId: categoriaId,
            cicloMes: cicloActual,
            gastoFijoId: gastoFijoId,
          ),
        );
      }
      return;
    }

    final existente = Movimiento.fromMap(filas.first);
    if (importe <= 0) {
      // Ya no corresponde este mes (p. ej. trimestral sin prorratear fuera
      // de su mes de pago tras editarlo).
      await borrarMovimiento(existente.id!);
    } else {
      await actualizarMovimiento(
        Movimiento(
          id: existente.id,
          // Usa el tipo actual de la plantilla, no el que tenía el
          // movimiento ya generado — si el usuario cambió Gasto/Ingreso al
          // editar, el mes en curso debe reflejarlo.
          tipo: tipo,
          origen: existente.origen,
          nombre: nombre,
          importe: importe,
          categoriaId: categoriaId,
          cicloMes: cicloActual,
          gastoFijoId: existente.gastoFijoId,
        ),
      );
    }
  }

  Future<void> actualizarMovimiento(Movimiento movimiento) async {
    await (await db).update(
      'movimiento',
      movimiento.toMap(),
      where: 'id = ?',
      whereArgs: [movimiento.id],
    );
  }

  Future<void> borrarMovimiento(int id) async {
    await (await db).delete('movimiento', where: 'id = ?', whereArgs: [id]);
  }

  /// Balance de un ciclo-mes: suma de ingresos menos suma de gastos.
  Future<double> balanceDeCiclo(String cicloMes) async {
    final movimientos = await listarMovimientosDeCiclo(cicloMes);
    return movimientos.fold<double>(
      0.0,
      (total, m) => total + m.importeConSigno,
    );
  }

  // ---------- MetaAhorro ----------

  Future<int> crearMetaAhorro(MetaAhorro meta) async {
    return (await db).insert('meta_ahorro', meta.toMap());
  }

  Future<List<MetaAhorro>> listarMetasAhorro() async {
    final filas = await (await db).query('meta_ahorro', orderBy: 'id');
    return filas.map(MetaAhorro.fromMap).toList();
  }

  Future<void> actualizarMetaAhorro(MetaAhorro meta) async {
    await (await db).update(
      'meta_ahorro',
      meta.toMap(),
      where: 'id = ?',
      whereArgs: [meta.id],
    );
  }

  Future<void> borrarMetaAhorro(int id) async {
    await (await db).delete('meta_ahorro', where: 'id = ?', whereArgs: [id]);
  }
}

const _creacionTablaMetaAhorro = '''
  CREATE TABLE meta_ahorro (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    importeObjetivo REAL NOT NULL,
    mesesPlazo INTEGER NOT NULL,
    cicloInicio TEXT NOT NULL
  )
''';
