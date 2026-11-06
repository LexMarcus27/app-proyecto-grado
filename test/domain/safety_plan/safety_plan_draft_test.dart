// Prueba del dominio del plan de seguridad (tarea 3.13): creación del borrador,
// detección de información y etiqueta del enlace, portados verbatim del
// prototipo (src/safety-plan.ts, src/safety-plan-story.ts).

import 'package:contigo/domain/safety_plan/safety_plan_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('createSafetyPlanDraft', () {
    test('sin ejemplos devuelve un borrador vacío con un texto por paso', () {
      final draft = createSafetyPlanDraft();
      expect(draft.stepTexts.length, safetyPlanStepTitles.length);
      expect(draft.stepTexts.every((t) => t.isEmpty), isTrue);
      expect(draft.contacts, isEmpty);
      expect(draft.activities, isEmpty);
      expect(draft.environment, '');
      expect(safetyPlanHasInformation(draft), isFalse);
    });

    test('con ejemplos devuelve el contenido ficticio del prototipo', () {
      final draft = createSafetyPlanDraft(withExampleInformation: true);
      expect(draft.contacts.length, 2);
      expect(draft.contacts.first.name, 'Mamá');
      expect(draft.activities, ['Caminar juntos en el parque', 'Tomar un café']);
      expect(safetyPlanHasInformation(draft), isTrue);
    });
  });

  group('safetyPlanHasInformation', () {
    test('es true si algún paso tiene texto', () {
      final draft = createSafetyPlanDraft().copyWith(
        stepTexts: ['algo', '', '', ''],
      );
      expect(safetyPlanHasInformation(draft), isTrue);
    });

    test('es true si hay una actividad', () {
      final draft = createSafetyPlanDraft().copyWith(activities: ['caminar']);
      expect(safetyPlanHasInformation(draft), isTrue);
    });

    test('ignora espacios en blanco en pasos y entorno', () {
      final draft = createSafetyPlanDraft().copyWith(
        stepTexts: ['   ', '', '', ''],
        environment: '   ',
      );
      expect(safetyPlanHasInformation(draft), isFalse);
    });
  });

  group('safetyPlanLinkLabel', () {
    test('sin información invita a construir el plan', () {
      expect(safetyPlanLinkLabel(false), 'Construir mi plan para desenredar');
    });

    test('con información invita a ir al plan', () {
      expect(safetyPlanLinkLabel(true), 'Ir a mi plan para desenredar');
    });
  });
}