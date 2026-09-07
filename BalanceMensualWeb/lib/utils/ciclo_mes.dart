/// Calcula el inicio del ciclo-mes al que pertenece [fecha], dado el día de
/// inicio de mes configurado por el usuario (1 = mes natural).
///
/// Ejemplo: diaInicioMes = 25, fecha = 20 de marzo -> el ciclo empezó el
/// 25 de febrero. fecha = 26 de marzo -> el ciclo empieza el 25 de marzo.
DateTime inicioDeCiclo(DateTime fecha, int diaInicioMes) {
  final antesDelCorte = fecha.day < diaInicioMes;
  final anio = antesDelCorte && fecha.month == 1 ? fecha.year - 1 : fecha.year;
  final mes = antesDelCorte
      ? (fecha.month == 1 ? 12 : fecha.month - 1)
      : fecha.month;

  final ultimoDiaDelMes = DateTime(anio, mes + 1, 0).day;
  final dia = diaInicioMes > ultimoDiaDelMes ? ultimoDiaDelMes : diaInicioMes;

  return DateTime(anio, mes, dia);
}

/// Último día del ciclo-mes al que pertenece [fecha] (el día antes de que
/// empiece el siguiente ciclo).
DateTime finDeCiclo(DateTime fecha, int diaInicioMes) {
  final inicioActual = inicioDeCiclo(fecha, diaInicioMes);
  // Una fecha con seguridad dentro del siguiente ciclo, sin importar cuántos
  // días tenga el mes actual.
  final dentroDelSiguiente = DateTime(
    inicioActual.year,
    inicioActual.month + 1,
    inicioActual.day,
  );
  final inicioSiguiente = inicioDeCiclo(dentroDelSiguiente, diaInicioMes);
  return inicioSiguiente.subtract(const Duration(days: 1));
}

/// Representación estable (yyyy-MM-dd) del ciclo-mes, para guardar en la
/// base de datos y agrupar Movimientos.
String claveCiclo(DateTime fecha, int diaInicioMes) {
  final inicio = inicioDeCiclo(fecha, diaInicioMes);
  return _formatearFecha(inicio);
}

String _formatearFecha(DateTime fecha) {
  final mm = fecha.month.toString().padLeft(2, '0');
  final dd = fecha.day.toString().padLeft(2, '0');
  return '${fecha.year}-$mm-$dd';
}

/// Fecha (sin hora) en la que un cambio de día de inicio de mes, pedido
/// [hoy], debería empezar a aplicarse: la próxima vez que el mes llegue a
/// [diaNuevo] — este mismo mes si ese día todavía no ha pasado (o es hoy),
/// o el que viene si ya pasó. Así el ciclo ya abierto nunca se ve alterado
/// a media, solo los que empiezan después de la transición.
DateTime fechaTransicionCiclo(DateTime hoy, int diaNuevo) {
  final esEsteMes = diaNuevo >= hoy.day;
  final anio = esEsteMes || hoy.month != 12 ? hoy.year : hoy.year + 1;
  final mes = esEsteMes ? hoy.month : (hoy.month == 12 ? 1 : hoy.month + 1);

  final ultimoDiaDelMes = DateTime(anio, mes + 1, 0).day;
  final dia = diaNuevo > ultimoDiaDelMes ? ultimoDiaDelMes : diaNuevo;
  return DateTime(anio, mes, dia);
}

/// [claveCiclo] de [fechaTransicionCiclo], para guardar en
/// ConfiguracionUsuario.fechaAplicacionPendiente.
String claveTransicionCiclo(DateTime hoy, int diaNuevo) =>
    _formatearFecha(fechaTransicionCiclo(hoy, diaNuevo));
