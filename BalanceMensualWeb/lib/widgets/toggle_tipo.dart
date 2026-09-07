import 'package:flutter/material.dart';

import '../models/movimiento.dart';
import '../theme/app_theme.dart';

/// Un único botón que alterna entre Gasto (rojo) e Ingreso (verde) al
/// pulsarlo, en vez de un selector con dos opciones. Usado tanto en el alta
/// de movimientos variables como en el alta de gastos/ingresos fijos.
class ToggleTipo extends StatelessWidget {
  const ToggleTipo({super.key, required this.tipo, required this.onTap});

  final TipoMovimiento tipo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esGasto = tipo == TipoMovimiento.gasto;
    final color = esGasto
        ? AppTheme.negativo(context)
        : AppTheme.positivo(context);

    return Material(
      color: color,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                esGasto
                    ? Icons.remove_circle_outline
                    : Icons.add_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                esGasto ? 'Gasto' : 'Ingreso',
                style: const TextStyle(
                  color: Colors.white,
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
