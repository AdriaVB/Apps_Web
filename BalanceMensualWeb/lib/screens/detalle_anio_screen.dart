import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/movimiento.dart';
import '../theme/app_theme.dart';
import '../utils/exportar_csv.dart';
import '../widgets/grafico_donut.dart';
import 'comparativa_anios_screen.dart';
import 'desglose_categoria_screen.dart';
import 'detalle_ciclo_screen.dart';

const _nombresMesesLargo = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String _etiquetaMes(String cicloMes) {
  final mes = int.parse(cicloMes.substring(5, 7));
  return _nombresMesesLargo[mes - 1];
}

/// Detalle de un año completo: balance del año, donuts de ingresos/gastos
/// agregados de los 12 meses, y la lista de esos 12 meses (más reciente
/// primero) para entrar al detalle de cada uno.
class DetalleAnioScreen extends StatefulWidget {
  const DetalleAnioScreen({super.key, required this.anio});

  final int anio;

  @override
  State<DetalleAnioScreen> createState() => _DetalleAnioScreenState();
}

class _DetalleAnioScreenState extends State<DetalleAnioScreen> {
  final _db = AppDatabase.instancia;
  late Future<_DetalleAnio> _datosFuture;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    _datosFuture = _cargar();
  }

  Future<_DetalleAnio> _cargar() async {
    final movimientos = await _db.listarMovimientosDeAnio(widget.anio);
    final recurrentes = await _db.listarCategoriasRecurrentes();
    final variables = await _db.listarCategoriasVariables();
    final ingreso = await _db.listarCategoriasIngreso();
    final nombresCategoria = {
      for (final c in [...recurrentes, ...variables, ...ingreso])
        if (c.id != null) c.id!: c.nombre,
    };

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

    final balancePorMes = <String, double>{};
    for (final m in movimientos) {
      balancePorMes[m.cicloMes] =
          (balancePorMes[m.cicloMes] ?? 0) + m.importeConSigno;
    }
    final meses = balancePorMes.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return _DetalleAnio(
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
      meses: meses,
    );
  }

  Future<void> _exportar() async {
    final datos = await _datosFuture;
    if (datos.movimientos.isEmpty || !mounted) return;
    await exportarMovimientosCsv(
      movimientos: datos.movimientos,
      nombresCategoria: datos.nombresCategoria,
      nombreArchivo: nombreArchivoExportacion('${widget.anio}'),
      tituloCompartir: 'Balance de ${widget.anio}',
    );
  }

  Future<void> _abrirMes(String cicloMes) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalleCicloScreen(
          cicloMes: cicloMes,
          etiqueta: '${_etiquetaMes(cicloMes)} ${widget.anio}',
        ),
      ),
    );
    setState(_recargar);
  }

  Future<void> _compararCon() async {
    final anios = (await _db.listarAniosCompletos())
        .where((a) => a != widget.anio)
        .toList();

    if (!mounted) return;

    if (anios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay otro año completo con el que comparar.'),
        ),
      );
      return;
    }

    final elegido = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Comparar ${widget.anio} con...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final anio in anios)
              ListTile(
                title: Text('$anio'),
                onTap: () => Navigator.of(context).pop(anio),
              ),
          ],
        ),
      ),
    );

    if (elegido == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ComparativaAniosScreen(anioA: widget.anio, anioB: elegido),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.anio}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Exportar a CSV',
            onPressed: _exportar,
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'Comparar con otro año',
            onPressed: _compararCon,
          ),
        ],
      ),
      body: FutureBuilder<_DetalleAnio>(
        future: _datosFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final datos = snapshot.data!;

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
                                titulo: 'Ingresos · ${widget.anio}',
                                segmentos: datos.segmentosIngreso,
                                tipo: TipoMovimiento.ingreso,
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
                                titulo: 'Gastos · ${widget.anio}',
                                segmentos: datos.segmentosGasto,
                                tipo: TipoMovimiento.gasto,
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
                    const Text('Balance del año'),
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
                  itemCount: datos.meses.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final mes = datos.meses[index];
                    return ListTile(
                      title: Text(_etiquetaMes(mes.key)),
                      trailing: Text(
                        _formatearImporte(mes.value),
                        style: TextStyle(
                          color: mes.value > 0
                              ? AppTheme.positivo(context)
                              : mes.value < 0
                              ? AppTheme.negativo(context)
                              : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => _abrirMes(mes.key),
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

String _formatearImporte(double importe) {
  final signo = importe > 0 ? '+' : '';
  return '$signo${importe.toStringAsFixed(2)} €';
}

class _DetalleAnio {
  final List<Movimiento> movimientos;
  final Map<int, String> nombresCategoria;
  final double balance;
  final List<SegmentoDonut> segmentosGasto;
  final List<SegmentoDonut> segmentosIngreso;

  /// Cada entrada es (cicloMes, balance de ese mes), ordenadas de más a
  /// menos reciente.
  final List<MapEntry<String, double>> meses;

  _DetalleAnio({
    required this.movimientos,
    required this.nombresCategoria,
    required this.balance,
    required this.segmentosGasto,
    required this.segmentosIngreso,
    required this.meses,
  });
}
