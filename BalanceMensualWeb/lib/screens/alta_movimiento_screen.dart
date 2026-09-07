import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/categoria.dart';
import '../models/movimiento.dart';
import '../utils/ciclo_mes.dart';
import '../widgets/toggle_tipo.dart';

/// Formulario de alta y edición de un movimiento.
///
/// Desde el botón + ([movimientoExistente] nulo) siempre crea uno variable:
/// los gastos fijos y anuales nunca se dan de alta aquí, solo desde
/// Configuración. Desde el detalle de un mes ([movimientoExistente] no
/// nulo) permite corregir cualquier movimiento, sea cual sea su origen —
/// editar aquí solo afecta a ese mes, nunca a la plantilla que lo generó.
class AltaMovimientoScreen extends StatefulWidget {
  const AltaMovimientoScreen({super.key, this.movimientoExistente});

  final Movimiento? movimientoExistente;

  @override
  State<AltaMovimientoScreen> createState() => _AltaMovimientoScreenState();
}

class _AltaMovimientoScreenState extends State<AltaMovimientoScreen> {
  final _db = AppDatabase.instancia;
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _importeController = TextEditingController();

  TipoMovimiento _tipo = TipoMovimiento.gasto;
  List<Categoria> _categorias = [];
  int? _categoriaId;
  bool _cargando = true;

  bool get _esEdicion => widget.movimientoExistente != null;
  bool get _esDePlantilla =>
      _esEdicion &&
      widget.movimientoExistente!.origen != OrigenMovimiento.variable;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// Un ingreso (fijo o variable) siempre usa el mismo catálogo, sin
  /// importar de dónde venga — solo los gastos distinguen plantilla
  /// (recurrente) de puntual (variable).
  Future<List<Categoria>> _categoriasParaTipo(TipoMovimiento tipo) {
    if (tipo == TipoMovimiento.ingreso) return _db.listarCategoriasIngreso();
    final existente = widget.movimientoExistente;
    final esDePlantilla =
        existente != null && existente.origen != OrigenMovimiento.variable;
    return esDePlantilla
        ? _db.listarCategoriasRecurrentes()
        : _db.listarCategoriasVariables();
  }

  Future<void> _cargar() async {
    final existente = widget.movimientoExistente;
    final tipoInicial = existente?.tipo ?? TipoMovimiento.gasto;
    final categorias = await _categoriasParaTipo(tipoInicial);

    setState(() {
      _categorias = categorias;
      _tipo = tipoInicial;
      if (existente != null) {
        _nombreController.text = existente.nombre;
        _importeController.text = existente.importe.toStringAsFixed(2);
        _categoriaId = existente.categoriaId;
      } else {
        _categoriaId = categorias.isNotEmpty ? categorias.first.id : null;
      }
      _cargando = false;
    });
  }

  Future<void> _cambiarTipo() async {
    final nuevoTipo = _tipo == TipoMovimiento.gasto
        ? TipoMovimiento.ingreso
        : TipoMovimiento.gasto;
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
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _categoriaId == null) return;

    final importe = double.parse(_importeController.text.replaceAll(',', '.'));

    if (_esEdicion) {
      final existente = widget.movimientoExistente!;
      await _db.actualizarMovimiento(
        Movimiento(
          id: existente.id,
          tipo: _tipo,
          origen: existente.origen,
          nombre: _nombreController.text.trim(),
          importe: importe,
          categoriaId: _categoriaId!,
          cicloMes: existente.cicloMes,
          gastoFijoId: existente.gastoFijoId,
        ),
      );
    } else {
      final config = await _db.obtenerConfiguracion();
      final ciclo = claveCiclo(DateTime.now(), config.diaInicioMes);
      await _db.crearMovimiento(
        Movimiento(
          tipo: _tipo,
          origen: OrigenMovimiento.variable,
          nombre: _nombreController.text.trim(),
          importe: importe,
          categoriaId: _categoriaId!,
          cicloMes: ciclo,
        ),
      );
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final esGasto = _tipo == TipoMovimiento.gasto;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar movimiento' : 'Nuevo movimiento'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Centro: nombre, importe, categoría y guardar.
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_esDePlantilla) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'Viene de un gasto fijo. Editarlo aquí solo corrige este mes — no toca la plantilla en Configuración.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    TextFormField(
                                      controller: _nombreController,
                                      decoration: InputDecoration(
                                        labelText: 'Nombre',
                                        hintText: esGasto
                                            ? 'p. ej. Cena, PlayStation, Gasolina'
                                            : 'p. ej. Nómina, Devolución',
                                      ),
                                      validator: (valor) =>
                                          (valor == null ||
                                              valor.trim().isEmpty)
                                          ? 'El nombre es obligatorio'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _importeController,
                                      decoration: const InputDecoration(
                                        labelText: 'Importe',
                                        suffixText: '€',
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator: (valor) {
                                        final normalizado = (valor ?? '')
                                            .replaceAll(',', '.');
                                        final numero = double.tryParse(
                                          normalizado,
                                        );
                                        if (numero == null) {
                                          return 'Introduce un importe válido';
                                        }
                                        if (numero <= 0) {
                                          return 'El importe debe ser mayor que 0';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<int>(
                                      key: ValueKey(_tipo),
                                      initialValue: _categoriaId,
                                      decoration: const InputDecoration(
                                        labelText: 'Categoría',
                                      ),
                                      items: [
                                        for (final categoria in _categorias)
                                          DropdownMenuItem(
                                            value: categoria.id,
                                            child: Text(categoria.nombre),
                                          ),
                                      ],
                                      onChanged: (valor) =>
                                          setState(() => _categoriaId = valor),
                                      validator: (valor) => valor == null
                                          ? 'Elige una categoría'
                                          : null,
                                    ),
                                    const SizedBox(height: 32),
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: FilledButton(
                                            style: FilledButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 20,
                                                  ),
                                              textStyle: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            onPressed: _guardar,
                                            child: const Text('Guardar'),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Abajo (misma altura que "Historial" en la pantalla
                    // principal): el interruptor Gasto/Ingreso.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: ToggleTipo(tipo: _tipo, onTap: _cambiarTipo),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
