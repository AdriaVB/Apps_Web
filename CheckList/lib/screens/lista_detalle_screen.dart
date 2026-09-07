import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/elemento_lista.dart';
import '../models/lista.dart';

/// Elementos de una lista concreta: añadir, marcar como hecho, borrar.
class ListaDetalleScreen extends StatefulWidget {
  const ListaDetalleScreen({super.key, required this.lista});

  final Lista lista;

  @override
  State<ListaDetalleScreen> createState() => _ListaDetalleScreenState();
}

class _ListaDetalleScreenState extends State<ListaDetalleScreen> {
  final _datos = AppData.instancia;
  final _textoController = TextEditingController();
  List<ElementoLista> _elementos = [];

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      _elementos = _datos.listarElementos(widget.lista.id);
    });
  }

  Future<void> _anadir() async {
    final texto = _textoController.text.trim();
    if (texto.isEmpty) return;
    await _datos.crearElemento(widget.lista.id, texto);
    _textoController.clear();
    _recargar();
  }

  Future<void> _marcar(ElementoLista elemento, bool valor) async {
    await _datos.marcarCompletado(elemento, valor);
    _recargar();
  }

  Future<void> _borrar(ElementoLista elemento) async {
    await _datos.borrarElemento(elemento.id);
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lista.nombre)),
      body: Column(
        children: [
          Expanded(
            child: _elementos.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Esta lista todavía no tiene nada. Añade el '
                        'primer elemento aquí abajo.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _elementos.length,
                    itemBuilder: (context, index) {
                      final elemento = _elementos[index];
                      return CheckboxListTile(
                        value: elemento.completado,
                        onChanged: (valor) => _marcar(elemento, valor ?? false),
                        title: Text(
                          elemento.texto,
                          style: elemento.completado
                              ? const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                )
                              : null,
                        ),
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Borrar',
                          onPressed: () => _borrar(elemento),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textoController,
                      decoration: const InputDecoration(
                        hintText: 'Nuevo elemento',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _anadir(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    tooltip: 'Añadir',
                    onPressed: _anadir,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
