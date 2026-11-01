import 'package:equatable/equatable.dart';

import 'user_role.dart';

/// Sesión del usuario tras la activación/login.
///
/// La sesión conserva el rol resuelto por el [AuthService]. Cuando el rol no es
/// uno de los soportados ([UserRole.pcs] o [UserRole.cuidador]), [role] es
/// `null`: la sesión se conserva pero no se cargan datos de otros roles y la
/// app indica que el rol no está soportado (Requirement 1.3).
class Session extends Equatable {
  const Session({required this.userId, this.role});

  /// Identificador del usuario de la sesión.
  final String userId;

  /// Rol soportado del usuario, o `null` si el rol no está soportado por la
  /// app móvil (Requirement 1.3).
  final UserRole? role;

  /// `true` si la sesión corresponde a un rol soportado por la app móvil.
  bool get hasSupportedRole => role != null;

  @override
  List<Object?> get props => [userId, role];
}
