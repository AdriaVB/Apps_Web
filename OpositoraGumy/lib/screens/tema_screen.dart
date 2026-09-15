import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/pregunta.dart';
import '../models/tema.dart';
import 'configurar_examen_screen.dart';
import 'pregunta_form_screen.dart';

/// Preguntas guardadas en un tema. Aquí es donde se revisan: cada fila
/// muestra el enunciado y un resumen de cuál es la correcta.
class TemaScreen extends StatefulWidget {
  const TemaScreen({super.key, required this.tema});

  final Tema tema;

  @override
  State<TemaScreen> createState() => _TemaScreenState();
}

class _TemaScreenState extends State<TemaScreen> {
  final _datos = AppData.instancia;
  List<Pregunta> _preguntas = [];

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    setState(() => _preguntas = _datos.listarPreguntas(widget.tema.id));
  }

  Future<void> _abrirFormulario({Pregunta? pregunta}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreguntaFormScreen(
          temaId: widget.tema.id,
          preguntaExistente: pregunta,
        ),
      ),
    );
    _recargar();
  }

  Future<void> _confirmarBorrado(Pregunta pregunta) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar pregunta'),
        content: const Text('¿Seguro que quieres borrar esta pregunta?'),
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
      await _datos.borrarPregunta(pregunta.id);
      _recargar();
    }
  }

  void _examenDelTema() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfigurarExamenScreen(
          titulo: 'Examen · ${widget.tema.nombre}',
          preguntasDisponibles: _preguntas,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tema.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz_outlined),
            tooltip: 'Examen del tema',
            onPressed: _preguntas.isEmpty ? null : _examenDelTema,
          ),
        ],
      ),
      body: _preguntas.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Este tema todavía no tiene preguntas. Añade la primera '
                  'con el botón de abajo.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _preguntas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final pregunta = _preguntas[index];
                return Card(
                  child: ListTile(
                    title: Text(pregunta.enunciado),
                    subtitle: Text('Correcta: ${pregunta.respuestaCorrecta}'),
                    onTap: () => _abrirFormulario(pregunta: pregunta),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Borrar',
                      onPressed: () => _confirmarBorrado(pregunta),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva pregunta'),
      ),
    );
  }
}
