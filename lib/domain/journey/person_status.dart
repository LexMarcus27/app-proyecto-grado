/// Estado de avance de la evaluación de una persona de la red.
///
/// Portado verbatim del prototipo (`src/journey.ts`, tipo `PersonStatus`).
/// Las cadenas (`wireValue`) se preservan exactamente: `pending`, `in-progress`,
/// `complete`.
enum PersonStatus {
  pending('pending'),
  inProgress('in-progress'),
  complete('complete');

  const PersonStatus(this.wireValue);

  /// Cadena exacta del prototipo (TypeScript).
  final String wireValue;

  /// Resuelve un [PersonStatus] a partir de su cadena del prototipo.
  static PersonStatus fromWire(String value) {
    for (final status in PersonStatus.values) {
      if (status.wireValue == value) return status;
    }
    throw ArgumentError.value(value, 'value', 'PersonStatus desconocido');
  }
}
