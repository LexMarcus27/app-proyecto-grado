// Pruebas del dominio de mensajes de cuidado (tarea 3.15): inserción aditiva
// (Property 11), registro sin datos privados (Property 12), alternancia de
// preguntas y visibilidad según vínculo. Portado de src/caring-messages.ts.

import 'package:contigo/content/caring_messages_content.dart';
import 'package:contigo/domain/caring_messages/caring_messages.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appendCaringIdea (Property 11: inserción aditiva)', () {
    test('agrega a un borrador vacío sin separadores', () {
      final d = appendCaringIdea(createCaringDraft(), 'Estoy pensando en ti.');
      expect(d.text, 'Estoy pensando en ti.');
    });

    test('añade sin sobrescribir el texto previo', () {
      var d = appendCaringIdea(createCaringDraft(), 'Primera idea.');
      d = appendCaringIdea(d, 'Segunda idea.');
      expect(d.text, 'Primera idea.\n\nSegunda idea.');
      // El texto previo se conserva íntegro.
      expect(d.text.contains('Primera idea.'), isTrue);
    });

    test('una idea vacía no cambia el borrador', () {
      final base = appendCaringIdea(createCaringDraft(), 'Algo.');
      final same = appendCaringIdea(base, '   ');
      expect(same, base);
    });
  });

  group('toggleCaringQuestion', () {
    test('selecciona y deselecciona manteniendo orden ascendente', () {
      var d = createCaringDraft();
      d = toggleCaringQuestion(d, 3);
      d = toggleCaringQuestion(d, 1);
      expect(d.selectedQuestions, [1, 3]);
      d = toggleCaringQuestion(d, 1);
      expect(d.selectedQuestions, [3]);
    });

    test('ignora índices fuera de rango', () {
      final d = createCaringDraft();
      expect(toggleCaringQuestion(d, -1), d);
      expect(toggleCaringQuestion(d, CaringContent.questions.length), d);
    });
  });

  group('createSimulatedCaringMessage (Property 12: sin datos privados)', () {
    test('no incluye notas ni preguntas; conserva identificadores y texto', () {
      final journey = createDemoJourney();
      // caregiver-m tiene vínculo activo en el recorrido demo.
      final msg = createSimulatedCaringMessage(
        journey,
        'caregiver-m',
        '  Me alegra que existas.  ',
        'msg-1',
      );
      expect(msg, isNotNull);
      expect(msg!.text, 'Me alegra que existas.');
      expect(msg.caregiverId, 'caregiver-m');
      expect(msg.delivery, 'simulated');
      expect(msg.pcsId, isNotEmpty);
      expect(msg.personId, isNotEmpty);
      expect(msg.associationId, isNotEmpty);
      // El registro NO expone notas privadas ni preguntas de reflexión: su
      // superficie son solo identificadores + texto + entrega.
      expect(msg.props.whereType<Map>(), isEmpty);
      expect(msg.props.contains('simulated'), isTrue);
    });

    test('devuelve null sin vínculo, texto vacío o id vacío', () {
      final journey = createDemoJourney();
      expect(
        createSimulatedCaringMessage(journey, 'desconocido', 'hola', 'id'),
        isNull,
      );
      expect(
        createSimulatedCaringMessage(journey, 'caregiver-m', '   ', 'id'),
        isNull,
      );
      expect(
        createSimulatedCaringMessage(journey, 'caregiver-m', 'hola', '  '),
        isNull,
      );
    });
  });

  group('visibleCaringMessages', () {
    test('muestra el mensaje mientras el vínculo siga vigente', () {
      final journey = createDemoJourney();
      final msg = createSimulatedCaringMessage(
        journey,
        'caregiver-m',
        'Estoy pensando en ti.',
        'msg-1',
      )!;
      expect(visibleCaringMessages(journey, [msg]), [msg]);
    });

    test('tras revocar el vínculo el mensaje deja de ser visible', () {
      final journey = createDemoJourney();
      final msg = createSimulatedCaringMessage(
        journey,
        'caregiver-m',
        'Estoy pensando en ti.',
        'msg-1',
      )!;
      // Revoca: todas las asociaciones inactivas.
      final revoked = seedForScenario(DemoScenario.withoutActiveLink);
      expect(visibleCaringMessages(revoked, [msg]), isEmpty);
    });
  });
}