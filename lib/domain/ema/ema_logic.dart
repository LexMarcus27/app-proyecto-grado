import 'dart:convert';

import '../journey/journey.dart';
import 'ema_constants.dart';
import 'ema_draft.dart';
import 'ema_item.dart';
import 'ema_reference.dart';

/// Clave de día local en formato `YYYY-MM-DD`.
///
/// Portado verbatim del prototipo (`src/ema.ts`, `emaDayKey`). Usa las partes de
/// fecha **locales** (año, mes+1 con relleno a dos dígitos, día con relleno a
/// dos dígitos). [date] por defecto es el momento actual.
String emaDayKey([DateTime? date]) {
  final value = date ?? DateTime.now();
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

/// Crea un borrador EMA nuevo.
///
/// Portado verbatim del prototipo (`src/ema.ts`, `createEmaDraft`). Versión
/// [emaVersion], día [day] (por defecto el día local actual), copia de
/// [reference] o `null`, sin omisión de relación, nueve respuestas `null`,
/// `questionIndex` 0 y sin completar.
EmaDraft createEmaDraft([EmaReference? reference, String? day]) {
  return EmaDraft(
    version: emaVersion,
    day: day ?? emaDayKey(),
    reference: reference,
    relationshipOmission: null,
    answers: List<Object?>.filled(emaItems.length, null),
    questionIndex: 0,
    completed: false,
  );
}

/// Índices de los ítems presentados en el borrador.
///
/// Portado verbatim del prototipo (`src/ema.ts`, `emaQuestionIndices`). Cuando
/// la omisión de relación está activa (`relationshipOmission == "no-active-link"`)
/// se omiten los tres ítems del bloque de relación, dando `[0, 1, 2, 6, 7, 8]`;
/// en otro caso se presentan los nueve ítems.
List<int> emaQuestionIndices(EmaDraft draft) {
  final indices = <int>[];
  for (var index = 0; index < emaItems.length; index++) {
    if (draft.relationshipOmission == 'no-active-link' &&
        emaItems[index].block == EmaItemBlock.relationship) {
      continue;
    }
    indices.add(index);
  }
  return indices;
}

/// Omite el bloque de relación solo para este registro diario.
///
/// Portado verbatim del prototipo (`src/ema.ts`, `omitEmaRelationship`). Solo
/// aplica si el borrador no está completado, no está ya omitido y no existe
/// ninguna persona vinculada activa ([validCaregivers] vacío). La preferencia de
/// persona guardada no se altera: aquí solo se limpia la referencia del borrador
/// del día, se marca la omisión, se vacían (a `null`) las respuestas del bloque
/// de relación y, si el `questionIndex` actual apunta a un ítem de relación, se
/// mueve al índice 6.
EmaDraft omitEmaRelationship(EmaDraft draft, JourneyState state) {
  if (draft.completed ||
      draft.relationshipOmission == 'no-active-link' ||
      validCaregivers(state).isNotEmpty) {
    return draft;
  }
  return draft.copyWith(
    reference: null,
    relationshipOmission: 'no-active-link',
    answers: [
      for (var index = 0; index < draft.answers.length; index++)
        emaItems[index].block == EmaItemBlock.relationship
            ? null
            : draft.answers[index],
    ],
    questionIndex:
        emaItems[draft.questionIndex].block == EmaItemBlock.relationship
        ? 6
        : draft.questionIndex,
  );
}

/// Construye la referencia EMA para una persona, o `null`.
///
/// Portado verbatim del prototipo (`src/ema.ts`, `emaReferenceForPerson`).
/// Devuelve `null` salvo que [canStrengthenRelationship] sea `true`; en ese caso
/// arma la referencia de cuatro IDs con la asociación activa que coincide en la
/// tupla exacta (persona, cuidador, PCS actual, activa).
EmaReference? emaReferenceForPerson(JourneyState state, String personId) {
  if (!canStrengthenRelationship(state, personId)) return null;
  final person = state.people.firstWhere((item) => item.id == personId);
  final association = state.associations.firstWhere(
    (item) =>
        item.personId == personId &&
        item.caregiverId == person.caregiverId &&
        item.pcsId == currentPcsId &&
        item.active,
  );
  return EmaReference(
    pcsId: currentPcsId,
    personId: personId,
    caregiverId: person.caregiverId!,
    associationId: association.id,
  );
}

/// Compara dos referencias EMA por valor (con manejo de `null`).
///
/// Portado verbatim del prototipo (`src/ema.ts`, `sameEmaReference`). Dos `null`
/// son iguales; un `null` y un no-`null` son distintos; en otro caso se comparan
/// los cuatro identificadores.
bool sameEmaReference(EmaReference? first, EmaReference? second) {
  if (first == null) return second == null;
  return second != null &&
      first.personId == second.personId &&
      first.caregiverId == second.caregiverId &&
      first.associationId == second.associationId &&
      first.pcsId == second.pcsId;
}

/// `true` si la referencia sigue correspondiendo a una asociación activa.
///
/// Portado verbatim del prototipo (`src/ema.ts`, `isEmaReferenceActive`). La
/// referencia debe ser no-`null` y coincidir exactamente con la referencia
/// recomputada para su persona ([emaReferenceForPerson]).
bool isEmaReferenceActive(JourneyState state, EmaReference? reference) {
  return reference != null &&
      sameEmaReference(
        emaReferenceForPerson(state, reference.personId),
        reference,
      );
}

/// Reconstruye la referencia guardada a partir de su JSON, solo con IDs.
///
/// Portado verbatim del prototipo (`src/ema.ts`, `parseEmaReference`). Rechaza
/// (devolviendo `null`) un JSON malformado, un PCS distinto al actual o
/// cualquier identificador vacío o no textual. Nunca arrastra respuestas ni
/// avance: devuelve únicamente los cuatro identificadores.
EmaReference? parseEmaReference(String? saved) {
  try {
    final value = jsonDecode(saved ?? 'null');
    if (value is! Map) return null;
    final record = value;
    if (record['pcsId'] != currentPcsId) return null;
    for (final key in const ['personId', 'caregiverId', 'associationId']) {
      final field = record[key];
      if (field is! String || field.isEmpty) return null;
    }
    return EmaReference(
      pcsId: currentPcsId,
      personId: record['personId'] as String,
      caregiverId: record['caregiverId'] as String,
      associationId: record['associationId'] as String,
    );
  } catch (_) {
    return null;
  }
}

/// Valida que [value] sea una respuesta admisible para el ítem en [index].
///
/// Portado verbatim del prototipo (`src/ema.ts`, `isEmaAnswer`). Los ítems
/// binarios aceptan solo `bool`; los de rango aceptan solo un `int` en `0..100`.
/// Un [index] no entero o fuera del banco se rechaza. En Dart, `bool` nunca es
/// `int` y un `double` (p. ej. `0.5`) nunca es `int`, por lo que los tipos no se
/// mezclan y los valores no enteros quedan excluidos.
bool isEmaAnswer(int index, Object? value) {
  if (index < 0 || index >= emaItems.length) return false;
  final item = emaItems[index];
  if (item.kind == EmaItemKind.binary) {
    return value is bool;
  }
  return value is int && value >= 0 && value <= 100;
}

/// Fija la respuesta del ítem [index] a [value].
///
/// Portado verbatim del prototipo (`src/ema.ts`, `setEmaAnswer`). Devuelve el
/// borrador sin cambios si está completado, si [value] no es válido para el
/// ítem, o si [index] no está entre los ítems presentados. `false` ("No") y `0`
/// son respuestas válidas.
EmaDraft setEmaAnswer(EmaDraft draft, int index, Object? value) {
  if (draft.completed ||
      !isEmaAnswer(index, value) ||
      !emaQuestionIndices(draft).contains(index)) {
    return draft;
  }
  return draft.copyWith(
    answers: [
      for (var itemIndex = 0; itemIndex < draft.answers.length; itemIndex++)
        itemIndex == index ? value : draft.answers[itemIndex],
    ],
  );
}

/// Cuenta los ítems presentados que tienen una respuesta válida.
///
/// Portado verbatim del prototipo (`src/ema.ts`, `answeredEmaCount`).
int answeredEmaCount(EmaDraft draft) {
  var count = 0;
  for (final index in emaQuestionIndices(draft)) {
    if (isEmaAnswer(index, draft.answers[index])) count++;
  }
  return count;
}

/// `true` si el borrador puede marcarse como completado.
///
/// Portado verbatim del prototipo (`src/ema.ts`, `canCompleteEma`). Requiere que
/// la versión coincida, que el contexto sea válido (si está omitido: referencia
/// `null` y todas las respuestas del bloque de relación en `null`; en otro caso:
/// referencia no `null`), que `answers` tenga exactamente nueve posiciones y que
/// el número de respondidos iguale el número de ítems presentados.
bool canCompleteEma(EmaDraft draft) {
  final omitted = draft.relationshipOmission == 'no-active-link';
  final bool validContext;
  if (omitted) {
    var relationshipAllNull = true;
    for (var index = 0; index < emaItems.length; index++) {
      if (emaItems[index].block == EmaItemBlock.relationship &&
          draft.answers[index] != null) {
        relationshipAllNull = false;
        break;
      }
    }
    validContext = draft.reference == null && relationshipAllNull;
  } else {
    validContext = draft.reference != null;
  }
  return draft.version == emaVersion &&
      validContext &&
      draft.answers.length == emaItems.length &&
      answeredEmaCount(draft) == emaQuestionIndices(draft).length;
}

/// Prepara el borrador para el día [day].
///
/// Portado verbatim del prototipo (`src/ema.ts`, `prepareEmaDay`). Si la versión
/// no coincide o el día es distinto, crea un borrador nuevo con [reference] y
/// [day]; en otro caso devuelve el borrador sin cambios.
EmaDraft prepareEmaDay(EmaDraft draft, EmaReference? reference, [String? day]) {
  final resolvedDay = day ?? emaDayKey();
  if (draft.version != emaVersion || draft.day != resolvedDay) {
    return createEmaDraft(reference, resolvedDay);
  }
  return draft;
}

/// Cambia la referencia de relación de un borrador sin finalizar.
///
/// Portado verbatim del prototipo (`src/ema.ts`, `changeEmaReference`). Devuelve
/// el borrador sin cambios si está completado, si está omitido, o si la nueva
/// referencia es igual a la actual. En otro caso fija la nueva referencia,
/// vacía (a `null`) las respuestas del bloque de relación y fija
/// `questionIndex = min(questionIndex, 3)`.
EmaDraft changeEmaReference(EmaDraft draft, EmaReference reference) {
  if (draft.completed ||
      draft.relationshipOmission == 'no-active-link' ||
      sameEmaReference(draft.reference, reference)) {
    return draft;
  }
  return draft.copyWith(
    reference: reference,
    answers: [
      for (var index = 0; index < draft.answers.length; index++)
        emaItems[index].block == EmaItemBlock.relationship
            ? null
            : draft.answers[index],
    ],
    questionIndex: draft.questionIndex < 3 ? draft.questionIndex : 3,
  );
}
