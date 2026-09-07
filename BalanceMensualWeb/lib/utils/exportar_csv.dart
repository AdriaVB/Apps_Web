import 'dart:convert';

import 'package:share_plus/share_plus.dart';

import '../models/movimiento.dart';

/// Genera un CSV con [movimientos] y abre el menú de compartir para
/// enviarlo (Drive, WhatsApp, correo...). Se genera en memoria, sin tocar
/// el sistema de archivos — funciona igual en Android y en la web.
///
/// Separador `;` y decimales con coma, para que Excel/Sheets en español lo
/// abran bien al vuelo sin pedir un asistente de importación.
Future<void> exportarMovimientosCsv({
  required List<Movimiento> movimientos,
  required Map<int, String> nombresCategoria,
  required String nombreArchivo,
  required String tituloCompartir,
}) async {
  final ordenados = [...movimientos]
    ..sort((a, b) => a.cicloMes.compareTo(b.cicloMes));

  final buffer = StringBuffer('Ciclo;Tipo;Origen;Categoría;Nombre;Importe\n');
  for (final m in ordenados) {
    final tipo = m.tipo == TipoMovimiento.ingreso ? 'Ingreso' : 'Gasto';
    final origen = m.origen == OrigenMovimiento.fijo ? 'Fijo' : 'Variable';
    final categoria = nombresCategoria[m.categoriaId] ?? 'Sin categoría';
    final importe = m.importe.toStringAsFixed(2).replaceAll('.', ',');
    buffer.writeln(
      '${m.cicloMes};$tipo;$origen;${_celda(categoria)};${_celda(m.nombre)};$importe',
    );
  }

  final bytes = utf8.encode(buffer.toString());

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, name: nombreArchivo, mimeType: 'text/csv')],
      subject: tituloCompartir,
    ),
  );
}

String _celda(String valor) {
  if (valor.contains(';') || valor.contains('"') || valor.contains('\n')) {
    return '"${valor.replaceAll('"', '""')}"';
  }
  return valor;
}

/// Convierte una etiqueta como "marzo 2026" en un nombre de archivo válido:
/// "balance_marzo_2026.csv".
String nombreArchivoExportacion(String etiqueta) {
  final normalizado = etiqueta
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9áéíóúñ]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return 'balance_$normalizado.csv';
}
