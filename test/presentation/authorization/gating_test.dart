// Prueba de la lógica de autorización compartida (tarea 3.6): el gating se deriva
// de canStrengthenRelationship (tupla exacta) y oculta el contenido de cuidado
// tras una revocación (Requirement 4.1, 4.2, 4.5).

import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/presentation/authorization/gating.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CareGating', () {
    test('habilita acciones para una persona con vínculo activo', () {
      final gating = CareGating(createDemoJourney());
      // demo-m tiene invitación accepted y asociación activa.
      expect(gating.canStrengthen('demo-m'), isTrue);
      expect(gating.isActionDisabled('demo-m'), isFalse);
      expect(gating.isCareContentHidden('demo-m'), isFalse);
      expect(gating.contextFor('caregiver-m'), isNotNull);
    });

    test('deshabilita y oculta si la asociación no está activa', () {
      // demo-carmen: accepted pero asociación inactiva en el recorrido demo.
      final gating = CareGating(createDemoJourney());
      expect(gating.canStrengthen('demo-carmen'), isFalse);
      expect(gating.isActionDisabled('demo-carmen'), isTrue);
      expect(gating.isCareContentHidden('demo-carmen'), isTrue);
    });

    test('tupla exacta: un pcsId distinto no autoriza', () {
      final gating = CareGating(createDemoJourney());
      expect(gating.canStrengthen('demo-m', pcsId: 'otro-pcs'), isFalse);
    });

    test('tras revocar (sin vínculo activo) se oculta todo el contenido', () {
      final revoked = seedForScenario(DemoScenario.withoutActiveLink);
      final gating = CareGating(revoked);
      expect(gating.authorizedPeople, isEmpty);
      for (final person in revoked.people) {
        expect(gating.isCareContentHidden(person.id), isTrue);
        expect(gating.isActionDisabled(person.id), isTrue);
      }
    });

    test('personId nulo nunca autoriza', () {
      final gating = CareGating(createDemoJourney());
      expect(gating.canStrengthen(null), isFalse);
      expect(gating.isActionDisabled(null), isTrue);
    });
  });
}