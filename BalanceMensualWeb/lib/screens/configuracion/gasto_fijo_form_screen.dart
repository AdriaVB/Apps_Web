import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../models/categoria.dart';
import '../../models/gasto_fijo.dart';
import '../../models/movimiento.dart';
import '../../widgets/formulario_centrado.dart';
import '../../widgets/toggle_tipo.dart';

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

/// Formulario de alta/edición de un gasto o ingreso fijo. Si [gastoExistente]
/// es nulo, crea uno nuevo; si no, lo edita. Cubre cualquier periodicidad
/// (mensual, trimestral, cuatrimestral, semestral, anual).
class GastoFijoFormScreen extends StatefulWidget {
  const GastoFijoFormScreen({super.key, this.gastoExistente});

  final GastoFijo? gastoExistente;

  @override
  State<GastoFijoFormScreen> createState() => _GastoFijoFormScreenState();
}

class _GastoFijoFormScreenState extends State<GastoFijoFormScreen> {
  final _db = AppDatabase.instancia;
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _importeController = TextEditingController();
  final _diaDelMesController = TextEditingController();

  TipoMovimiento _tipo = TipoMovimiento.gasto;
  List<Categoria> _categorias = [];
  int? _categoriaId;
  int _periodicidadMeses = 1;
  int _mesDePago = 1;
  bool _prorratear = true;
  bool _cargando = true;

  bool get _esEdicion => widget.gastoExistente != null;
  bool get _esGasto => _tipo == TipoMovimiento.gasto;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<List<Categoria>> _categoriasParaTipo(TipoMovimiento tipo) {
    return tipo == TipoMovimiento.ingreso
        ? _db.listarCategoriasIngreso()
        : _db.listarCategoriasRecurrentes();
  }

  Future<void> _cargar() async {
    final gasto = widget.gastoExistente;
    final tipoInicial = gasto?.tipo ?? TipoMovimiento.gasto;
    final categorias = await _categoriasParaTipo(tipoInicial);
    setState(() {
      _categorias = categorias;
      _tipo = tipoInicial;
      if (gasto != null) {
        _nombreController.text = gasto.nombre;
        _importeController.text = gasto.importe.toStringAsFixed(2);
        _categoriaId = gasto.categoriaId;
        _periodicidadMeses = gasto.periodicidadMeses;
        _mesDePago = gasto.mesDePago ?? 1;
        _prorratear = gasto.prorratear;
        if (gasto.diaDelMes != null) {
          _diaDelMesController.text = '${gasto.diaDelMes}';
        }
      } else {
        _categoriaId = categorias.isNotEmpty ? categorias.first.id : null;
      }
      _cargando = false;
    });
  }

