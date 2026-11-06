// Prueba del enrutamiento de activación simulada (Property 20, opcional):
// longitud mínima, normalización a mayúsculas y resolución de rol por prefijo.

import 'package:contigo/data/auth/simulated_auth_service.dart';
import 'package:contigo/domain/auth/auth_service.dart';
import 'package:contigo/domain/auth/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = SimulatedAuthService(verifyDelay: Duration.zero);

  group('SimulatedAuthService.activate', () {
    test('rechaza códigos de menos de 4 caracteres', () {
      expect(
        () => service.activate('ABC'),
        throwsA(isA<ActivationException>()),
      );
    });

    test('rechaza el código vacío', () {
      expect(
        () => service.activate(''),
        throwsA(isA<ActivationException>()),
      );
    });

    test('un código genérico válido resuelve el rol PCS', () async {
      final session = await service.activate('A3K9X2');
      expect(session.role, UserRole.pcs);
    });

    test('un código que empieza con «C» resuelve el rol Cuidador', () async {
      final session = await service.activate('C1D2E3');
      expect(session.role, UserRole.cuidador);
    });

    test('normaliza a mayúsculas: «c...» en minúscula resuelve Cuidador',
        () async {
      final session = await service.activate('c1d2e3');
      expect(session.role, UserRole.cuidador);
    });

    test('el mensaje de la excepción es el del prototipo (verbatim)', () async {
      try {
        await service.activate('ab');
        fail('se esperaba ActivationException');
      } on ActivationException catch (e) {
        expect(e.message, activationInvalidCodeMessage);
      }
    });
  });
}