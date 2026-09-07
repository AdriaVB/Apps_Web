import 'dart:math';

import 'package:flutter/material.dart';

import '../models/movimiento.dart';

/// Una porción del donut: nombre de la categoría, su importe (positivo) y
/// el color con el que se dibuja.
class SegmentoDonut {
  const SegmentoDonut({
    required this.categoriaId,
    required this.nombre,
    required this.importe,
    required this.color,
  });

  final int categoriaId;
  final String nombre;
  final double importe;
  final Color color;
}

/// Suma el importe de [movimientos] por categoría y le asigna un color de
/// [paleta] a cada una, de mayor a menor importe. Usado tanto en el detalle
/// de un mes como en el de un año.
List<SegmentoDonut> agruparEnSegmentos(
  List<Movimiento> movimientos,
  Map<int, String> nombresCategoria,
  List<Color> Function(int) paleta,
) {
  final totales = <int, double>{};
  for (final m in movimientos) {
    totales[m.categoriaId] = (totales[m.categoriaId] ?? 0) + m.importe;
  }
  final entradas = totales.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final colores = paleta(entradas.length);
  return [
    for (var i = 0; i < entradas.length; i++)
      SegmentoDonut(
        categoriaId: entradas[i].key,
        nombre: nombresCategoria[entradas[i].key] ?? 'Sin categoría',
        importe: entradas[i].value,
        color: colores[i],
      ),
  ];
}

/// Gráfico de anillo (donut): reparte [segmentos] proporcionalmente a su
/// importe sobre el total. Si se pasa [centro], se dibuja encima, centrado
/// (pensado para el importe total en la versión grande del gráfico).
class GraficoDonut extends StatelessWidget {
  const GraficoDonut({
    super.key,
    required this.segmentos,
    required this.tamano,
    this.grosor,
    this.centro,
  });

  final List<SegmentoDonut> segmentos;
  final double tamano;
  final double? grosor;
  final Widget? centro;

  @override
  Widget build(BuildContext context) {
    final total = segmentos.fold<double>(0, (t, s) => t + s.importe);
    return SizedBox(
      width: tamano,
      height: tamano,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(tamano),
            painter: _DonutPainter(
              segmentos: segmentos,
              total: total,
              grosor: grosor ?? tamano * 0.22,
            ),
          ),
          ?centro,
        ],
      ),
    );
  }
}

/// Donut pequeño con su título y el total debajo, pulsable — pensado para
/// mostrar dos de estos (ingresos/gastos) en la cabecera del detalle de un
/// mes o de un año.
class MiniDonut extends StatelessWidget {
  const MiniDonut({
    super.key,
    required this.titulo,
    required this.color,
    required this.segmentos,
    required this.onTap,
  });

  final String titulo;
  final Color color;
  final List<SegmentoDonut> segmentos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = segmentos.fold<double>(0, (t, s) => t + s.importe);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            GraficoDonut(segmentos: segmentos, tamano: 88),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: color),
            ),
            Text(
              '${total.toStringAsFixed(2)} €',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segmentos,
    required this.total,
    required this.grosor,
  });

  final List<SegmentoDonut> segmentos;
  final double total;
  final double grosor;

  /// Hueco entre porciones (en radianes), solo visible si hay más de una.
  static const _hueco = 0.045;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0 || segmentos.isEmpty) return;

    final centro = Offset(size.width / 2, size.height / 2);
    final radio = (size.shortestSide - grosor) / 2;
    final rect = Rect.fromCircle(center: centro, radius: radio);
    final hayVarios = segmentos.length > 1;

    var inicio = -pi / 2;
    for (final segmento in segmentos) {
      final barrido = (segmento.importe / total) * 2 * pi;
      final paint = Paint()
        ..color = segmento.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..strokeCap = StrokeCap.round;
      final barridoDibujado = hayVarios ? max(barrido - _hueco, 0.01) : barrido;
      canvas.drawArc(rect, inicio, barridoDibujado, false, paint);
      inicio += barrido;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.segmentos != segmentos ||
        oldDelegate.total != total ||
        oldDelegate.grosor != grosor;
  }
}