  Future<void> _cambiarTipo() async {
    final nuevoTipo = _esGasto ? TipoMovimiento.ingreso : TipoMovimiento.gasto;
    final categorias = await _categoriasParaTipo(nuevoTipo);
    setState(() {
      _tipo = nuevoTipo;
      _categorias = categorias;
      _categoriaId = categorias.isNotEmpty ? categorias.first.id : null;
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _importeController.dispose();
    _diaDelMesController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _categoriaId == null) return;

    final importe = double.parse(_importeController.text.replaceAll(',', '.'));
    final esMensual = _periodicidadMeses <= 1;
    final diaDelMes = int.tryParse(_diaDelMesController.text.trim());

    if (_esEdicion) {
      final actualizado = widget.gastoExistente!.copyWith(
        nombre: _nombreController.text.trim(),
        tipo: _tipo,
        categoriaId: _categoriaId,
        importe: importe,
        periodicidadMeses: _periodicidadMeses,
        mesDePago: esMensual ? null : _mesDePago,
        prorratear: !esMensual && _prorratear,
        diaDelMes: diaDelMes,
      );
      await _db.actualizarGastoFijo(actualizado);
      // El mes actual sigue abierto: si ya se había generado su movimiento,
      // que refleje el cambio (los meses cerrados nunca se tocan aquí).
      await _db.sincronizarGastoFijoEnCicloActual(actualizado);
    } else {
      await _db.crearGastoFijo(
        GastoFijo(
          nombre: _nombreController.text.trim(),
          tipo: _tipo,
          categoriaId: _categoriaId!,
          importe: importe,
          periodicidadMeses: _periodicidadMeses,
          mesDePago: esMensual ? null : _mesDePago,
          prorratear: !esMensual && _prorratear,
          diaDelMes: diaDelMes,
        ),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  String _importeParaMostrar() {
    final normalizado = _importeController.text.replaceAll(',', '.');
    final numero = double.tryParse(normalizado) ?? 0;
    return (numero / _periodicidadMeses).toStringAsFixed(2);
  }

  String _mesesDePagoTexto() {
    final meses = <String>[];
    var mes = _mesDePago;
    for (var i = 0; i < 12 ~/ _periodicidadMeses; i++) {
      meses.add(_nombresMeses[mes - 1]);
      mes = ((mes - 1 + _periodicidadMeses) % 12) + 1;
    }
    return meses.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final esMensual = _periodicidadMeses <= 1;
    final titulo = _esEdicion
        ? (_esGasto ? 'Editar gasto fijo' : 'Editar ingreso fijo')
        : (_esGasto ? 'Nuevo gasto fijo' : 'Nuevo ingreso fijo');

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: FormularioCentrado(
                onGuardar: _guardar,
                notaInferior: Text(
                  esMensual
                      ? 'Este importe se aplicará cada mes. Cuando llegue el '
                            'recibo real, edítalo en cualquier momento — el '
                            'cambio no afecta a los meses anteriores.'
                      : 'Puedes editar el importe o la periodicidad en '
                            'cualquier momento — el cambio no afecta a los '
                            'meses ya pasados.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ToggleTipo(tipo: _tipo, onTap: _cambiarTipo),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      hintText: _esGasto
                          ? 'p. ej. Alquiler, Luz, IBI, Seguro coche'
                          : 'p. ej. Nómina, Alquiler cobrado',
                    ),
                    validator: (valor) =>
                        (valor == null || valor.trim().isEmpty)
                        ? 'El nombre es obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    key: ValueKey(_tipo),
                    initialValue: _categoriaId,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: [
                      for (final categoria in _categorias)
                        DropdownMenuItem(
                          value: categoria.id,
                          child: Text(categoria.nombre),
                        ),
                    ],
                    onChanged: (valor) => setState(() => _categoriaId = valor),
                    validator: (valor) =>
                        valor == null ? 'Elige una categoría' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _importeController,
                    decoration: const InputDecoration(
                      labelText: 'Importe',
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
                  DropdownButtonFormField<int>(
                    initialValue: _periodicidadMeses,
                    decoration: const InputDecoration(
                      labelText: '¿Cada cuánto se paga?',
                    ),
                    items: [
                      for (final entrada in etiquetasPeriodicidad.entries)
                        DropdownMenuItem(
                          value: entrada.key,
                          child: Text(entrada.value),
                        ),
                    ],
                    onChanged: (valor) =>
                        setState(() => _periodicidadMeses = valor ?? 1),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _diaDelMesController,
                    decoration: const InputDecoration(
                      labelText: 'Día del mes en que se cobra (opcional)',
                      hintText: 'p. ej. 5',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) return null;
                      final numero = int.tryParse(valor.trim());
                      if (numero == null || numero < 1 || numero > 31) {
                        return 'Introduce un día entre 1 y 31';
                      }
                      return null;
                    },
                  ),
                  if (!esMensual) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _mesDePago,
                      decoration: const InputDecoration(
                        labelText: 'Mes del próximo pago',
                      ),
                      items: [
                        for (var mes = 1; mes <= 12; mes++)
                          DropdownMenuItem(
                            value: mes,
                            child: Text(_nombresMeses[mes - 1]),
                          ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) {
                          setState(() => _mesDePago = valor);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Repartir en los $_periodicidadMeses meses'),
                      subtitle: Text(
                        _prorratear
                            ? 'Cada mes se contará ${_importeParaMostrar()} €, '
                                  'en vez de golpear entero el mes de pago.'
                            : 'El importe completo se contará solo en '
                                  '${_mesesDePagoTexto()}.',
                      ),
                      value: _prorratear,
                      onChanged: (valor) => setState(() => _prorratear = valor),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
