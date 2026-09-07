/// Versión sin `dart:io` (se usa en web) — [AppDatabase.paraPruebas] solo se
/// llama desde los tests, que corren en la VM, nunca en un build real de
/// web, así que esta rama nunca debería ejecutarse de verdad.
String rutaTemporalUnica(String nombre) {
  throw UnsupportedError(
    'rutaTemporalUnica solo está disponible en la VM (tests), no en web.',
  );
}
