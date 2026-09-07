import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/meta_ahorro.dart';
import '../models/movimiento.dart';
import '../theme/app_theme.dart';
import '../utils/ciclo_mes.dart';
import '../utils/progreso_meta_ahorro.dart';
import '../utils/proyeccion.dart';
import '../utils/salud_financiera.dart';
import '../widgets/boton_pildora.dart';
import 'alta_movimiento_screen.dart';
import 'configuracion/configuracion_screen.dart';
import 'configuracion/metas_ahorro_screen.dart';
import 'detalle_anio_screen.dart';
import 'detalle_ciclo_screen.dart';

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

/// "1 a 31 ago" para mes natural, "25ago - 25sep" para un ciclo a caballo
/// entre dos meses.
String _rangoCiclo(DateTime inicio, DateTime fin, int diaInicioMes) {
  if (diaInicioMes == 1) {
    return '${inicio.day} a ${fin.day} ${_nombresMesesCorto[fin.month - 1]}';
  }
  final desde = '${inicio.day}${_nombresMesesCorto[inicio.month - 1]}';
  final hasta = '${fin.day}${_nombresMesesCorto[fin.month - 1]}';
  return '$desde - $hasta';
}

class _BurbujaMes {
  final String cicloMes;
  final double balance;
  final bool esActual;

  _BurbujaMes({
    required this.cicloMes,
    required this.balance,
    required this.esActual,
  });

  String get etiqueta {
    final anio = int.parse(cicloMes.substring(0, 4));
    final mes = int.parse(cicloMes.substring(5, 7));
    return '${_nombresMesesCorto[mes - 1]} $anio';
  }
}

class _BurbujaAnio {
  final int anio;
  final double balance;

  _BurbujaAnio({required this.anio, required this.balance});
}

class _DatosInicio {
  final int diaInicioMes;
  final String cicloActual;
  final DateTime inicioCiclo;
  final DateTime finCiclo;
  final double balanceCicloActual;
  final double? proyeccionFinDeCiclo;
  final List<_BurbujaMes> meses;
  final List<_BurbujaAnio> anios;
  final List<MetaAhorro> metas;
  final Map<int, ProgresoMetaAhorro> progresosMetas;
  final SaludFinanciera? saludFinanciera;

