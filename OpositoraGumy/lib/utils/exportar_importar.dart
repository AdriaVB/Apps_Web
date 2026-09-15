import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_data.dart';

/// Vuelca todo lo guardado a un archivo .json y abre el menú de
/// compartir/guardar del navegador. Sin guardado silencioso: quien lo use
/// decide dónde termina el archivo.
Future<void> exportarACopia(AppData datos) async {
  final json = const JsonEncoder.withIndent('  ').convert(datos.exportarTodo());
  final bytes = Uint8List.fromList(utf8.encode(json));

  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          bytes,
          name: 'opositoragumy_copia.json',
          mimeType: 'application/json',
        ),
      ],
      subject: 'Copia de seguridad de OpositoraGumy',
    ),
  );
}

/// Abre el selector de archivos, lee el .json elegido y sustituye todo el
/// contenido actual por el de la copia. Nulo si el usuario cancela la
/// selección.
Future<bool> importarDesdeCopia(AppData datos) async {
  const tipo = XTypeGroup(label: 'json', extensions: ['json']);
  final archivo = await openFile(acceptedTypeGroups: [tipo]);
  if (archivo == null) return false;

  final contenido = await archivo.readAsString();
  final mapa = jsonDecode(contenido) as Map<String, dynamic>;
  await datos.importarTodo(mapa);
  return true;
}
