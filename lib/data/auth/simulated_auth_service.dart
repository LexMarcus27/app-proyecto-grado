import '../../domain/auth/auth_service.dart';
import '../../domain/auth/session.dart';
import '../../domain/auth/user_role.dart';

/// Implementación simulada de [AuthService] (Capa_Simulada).
///
/// Reproduce la activación por código del prototipo (`MobileScreen01`): el
/// código se normaliza a mayúsculas; si tiene menos de 4 caracteres se rechaza
/// con [ActivationException]; en otro caso el rol se resuelve por el prefijo
/// `C` (Cuidador) o, si no, PCS. No hay validación ni red reales; se añade un
/// retardo breve que imita la verificación del prototipo (~900 ms).
class SimulatedAuthService implements AuthService {
  SimulatedAuthService({this.verifyDelay = const Duration(milliseconds: 900)});

  /// Retardo de la verificación simulada. Configurable para pruebas.
  final Duration verifyDelay;

  @override
  Future<Session> activate(String code) async {
    final normalized = code.toUpperCase();
    if (normalized.length < 4) {
      throw const ActivationException();
    }
    await Future<void>.delayed(verifyDelay);
    final role = normalized.startsWith('C') ? UserRole.cuidador : UserRole.pcs;
    final userId = role == UserRole.cuidador ? 'demo-cuidador' : 'demo-pcs';
    return Session(userId: userId, role: role);
  }

  @override
  Future<void> signOut() async {}
}
