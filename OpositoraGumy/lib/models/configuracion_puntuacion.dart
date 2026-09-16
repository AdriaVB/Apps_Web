/// Cómo se puntúa un examen: si los fallos restan puntos y, si es así,
/// cuánto suma un acierto y cuánto resta un fallo.
class ConfiguracionPuntuacion {
  final bool restarErrores;
  final double puntosPorAcierto;
  final double puntosPorFallo;

  const ConfiguracionPuntuacion({
    this.restarErrores = false,
    this.puntosPorAcierto = 1,
    this.puntosPorFallo = 0,
  });
}
