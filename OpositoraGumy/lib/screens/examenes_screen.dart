import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/examen_general.dart';
import '../utils/exportar_importar.dart';
import 'examen_general_screen.dart';

/// Pantalla principal: todos los exámenes generales que el usuario ha
/// creado (p. ej. "Auxiliar Administrativo 2026").
class ExamenesScreen extends StatefulWidget {
  const ExamenesScreen({super.key});

  @override
  State<ExamenesScreen> createState() => _ExamenesScreenState();
}

class _ExamenesScreenState extends State<ExamenesScreen> {
  final _datos = AppData.instancia;
  List<ExamenGeneral> _examenes = [];

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    setState(() => _examenes = _datos.listarExamenesGenerales());
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

  Future<void> _crear() async {
    final nombre = await _pedirNombre(
      titulo: 'Nuevo examen general',
      pista: 'p. ej. Auxiliar Administrativo 2026',
    );
    final limpio = nombre?.trim() ?? '';
    if (limpio.isEmpty) return;
    await _datos.crearExamenGeneral(limpio);
    _recargar();
  }

  Future<void> _renombrar(ExamenGeneral examen) async {
    final nombre = await _pedirNombre(
      titulo: 'Renombrar examen general',
      pista: 'Nombre',
      inicial: examen.nombre,
    );
    final limpio = nombre?.trim() ?? '';
    if (limpio.isEmpty || limpio == examen.nombre) return;
    await _datos.renombrarExamenGeneral(examen.id, limpio);
    _recargar();
  }

  Future<void> _abrir(ExamenGeneral examen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExamenGeneralScreen(examenGeneral: examen),
      ),
    );
    _recargar();
  }

  Future<void> _confirmarBorrado(ExamenGeneral examen) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar examen general'),
        content: Text(
          '¿Seguro que quieres borrar "${examen.nombre}" y todos sus '
          'temas y preguntas?',
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
      await _datos.borrarExamenGeneral(examen.id);
      _recargar();
    }
  }

  Future<void> _exportar() async {
    await exportarACopia(_datos);
  }

  Future<void> _importar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar copia de seguridad'),
        content: const Text(
          'Esto sustituye todo lo que tienes guardado ahora mismo por el '
          'contenido del archivo que elijas. No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elegir archivo'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    final importado = await importarDesdeCopia(_datos);
    if (!mounted) return;
    if (importado) {
      _recargar();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Copia importada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpositoraGumy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Exportar copia de seguridad',
            onPressed: _exportar,
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Importar copia de seguridad',
            onPressed: _importar,
          ),
        ],
      ),
      body: _examenes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Todavía no tienes ningún examen general. Crea el '
                  'primero con el botón de abajo — el nombre lo eliges tú.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _examenes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final examen = _examenes[index];
                return Card(
                  child: ListTile(
                    title: Text(examen.nombre),
                    onTap: () => _abrir(examen),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Renombrar',
                          onPressed: () => _renombrar(examen),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Borrar',
                          onPressed: () => _confirmarBorrado(examen),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crear,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo examen general'),
      ),
    );
  }
}
