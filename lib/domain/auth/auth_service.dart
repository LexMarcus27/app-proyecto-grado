import 'session.dart';

/// Servicio de activación/login que resuelve el rol de la sesión.
///
/// La implementación inicial es simulada (Capa_Simulada): código en mayúsculas,
/// longitud mínima de 4 y prefijo "C" para el Cuidador (ver Requirement 11 y
/// design.md). Se intercambia por una implementación de Firebase Auth en la
/// etapa posterior sin tocar las pantallas.
/// Mensaje de error del prototipo cuando el código no es válido (verbatim).
const String activationInvalidCodeMessage =
    'No pudimos validar el código. Revísalo o solicita ayuda.';

/// Error de activación simulada: el código ingresado no cumple el mínimo del
/// prototipo (longitud < 4). Lleva el mensaje que la UI muestra tal cual.
class ActivationException implements Exception {
  const ActivationException([this.message = activationInvalidCodeMessage]);

  /// Mensaje legible para la UI.
  final String message;

  @override
  String toString() => 'ActivationException: $message';
}

abstract class AuthService {
  /// Activa la sesión a partir de un código y devuelve la [Session] resuelta.
  Future<Session> activate(String code);

  /// Cierra la sesión actual.
  Future<void> signOut();
}
