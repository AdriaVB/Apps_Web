import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/movimiento.dart';
import '../theme/app_theme.dart';

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

/// Compara dos años completos lado a lado: totales de ingresos, gastos y
/// balance, y el balance de cada uno de los 12 meses.
class ComparativaAniosScreen extends StatefulWidget {
  const ComparativaAniosScreen({
    super.key,
    required this.anioA,
    required this.anioB,
  });

  final int anioA;
  final int anioB;

  @override
  State<ComparativaAniosScreen> createState() => _ComparativaAniosScreenState();
}

class _ComparativaAniosScreenState extends State<ComparativaAniosScreen> {
  final _db = AppDatabase.instancia;
  late Future<_Comparativa> _datosFuture;

  @override
  void initState() {
    super.initState();
    _datosFuture = _cargar();
  }

  Future<_Comparativa> _cargar() async {
    final movimientosA = await _db.listarMovimientosDeAnio(widget.anioA);
    final movimientosB = await _db.listarMovimientosDeAnio(widget.anioB);
    return _Comparativa(
      resumenA: _resumir(movimientosA),
      resumenB: _resumir(movimientosB),
    );
  }

  _ResumenAnio _resumir(List<Movimiento> movimientos) {
    final ingresos = movimientos
        .where((m) => m.tipo == TipoMovimiento.ingreso)
        .fold<double>(0, (t, m) => t + m.importe);
    final gastos = movimientos
        .where((m) => m.tipo == TipoMovimiento.gasto)
        .fold<double>(0, (t, m) => t + m.importe);
    final porMes = List<double>.filled(12, 0);
    for (final m in movimientos) {
      final mes = int.parse(m.cicloMes.substring(5, 7));
      porMes[mes - 1] += m.importeConSigno;
    }
    return _ResumenAnio(ingresos: ingresos, gastos: gastos, porMes: porMes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.anioA} vs ${widget.anioB}')),
      body: FutureBuilder<_Comparativa>(
        future: _datosFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final datos = snapshot.data!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ColumnaResumen(
                        titulo: '${widget.anioA}',
                        resumen: datos.resumenA,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ColumnaResumen(
                        titulo: '${widget.anioB}',
                        resumen: datos.resumenB,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: 12,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return _FilaMes(
                      nombreMes: _nombresMesesLargo[index],
                      balanceA: datos.resumenA.porMes[index],
                      balanceB: datos.resumenB.porMes[index],
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

class _ColumnaResumen extends StatelessWidget {
  const _ColumnaResumen({required this.titulo, required this.resumen});

  final String titulo;
  final _ResumenAnio resumen;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Text(
              _formatearImporte(resumen.balance),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: resumen.balance >= 0
                    ? AppTheme.positivo(context)
                    : AppTheme.negativo(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresos ${resumen.ingresos.toStringAsFixed(2)} €',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: esquema.onSurfaceVariant),
            ),
            Text(
              'Gastos ${resumen.gastos.toStringAsFixed(2)} €',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: esquema.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaMes extends StatelessWidget {
  const _FilaMes({
    required this.nombreMes,
    required this.balanceA,
    required this.balanceB,
  });

  final String nombreMes;
  final double balanceA;
  final double balanceB;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              nombreMes,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              _formatearImporte(balanceA),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: balanceA >= 0
                    ? AppTheme.positivo(context)
                    : AppTheme.negativo(context),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _formatearImporte(balanceB),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: balanceB >= 0
                    ? AppTheme.positivo(context)
                    : AppTheme.negativo(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatearImporte(double importe) {
  final signo = importe > 0 ? '+' : '';
  return '$signo${importe.toStringAsFixed(2)} €';
}

class _ResumenAnio {
  final double ingresos;
  final double gastos;

  /// Balance de cada mes (índice 0 = enero .. 11 = diciembre).
  final List<double> porMes;

  _ResumenAnio({
    required this.ingresos,
    required this.gastos,
    required this.porMes,
  });

  double get balance => ingresos - gastos;
}

class _Comparativa {
  final _ResumenAnio resumenA;
  final _ResumenAnio resumenB;

  _Comparativa({required this.resumenA, required this.resumenB});
}
