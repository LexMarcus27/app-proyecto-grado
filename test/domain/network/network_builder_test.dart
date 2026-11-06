// Pruebas del dominio de construcción del mapa (tarea 3.11): contenido verbatim
// (preguntas y escala), evaluación por persona y generateResults. Portado de
// src/screens/network.tsx.

import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/domain/network/network.dart';
import 'package:flutter_test/flutter_test.dart';

NetworkPerson _person({
  PersonStatus status = PersonStatus.pending,
  List<int?>? answers,
}) {
  return NetworkPerson(
    id: 'p',
    name: 'Ana',
    relationshipType: RelationshipType.amistades,
    answers: answers ?? List<int?>.filled(relationshipItemCount, null),
    status: status,
    invitationStatus: InvitationStatus.notInvited,
  );
}

void main() {
  group('contenido verbatim', () {
    test('10 preguntas del generador de nombres y 18 ítems de relación', () {
      expect(nameGeneratorQuestions.length, 10);
      expect(relationshipQuestions.length, relationshipItemCount);
      expect(relationshipItemCount, 18);
      expect(relationshipScale.length, 6);
      expect(relationshipScale.first, 'Nada');
      expect(relationshipScale.last, 'Extremadamente');
    });
  });

  group('answerRelationshipItem', () {
    test('marca complete al responder los 18 ítems', () {
      var person = _person();
      for (var i = 0; i < relationshipItemCount; i++) {
        person = answerRelationshipItem(person, i, 4);
        if (i < relationshipItemCount - 1) {
          expect(person.status, PersonStatus.inProgress);
        }
      }
      expect(person.status, PersonStatus.complete);
      expect(isPersonAssessed(person), isTrue);
    });

    test('ignora índices fuera de rango', () {
      final person = _person();
      expect(answerRelationshipItem(person, -1, 3), person);
      expect(answerRelationshipItem(person, relationshipItemCount, 3), person);
    });
  });

  group('generateResults', () {
    test('no genera sin personas evaluadas', () {
      final journey = emptyJourney;
      expect(generateResults(journey).mapGenerated, isFalse);
    });

    test('genera cuando hay al menos una persona evaluada', () {
      final complete = _person(
        status: PersonStatus.complete,
        answers: List<int?>.filled(relationshipItemCount, 4),
      );
      final journey = emptyJourney.copyWith(people: [complete]);
      final result = generateResults(journey);
      expect(result.mapGenerated, isTrue);
      expect(result.mapStarted, isTrue);
    });

    test('excluye del cómputo a quien no tiene los 18 ítems', () {
      final partial = _person(
        status: PersonStatus.inProgress,
        answers: [for (var i = 0; i < relationshipItemCount; i++) i == 0 ? null : 4],
      );
      final journey = emptyJourney.copyWith(people: [partial]);
      expect(assessedPeople(journey), isEmpty);
      expect(generateResults(journey).mapGenerated, isFalse);
    });
  });
}