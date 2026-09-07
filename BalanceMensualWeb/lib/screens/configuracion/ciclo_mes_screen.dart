import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../models/configuracion_usuario.dart';
import '../../utils/ciclo_mes.dart';
import '../../widgets/formulario_centrado.dart';

const _nombresMeses = [
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

String _fechaLarga(DateTime fecha) =>
    '${fecha.day} de ${_nombresMeses[fecha.month - 1]} de ${fecha.year}';

class CicloMesScreen extends StatefulWidget {
  const CicloMesScreen({super.key});

  @override
  State<CicloMesScreen> createState() => _CicloMesScreenState();
}

class _CicloMesScreenState extends State<CicloMesScreen> {
  final _db = AppDatabase.instancia;
  ConfiguracionUsuario _configuracion = ConfiguracionUsuario.porDefecto;
  int _diaSeleccionado = 1;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final config = await _db.obtenerConfiguracion();
    setState(() {
      _configuracion = config;
      _diaSeleccionado = config.diaInicioMes;
      _cargando = false;
    });
  }

  Future<void> _guardar() async {
    if (_diaSeleccionado == _configuracion.diaInicioMes) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final hoy = DateTime.now();
    final fechaTransicion = fechaTransicionCiclo(hoy, _diaSeleccionado);
    final esInmediato = !DateTime(
      hoy.year,
      hoy.month,
      hoy.day,
    ).isBefore(fechaTransicion);

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar día de inicio de mes'),
        content: Text(
          esInmediato
              ? 'A partir de hoy, tus meses empezarán el día '
                    '$_diaSeleccionado.'
              : 'Tu ciclo actual sigue igual hasta el '
                    '${_fechaLarga(fechaTransicion)} — a partir de ese día, '
                    'tus meses empezarán el día $_diaSeleccionado. Nada de '
                    'lo que ya tienes registrado se ve afectado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    final nueva = esInmediato
        ? _configuracion.copyWith(diaInicioMes: _diaSeleccionado)
        : _configuracion.conCambioPendiente(
            _diaSeleccionado,
            claveTransicionCiclo(hoy, _diaSeleccionado),
          );
    await _db.guardarConfiguracion(nueva);

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ciclo de mes guardado')));
      Navigator.of(context).pop();
    }
  }

  Future<void> _cancelarPendiente() async {
    final sinPendiente = _configuracion.conCambioPendiente(null, null);
    await _db.guardarConfiguracion(sinPendiente);
    setState(() => _configuracion = sinPendiente);
  }

  @override
  Widget build(BuildContext context) {
    final diaPendiente = _configuracion.diaInicioMesPendiente;
    final fechaPendiente = _configuracion.fechaAplicacionPendiente;

    return Scaffold(
      appBar: AppBar(title: const Text('Ciclo de mes')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : FormularioCentrado(
              onGuardar: _guardar,
              notaInferior: Text(
                'Si lo cambias, tu ciclo ya abierto no se toca — el cambio '
                'se aplica en cuanto llegue el nuevo día (este mes o el que '
                'viene, lo que toque antes).',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              children: [
                const Text(
                  'Elige el día en que empieza tu mes. Usa 1 para el mes '
                  'natural, o el día aproximado de tu nómina para un ciclo '
                  'de nómina a nómina.',
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<int>(
                  initialValue: _diaSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Día de inicio de mes',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (var dia = 1; dia <= 31; dia++)
                      DropdownMenuItem(
                        value: dia,
                        child: Text(
                          dia == 1 ? '1 (mes natural)' : dia.toString(),
                        ),
                      ),
                  ],
                  onChanged: (valor) {
                    if (valor != null) {
                      setState(() => _diaSeleccionado = valor);
                    }
                  },
                ),
                if (diaPendiente != null && fechaPendiente != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Cambio en cola: pasará a día $diaPendiente '
                              'el ${_fechaLarga(DateTime.parse(fechaPendiente))}.',
                            ),
                          ),
                          TextButton(
                            onPressed: _cancelarPendiente,
                            child: const Text('Cancelar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
