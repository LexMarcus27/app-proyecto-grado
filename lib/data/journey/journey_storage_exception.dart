/// Excepción tipada de la capa de datos del recorrido (journey).
///
/// Representa un fallo al leer/decodificar el `JourneyState` persistido
/// (almacenamiento corrupto, JSON malformado, enum desconocido). La capa de
/// repositorio la captura para degradar de forma controlada (p. ej. volver al
/// recorrido vacío) en lugar de propagar errores crudos a la presentación.
class JourneyStorageException implements Exception {
  const JourneyStorageException(this.message, [this.cause]);

  /// Descripción legible del fallo.
  final String message;

  /// Causa original, si la hubo (p. ej. `FormatException` del decodificador).
  final Object? cause;

  @override
  String toString() {
    final suffix = cause == null ? '' : ' (causa: $cause)';
    return 'JourneyStorageException: $message$suffix';
  }
}
