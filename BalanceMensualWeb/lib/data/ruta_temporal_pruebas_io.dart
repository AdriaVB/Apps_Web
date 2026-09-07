import 'dart:io';

import 'package:path/path.dart' as p;

/// Ruta de archivo temporal real, para las bases de datos aisladas que usan
/// los tests (vía `sqflite_common_ffi` en la VM).
String rutaTemporalUnica(String nombre) {
  return p.join(Directory.systemTemp.path, nombre);
}
