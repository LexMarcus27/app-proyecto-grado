import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth/session.dart';
import '../domain/auth/user_role.dart';

/// Estado de sesión de la app, usado por las guardas del router.
///
/// Mantiene la [Session] actual (o `null` si no hay sesión activa, lo que lleva
/// a la pantalla de activación). El flujo de activación real (Requirement 11)
/// se implementa en una tarea posterior sobre el `AuthService`; aquí solo se
/// expone el estado mínimo que necesita el router para enrutar por rol y para
/// denegar roles no soportados (Requirements 1.2, 1.3).
class SessionController extends Notifier<Session?> {
  @override
  Session? build() => null;

  /// Establece la sesión actual (p. ej. tras una activación exitosa).
  void setSession(Session session) => state = session;

  /// Limpia la sesión actual (cierre de sesión).
  void clear() => state = null;
}

/// Provider del estado de sesión. El router observa este provider para redirigir
/// según el rol y conservar la sesión sin cargar datos de otros roles.
final sessionControllerProvider =
    NotifierProvider<SessionController, Session?>(SessionController.new);

/// Rol soportado de la sesión actual, o `null` si no hay sesión o el rol no es
/// soportado por la app móvil (Requirement 1.3).
final currentRoleProvider = Provider<UserRole?>(
  (ref) => ref.watch(sessionControllerProvider)?.role,
);
