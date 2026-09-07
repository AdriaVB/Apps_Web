import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../models/meta_ahorro.dart';
import '../../utils/ciclo_mes.dart';
import '../../widgets/formulario_centrado.dart';

/// Formulario de alta/edición de una meta de ahorro. Si [metaExistente] es
/// nula, crea una nueva; si no, la edita (el ciclo de inicio no se puede
/// tocar, solo nombre/importe/plazo).
class MetaAhorroFormScreen extends StatefulWidget {
  const MetaAhorroFormScreen({super.key, this.metaExistente});

  final MetaAhorro? metaExistente;

  @override
  State<MetaAhorroFormScreen> createState() => _MetaAhorroFormScreenState();
}

class _MetaAhorroFormScreenState extends State<MetaAhorroFormScreen> {
  final _db = AppDatabase.instancia;
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _importeController = TextEditingController();
  final _mesesController = TextEditingController();

  bool get _esEdicion => widget.metaExistente != null;

  @override
  void initState() {
    super.initState();
    final meta = widget.metaExistente;
    if (meta != null) {
      _nombreController.text = meta.nombre;
      _importeController.text = meta.importeObjetivo.toStringAsFixed(2);
      _mesesController.text = '${meta.mesesPlazo}';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _importeController.dispose();
    _mesesController.dispose();
    super.dispose();
  }

  String get _aportacionMensual {
    final importe = double.tryParse(
      _importeController.text.replaceAll(',', '.'),
    );
    final meses = int.tryParse(_mesesController.text.trim());
    if (importe == null || meses == null || meses <= 0) return '';
    return (importe / meses).toStringAsFixed(2);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final importe = double.parse(_importeController.text.replaceAll(',', '.'));
    final meses = int.parse(_mesesController.text.trim());

    if (_esEdicion) {
      final actualizada = widget.metaExistente!.copyWith(
        nombre: _nombreController.text.trim(),
        importeObjetivo: importe,
        mesesPlazo: meses,
      );
      await _db.actualizarMetaAhorro(actualizada);
    } else {
      final config = await _db.obtenerConfiguracion();
      final cicloActual = claveCiclo(DateTime.now(), config.diaInicioMes);
      await _db.crearMetaAhorro(
        MetaAhorro(
          nombre: _nombreController.text.trim(),
          importeObjetivo: importe,
          mesesPlazo: meses,
          cicloInicio: cicloActual,
        ),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final aportacion = _aportacionMensual;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _esEdicion ? 'Editar meta de ahorro' : 'Nueva meta de ahorro',
        ),
      ),
      body: Form(
        key: _formKey,
        child: FormularioCentrado(
          onGuardar: _guardar,
          notaInferior: Text(
            'Es solo informativa: no aparta dinero ni crea ningún '
            'movimiento, solo compara lo que ya ahorras con lo que haría '
            'falta para llegar a tiempo.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'p. ej. iPhone, Vacaciones, Fondo de emergencia',
              ),
              validator: (valor) => (valor == null || valor.trim().isEmpty)
                  ? 'El nombre es obligatorio'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _importeController,
              decoration: const InputDecoration(
                labelText: 'Importe objetivo',
                suffixText: '€',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              validator: (valor) {
                final normalizado = (valor ?? '').replaceAll(',', '.');
                final numero = double.tryParse(normalizado);
                if (numero == null) return 'Introduce un importe válido';
                if (numero <= 0) return 'El importe debe ser mayor que 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mesesController,
              decoration: const InputDecoration(
                labelText: 'Plazo (meses)',
                hintText: 'p. ej. 6',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (valor) {
                final numero = int.tryParse((valor ?? '').trim());
                if (numero == null || numero <= 0) {
                  return 'Introduce un número de meses válido';
                }
                return null;
              },
            ),
            if (aportacion.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Necesitarás ahorrar $aportacion € al mes para llegar a '
                'tiempo.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
