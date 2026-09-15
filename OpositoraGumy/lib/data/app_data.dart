import 'package:hive_flutter/hive_flutter.dart';

import '../models/examen_general.dart';
import '../models/pregunta.dart';
import '../models/tema.dart';

/// Punto único de acceso a los datos. Guardados con Hive — en la web usa el
/// almacén local del propio navegador (IndexedDB) por debajo, nada de
/// cuenta ni servidor.
class AppData {
  AppData._();

  static final AppData instancia = AppData._();

  late Box _examenes;
  late Box _temas;
  late Box _preguntas;

  Future<void> abrir() async {
    await Hive.initFlutter();
    _examenes = await Hive.openBox('examenesGenerales');
    _temas = await Hive.openBox('temas');
    _preguntas = await Hive.openBox('preguntas');
  }

  // ---------- ExamenGeneral ----------

  Future<int> crearExamenGeneral(String nombre) {
    return _examenes.add({'nombre': nombre});
  }

  Future<void> renombrarExamenGeneral(int id, String nombre) {
    return _examenes.put(id, {'nombre': nombre});
  }

  List<ExamenGeneral> listarExamenesGenerales() {
    final examenes = [
      for (final entry in _examenes.toMap().entries)
        ExamenGeneral.fromMap(entry.key as int, entry.value as Map),
    ];
    return examenes..sort((a, b) => a.id.compareTo(b.id));
  }

  /// Borra el examen general y, en cascada, sus temas y las preguntas de
  /// esos temas.
  Future<void> borrarExamenGeneral(int id) async {
    for (final tema in listarTemas(id)) {
      await borrarTema(tema.id);
    }
    await _examenes.delete(id);
  }

  // ---------- Tema ----------

  Future<int> crearTema(int examenGeneralId, String nombre) {
    return _temas.add({'examenGeneralId': examenGeneralId, 'nombre': nombre});
  }

  Future<void> renombrarTema(int id, String nombre) async {
    final actual = Tema.fromMap(id, _temas.get(id) as Map);
    await _temas.put(
      id,
      Tema(
        id: id,
        examenGeneralId: actual.examenGeneralId,
        nombre: nombre,
      ).toMap(),
    );
  }

  List<Tema> listarTemas(int examenGeneralId) {
    final temas = [
      for (final entry in _temas.toMap().entries)
        if ((entry.value as Map)['examenGeneralId'] == examenGeneralId)
          Tema.fromMap(entry.key as int, entry.value as Map),
    ];
    return temas..sort((a, b) => a.id.compareTo(b.id));
  }

  /// Borra el tema y, en cascada, sus preguntas.
  Future<void> borrarTema(int id) async {
    final idsPreguntas = [
      for (final entry in _preguntas.toMap().entries)
        if ((entry.value as Map)['temaId'] == id) entry.key as int,
    ];
    await _preguntas.deleteAll(idsPreguntas);
    await _temas.delete(id);
  }

  // ---------- Pregunta ----------

  Future<int> crearPregunta({
    required int temaId,
    required String enunciado,
    required TipoPregunta tipo,
    required List<String> respuestas,
    required int indiceCorrecta,
  }) {
    return _preguntas.add(
      Pregunta(
        id: 0,
        temaId: temaId,
        enunciado: enunciado,
        tipo: tipo,
        respuestas: respuestas,
        indiceCorrecta: indiceCorrecta,
      ).toMap(),
    );
  }

  Future<void> actualizarPregunta(Pregunta pregunta) {
    return _preguntas.put(pregunta.id, pregunta.toMap());
  }

  List<Pregunta> listarPreguntas(int temaId) {
    final preguntas = [
      for (final entry in _preguntas.toMap().entries)
        if ((entry.value as Map)['temaId'] == temaId)
          Pregunta.fromMap(entry.key as int, entry.value as Map),
    ];
    return preguntas..sort((a, b) => a.id.compareTo(b.id));
  }

  /// Todas las preguntas de todos los temas de un examen general — para el
  /// "Examen general" que las mezcla todas.
  List<Pregunta> listarPreguntasDeExamenGeneral(int examenGeneralId) {
    final temas = listarTemas(examenGeneralId);
    return [for (final tema in temas) ...listarPreguntas(tema.id)];
  }

  Future<void> borrarPregunta(int id) {
    return _preguntas.delete(id);
  }

  // ---------- Exportar / Importar ----------

  /// Todo el contenido (exámenes, temas y preguntas) en una sola
  /// estructura, lista para volcar a JSON.
  Map<String, dynamic> exportarTodo() {
    return {
      'examenesGenerales': [
        for (final entry in _examenes.toMap().entries)
          {'id': entry.key, ...(entry.value as Map)},
      ],
      'temas': [
        for (final entry in _temas.toMap().entries)
          {'id': entry.key, ...(entry.value as Map)},
      ],
      'preguntas': [
        for (final entry in _preguntas.toMap().entries)
          {'id': entry.key, ...(entry.value as Map)},
      ],
    };
  }

  /// Sustituye todo el contenido actual por el del archivo importado —
  /// pensado para restaurar una copia de seguridad completa, no para
  /// combinar con lo que ya hubiera.
  Future<void> importarTodo(Map<String, dynamic> datos) async {
    await _examenes.clear();
    await _temas.clear();
    await _preguntas.clear();

    for (final examen in (datos['examenesGenerales'] as List)) {
      final mapa = Map<String, dynamic>.from(examen as Map);
      final id = mapa.remove('id') as int;
      await _examenes.put(id, mapa);
    }
    for (final tema in (datos['temas'] as List)) {
      final mapa = Map<String, dynamic>.from(tema as Map);
      final id = mapa.remove('id') as int;
      await _temas.put(id, mapa);
    }
    for (final pregunta in (datos['preguntas'] as List)) {
      final mapa = Map<String, dynamic>.from(pregunta as Map);
      final id = mapa.remove('id') as int;
      mapa['respuestas'] = (mapa['respuestas'] as List).cast<String>();
      await _preguntas.put(id, mapa);
    }
  }
}
