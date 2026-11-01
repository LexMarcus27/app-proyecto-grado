// Pruebas de ejemplo del dominio EMA (banco diario `daily-nine-v2`).
//
// Portadas de la suite del prototipo (`tests/ema.test.mjs`) a `dart test` como
// pruebas de ejemplo obligatorias de la tarea 2.4. Cada caso replica un `test`
// del prototipo con aserciones equivalentes. Dart puro, sin Flutter ni Firebase.
//
// La prueba del prototipo que inspecciona `App.tsx` en busca de cadenas de
// persistencia NO es portable (depende de los fuentes TSX de la app) y se omite
// aquí; la persistencia solo-IDs se cubre en las tareas 2.8/2.9.
//
// Igualdad por valor: `EmaDraft`/`EmaReference` extienden `Equatable`, por lo que
// las aserciones de "devuelve el borrador sin cambios" usan `equals(...)`.
import 'dart:convert';

import 'package:contigo/domain/ema/ema.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:test/test.dart';

void main() {
  // Fixtures equivalentes a las del prototipo (`tests/ema.test.mjs`).
  final active = createDemoJourney();
  final reference = emaReferenceForPerson(active, 'demo-m');

  // `otherActive`: el demo con TODAS las asociaciones activas, de modo que
  // `demo-carmen` pase a ser una persona vinculada activa válida.
  final otherActive = active.copyWith(
    associations: [
      for (final item in active.associations) item.copyWith(active: true),
    ],
  );
  final otherReference = emaReferenceForPerson(otherActive, 'demo-carmen');

  EmaDraft start() => createEmaDraft(reference, '2026-10-15');

  EmaDraft fill(EmaDraft draft) {
    for (var index = 0; index < 9; index++) {
      draft = setEmaAnswer(draft, index, index < 3 ? false : 0);
    }
    return draft;
  }

  group('dominio EMA (daily-nine-v2) — portado de tests/ema.test.mjs', () {
    test(
      'el banco oficial diario tiene tres ítems binarios seguidos de dos '
      'bloques de tres rangos',
      () {
        expect(emaItems.length, 9);
        expect(emaItems.map((item) => item.id).toSet().length, 9);
        expect(
          emaItems.map((item) => item.kind).toList(),
          [
            EmaItemKind.binary,
            EmaItemKind.binary,
            EmaItemKind.binary,
            EmaItemKind.range,
            EmaItemKind.range,
            EmaItemKind.range,
            EmaItemKind.range,
            EmaItemKind.range,
            EmaItemKind.range,
          ],
        );
        expect(
          emaItems
              .where((item) => item.block == EmaItemBlock.relationship)
              .length,
          3,
        );
        expect(
          emaItems[8].text,
          'Hoy, me ha sido fácil conectar con otros cuando lo he necesitado.',
        );
        expect(emaTimeWindow, contains('desde que te despertaste hasta ahora'));
        expect(emaItems.every((item) => item.text.startsWith('Hoy')), isTrue);
      },
    );

    test(
      'un registro diario arranca con las nueve respuestas vacías y sin valor '
      'de escala seleccionado',
      () {
        final draft = start();
        expect(draft.questionIndex, 0);
        expect(draft.answers.length, 9);
        expect(draft.answers.every((value) => value == null), isTrue);
        expect(answeredEmaCount(draft), 0);
        expect(canCompleteEma(draft), isFalse);
        // Cada `start()`/`createEmaDraft` produce listas independientes: mutar
        // una copia local no afecta a un borrador recién creado.
        draft.answers[0] = true;
        expect(start().answers[0], isNull);
      },
    );

    test(
      '"No" y el extremo "Nada cierta" (0) cuentan como respuestas explícitas; '
      'null no',
      () {
        var draft = start();
        draft = setEmaAnswer(draft, 0, false);
        draft = setEmaAnswer(draft, 3, 0);
        expect(answeredEmaCount(draft), 2);
        expect(draft.answers[0], false);
        expect(draft.answers[3], 0);
        final full = fill(start());
        expect(answeredEmaCount(full), 9);
        expect(canCompleteEma(full), isTrue);
        expect(canCompleteEma(full.copyWith(reference: null)), isFalse);
        expect(
          canCompleteEma(full.copyWith(answers: full.answers.sublist(0, 8))),
          isFalse,
        );
      },
    );

    test(
      'los tipos de respuesta binario y rango no se mezclan y los valores '
      'inválidos no alteran el borrador',
      () {
        final draft = start();
        // Ítem 0 (binario): solo admite `bool`.
        for (final value in <Object?>[0, 1, 100, 'Sí', null]) {
          expect(setEmaAnswer(draft, 0, value), equals(draft));
        }
        // Ítem 3 (rango): solo admite un `int` en 0..100.
        for (final value in <Object?>[
          true,
          false,
          -1,
          101,
          double.nan,
          double.infinity,
          '50',
          null,
        ]) {
          expect(setEmaAnswer(draft, 3, value), equals(draft));
        }
        // Índices fuera del banco (en Dart `setEmaAnswer` solo acepta `int`,
        // por lo que los casos no enteros del prototipo —0.5, NaN— se cubren
        // con los índices fuera de rango -1 y 9).
        for (final index in <int>[-1, 9]) {
          expect(setEmaAnswer(draft, index, false), equals(draft));
        }
        expect(setEmaAnswer(draft, 3, 100).answers[3], 100);
        // Un borrador completado ignora nuevas respuestas.
        expect(
          setEmaAnswer(draft.copyWith(completed: true), 0, true).answers[0],
          isNull,
        );
      },
    );

    test(
      'una referencia requiere aceptación y la tupla exacta de PCS, cuidador, '
      'persona y asociación activa',
      () {
        expect(reference, isNotNull);
        for (final id in const [
          'demo-alex',
          'demo-carmen',
          'demo-lu',
          'demo-sam',
          'missing',
        ]) {
          expect(emaReferenceForPerson(active, id), isNull);
        }
        expect(isEmaReferenceActive(active, reference), isTrue);
        // Alterar cualquiera de los cuatro IDs rompe la coincidencia.
        expect(
          isEmaReferenceActive(
            active,
            EmaReference(
              pcsId: 'other',
              personId: reference!.personId,
              caregiverId: reference.caregiverId,
              associationId: reference.associationId,
            ),
          ),
          isFalse,
        );
        expect(
          isEmaReferenceActive(
            active,
            EmaReference(
              pcsId: reference.pcsId,
              personId: 'other',
              caregiverId: reference.caregiverId,
              associationId: reference.associationId,
            ),
          ),
          isFalse,
        );
        expect(
          isEmaReferenceActive(
            active,
            EmaReference(
              pcsId: reference.pcsId,
              personId: reference.personId,
              caregiverId: 'other',
              associationId: reference.associationId,
            ),
          ),
          isFalse,
        );
        expect(
          isEmaReferenceActive(
            active,
            EmaReference(
              pcsId: reference.pcsId,
              personId: reference.personId,
              caregiverId: reference.caregiverId,
              associationId: 'other',
            ),
          ),
          isFalse,
        );
        // Sin asociaciones: inactiva.
        final revoked = active.copyWith(associations: const []);
        expect(isEmaReferenceActive(revoked, reference), isFalse);
        // Asociación con id distinto ("re-vinculada"): la referencia guardada
        // ya no coincide.
        final relinked = active.copyWith(
          associations: [
            for (final item in active.associations)
              item.copyWith(id: 'new-association'),
          ],
        );
        expect(isEmaReferenceActive(relinked, reference), isFalse);
        expect(isEmaReferenceActive(active, null), isFalse);
        // Seleccionar otra persona en el estado no afecta la actividad de la
        // referencia.
        expect(
          isEmaReferenceActive(
            active.copyWith(selectedPersonId: 'demo-alex'),
            reference,
          ),
          isTrue,
        );
      },
    );

    test(
      'la preferencia guardada se recarga solo como IDs, rechazando datos '
      'malformados o de otro PCS',
      () {
        final parsed = parseEmaReference(
          jsonEncode({
            'pcsId': reference!.pcsId,
            'personId': reference.personId,
            'caregiverId': reference.caregiverId,
            'associationId': reference.associationId,
            'answers': [true, 100],
            'questionIndex': 4,
          }),
        );
        expect(sameEmaReference(reference, parsed), isTrue);
        // El objeto reconstruido es una `EmaReference` pura: no arrastra
        // respuestas ni avance (no existen esos campos en el modelo).
        expect(parsed, isA<EmaReference>());
        for (final value in <String?>[
          null,
          'bad json',
          'null',
          '[]',
          '{}',
          jsonEncode({
            'pcsId': 'other-pcs',
            'personId': reference.personId,
            'caregiverId': reference.caregiverId,
            'associationId': reference.associationId,
          }),
          jsonEncode({
            'pcsId': reference.pcsId,
            'personId': reference.personId,
            'caregiverId': reference.caregiverId,
            'associationId': '',
          }),
        ]) {
          expect(parseEmaReference(value), isNull);
        }
      },
    );

    test(
      'volver el mismo día reanuda el borrador; un día local nuevo arranca '
      'nueve ítems vacíos con la persona guardada',
      () {
        final draft = fill(start());
        expect(prepareEmaDay(draft, otherReference, '2026-10-15'), equals(draft));
        final tomorrow = prepareEmaDay(draft, otherReference, '2026-10-16');
        expect(answeredEmaCount(tomorrow), 0);
        expect(tomorrow.questionIndex, 0);
        expect(tomorrow.completed, isFalse);
        expect(sameEmaReference(tomorrow.reference, otherReference), isTrue);
        expect(emaDayKey(DateTime(2026, 10, 15, 23, 59)), '2026-10-15');
        expect(emaDayKey(DateTime(2026, 10, 16, 0, 0)), '2026-10-16');
      },
    );

    test(
      'un cambio de persona confirmado limpia solo el bloque de relación de un '
      'registro sin finalizar',
      () {
        final original = fill(start()).copyWith(questionIndex: 5);
        final changed = changeEmaReference(original, otherReference!);
        expect(sameEmaReference(changed.reference, otherReference), isTrue);
        expect(
          changed.answers,
          <Object?>[false, false, false, null, null, null, 0, 0, 0],
        );
        expect(changed.questionIndex, 3);
        expect(
          changeEmaReference(
            original.copyWith(questionIndex: 8),
            otherReference,
          ).questionIndex,
          3,
        );
        // Inmutabilidad del borrador original.
        expect(original.answers[3], 0);
        // Misma referencia → sin cambios.
        expect(changeEmaReference(original, reference!), equals(original));
      },
    );

    test(
      'un registro completado conserva su persona original; la nueva '
      'preferencia aplica al día siguiente',
      () {
        final completed = fill(start()).copyWith(completed: true);
        expect(
          changeEmaReference(completed, otherReference!),
          equals(completed),
        );
        expect(sameEmaReference(completed.reference, reference), isTrue);
        final tomorrow = prepareEmaDay(completed, otherReference, '2026-10-16');
        expect(sameEmaReference(tomorrow.reference, otherReference), isTrue);
      },
    );

    test(
      'sin ninguna persona vinculada activa, el registro de hoy contiene '
      'exactamente los seis ítems personales y de conexión',
      () {
        final original = createEmaDraft(null, '2026-10-15');
        final skipped = omitEmaRelationship(original, emptyJourney);
        expect(skipped.relationshipOmission, 'no-active-link');
        expect(skipped.reference, isNull);
        expect(emaQuestionIndices(skipped), [0, 1, 2, 6, 7, 8]);
        expect(canCompleteEma(skipped), isFalse);
        final completed = fill(skipped);
        expect(answeredEmaCount(completed), 6);
        expect(canCompleteEma(completed), isTrue);
        expect(
          completed.answers,
          <Object?>[false, false, false, null, null, null, 0, 0, 0],
        );
        // El ítem de relación no está presentado: fijar su respuesta no cambia.
        expect(setEmaAnswer(skipped, 3, 50), equals(skipped));
        // Sin mutación del borrador original.
        expect(original.relationshipOmission, isNull);
        // Responder el bloque de relación mientras se omite impide completar.
        expect(
          canCompleteEma(
            completed.copyWith(
              answers: <Object?>[false, false, false, 0, 0, 0, 0, 0, 0],
            ),
          ),
          isFalse,
        );
      },
    );

    test(
      'el bloque no puede omitirse cuando existe una persona vinculada válida, '
      'pero las asociaciones inactivas no bloquean la omisión',
      () {
        final draft = start();
        expect(omitEmaRelationship(draft, active), equals(draft));
        expect(omitEmaRelationship(draft, otherActive), equals(draft));
        final inactive = active.copyWith(
          associations: [
            for (final item in active.associations)
              item.copyWith(active: false),
          ],
        );
        final original = fill(draft).copyWith(questionIndex: 4);
        final skipped = omitEmaRelationship(original, inactive);
        expect(skipped.reference, isNull);
        expect(skipped.questionIndex, 6);
        expect(
          skipped.answers,
          <Object?>[false, false, false, null, null, null, 0, 0, 0],
        );
        final completed = original.copyWith(completed: true);
        expect(omitEmaRelationship(completed, inactive), equals(completed));
      },
    );

    test(
      'la omisión dura solo este día y no añade preguntas de relación si se '
      'vincula una persona a mitad de camino',
      () {
        final skipped = omitEmaRelationship(
          createEmaDraft(null, '2026-10-15'),
          emptyJourney,
        );
        expect(changeEmaReference(skipped, reference!), equals(skipped));
        expect(
          prepareEmaDay(skipped, reference, '2026-10-15'),
          equals(skipped),
        );
        final tomorrow = prepareEmaDay(skipped, reference, '2026-10-16');
        expect(tomorrow.relationshipOmission, isNull);
        expect(sameEmaReference(tomorrow.reference, reference), isTrue);
        expect(emaQuestionIndices(tomorrow).length, 9);
        expect(answeredEmaCount(tomorrow), 0);
        final withoutLinkTomorrow = prepareEmaDay(skipped, null, '2026-10-16');
        expect(withoutLinkTomorrow.relationshipOmission, isNull);
        expect(canCompleteEma(fill(withoutLinkTomorrow)), isFalse);
      },
    );
  });
}
