import 'package:hive_flutter/hive_flutter.dart';

import '../models/elemento_lista.dart';
import '../models/lista.dart';

/// Punto único de acceso a los datos. Guardados con Hive — en la web usa el
/// almacén local del propio navegador (IndexedDB) por debajo, nada de
/// cuenta ni servidor.
class AppData {
  AppData._();

  static final AppData instancia = AppData._();

  late Box _listas;
  late Box _elementos;

  Future<void> abrir() async {
    await Hive.initFlutter();
    _listas = await Hive.openBox('listas');
    _elementos = await Hive.openBox('elementos');
  }

  // ---------- Lista ----------

  Future<int> crearLista(String nombre) {
    return _listas.add({'nombre': nombre});
  }

  List<Lista> listarListas() {
    final listas = [
      for (final entry in _listas.toMap().entries)
        Lista.fromMap(entry.key as int, entry.value as Map),
    ];
    return listas..sort((a, b) => a.id.compareTo(b.id));
  }

  Future<void> renombrarLista(int id, String nombre) {
    return _listas.put(id, {'nombre': nombre});
  }

  /// Borra la lista y todos sus elementos.
  Future<void> borrarLista(int id) async {
    final idsElementos = [
      for (final entry in _elementos.toMap().entries)
        if ((entry.value as Map)['listaId'] == id) entry.key as int,
    ];
    await _elementos.deleteAll(idsElementos);
    await _listas.delete(id);
  }

  // ---------- ElementoLista ----------

  Future<int> crearElemento(int listaId, String texto) {
    return _elementos.add({
      'listaId': listaId,
      'texto': texto,
      'completado': false,
    });
  }

  List<ElementoLista> listarElementos(int listaId) {
    final elementos = [
      for (final entry in _elementos.toMap().entries)
        if ((entry.value as Map)['listaId'] == listaId)
          ElementoLista.fromMap(entry.key as int, entry.value as Map),
    ];
    return elementos..sort((a, b) => a.id.compareTo(b.id));
  }

  Future<void> marcarCompletado(ElementoLista elemento, bool completado) {
    return _elementos.put(
      elemento.id,
      elemento.copyWith(completado: completado).toMap(),
    );
  }

  Future<void> borrarElemento(int id) {
    return _elementos.delete(id);
  }
}
