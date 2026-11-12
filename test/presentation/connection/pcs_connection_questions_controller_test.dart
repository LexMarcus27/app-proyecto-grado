// E3-W13-01 (lógica): el partner del PCS es la persona vinculada activa
// (journey.selectedPersonId con asociación activa); el estado se aísla por
// contexto completo del vínculo (persona + asociación + PCS) y "focusQuestion"
// conserva la pregunta de la notificación aunque no esté entre las seis.

import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/presentation/caregiver_journeys/caregiver_journeys_content.dart';
import 'package:contigo/presentation/connection/pcs_connection_questions_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pcsConnectionPartner', () {
    test('usa la persona seleccionada si está vinculada activa', () {
      final journey = createDemoJourney().copyWith(selectedPersonId: 'demo-m');
      expect(pcsConnectionPartner(journey)?.id, 'demo-m');
    });

    test('si la seleccionada no está activa, cae a una vinculada activa', () {
      final journey =
          createDemoJourney().copyWith(selectedPersonId: 'demo-carmen');
      expect(pcsConnectionPartner(journey)?.id, 'demo-m');
    });

    test('sin ninguna vinculada activa devuelve null', () {
      final base = createDemoJourney();
      final noLinks = base.copyWith(
        associations: [for (final a in base.associations) a.copyWith(active: false)],
      );
      expect(pcsConnectionPartner(noLinks), isNull);
    });
  });

  group('pcsLinkKey (contexto completo)', () {
    test('incluye persona y asociación; una asociación nueva cambia la clave', () {
      final base = createDemoJourney();
      final k1 = pcsLinkKey(base, 'demo-m');
      final renamed = base.copyWith(associations: [
        for (final a in base.associations)
          a.personId == 'demo-m' ? a.copyWith(id: 'asociacion-nueva') : a,
      ]);
      final k2 = pcsLinkKey(renamed, 'demo-m');
      expect(k1, isNotNull);
      expect(k2, isNotNull);
      expect(k1, isNot(equals(k2)),
          reason: 'Una asociación distinta con la misma persona es otro contexto');
    });

    test('sin asociación activa la clave es null', () {
      final base = createDemoJourney();
      final noLinks = base.copyWith(
        associations: [for (final a in base.associations) a.copyWith(active: false)],
      );
      expect(pcsLinkKey(noLinks, 'demo-m'), isNull);
    });
  });

  group('focusQuestion', () {
    test('pregunta del banco posiciona el índice y no deja extra', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller =
          container.read(pcsConnectionQuestionsControllerProvider.notifier);
      const key = 'k';
      controller.focusQuestion(key, connectionQuestions[3]);
      expect(controller.stateForKey(key).index, 3);
      expect(controller.stateForKey(key).extraQuestion, isNull);
    });

    test('pregunta fuera del banco se conserva como extra y se muestra primero',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller =
          container.read(pcsConnectionQuestionsControllerProvider.notifier);
      const key = 'k';
      const external = 'Si los animales pudieran hablar, ¿cuál sería el más bocón?';
      controller.focusQuestion(key, external);
      final s = controller.stateForKey(key);
      expect(s.extraQuestion, external);
      expect(s.index, 0);
      expect(s.questions.first, external);
      expect(s.questions.length, connectionQuestions.length + 1);
    });
  });
}