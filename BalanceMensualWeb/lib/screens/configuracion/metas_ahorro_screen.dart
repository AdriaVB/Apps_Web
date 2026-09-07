import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../models/meta_ahorro.dart';
import '../../theme/app_theme.dart';
import '../../utils/ciclo_mes.dart';
import '../../utils/progreso_meta_ahorro.dart';
import '../../widgets/boton_pildora.dart';
import 'meta_ahorro_form_screen.dart';

class MetasAhorroScreen extends StatefulWidget {
  const MetasAhorroScreen({super.key});

  @override
  State<MetasAhorroScreen> createState() => _MetasAhorroScreenState();
}

class _MetasAhorroScreenState extends State<MetasAhorroScreen> {
  final _db = AppDatabase.instancia;
  late Future<_DatosMetas> _datosFuture;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    _datosFuture = _cargar();
  }

  Future<_DatosMetas> _cargar() async {
    final config = await _db.obtenerConfiguracion();
    final cicloActual = claveCiclo(DateTime.now(), config.diaInicioMes);
    final metas = await _db.listarMetasAhorro();

    final ciclos = (await _db.listarCiclosConMovimientos()).toSet()
      ..add(cicloActual);
    final balancePorCiclo = <String, double>{
      for (final ciclo in ciclos) ciclo: await _db.balanceDeCiclo(ciclo),
    };

    final progresos = <int, ProgresoMetaAhorro>{
      for (final meta in metas)
        meta.id!: calcularProgresoMetaAhorro(
          meta: meta,
          cicloActual: cicloActual,
          balancePorCiclo: balancePorCiclo,
        ),
    };

    return _DatosMetas(metas: metas, progresos: progresos);
  }

  Future<void> _abrirFormulario({MetaAhorro? meta}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MetaAhorroFormScreen(metaExistente: meta),
      ),
    );
    setState(_recargar);
  }

  Future<void> _confirmarBorrado(MetaAhorro meta) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar meta de ahorro'),
        content: Text('¿Seguro que quieres borrar "${meta.nombre}"?'),
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

    if (confirmado == true && meta.id != null) {
      await _db.borrarMetaAhorro(meta.id!);
      setState(_recargar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Metas de ahorro')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<_DatosMetas>(
                future: _datosFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final datos = snapshot.data!;
                  if (datos.metas.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aún no tienes ninguna meta de ahorro. Fija un '
                          'objetivo (p. ej. "iPhone, 800€ en 6 meses") y te '
                          'diremos si vas al día.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: datos.metas.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final meta = datos.metas[index];
                      return _FilaMeta(
                        meta: meta,
                        progreso: datos.progresos[meta.id]!,
                        onTap: () => _abrirFormulario(meta: meta),
                        onBorrar: () => _confirmarBorrado(meta),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            BotonPildora(
              texto: 'Añadir meta de ahorro',
              onTap: () => _abrirFormulario(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatosMetas {
  final List<MetaAhorro> metas;
  final Map<int, ProgresoMetaAhorro> progresos;

  _DatosMetas({required this.metas, required this.progresos});
}

class _FilaMeta extends StatelessWidget {
  const _FilaMeta({
    required this.meta,
    required this.progreso,
    required this.onTap,
    required this.onBorrar,
  });

  final MetaAhorro meta;
  final ProgresoMetaAhorro progreso;
  final VoidCallback onTap;
  final VoidCallback onBorrar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final porcentaje = (progreso.ahorroAcumulado / meta.importeObjetivo * 100)
        .clamp(0, 999);
    final bien = progreso.completada || progreso.vaAlDia;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.nombre,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${progreso.ahorroAcumulado.toStringAsFixed(2)} € de '
                      '${meta.importeObjetivo.toStringAsFixed(2)} € '
                      '(${porcentaje.toStringAsFixed(0)}%)',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: esquema.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _textoEstado(progreso),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: bien
                            ? AppTheme.positivo(context)
                            : AppTheme.negativo(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Borrar',
                onPressed: onBorrar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _textoEstado(ProgresoMetaAhorro progreso) {
  if (progreso.completada) return '¡Objetivo cumplido!';
  if (progreso.vaAlDia) return 'Vas al día';
  final falta =
      (progreso.aportacionEsperadaAcumulada - progreso.ahorroAcumulado)
          .toStringAsFixed(2);
  final meses = progreso.mesesEstimadosAlRitmoActual;
  return meses == null
      ? 'Vas $falta € por detrás de lo previsto'
      : 'Vas $falta € por detrás — a este ritmo, $meses meses en vez del '
            'plazo previsto';
}
