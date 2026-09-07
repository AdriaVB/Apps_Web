import 'package:flutter_test/flutter_test.dart';

import 'package:checklist/models/elemento_lista.dart';
import 'package:checklist/models/lista.dart';

void main() {
  group('Lista', () {
    test('fromMap/toMap hacen el viaje de ida y vuelta', () {
      const lista = Lista(id: 3, nombre: 'Videojuegos');
      final reconstruida = Lista.fromMap(lista.id, lista.toMap());
      expect(reconstruida.id, lista.id);
      expect(reconstruida.nombre, lista.nombre);
    });

    test('copyWith solo cambia lo indicado', () {
      const lista = Lista(id: 1, nombre: 'Tareas de casa');
      final renombrada = lista.copyWith(nombre: 'Tareas');
      expect(renombrada.id, 1);
      expect(renombrada.nombre, 'Tareas');
    });
  });

  group('ElementoLista', () {
    test('fromMap/toMap hacen el viaje de ida y vuelta', () {
      const elemento = ElementoLista(
        id: 5,
        listaId: 1,
        texto: 'Fregar el suelo',
        completado: true,
      );
      final reconstruido = ElementoLista.fromMap(elemento.id, elemento.toMap());
      expect(reconstruido.id, elemento.id);
      expect(reconstruido.listaId, elemento.listaId);
      expect(reconstruido.texto, elemento.texto);
      expect(reconstruido.completado, elemento.completado);
    });

    test('copyWith cambia completado sin tocar el resto', () {
      const elemento = ElementoLista(
        id: 2,
        listaId: 1,
        texto: 'Poner la lavadora',
      );
      final marcado = elemento.copyWith(completado: true);
      expect(marcado.completado, isTrue);
      expect(marcado.texto, elemento.texto);
      expect(marcado.listaId, elemento.listaId);
    });
  });
}
