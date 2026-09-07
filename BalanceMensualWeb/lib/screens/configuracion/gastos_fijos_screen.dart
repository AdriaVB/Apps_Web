import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../models/gasto_fijo.dart';
import '../../models/movimiento.dart';
import '../../theme/app_theme.dart';
import '../../widgets/boton_pildora.dart';
import '../../widgets/fila_gasto.dart';
import 'gasto_fijo_form_screen.dart';

const _nombresMesesCorto = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// Descripción de la periodicidad para el subtítulo de la fila: nada si es
/// mensual (el caso implícito), o el detalle de cuándo se paga si no.
String _descripcionPeriodicidad(GastoFijo gasto) {
  if (gasto.periodicidadMeses <= 1) return '';
  final etiqueta = etiquetasPeriodicidad[gasto.periodicidadMeses] ?? '';
  if (gasto.prorratear) return '$etiqueta, repartido';
  final meses = <String>[];
  var mes = gasto.mesDePago!;
  for (var i = 0; i < 12 ~/ gasto.periodicidadMeses; i++) {
    meses.add(_nombresMesesCorto[mes - 1]);
    mes = ((mes - 1 + gasto.periodicidadMeses) % 12) + 1;
  }
  return '$etiqueta, paga en ${meses.join(', ')}';
}

class GastosFijosScreen extends StatefulWidget {
  const GastosFijosScreen({super.key});

  @override
  State<GastosFijosScreen> createState() => _GastosFijosScreenState();
}

class _GastosFijosScreenState extends State<GastosFijosScreen> {
  final _db = AppDatabase.instancia;
  late Future<List<GastoFijo>> _gastosFuture;
  Map<int, String> _nombresCategoria = {};

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    _gastosFuture = _cargar();
  }

  Future<List<GastoFijo>> _cargar() async {
    final recurrentes = await _db.listarCategoriasRecurrentes();
    final ingreso = await _db.listarCategoriasIngreso();
    _nombresCategoria = {
      for (final c in [...recurrentes, ...ingreso])
        if (c.id != null) c.id!: c.nombre,
    };
    return _db.listarGastosFijos();
  }

  Future<void> _abrirFormulario({GastoFijo? gasto}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GastoFijoFormScreen(gastoExistente: gasto),
      ),
    );
    setState(_recargar);
  }

  Future<void> _confirmarBorrado(GastoFijo gasto) async {
    final esGasto = gasto.tipo == TipoMovimiento.gasto;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(esGasto ? 'Borrar gasto fijo' : 'Borrar ingreso fijo'),
        content: Text(
          '¿Seguro que quieres borrar "${gasto.nombre}"? Dejará de '
          'aplicarse a partir de ahora: si ya se había generado su '
          'movimiento este mes, también se quita. Los meses ya cerrados no '
          'se ven afectados.',
        ),
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

    if (confirmado == true && gasto.id != null) {
      await _db.borrarGastoFijo(gasto);
      setState(_recargar);
    }
  }

  Widget _fila(BuildContext context, GastoFijo gasto) {
    final esGasto = gasto.tipo == TipoMovimiento.gasto;
    final categoria = _nombresCategoria[gasto.categoriaId] ?? 'Sin categoría';
    final periodicidad = _descripcionPeriodicidad(gasto);
    final subtitulo = periodicidad.isEmpty
        ? categoria
        : '$categoria · $periodicidad';
    return FilaGasto(
      titulo: gasto.nombre,
      subtitulo: subtitulo,
      importe: '${esGasto ? '' : '+'}${gasto.importe.toStringAsFixed(2)} €',
      colorImporte: esGasto ? null : AppTheme.positivo(context),
      onTap: () => _abrirFormulario(gasto: gasto),
      onBorrar: () => _confirmarBorrado(gasto),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos/Ingresos fijos')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<GastoFijo>>(
                future: _gastosFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final gastos = snapshot.data!;
                  if (gastos.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aún no tienes nada fijo. Añade lo primero: gastos '
                          'mensuales (alquiler, luz, agua...), de otra '
                          'periodicidad (IBI, seguro anual...) o ingresos '
                          'fijos como la nómina.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final ingresos = gastos
                      .where((g) => g.tipo == TipoMovimiento.ingreso)
                      .toList();
                  final gastosSolo = gastos
                      .where((g) => g.tipo == TipoMovimiento.gasto)
                      .toList();

                  return ListView(
                    children: [
                      if (ingresos.isNotEmpty) ...[
                        Text(
                          'Ingresos fijos',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        for (final gasto in ingresos) ...[
                          _fila(context, gasto),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 8),
                      ],
                      if (gastosSolo.isNotEmpty) ...[
                        Text(
                          'Gastos fijos',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        for (final gasto in gastosSolo) ...[
                          _fila(context, gasto),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            BotonPildora(
              texto: 'Añadir gasto/ingreso fijo',
              onTap: () => _abrirFormulario(),
            ),
          ],
        ),
      ),
    );
  }
}
