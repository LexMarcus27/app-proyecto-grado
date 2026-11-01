import 'session.dart';

/// Servicio de activación/login que resuelve el rol de la sesión.
///
/// La implementación inicial es simulada (Capa_Simulada): código en mayúsculas,
/// longitud mínima de 4 y prefijo "C" para el Cuidador (ver Requirement 11 y
/// design.md). Se intercambia por una implementación de Firebase Auth en la
/// etapa posterior sin tocar las pantallas.
abstract class AuthService {
  /// Activa la sesión a partir de un código y devuelve la [Session] resuelta.
  Future<Session> activate(String code);

  /// Cierra la sesión actual.
  Future<void> signOut();
}
