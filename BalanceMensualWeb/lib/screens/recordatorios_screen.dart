import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/gasto_fijo.dart';
import '../models/movimiento.dart';
import '../theme/app_theme.dart';
import '../utils/recordatorios.dart';

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

/// Aviso pasivo, sin notificaciones: al entrar, un vistazo de lo que toca
/// pagar/cobrar este mes (y cuándo), y un calendario de los 12 meses del
/// año para consultar cualquier otro. Todo se deriva de los gastos/ingresos
/// fijos ya dados de alta en Configuración — no se vuelve a pedir nada.
class RecordatoriosScreen extends StatefulWidget {
  const RecordatoriosScreen({super.key});

  @override
  State<RecordatoriosScreen> createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends State<RecordatoriosScreen> {
  final _db = AppDatabase.instancia;
  late Future<_DatosRecordatorios> _datosFuture;

  @override
  void initState() {
    super.initState();
    _datosFuture = _cargar();
  }

  Future<_DatosRecordatorios> _cargar() async {
    final fijos = await _db.listarGastosFijos(soloActivos: true);
    final recurrentes = await _db.listarCategoriasRecurrentes();
    final ingreso = await _db.listarCategoriasIngreso();
    final nombresCategoria = {
      for (final c in [...recurrentes, ...ingreso])
        if (c.id != null) c.id!: c.nombre,
    };

    final hoy = DateTime.now();
    final esteMes = proximosPagosDelMes(fijos, hoy);

    return _DatosRecordatorios(
      fijos: fijos,
      nombresCategoria: nombresCategoria,
      esteMes: esteMes,
      hoy: hoy,
    );
  }

  void _abrirMes(
    int mes,
    int anio,
    List<GastoFijo> fijos,
    Map<int, String> nombresCategoria,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _RecordatoriosMesScreen(
          etiqueta: '${_nombresMesesLargo[mes - 1]} $anio',
          fijosDelMes: fijos.where((f) => f.aplicaEnMes(mes)).toList(),
          nombresCategoria: nombresCategoria,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recordatorios')),
      body: FutureBuilder<_DatosRecordatorios>(
        future: _datosFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final datos = snapshot.data!;
          final anioActual = datos.hoy.year;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text('Este mes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (datos.esteMes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Nada pendiente este mes entre tus gastos e ingresos fijos.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...datos.esteMes.map(
                  (fijo) => _FilaRecordatorio(
                    fijo: fijo,
                    categoria: datos.nombresCategoria[fijo.categoriaId],
                    dias: diasHastaProximoCobro(fijo, datos.hoy),
                  ),
                ),
              const SizedBox(height: 28),
              Text(
                'Calendario del año',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.6,
                children: [
                  for (var mes = 1; mes <= 12; mes++)
                    _BurbujaMesRecordatorio(
                      etiqueta: _nombresMesesLargo[mes - 1],
                      destacada: mes == datos.hoy.month,
                      neto: datos.fijos
                          .where((f) => f.aplicaEnMes(mes))
                          .fold<double>(
                            0,
                            (t, f) =>
                                t +
                                (f.tipo == TipoMovimiento.ingreso
                                    ? f.importe
                                    : -f.importe),
                          ),
                      onTap: () => _abrirMes(
                        mes,
                        anioActual,
                        datos.fijos,
                        datos.nombresCategoria,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilaRecordatorio extends StatelessWidget {
  const _FilaRecordatorio({
    required this.fijo,
    required this.categoria,
    required this.dias,
  });

  final GastoFijo fijo;
  final String? categoria;
  final int? dias;

  String get _etiquetaDias {
    if (dias == null) return '';
    if (dias == 0) return 'Hoy';
    if (dias == 1) return 'Mañana';
    return 'En $dias días';
  }

  @override
  Widget build(BuildContext context) {
    final esGasto = fijo.tipo == TipoMovimiento.gasto;
    final color = esGasto
        ? AppTheme.negativo(context)
        : AppTheme.positivo(context);
    final esquema = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              esGasto ? Icons.arrow_upward : Icons.arrow_downward,
              color: color,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fijo.nombre,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dias == null
                        ? (categoria ?? 'Sin categoría')
                        : '${categoria ?? 'Sin categoría'} · $_etiquetaDias',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: esquema.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(
              '${esGasto ? '-' : '+'}${fijo.importe.toStringAsFixed(2)} €',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _BurbujaMesRecordatorio extends StatelessWidget {
  const _BurbujaMesRecordatorio({
    required this.etiqueta,
    required this.destacada,
    required this.neto,
    required this.onTap,
  });

  final String etiqueta;
  final bool destacada;
  final double neto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final color = neto > 0
        ? AppTheme.positivo(context)
        : neto < 0
        ? AppTheme.negativo(context)
        : esquema.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: destacada ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(etiqueta, style: const TextStyle(fontSize: 12)),
            if (neto != 0)
              Text(
                '${neto > 0 ? '+' : ''}${neto.toStringAsFixed(0)} €',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lista de solo lectura de los gastos/ingresos fijos que le tocan a un mes
/// concreto (al pulsar una burbuja del calendario del año).
class _RecordatoriosMesScreen extends StatelessWidget {
  const _RecordatoriosMesScreen({
    required this.etiqueta,
    required this.fijosDelMes,
    required this.nombresCategoria,
  });

  final String etiqueta;
  final List<GastoFijo> fijosDelMes;
  final Map<int, String> nombresCategoria;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(etiqueta)),
      body: fijosDelMes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Nada pendiente ese mes entre tus gastos e ingresos fijos.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final fijo in fijosDelMes)
                  _FilaRecordatorio(
                    fijo: fijo,
                    categoria: nombresCategoria[fijo.categoriaId],
                    dias: null,
                  ),
              ],
            ),
    );
  }
}

class _DatosRecordatorios {
  final List<GastoFijo> fijos;
  final Map<int, String> nombresCategoria;
  final List<GastoFijo> esteMes;
  final DateTime hoy;

  _DatosRecordatorios({
    required this.fijos,
    required this.nombresCategoria,
    required this.esteMes,
    required this.hoy,
  });
}