  _DatosInicio({
    required this.diaInicioMes,
    required this.cicloActual,
    required this.inicioCiclo,
    required this.finCiclo,
    required this.balanceCicloActual,
    required this.proyeccionFinDeCiclo,
    required this.meses,
    required this.anios,
    required this.metas,
    required this.progresosMetas,
    required this.saludFinanciera,
  });
}

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key, AppDatabase? db}) : _dbInyectada = db;

  /// Solo para tests: permite inyectar una base de datos aislada en vez de
  /// usar el singleton real (que depende de path_provider).
  final AppDatabase? _dbInyectada;

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  late final AppDatabase _db = widget._dbInyectada ?? AppDatabase.instancia;
  late Future<_DatosInicio> _datosFuture;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    _datosFuture = _cargar();
  }

  Future<_DatosInicio> _cargar() async {
    final config = await _db.obtenerConfiguracion();
    final ahora = DateTime.now();
    final cicloActual = claveCiclo(ahora, config.diaInicioMes);
    final inicioCiclo = inicioDeCiclo(ahora, config.diaInicioMes);
    final finCiclo = finDeCiclo(ahora, config.diaInicioMes);

    // Motor de cierre: garantiza que los fijos/anuales activos ya estén
    // aplicados al ciclo actual antes de calcular ningún balance.
    await _db.generarMovimientosDelCiclo(cicloActual);

    final movimientosCicloActual = await _db.listarMovimientosDeCiclo(
      cicloActual,
    );

    final ciclos = (await _db.listarCiclosConMovimientos()).toSet();
    ciclos.add(cicloActual);
    final ciclosOrdenados = ciclos.toList()..sort();

    final todosMeses = <_BurbujaMes>[];
    final ingresosPorCiclo = <String, double>{};
    for (final ciclo in ciclosOrdenados) {
      final movimientos = ciclo == cicloActual
          ? movimientosCicloActual
          : await _db.listarMovimientosDeCiclo(ciclo);
      final balance = movimientos.fold<double>(
        0,
        (t, m) => t + m.importeConSigno,
      );
      ingresosPorCiclo[ciclo] = movimientos
          .where((m) => m.tipo == TipoMovimiento.ingreso)
          .fold<double>(0, (t, m) => t + m.importe);
      todosMeses.add(
        _BurbujaMes(
          cicloMes: ciclo,
          balance: balance,
          esActual: ciclo == cicloActual,
        ),
      );
    }

    // Burbuja de año: sobre todos los meses con datos, no solo el año en
    // curso — solo cuando hay 12 ciclos-mes distintos para ese año.
    final porAnio = <int, List<_BurbujaMes>>{};
    for (final mes in todosMeses) {
      final anio = int.parse(mes.cicloMes.substring(0, 4));
      porAnio.putIfAbsent(anio, () => []).add(mes);
    }
    final anios = <_BurbujaAnio>[
      for (final entrada in porAnio.entries)
        if (entrada.value.length == 12)
          _BurbujaAnio(
            anio: entrada.key,
            balance: entrada.value.fold(0.0, (t, m) => t + m.balance),
          ),
    ];

    // Historial: solo los meses del año en curso — los años ya cerrados se
    // consultan desde su burbuja en "Años", no hace falta repetirlos aquí.
    final anioActual = int.parse(cicloActual.substring(0, 4));
    final meses = todosMeses
        .where((m) => int.parse(m.cicloMes.substring(0, 4)) == anioActual)
        .toList();

    final balanceCicloActual = todosMeses.firstWhere((m) => m.esActual).balance;

    final metas = await _db.listarMetasAhorro();
    final balancePorCiclo = {
      for (final mes in todosMeses) mes.cicloMes: mes.balance,
    };
    final progresosMetas = <int, ProgresoMetaAhorro>{
      for (final meta in metas)
        meta.id!: calcularProgresoMetaAhorro(
          meta: meta,
          cicloActual: cicloActual,
          balancePorCiclo: balancePorCiclo,
        ),
    };

    // Solo con ciclos ya cerrados: el actual va a medias y sesgaría la media.
    final ciclosCerrados = todosMeses.where((m) => !m.esActual);
    final saludFinanciera = calcularSaludFinanciera(
      ingresosPorCiclo: [
        for (final mes in ciclosCerrados) ingresosPorCiclo[mes.cicloMes]!,
      ],
      balancesPorCiclo: [for (final mes in ciclosCerrados) mes.balance],
    );

    return _DatosInicio(
      diaInicioMes: config.diaInicioMes,
      cicloActual: cicloActual,
      inicioCiclo: inicioCiclo,
      finCiclo: finCiclo,
      balanceCicloActual: balanceCicloActual,
      proyeccionFinDeCiclo: proyectarFinDeCiclo(
        balanceActual: balanceCicloActual,
        movimientosDelCiclo: movimientosCicloActual,
        inicioCiclo: inicioCiclo,
        finCiclo: finCiclo,
        ahora: ahora,
      ),
      metas: metas,
      progresosMetas: progresosMetas,
      saludFinanciera: saludFinanciera,
      meses: meses,
      anios: anios,
    );
  }

  Future<void> _abrirAltaMovimiento() async {
    final creado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AltaMovimientoScreen()),
    );
    if (creado == true) setState(_recargar);
  }

  Future<void> _abrirDetalle(String cicloMes, String etiqueta) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            DetalleCicloScreen(cicloMes: cicloMes, etiqueta: etiqueta),
      ),
    );
    setState(_recargar);
  }

  Future<void> _abrirDetalleAnio(int anio) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => DetalleAnioScreen(anio: anio)));
    setState(_recargar);
  }

  Future<void> _abrirMetasAhorro() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MetasAhorroScreen()));
    setState(_recargar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConfiguracionScreen()),
              );
              setState(_recargar);
            },
          ),
        ],
      ),
      body: FutureBuilder<_DatosInicio>(
        future: _datosFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se han podido cargar los datos.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final datos = snapshot.data!;
          final hoy = DateTime.now();

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Column(
              children: [
                if (datos.metas.isNotEmpty) ...[
                  Text(
                    'Metas de ahorro',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final meta in datos.metas) ...[
                    _FilaMetaResumen(
                      meta: meta,
                      progreso: datos.progresosMetas[meta.id]!,
                      onTap: _abrirMetasAhorro,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
                const SizedBox(height: 28),
                // Arriba: fecha y balance. Pulsable — lleva al detalle del
                // mes actual, igual que su burbuja en el historial.
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _abrirDetalle(
                    datos.cicloActual,
                    datos.meses.firstWhere((m) => m.esActual).etiqueta,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Text(
                            '${hoy.day} de ${_nombresMesesLargo[hoy.month - 1]}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _formatearImporte(datos.balanceCicloActual),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: _colorBalance(
                                    context,
                                    datos.balanceCicloActual,
                                  ),
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _rangoCiclo(
                              datos.inicioCiclo,
                              datos.finCiclo,
                              datos.diaInicioMes,
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          if (datos.proyeccionFinDeCiclo != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Si sigues así, terminas con '
                              '${_formatearImporte(datos.proyeccionFinDeCiclo!)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                          if (datos.saludFinanciera != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _textoSaludFinanciera(datos.saludFinanciera!),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: _colorNivelSalud(
                                      context,
                                      datos.saludFinanciera!.nivel,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Centro: el botón de añadir, lo más importante de la app.
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: BotonPildora(
                        texto: 'Añadir gasto/ingreso',
                        onTap: _abrirAltaMovimiento,
                      ),
                    ),
                  ),
                ),

                // Abajo (con margen, no pegado del todo): el historial.
                Text(
                  'Historial',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _FilaBurbujas(
                  children: [
                    for (final mes in datos.meses)
                      _Burbuja(
                        etiqueta: mes.etiqueta,
                        balance: mes.balance,
                        destacada: mes.esActual,
                        onTap: () => _abrirDetalle(mes.cicloMes, mes.etiqueta),
                      ),
                  ],
                ),
                if (datos.anios.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Años', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _FilaBurbujas(
                    children: [
                      for (final anio in datos.anios)
                        _Burbuja(
                          etiqueta: '${anio.anio}',
                          balance: anio.balance,
                          destacada: false,
                          onTap: () => _abrirDetalleAnio(anio.anio),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Fila horizontal de burbujas, alineada a la izquierda, con scroll
/// horizontal si no caben todas.
class _FilaBurbujas extends StatelessWidget {
  const _FilaBurbujas({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

Color _colorBalance(BuildContext context, double balance) {
  if (balance > 0) return AppTheme.positivo(context);
  if (balance < 0) return AppTheme.negativo(context);
  return Theme.of(context).colorScheme.onSurface;
}

/// Una línea por meta de ahorro: nombre, % conseguido y si vas al día — un
/// vistazo rápido, sin entrar a ver el detalle salvo que se toque.
class _FilaMetaResumen extends StatelessWidget {
  const _FilaMetaResumen({
    required this.meta,
    required this.progreso,
    required this.onTap,
  });

  final MetaAhorro meta;
  final ProgresoMetaAhorro progreso;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bien = progreso.completada || progreso.vaAlDia;
    final color = bien
        ? AppTheme.positivo(context)
        : AppTheme.negativo(context);
    final porcentaje = (progreso.ahorroAcumulado / meta.importeObjetivo * 100)
        .clamp(0, 999);
    final estado = progreso.completada
        ? '¡Cumplido!'
        : (bien ? 'Al día' : 'Por detrás');

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${meta.nombre} · ${porcentaje.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                estado,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatearImporte(double importe) {
  final signo = importe > 0 ? '+' : '';
  return '$signo${importe.toStringAsFixed(2)} €';
}

String _textoSaludFinanciera(SaludFinanciera salud) {
  final etiqueta = etiquetaSaludFinanciera(salud.nivel);
  final porcentaje = (salud.tasaAhorro * 100).abs().toStringAsFixed(0);
  final verbo = salud.tasaAhorro >= 0
      ? 'ahorras de media un $porcentaje% de lo que ingresas'
      : 'gastas de media un $porcentaje% más de lo que ingresas';
  return 'Salud financiera: $etiqueta — $verbo';
}

Color _colorNivelSalud(BuildContext context, NivelSaludFinanciera nivel) {
  switch (nivel) {
    case NivelSaludFinanciera.excelente:
    case NivelSaludFinanciera.saludable:
      return AppTheme.positivo(context);
    case NivelSaludFinanciera.alerta:
      return AppTheme.negativo(context);
    case NivelSaludFinanciera.ajustada:
      return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({
    required this.etiqueta,
    required this.balance,
    required this.destacada,
    this.onTap,
  });

  final String etiqueta;
  final double balance;
  final bool destacada;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorBalance(context, balance);
    final burbuja = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: destacada ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(etiqueta, style: const TextStyle(fontSize: 11)),
          Text(
            _formatearImporte(balance),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );

    if (onTap == null) return burbuja;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: burbuja,
    );
  }
}
