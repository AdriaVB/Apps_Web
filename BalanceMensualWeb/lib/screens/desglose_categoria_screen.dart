import 'package:flutter/material.dart';

import '../models/movimiento.dart';
import '../theme/app_theme.dart';
import '../utils/comparacion_categoria.dart';
import '../widgets/grafico_donut.dart';

/// Versión grande del donut de una pantalla de detalle de mes, con leyenda:
/// cada categoría con su importe y el porcentaje que representa sobre el
/// total.
class DesgloseCategoriaScreen extends StatelessWidget {
  const DesgloseCategoriaScreen({
    super.key,
    required this.titulo,
    required this.segmentos,
    required this.tipo,
    this.comparaciones = const {},
  });

  final String titulo;
  final List<SegmentoDonut> segmentos;

  /// Para saber si "por encima de tu media" es bueno (ingreso) o malo
  /// (gasto) a la hora de colorear la comparación.
  final TipoMovimiento tipo;

  /// Comparación con la media histórica y el récord del año, por
  /// categoriaId. Vacío cuando no aplica (p. ej. el desglose de un año
  /// completo, donde "un mes frente a otros" no tiene sentido).
  final Map<int, ComparacionCategoria> comparaciones;

  @override
  Widget build(BuildContext context) {
    final ordenados = [...segmentos]
      ..sort((a, b) => b.importe.compareTo(a.importe));
    final total = segmentos.fold<double>(0, (t, s) => t + s.importe);

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          children: [
            Center(
              child: GraficoDonut(
                segmentos: ordenados,
                tamano: 220,
                centro: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${total.toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: ListView.separated(
                itemCount: ordenados.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final segmento = ordenados[index];
                  final porcentaje = total > 0
                      ? (segmento.importe / total) * 100
                      : 0.0;
                  return _FilaLeyenda(
                    segmento: segmento,
                    porcentaje: porcentaje,
                    tipo: tipo,
                    comparacion: comparaciones[segmento.categoriaId],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaLeyenda extends StatelessWidget {
  const _FilaLeyenda({
    required this.segmento,
    required this.porcentaje,
    required this.tipo,
    this.comparacion,
  });

  final SegmentoDonut segmento;
  final double porcentaje;
  final TipoMovimiento tipo;
  final ComparacionCategoria? comparacion;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final comparacion = this.comparacion;
    final diferencia = comparacion == null
        ? null
        : _diferenciaPorcentual(comparacion, segmento.importe);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: segmento.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    segmento.nombre,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${porcentaje.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: esquema.onSurfaceVariant),
                  ),
                  if (comparacion != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _textoComparacion(diferencia!, comparacion.media),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _colorComparacion(context, tipo, diferencia),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (comparacion?.esRecordDelAnio == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Récord del año',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: esquema.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '${segmento.importe.toStringAsFixed(2)} €',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

double _diferenciaPorcentual(ComparacionCategoria comparacion, double importe) {
  return ((importe - comparacion.media) / comparacion.media) * 100;
}

String _textoComparacion(double diferencia, double media) {
  final direccion = diferencia >= 0 ? 'por encima' : 'por debajo';
  return 'Un ${diferencia.abs().toStringAsFixed(0)}% $direccion de tu media '
      '(${media.toStringAsFixed(2)} €)';
}

/// "Por encima de tu media" es bueno en un ingreso y malo en un gasto — y al
/// revés para "por debajo". Sin diferencia, color neutro.
Color _colorComparacion(
  BuildContext context,
  TipoMovimiento tipo,
  double diferencia,
) {
  if (diferencia == 0) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
  final favorable = tipo == TipoMovimiento.gasto
      ? diferencia < 0
      : diferencia > 0;
  return favorable ? AppTheme.positivo(context) : AppTheme.negativo(context);
}
