import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/lista.dart';
import 'lista_detalle_screen.dart';

/// Pantalla principal: todas las listas que el usuario ha creado.
class ListasScreen extends StatefulWidget {
  const ListasScreen({super.key});

  @override
  State<ListasScreen> createState() => _ListasScreenState();
}

class _ListasScreenState extends State<ListasScreen> {
  final _datos = AppData.instancia;
  List<Lista> _listas = [];

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    setState(() {
      _listas = _datos.listarListas();
    });
  }

  Future<void> _crearLista() async {
    final controller = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva lista'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'p. ej. Videojuegos, Tareas de casa',
          ),
          onSubmitted: (valor) => Navigator.of(context).pop(valor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    final nombreLimpio = nombre?.trim() ?? '';
    if (nombreLimpio.isEmpty) return;
    await _datos.crearLista(nombreLimpio);
    _recargar();
  }

  Future<void> _abrirLista(Lista lista) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ListaDetalleScreen(lista: lista)));
    _recargar();
  }

  Future<void> _confirmarBorrado(Lista lista) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar lista'),
        content: Text(
          '¿Seguro que quieres borrar "${lista.nombre}" y todo lo que '
          'tiene dentro?',
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
      await _datos.borrarLista(lista.id);
      _recargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CheckList')),
      body: _listas.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Todavía no tienes ninguna lista. Crea la primera con '
                  'el botón de abajo — el nombre lo eliges tú.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _listas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final lista = _listas[index];
                return Card(
                  child: ListTile(
                    title: Text(lista.nombre),
                    onTap: () => _abrirLista(lista),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Borrar',
                      onPressed: () => _confirmarBorrado(lista),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearLista,
        icon: const Icon(Icons.add),
        label: const Text('Nueva lista'),
      ),
    );
  }
}
