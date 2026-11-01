/// Tipo de relación de una persona de la red de apoyo.
///
/// Portado verbatim del prototipo (`src/journey.ts`, tipo `RelationshipType`).
/// En el prototipo es una unión de cadenas literales; aquí se modela como un
/// enum cuyas cadenas (`wireValue`) se preservan exactamente, incluyendo acentos
/// y mayúsculas: `Familia`, `Amistades`, `Pareja`, `Trabajo o estudio`,
/// `Comunidad, servicio o credo`, `Otro`.
enum RelationshipType {
  familia('Familia'),
  amistades('Amistades'),
  pareja('Pareja'),
  trabajoOEstudio('Trabajo o estudio'),
  comunidadServicioOCredo('Comunidad, servicio o credo'),
  otro('Otro');

  const RelationshipType(this.wireValue);

  /// Cadena exacta del prototipo (TypeScript).
  final String wireValue;

  /// Resuelve un [RelationshipType] a partir de su cadena del prototipo.
  static RelationshipType fromWire(String value) {
    for (final type in RelationshipType.values) {
      if (type.wireValue == value) return type;
    }
    throw ArgumentError.value(value, 'value', 'RelationshipType desconocido');
  }
}
