import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/examen_general.dart';
import '../models/tema.dart';
import 'configurar_examen_screen.dart';

/// Elegir con qué temas concretos examinarse (p. ej. solo el 1, 2, 3 y 7 de
/// todos los que hay), en vez de un tema suelto o todos a la vez.
class SeleccionarTemasScreen extends StatefulWidget {
  const SeleccionarTemasScreen({
    super.key,
    required this.examenGeneral,
    required this.temas,
  });

  final ExamenGeneral examenGeneral;
  final List<Tema> temas;

  @override
  State<SeleccionarTemasScreen> createState() => _SeleccionarTemasScreenState();
}

class _SeleccionarTemasScreenState extends State<SeleccionarTemasScreen> {
  final _datos = AppData.instancia;
  final Set<int> _seleccionados = {};

  void _continuar() {
    final preguntas = [
      for (final tema in widget.temas)
        if (_seleccionados.contains(tema.id))
          ..._datos.listarPreguntas(tema.id),
    ];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfigurarExamenScreen(
          titulo: 'Examen · ${_seleccionados.length} temas',
          preguntasDisponibles: preguntas,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elegir temas')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: widget.temas.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final tema = widget.temas[index];
          final total = _datos.listarPreguntas(tema.id).length;
          return CheckboxListTile(
            title: Text(tema.nombre),
            subtitle: Text(
              total == 0
                  ? 'Sin preguntas todavía'
                  : '$total pregunta${total == 1 ? '' : 's'}',
            ),
            value: _seleccionados.contains(tema.id),
            onChanged: total == 0
                ? null
                : (marcado) => setState(() {
                    if (marcado == true) {
                      _seleccionados.add(tema.id);
                    } else {
                      _seleccionados.remove(tema.id);
                    }
                  }),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _seleccionados.isEmpty ? null : _continuar,
            child: Text(
              _seleccionados.isEmpty
                  ? 'Elige al menos un tema'
                  : 'Continuar con ${_seleccionados.length} '
                        'tema${_seleccionados.length == 1 ? '' : 's'}',
            ),
          ),
        ),
      ),
    );
  }
}
