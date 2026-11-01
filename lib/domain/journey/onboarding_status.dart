/// Estado del recorrido de onboarding del PCS.
///
/// Portado verbatim del prototipo (`src/journey.ts`, tipo `OnboardingStatus`).
/// Las cadenas (`wireValue`) se preservan exactamente: `not-started`,
/// `in-progress`, `completed`, `deferred`.
enum OnboardingStatus {
  notStarted('not-started'),
  inProgress('in-progress'),
  completed('completed'),
  deferred('deferred');

  const OnboardingStatus(this.wireValue);

  /// Cadena exacta del prototipo (TypeScript).
  final String wireValue;

  /// Resuelve un [OnboardingStatus] a partir de su cadena del prototipo.
  static OnboardingStatus fromWire(String value) {
    for (final status in OnboardingStatus.values) {
      if (status.wireValue == value) return status;
    }
    throw ArgumentError.value(value, 'value', 'OnboardingStatus desconocido');
  }
}
