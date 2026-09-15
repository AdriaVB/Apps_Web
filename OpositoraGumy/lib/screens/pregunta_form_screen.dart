import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/pregunta.dart';

/// Alta/edición de una pregunta. El formulario cambia según el tipo:
/// opción múltiple pide 4 respuestas escritas, verdadero/falso no pide
/// ningún texto de respuesta (son fijas).
class PreguntaFormScreen extends StatefulWidget {
  const PreguntaFormScreen({
    super.key,
    required this.temaId,
    this.preguntaExistente,
  });

  final int temaId;
  final Pregunta? preguntaExistente;

  @override
  State<PreguntaFormScreen> createState() => _PreguntaFormScreenState();
}

class _PreguntaFormScreenState extends State<PreguntaFormScreen> {
  final _db = AppData.instancia;
  final _formKey = GlobalKey<FormState>();
  final _enunciadoController = TextEditingController();
  final _respuestaControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  TipoPregunta _tipo = TipoPregunta.opcionMultiple;
  int _indiceCorrecta = 0;

  bool get _esEdicion => widget.preguntaExistente != null;

  @override
  void initState() {
    super.initState();
    final pregunta = widget.preguntaExistente;
    if (pregunta != null) {
      _enunciadoController.text = pregunta.enunciado;
      _tipo = pregunta.tipo;
      _indiceCorrecta = pregunta.indiceCorrecta;
      if (pregunta.tipo == TipoPregunta.opcionMultiple) {
        for (var i = 0; i < pregunta.respuestas.length; i++) {
          _respuestaControllers[i].text = pregunta.respuestas[i];
        }
      }
    }
  }

  @override
  void dispose() {
    _enunciadoController.dispose();
    for (final c in _respuestaControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final respuestas = _tipo == TipoPregunta.opcionMultiple
        ? [for (final c in _respuestaControllers) c.text.trim()]
        : respuestasVerdaderoFalso;

    if (_esEdicion) {
      final actualizada = Pregunta(
        id: widget.preguntaExistente!.id,
        temaId: widget.temaId,
        enunciado: _enunciadoController.text.trim(),
        tipo: _tipo,
        respuestas: respuestas,
        indiceCorrecta: _indiceCorrecta,
      );
      await _db.actualizarPregunta(actualizada);
    } else {
      await _db.crearPregunta(
        temaId: widget.temaId,
        enunciado: _enunciadoController.text.trim(),
        tipo: _tipo,
        respuestas: respuestas,
        indiceCorrecta: _indiceCorrecta,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar pregunta' : 'Nueva pregunta'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<TipoPregunta>(
              segments: const [
                ButtonSegment(
                  value: TipoPregunta.opcionMultiple,
                  label: Text('Opción múltiple'),
                ),
                ButtonSegment(
                  value: TipoPregunta.verdaderoFalso,
                  label: Text('Verdadero / Falso'),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (seleccion) {
                setState(() {
                  _tipo = seleccion.first;
                  _indiceCorrecta = 0;
                });
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _enunciadoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Enunciado',
                hintText: '¿Qué año se aprobó la Constitución Española?',
                alignLabelWithHint: true,
              ),
              validator: (valor) => (valor == null || valor.trim().isEmpty)
                  ? 'El enunciado es obligatorio'
                  : null,
            ),
            const SizedBox(height: 20),
            RadioGroup<int>(
              groupValue: _indiceCorrecta,
              onChanged: (valor) => setState(() => _indiceCorrecta = valor!),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _tipo == TipoPregunta.opcionMultiple
                    ? _camposOpcionMultiple()
                    : [_camposVerdaderoFalso()],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _guardar,
            child: const Text('Guardar'),
          ),
        ),
      ),
    );
  }

  List<Widget> _camposOpcionMultiple() {
    const letras = ['A', 'B', 'C', 'D'];
    return [
      Text(
        'Respuestas — marca cuál es la correcta',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 8),
      for (var i = 0; i < 4; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Radio<int>(value: i),
              Expanded(
                child: TextFormField(
                  controller: _respuestaControllers[i],
                  decoration: InputDecoration(
                    labelText: 'Respuesta ${letras[i]}',
                  ),
                  validator: (valor) => (valor == null || valor.trim().isEmpty)
                      ? 'Obligatoria'
                      : null,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _camposVerdaderoFalso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¿Cuál es la correcta?',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        const RadioListTile<int>(
          contentPadding: EdgeInsets.zero,
          title: Text('Verdadero'),
          value: 0,
        ),
        const RadioListTile<int>(
          contentPadding: EdgeInsets.zero,
          title: Text('Falso'),
          value: 1,
        ),
      ],
    );
  }
}
