// Pruebas de autorización del recorrido (journey) sobre el demo.
//
// Complemento de ejemplo para la tarea 2.2 ("autorización/journey"): cubre
// `canStrengthenRelationship` y `validCaregivers` sobre `createDemoJourney()`.
// Portado del comportamiento del prototipo (`src/journey.ts`). Dart puro.
import 'package:contigo/domain/journey/journey.dart';
import 'package:test/test.dart';

void main() {
  group('autorización del journey sobre createDemoJourney()', () {
    final demo = createDemoJourney();

    test(
      'demo-m es fortalecible: tiene invitación aceptada y asociación activa',
      () {
        expect(canStrengthenRelationship(demo, 'demo-m'), isTrue);
      },
    );

    test(
      'demo-carmen NO es fortalecible: su asociación está inactiva',
      () {
        expect(canStrengthenRelationship(demo, 'demo-carmen'), isFalse);
      },
    );

    test('validCaregivers contiene a demo-m', () {
      final valid = validCaregivers(demo);
      expect(valid.map((p) => p.id), contains('demo-m'));
    });

    test(
      'validCaregivers excluye a demo-carmen (asociación inactiva)',
      () {
        final valid = validCaregivers(demo);
        expect(valid.map((p) => p.id), isNot(contains('demo-carmen')));
      },
    );

    test('un personId nulo o inexistente no es fortalecible', () {
      expect(canStrengthenRelationship(demo, null), isFalse);
      expect(canStrengthenRelationship(demo, 'no-existe'), isFalse);
    });
  });
}
