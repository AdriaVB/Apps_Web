import 'package:flutter/material.dart';

/// Fila de gasto con estilo de tarjeta: nombre, subtítulo (categoría y
/// detalle), importe y borrado. Usada en las listas de gastos fijos y
/// anuales de Configuración.
class FilaGasto extends StatelessWidget {
  const FilaGasto({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.importe,
    required this.onTap,
    required this.onBorrar,
    this.colorImporte,
  });

  final String titulo;
  final String subtitulo;
  final String importe;
  final VoidCallback onTap;
  final VoidCallback onBorrar;

  /// Color del importe (p. ej. verde para un ingreso fijo). Si es nulo, usa
  /// el color de texto por defecto.
  final Color? colorImporte;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: esquema.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                importe,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: colorImporte),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Borrar',
                onPressed: onBorrar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
