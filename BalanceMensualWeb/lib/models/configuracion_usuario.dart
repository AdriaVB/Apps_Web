class ConfiguracionUsuario {
  final int diaInicioMes;

  /// Si ya pasó por la pantalla de bienvenida (elegir día de inicio de
  /// mes) al menos una vez. Distingue "el usuario eligió 1" de "todavía no
  /// se ha configurado nada y 1 es solo el valor de partida".
  final bool onboardingCompletado;

  final bool modoOscuro;

  /// Cambio de día de inicio de mes en cola, todavía sin aplicar — para no
  /// alterar el ciclo ya abierto a media. Los dos van juntos: si uno es
  /// nulo, el otro también. Ver [fechaTransicionCiclo] en ciclo_mes.dart
  /// para cómo se calcula [fechaAplicacionPendiente].
  final int? diaInicioMesPendiente;

  /// Fecha (yyyy-MM-dd) en la que [diaInicioMesPendiente] pasa a ser
  /// [diaInicioMes]. Se resuelve solo, la próxima vez que se lea la
  /// configuración en o después de esa fecha (ver AppDatabase.obtenerConfiguracion).
  final String? fechaAplicacionPendiente;

  const ConfiguracionUsuario({
    required this.diaInicioMes,
    this.onboardingCompletado = false,
    this.modoOscuro = false,
    this.diaInicioMesPendiente,
    this.fechaAplicacionPendiente,
  });

  factory ConfiguracionUsuario.fromMap(Map<String, Object?> map) {
    return ConfiguracionUsuario(
      diaInicioMes: map['diaInicioMes'] as int,
      onboardingCompletado: (map['onboardingCompletado'] as int) == 1,
      modoOscuro: (map['modoOscuro'] as int) == 1,
      diaInicioMesPendiente: map['diaInicioMesPendiente'] as int?,
      fechaAplicacionPendiente: map['fechaAplicacionPendiente'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': 1,
      'diaInicioMes': diaInicioMes,
      'onboardingCompletado': onboardingCompletado ? 1 : 0,
      'modoOscuro': modoOscuro ? 1 : 0,
      'diaInicioMesPendiente': diaInicioMesPendiente,
      'fechaAplicacionPendiente': fechaAplicacionPendiente,
    };
  }

  ConfiguracionUsuario copyWith({
    int? diaInicioMes,
    bool? onboardingCompletado,
    bool? modoOscuro,
  }) {
    return ConfiguracionUsuario(
      diaInicioMes: diaInicioMes ?? this.diaInicioMes,
      onboardingCompletado: onboardingCompletado ?? this.onboardingCompletado,
      modoOscuro: modoOscuro ?? this.modoOscuro,
      diaInicioMesPendiente: diaInicioMesPendiente,
      fechaAplicacionPendiente: fechaAplicacionPendiente,
    );
  }

  /// Pone en cola un cambio de día de inicio de mes, o lo quita si
  /// [diaInicioMesPendiente] es nulo — a diferencia de [copyWith], sí puede
  /// limpiar el campo.
  ConfiguracionUsuario conCambioPendiente(
    int? diaInicioMesPendiente,
    String? fechaAplicacionPendiente,
  ) {
    return ConfiguracionUsuario(
      diaInicioMes: diaInicioMes,
      onboardingCompletado: onboardingCompletado,
      modoOscuro: modoOscuro,
      diaInicioMesPendiente: diaInicioMesPendiente,
      fechaAplicacionPendiente: fechaAplicacionPendiente,
    );
  }

  static const ConfiguracionUsuario porDefecto = ConfiguracionUsuario(
    diaInicioMes: 1,
    onboardingCompletado: false,
    modoOscuro: false,
  );
}
