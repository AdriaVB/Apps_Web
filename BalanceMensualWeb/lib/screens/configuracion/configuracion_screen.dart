import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../theme/tema_controlador.dart';
import '../recordatorios_screen.dart';
import 'ciclo_mes_screen.dart';
import 'gastos_fijos_screen.dart';
import 'metas_ahorro_screen.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final _db = AppDatabase.instancia;

  Future<void> _recargar() async {
    setState(() {});
  }

  Future<void> _cambiarModoOscuro(bool activo) async {
    final config = await _db.obtenerConfiguracion();
    await _db.guardarConfiguracion(config.copyWith(modoOscuro: activo));
    temaControlador.value = activo ? ThemeMode.dark : ThemeMode.light;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          children: [
            // Arriba: navegación a las pantallas de configuración.
            Expanded(
              child: ListView(
                children: [
                  FutureBuilder(
                    future: _db.obtenerConfiguracion(),
                    builder: (context, snapshot) {
                      final config = snapshot.data;
                      final dia = config?.diaInicioMes;
                      final pendiente = config?.diaInicioMesPendiente;
                      final base = snapshot.hasError
                          ? 'Error al cargar'
                          : dia == null
                          ? 'Cargando...'
                          : dia == 1
                          ? 'Mes natural (empieza el día 1)'
                          : 'Empieza el día $dia de cada mes';
                      return _FilaAjuste(
                        icono: Icons.calendar_month,
                        titulo: 'Ciclo de mes',
                        subtitulo: pendiente == null
                            ? base
                            : '$base · cambia a día $pendiente pronto',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CicloMesScreen(),
                            ),
                          );
                          _recargar();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder(
                    future: _db.listarGastosFijos(),
                    builder: (context, snapshot) {
                      final total = snapshot.data?.length;
                      return _FilaAjuste(
                        icono: Icons.repeat,
                        titulo: 'Gastos/Ingresos fijos',
                        subtitulo: snapshot.hasError
                            ? 'Error al cargar'
                            : total == null
                            ? 'Cargando...'
                            : total == 0
                            ? 'Ninguno configurado todavía'
                            : '$total configurados',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const GastosFijosScreen(),
                            ),
                          );
                          _recargar();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder(
                    future: _db.listarMetasAhorro(),
                    builder: (context, snapshot) {
                      final total = snapshot.data?.length;
                      return _FilaAjuste(
                        icono: Icons.savings_outlined,
                        titulo: 'Metas de ahorro',
                        subtitulo: snapshot.hasError
                            ? 'Error al cargar'
                            : total == null
                            ? 'Cargando...'
                            : total == 0
                            ? 'Ninguna configurada todavía'
                            : '$total configuradas',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MetasAhorroScreen(),
                            ),
                          );
                          _recargar();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _FilaAjuste(
                    icono: Icons.notifications_none,
                    titulo: 'Recordatorios',
                    subtitulo: 'Qué toca pagar o cobrar y cuándo',
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RecordatoriosScreen(),
                        ),
                      );
                      _recargar();
                    },
                  ),
                ],
              ),
            ),

            // Abajo del todo (misma altura que "Historial" en la pantalla
            // principal): las preferencias, aparte de la navegación.
            Text(
              'Preferencias',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            FutureBuilder(
              future: _db.obtenerConfiguracion(),
              builder: (context, snapshot) {
                final activo = snapshot.data?.modoOscuro ?? false;
                return _FilaAjuste(
                  icono: Icons.dark_mode_outlined,
                  titulo: 'Modo oscuro',
                  subtitulo: activo ? 'Activado' : 'Desactivado',
                  trailing: Switch(
                    value: activo,
                    onChanged: snapshot.hasData ? _cambiarModoOscuro : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de ajuste con estilo de tarjeta: icono en una chapa de color,
/// título, subtítulo y un elemento a la derecha (flecha por defecto, o el
/// que se indique).
class _FilaAjuste extends StatelessWidget {
  const _FilaAjuste({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    this.onTap,
    this.trailing,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: esquema.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: esquema.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: esquema.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  Icon(Icons.chevron_right, color: esquema.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
