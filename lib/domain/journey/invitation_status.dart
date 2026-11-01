/// Estados de invitación de una persona de la red de apoyo.
///
/// Portado verbatim del prototipo (`src/journey.ts`, tipo `InvitationStatus`).
/// Los seis valores y, sobre todo, sus **cadenas** (`wireValue`) se preservan
/// exactamente como en el prototipo porque las pruebas portadas y el dominio
/// EMA dependen de ellas:
/// `not-invited`, `pending`, `accepted`, `declined`, `cancelled`, `expired`.
enum InvitationStatus {
  notInvited('not-invited'),
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  cancelled('cancelled'),
  expired('expired');

  const InvitationStatus(this.wireValue);

  /// Cadena exacta del prototipo (TypeScript), estable para serialización y
  /// para las pruebas portadas.
  final String wireValue;

  /// Resuelve un [InvitationStatus] a partir de su cadena del prototipo.
  ///
  /// Lanza [ArgumentError] si la cadena no corresponde a ninguno de los seis
  /// valores verbatim.
  static InvitationStatus fromWire(String value) {
    for (final status in InvitationStatus.values) {
      if (status.wireValue == value) return status;
    }
    throw ArgumentError.value(value, 'value', 'InvitationStatus desconocido');
  }
}
