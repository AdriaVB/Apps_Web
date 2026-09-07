import 'package:flutter/material.dart';

/// Botón de acción principal con forma de píldora: fondo de color sólido,
/// icono y texto centrados. Usado para las acciones de "añadir" en toda
/// la app (pantalla principal, gastos fijos, gastos anuales...).
class BotonPildora extends StatelessWidget {
  const BotonPildora({
    super.key,
    required this.texto,
    required this.onTap,
    this.icono = Icons.add,
  });

  final String texto;
  final IconData icono;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Material(
      color: esquema.primary,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, color: esquema.onPrimary),
              const SizedBox(width: 8),
              Text(
                texto,
                style: TextStyle(
                  color: esquema.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
