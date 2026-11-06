// Propiedad 10 (aislamiento entre escenarios de demostración del plan, tarea
// 3.14 opcional): modificar el borrador de un escenario no altera el de otro.
// Verifica también que el borrador vive solo en memoria (sesión).

import 'package:contigo/data/safety_plan/in_memory_safety_plan_store.dart';
import 'package:contigo/domain/safety_plan/safety_plan_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemorySafetyPlanStore', () {
    test('un escenario sin borrador devuelve null', () async {
      final store = InMemorySafetyPlanStore();
      expect(await store.loadDraft('a'), isNull);
    });

    test('guarda y recupera el borrador del mismo escenario', () async {
      final store = InMemorySafetyPlanStore();
      final draft = createSafetyPlanDraft().copyWith(activities: ['caminar']);
      await store.saveDraft('a', draft);
      expect(await store.loadDraft('a'), draft);
    });

    test('aislamiento: editar un escenario no altera el otro', () async {
      final store = InMemorySafetyPlanStore();
      final draftA =
          createSafetyPlanDraft().copyWith(environment: 'entorno A');
      final draftB = createSafetyPlanDraft(withExampleInformation: true);

      await store.saveDraft('a', draftA);
      await store.saveDraft('b', draftB);

      // Modifica A de nuevo; B debe permanecer idéntico.
      await store.saveDraft(
        'a',
        draftA.copyWith(activities: ['nueva']),
      );

      final loadedB = await store.loadDraft('b');
      expect(loadedB, draftB);

      final loadedA = await store.loadDraft('a');
      expect(loadedA!.activities, ['nueva']);
      expect(loadedA.environment, 'entorno A');
    });

    test('clear elimina solo el escenario indicado', () async {
      final store = InMemorySafetyPlanStore();
      await store.saveDraft('a', createSafetyPlanDraft());
      await store.saveDraft(
        'b',
        createSafetyPlanDraft(withExampleInformation: true),
      );

      await store.clear('a');

      expect(await store.loadDraft('a'), isNull);
      expect(await store.loadDraft('b'), isNotNull);
    });
  });
}