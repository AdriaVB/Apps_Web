import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/examen_general.dart';
import '../models/tema.dart';
import 'configurar_examen_screen.dart';
import 'tema_screen.dart';

/// Temas de un examen general concreto.
class ExamenGeneralScreen extends StatefulWidget {
  const ExamenGeneralScreen({super.key, required this.examenGeneral});

  final ExamenGeneral examenGeneral;

  @override
  State<ExamenGeneralScreen> createState() => _ExamenGeneralScreenState();
}

class _ExamenGeneralScreenState extends State<ExamenGeneralScreen> {
  final _datos = AppData.instancia;
  List<Tema> _temas = [];

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    setState(() => _temas = _datos.listarTemas(widget.examenGeneral.id));
  }

  Future<String?> _pedirNombre({
    required String titulo,
    required String pista,
    String inicial = '',
  }) {
    final controller = TextEditingController(text: inicial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: pista),
          onSubmitted: (valor) => Navigator.of(context).pop(valor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _crearTema() async {
    final nombre = await _pedirNombre(
      titulo: 'Nuevo tema',
      pista: 'p. ej. Tema 3 — La Constitución Española',
    );
    final limpio = nombre?.trim() ?? '';
    if (limpio.isEmpty) return;
    await _datos.crearTema(widget.examenGeneral.id, limpio);
    _recargar();
  }

  Future<void> _renombrarTema(Tema tema) async {
    final nombre = await _pedirNombre(
      titulo: 'Renombrar tema',
      pista: 'Nombre',
      inicial: tema.nombre,
    );
    final limpio = nombre?.trim() ?? '';
    if (limpio.isEmpty || limpio == tema.nombre) return;
    await _datos.renombrarTema(tema.id, limpio);
    _recargar();
  }

  Future<void> _abrirTema(Tema tema) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => TemaScreen(tema: tema)));
    _recargar();
  }

  Future<void> _confirmarBorrado(Tema tema) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar tema'),
        content: Text(
          '¿Seguro que quieres borrar "${tema.nombre}" y todas sus '
          'preguntas?',
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
    if (confirmado == true) {
      await _datos.borrarTema(tema.id);
      _recargar();
    }
  }

  void _examenGeneral() {
    final preguntas = _datos.listarPreguntasDeExamenGeneral(
      widget.examenGeneral.id,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfigurarExamenScreen(
          titulo: 'Examen general · ${widget.examenGeneral.nombre}',
          preguntasDisponibles: preguntas,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examenGeneral.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz_outlined),
            tooltip: 'Examen general (todos los temas)',
            onPressed: _temas.isEmpty ? null : _examenGeneral,
          ),
        ],
      ),
      body: _temas.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Este examen todavía no tiene ningún tema. Añade el '
                  'primero con el botón de abajo.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _temas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final tema = _temas[index];
                final total = _datos.listarPreguntas(tema.id).length;
                return Card(
                  child: ListTile(
                    title: Text(tema.nombre),
                    subtitle: Text(
                      total == 0
                          ? 'Sin preguntas todavía'
                          : '$total pregunta${total == 1 ? '' : 's'}',
                    ),
                    onTap: () => _abrirTema(tema),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Renombrar',
                          onPressed: () => _renombrarTema(tema),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Borrar',
                          onPressed: () => _confirmarBorrado(tema),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearTema,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo tema'),
      ),
    );
  }
}
