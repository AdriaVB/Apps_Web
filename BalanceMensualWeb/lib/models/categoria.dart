enum TipoCategoria { recurrente, variable, ingreso }

/// Categoría de gasto/ingreso. Cada una pertenece a un [tipo]:
/// - [TipoCategoria.recurrente]: para gastos fijos (luz, alquiler...)
/// - [TipoCategoria.variable]: para gastos puntuales (comida, ocio...)
/// - [TipoCategoria.ingreso]: para cualquier ingreso, fijo o variable
///   (nómina, bizum...) — un mismo catálogo para los dos, porque de dónde
///   viene el dinero no depende de si es recurrente o no.
///
/// Son catálogos separados a propósito: un gasto fijo nunca se registra
/// como movimiento variable (siempre nace en Configuración), así que no
/// tiene sentido que compartan lista de categorías.
class Categoria {
  final int? id;
  final String nombre;
  final TipoCategoria tipo;

  const Categoria({this.id, required this.nombre, required this.tipo});

  factory Categoria.fromMap(Map<String, Object?> map) {
    return Categoria(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      tipo: TipoCategoria.values.byName(map['tipo'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {if (id != null) 'id': id, 'nombre': nombre, 'tipo': tipo.name};
  }

  static const List<String> catalogoRecurrente = [
    'luz',
    'agua',
    'alquiler',
    'hipoteca',
    'seguros',
    'impuestos',
    'otros',
  ];

  static const List<String> catalogoVariable = [
    'comida',
    'restaurantes',
    'ocio',
    'gasolina',
    'gastos coche',
    'gastos casa',
    'salud/higiene',
    'otros',
  ];

  static const List<String> catalogoIngreso = [
    'nómina',
    'autónomo/freelance',
    'bizum',
    'alquiler cobrado',
    'ventas',
    'reembolsos/devoluciones',
    'ayudas/pensión',
    'otros',
  ];
}
