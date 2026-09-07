import 'package:flutter/material.dart';

/// Estructura común para las pantallas de formulario de Configuración:
/// contenido centrado verticalmente en el área disponible con un botón
/// grande de guardar al final, y opcionalmente una nota al fondo de la
/// pantalla (misma altura que "Historial" en la pantalla principal).
class FormularioCentrado extends StatelessWidget {
  const FormularioCentrado({
    super.key,
    required this.children,
    required this.onGuardar,
    this.textoBoton = 'Guardar',
    this.notaInferior,
  });

  final List<Widget> children;
  final VoidCallback onGuardar;
  final String textoBoton;
  final Widget? notaInferior;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        children: [
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
                          ...children,
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onPressed: onGuardar,
                                  child: Text(textoBoton),
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
          ?notaInferior,
        ],
      ),
    );
  }
}
