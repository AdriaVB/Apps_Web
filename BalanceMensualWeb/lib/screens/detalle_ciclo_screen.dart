import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/gasto_fijo.dart';
import '../models/movimiento.dart';
import '../theme/app_theme.dart';
import '../utils/comparacion_categoria.dart';
import '../utils/exportar_csv.dart';
import '../widgets/grafico_donut.dart';
import 'alta_movimiento_screen.dart';
import 'configuracion/gasto_fijo_form_screen.dart';
import 'configuracion/gastos_fijos_screen.dart';
import 'desglose_categoria_screen.dart';

class DetalleCicloScreen extends StatefulWidget {
  const DetalleCicloScreen({
    super.key,
    required this.cicloMes,
    required this.etiqueta,
  });

  final String cicloMes;
  final String etiqueta;

  @override
  State<DetalleCicloScreen> createState() => _DetalleCicloScreenState();
}

class _DetalleCicloScreenState extends State<DetalleCicloScreen> {
  final _db = AppDatabase.instancia;
  late Future<_DetalleCiclo> _datosFuture;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    _datosFuture = _cargar();
  }

  Future<_DetalleCiclo> _cargar() async {
    final movimientos = await _db.listarMovimientosDeCiclo(widget.cicloMes);
    final recurrentes = await _db.listarCategoriasRecurrentes();
    final variables = await _db.listarCategoriasVariables();
    final ingreso = await _db.listarCategoriasIngreso();
    final nombresCategoria = {
      for (final c in [...recurrentes, ...variables, ...ingreso])
        if (c.id != null) c.id!: c.nombre,
    };

    // Para comparar cada categoría con tu media histórica y con tu máximo
    // del año: hace falta el desglose de todos los ciclos, no solo el
    // actual.
    final ciclos = (await _db.listarCiclosConMovimientos()).toSet()
      ..add(widget.cicloMes);
    final movimientosPorCiclo = <String, List<Movimiento>>{
      for (final ciclo in ciclos)
        ciclo: ciclo == widget.cicloMes
            ? movimientos
            : await _db.listarMovimientosDeCiclo(ciclo),
    };
    // Los movimientos no guardan una fecha propia (todos comparten el mismo
    // cicloMes), así que el id — que crece según el orden de creación —
    // es la mejor referencia de "más reciente primero".
    movimientos.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    final balance = movimientos.fold<double>(
      0.0,
      (t, m) => t + m.importeConSigno,
    );

    final gastos = movimientos
        .where((m) => m.tipo == TipoMovimiento.gasto)
        .toList();
    final ingresos = movimientos
        .where((m) => m.tipo == TipoMovimiento.ingreso)
        .toList();

    return _DetalleCiclo(
      movimientos: movimientos,
      nombresCategoria: nombresCategoria,
      balance: balance,
      segmentosGasto: agruparEnSegmentos(
        gastos,
        nombresCategoria,
        AppTheme.paletaGastos,
      ),
      segmentosIngreso: agruparEnSegmentos(
        ingresos,
        nombresCategoria,
        AppTheme.paletaIngresos,
      ),
      comparacionesGasto: compararCategorias(
        cicloActual: widget.cicloMes,
        movimientosPorCiclo: movimientosPorCiclo,
        tipo: TipoMovimiento.gasto,
      ),
      comparacionesIngreso: compararCategorias(
        cicloActual: widget.cicloMes,
        movimientosPorCiclo: movimientosPorCiclo,
        tipo: TipoMovimiento.ingreso,
      ),
    );
  }

  /// Un movimiento fijo se edita desde su plantilla (Configuración), nunca
  /// suelto para un mes — así el cambio no se "pierde" al mes siguiente.
  /// Si la plantilla ya no existe (se borró desde Configuración), no queda
  /// nada que editar salvo el propio movimiento de ese mes.
  Future<void> _editar(Movimiento movimiento) async {
    if (movimiento.origen == OrigenMovimiento.fijo) {
      final gastos = await _db.listarGastosFijos();
      GastoFijo? plantilla;
      for (final g in gastos) {
        if (g.id == movimiento.gastoFijoId) {
          plantilla = g;
          break;
        }
      }
      if (plantilla != null) {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GastoFijoFormScreen(gastoExistente: plantilla),
          ),
        );
        setState(_recargar);
        return;
      }
    }

    if (!mounted) return;
    final cambiado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AltaMovimientoScreen(movimientoExistente: movimiento),
      ),
    );
    if (cambiado == true) setState(_recargar);
  }

  /// Un movimiento fijo no se borra suelto para un mes — si se pudiera,
  /// volvería a aparecer solo al mes siguiente (el motor de cierre no sabe
  /// que "este mes no cuenta"). Se borra desde su plantilla en Configuración,
  /// igual que se edita. Si la plantilla ya no existe, no queda a dónde
  /// redirigir y se borra el movimiento suelto como cualquier otro.
  Future<void> _confirmarBorrado(Movimiento movimiento) async {
    if (movimiento.origen == OrigenMovimiento.fijo) {
      final gastos = await _db.listarGastosFijos();
      final existePlantilla = gastos.any((g) => g.id == movimiento.gastoFijoId);
      if (existePlantilla) {
        if (!mounted) return;
        final ir = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No se puede borrar aquí'),
            content: const Text(
              'Los gastos/ingresos fijos solo se pueden borrar desde '
              '"Gastos/Ingresos fijos" en Configuración — al borrarlo ahí, '
              'también se quita el movimiento ya generado este mes.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Ir a Gastos fijos'),
              ),
            ],
          ),
        );
        if (ir == true && mounted) {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const GastosFijosScreen()));
          setState(_recargar);
        }
        return;
      }
    }

    if (!mounted) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar movimiento'),
        content: Text('¿Seguro que quieres borrar "${movimiento.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmado == true && movimiento.id != null) {
      await _db.borrarMovimiento(movimiento.id!);
      setState(_recargar);
    }
  }

  Future<void> _exportar() async {
    final datos = await _datosFuture;
    if (datos.movimientos.isEmpty || !mounted) return;
    await exportarMovimientosCsv(
      movimientos: datos.movimientos,
      nombresCategoria: datos.nombresCategoria,
      nombreArchivo: nombreArchivoExportacion(widget.etiqueta),
      tituloCompartir: 'Balance de ${widget.etiqueta}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.etiqueta),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Exportar a CSV',
            onPressed: _exportar,
          ),
        ],
      ),
      body: FutureBuilder<_DetalleCiclo>(
        future: _datosFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se han podido cargar los datos.\n${snapshot.error}',
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final datos = snapshot.data!;
          if (datos.movimientos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Este mes todavía no tiene ningún movimiento.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return Column(
            children: [
              if (datos.segmentosIngreso.isNotEmpty ||
                  datos.segmentosGasto.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (datos.segmentosIngreso.isNotEmpty)
                        MiniDonut(
                          titulo: 'Ingresos',
                          color: AppTheme.positivo(context),
                          segmentos: datos.segmentosIngreso,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DesgloseCategoriaScreen(
                                titulo: 'Ingresos · ${widget.etiqueta}',
                                segmentos: datos.segmentosIngreso,
                                tipo: TipoMovimiento.ingreso,
                                comparaciones: datos.comparacionesIngreso,
                              ),
                            ),
                          ),
                        ),
                      if (datos.segmentosGasto.isNotEmpty)
                        MiniDonut(
                          titulo: 'Gastos',
                          color: AppTheme.negativo(context),
                          segmentos: datos.segmentosGasto,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DesgloseCategoriaScreen(
                                titulo: 'Gastos · ${widget.etiqueta}',
                                segmentos: datos.segmentosGasto,
                                tipo: TipoMovimiento.gasto,
                                comparaciones: datos.comparacionesGasto,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Balance del mes'),
                    Text(
                      _formatearImporte(datos.balance),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: datos.balance > 0
                            ? AppTheme.positivo(context)
                            : datos.balance < 0
                            ? AppTheme.negativo(context)
                            : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: datos.movimientos.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final movimiento = datos.movimientos[index];
                    final esIngreso = movimiento.tipo == TipoMovimiento.ingreso;
                    return ListTile(
                      leading: Icon(
                        esIngreso ? Icons.arrow_upward : Icons.arrow_downward,
                        color: esIngreso
                            ? AppTheme.positivo(context)
                            : AppTheme.negativo(context),
                      ),
                      title: Text(movimiento.nombre),
                      subtitle: Text(
                        '${datos.nombresCategoria[movimiento.categoriaId] ?? 'Sin categoría'} · ${_etiquetaOrigen(movimiento.origen)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatearImporte(movimiento.importeConSigno),
                            style: TextStyle(
                              color: esIngreso
                                  ? AppTheme.positivo(context)
                                  : AppTheme.negativo(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Borrar',
                            onPressed: () => _confirmarBorrado(movimiento),
                          ),
                        ],
                      ),
                      onTap: () => _editar(movimiento),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _etiquetaOrigen(OrigenMovimiento origen) {
  switch (origen) {
    case OrigenMovimiento.fijo:
      return 'fijo';
    case OrigenMovimiento.variable:
      return 'variable';
  }
}

String _formatearImporte(double importe) {
  final signo = importe > 0 ? '+' : '';
  return '$signo${importe.toStringAsFixed(2)} €';
}

class _DetalleCiclo {
  final List<Movimiento> movimientos;
  final Map<int, String> nombresCategoria;
  final double balance;
  final List<SegmentoDonut> segmentosGasto;
  final List<SegmentoDonut> segmentosIngreso;
  final Map<int, ComparacionCategoria> comparacionesGasto;
  final Map<int, ComparacionCategoria> comparacionesIngreso;

  _DetalleCiclo({
    required this.movimientos,
    required this.nombresCategoria,
    required this.balance,
    required this.segmentosGasto,
    required this.segmentosIngreso,
    required this.comparacionesGasto,
    required this.comparacionesIngreso,
  });
}
