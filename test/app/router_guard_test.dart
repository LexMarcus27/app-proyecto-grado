import 'package:contigo/app/router.dart';
import 'package:contigo/domain/auth/session.dart';
import 'package:contigo/domain/auth/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('guarda por rol del router', () {
    test('sin sesión redirige a activación desde cualquier ruta', () {
      expect(guardForTest(null, AppPath.pcsHome), AppPath.activation);
      expect(guardForTest(null, AppPath.caregiverHome), AppPath.activation);
      // En la propia activación no redirige.
      expect(guardForTest(null, AppPath.activation), isNull);
    });

    test(
      'rol no soportado conserva la sesión y va a pantalla no soportado',
      () {
        const session = Session(userId: 'x'); // role == null → no soportado
        expect(guardForTest(session, AppPath.pcsHome), AppPath.unsupportedRole);
        expect(
          guardForTest(session, AppPath.activation),
          AppPath.unsupportedRole,
        );
        expect(guardForTest(session, AppPath.unsupportedRole), isNull);
      },
    );

    test('PCS no puede acceder al inicio del Cuidador', () {
      const session = Session(userId: 'p', role: UserRole.pcs);
      expect(guardForTest(session, AppPath.caregiverHome), AppPath.pcsHome);
      // En su propio inicio no redirige.
      expect(guardForTest(session, AppPath.pcsHome), isNull);
      // Desde activación va a su inicio.
      expect(guardForTest(session, AppPath.activation), AppPath.pcsHome);
    });

    test('Cuidador no puede acceder al inicio del PCS', () {
      const session = Session(userId: 'c', role: UserRole.cuidador);
      expect(guardForTest(session, AppPath.pcsHome), AppPath.caregiverHome);
      expect(guardForTest(session, AppPath.caregiverHome), isNull);
      expect(guardForTest(session, AppPath.activation), AppPath.caregiverHome);
    });

    test('homePathForRole mapea cada rol a su inicio', () {
      expect(homePathForRole(UserRole.pcs), AppPath.pcsHome);
      expect(homePathForRole(UserRole.cuidador), AppPath.caregiverHome);
    });

    test('PCS puede acceder a "Tu mapa de red"', () {
      const session = Session(userId: 'p', role: UserRole.pcs);
      // El PCS alcanza el mapa sin redirección (2.12 navega aquí como primaria).
      expect(guardForTest(session, AppPath.networkMap), isNull);
    });

    test('Cuidador no puede acceder a "Tu mapa de red"', () {
      const session = Session(userId: 'c', role: UserRole.cuidador);
      expect(guardForTest(session, AppPath.networkMap), AppPath.caregiverHome);
    });

    test('sin sesión el mapa de red redirige a activación', () {
      expect(guardForTest(null, AppPath.networkMap), AppPath.activation);
    });

    test('PCS puede acceder a la selección de Referencia_EMA', () {
      const session = Session(userId: 'p', role: UserRole.pcs);
      expect(guardForTest(session, AppPath.emaReference), isNull);
    });

    test('Cuidador no puede acceder a la selección de Referencia_EMA', () {
      const session = Session(userId: 'c', role: UserRole.cuidador);
      expect(
        guardForTest(session, AppPath.emaReference),
        AppPath.caregiverHome,
      );
    });

    test('sin sesión la selección de Referencia_EMA redirige a activación', () {
      expect(guardForTest(null, AppPath.emaReference), AppPath.activation);
    });

    test('PCS puede acceder a la revisión de Referencia_EMA obsoleta', () {
      const session = Session(userId: 'p', role: UserRole.pcs);
      expect(guardForTest(session, AppPath.emaStaleReference), isNull);
    });

    test('Cuidador no puede acceder a la revisión de Referencia_EMA', () {
      const session = Session(userId: 'c', role: UserRole.cuidador);
      expect(
        guardForTest(session, AppPath.emaStaleReference),
        AppPath.caregiverHome,
      );
    });

    test('sin sesión la revisión de Referencia_EMA redirige a activación', () {
      expect(guardForTest(null, AppPath.emaStaleReference), AppPath.activation);
    });

    test('los controles de demostración son alcanzables como la galería', () {
      // Pantalla de desarrollo: se permite siempre, con o sin sesión, igual que
      // la galería de componentes (no la gatea el rol).
      const session = Session(userId: 'p', role: UserRole.pcs);
      expect(guardForTest(session, AppPath.demoControls), isNull);
      expect(guardForTest(null, AppPath.demoControls), isNull);
    });
  });
}
