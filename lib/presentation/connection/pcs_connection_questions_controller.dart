import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../domain/journey/journey.dart';
import '../caregiver_journeys/caregiver_journeys_content.dart';
import '../caregiver_journeys/caregiver_journeys_controller.dart'
    show ConnectionResponseFormat;

/// Las seis preguntas conversacionales (verbatim), compartidas con el recorrido
/// del cuidador (`connectionQuestions`).
List<String> get connectionQuestionsForPcs => connectionQuestions;

/// Recorrido conversacional de **preguntas para conectar** del PCS
/// (``MobileScreen14`` con ``role === "pcs"``), portado del prototipo
/// (``src/screens/social.tsx``). Es **distinto** de la evaluación de nueve
/// preguntas (``RelationEvaluationScreen``): aquí el PCS y su persona cercana
/// **vinculada activa** comparten respuestas a seis preguntas conversacionales.
///
/// La persona interlocutora es ``journey.selectedPersonId`` cuando tiene una
/// Asociacion_Activa (autorización, Requirement 8.10). El estado en curso se
/// **aísla por contexto completo del vínculo** (persona + asociación + PCS) y
/// vive solo en memoria de sesión: una **asociación nueva** con la misma persona
/// empieza vacía, y **revocar/reactivar la misma** conserva el estado.

/// Estado en curso de las preguntas para conectar del PCS.
///
/// [extraQuestion] es la pregunta inicial de una notificación cuando **no**
/// pertenece al banco de seis: ``MobileScreen14`` la antepone a la lista y la
/// muestra primero, y luego permite recorrer las demás.
class PcsConnectionQuestionsState {
  const PcsConnectionQuestionsState({
    this.index = 0,
    this.format = ConnectionResponseFormat.text,
    this.text = '',
    this.attachment = '',
    this.shared = false,
    this.extraQuestion,
  });

  /// Índice de la pregunta actual dentro de la lista efectiva ([questions]).
  final int index;
  final ConnectionResponseFormat format;
  final String text;
  final String attachment;
  final bool shared;

  /// Pregunta inicial de la notificación ajena al banco de seis, o ``null``.
  final String? extraQuestion;

  bool get hasResponse => format == ConnectionResponseFormat.text
      ? text.trim().isNotEmpty
      : attachment.isNotEmpty;

  /// Lista efectiva de preguntas: si hay [extraQuestion] fuera del banco, se
  /// antepone (como ``MobileScreen14``); si no, son las seis del banco.
  List<String> get questions {
    final extra = extraQuestion;
    if (extra == null || connectionQuestionsForPcs.contains(extra)) {
      return connectionQuestionsForPcs;
    }
    return [extra, ...connectionQuestionsForPcs];
  }

  PcsConnectionQuestionsState copyWith({
    int? index,
    ConnectionResponseFormat? format,
    String? text,
    String? attachment,
    bool? shared,
    Object? extraQuestion = _unset,
  }) {
    return PcsConnectionQuestionsState(
      index: index ?? this.index,
      format: format ?? this.format,
      text: text ?? this.text,
      attachment: attachment ?? this.attachment,
      shared: shared ?? this.shared,
      extraQuestion: extraQuestion == _unset
          ? this.extraQuestion
          : extraQuestion as String?,
    );
  }

  static const Object _unset = Object();
}

/// Persona interlocutora del PCS: la persona seleccionada con vínculo activo, o
/// ``null`` si no hay ninguna autorizada. Portado de la resolución de
/// ``journey.selectedPersonId`` en el prototipo (pantalla 18).
NetworkPerson? pcsConnectionPartner(JourneyState journey) {
  final selectedId = journey.selectedPersonId;
  if (selectedId != null && canStrengthenRelationship(journey, selectedId)) {
    for (final person in journey.people) {
      if (person.id == selectedId) return person;
    }
  }
  // Si no hay seleccionada pero existe alguna vinculada activa, usa la primera
  // (el PCS puede elegir explícitamente otra desde la pantalla de selección).
  final valid = validCaregivers(journey);
  return valid.isEmpty ? null : valid.first;
}

/// Clave de sesión del **contexto completo** del vínculo PCS→persona: incluye la
/// persona, la **asociación activa** (su id) y el PCS. Así, una asociación nueva
/// con la misma persona empieza con su propio estado y revocar/reactivar la
/// misma asociación conserva el suyo. Devuelve ``null`` sin vínculo activo.
String? pcsLinkKey(JourneyState journey, String personId,
    {String pcsId = currentPcsId}) {
  if (!canStrengthenRelationship(journey, personId, pcsId: pcsId)) return null;
  for (final a in journey.associations) {
    if (a.active && a.personId == personId && a.pcsId == pcsId) {
      return '$pcsId|$personId|${a.id}';
    }
  }
  return null;
}

/// Controlador del recorrido conversacional del PCS, **aislado por contexto
/// completo del vínculo** (persona + asociación + PCS). Solo en memoria de
/// sesión. La clave la calcula [pcsLinkKey]; las escrituras sin vínculo activo
/// (clave ``null``) son no-op.
class PcsConnectionQuestionsController
    extends Notifier<Map<String, PcsConnectionQuestionsState>> {
  @override
  Map<String, PcsConnectionQuestionsState> build() => const {};

  PcsConnectionQuestionsState stateForKey(String? key) {
    if (key == null) return const PcsConnectionQuestionsState();
    return state[key] ?? const PcsConnectionQuestionsState();
  }

  void _edit(
    String? key,
    PcsConnectionQuestionsState Function(PcsConnectionQuestionsState c) update,
  ) {
    if (key == null) return;
    state = {...state, key: update(stateForKey(key))};
  }

  /// Posiciona el recorrido en la pregunta [question] de la notificación,
  /// conservándola y mostrándola primero. Si pertenece al banco de seis, solo
  /// cambia el índice; si no, se guarda como [extraQuestion] y se muestra en el
  /// índice 0. Conserva el resto del estado del vínculo.
  void focusQuestion(String? key, String? question) {
    if (key == null || question == null) return;
    _edit(key, (c) {
      final bankIndex = connectionQuestionsForPcs.indexOf(question);
      if (bankIndex >= 0) {
        return c.copyWith(index: bankIndex, extraQuestion: null);
      }
      // Fuera del banco: se antepone y queda en el índice 0.
      return c.copyWith(extraQuestion: question, index: 0);
    });
  }

  void reset(String? key, int nextIndex) => _edit(
        key,
        (c) {
          final total = c.questions.length;
          // Conserva la pregunta extra (sigue en la lista efectiva).
          return PcsConnectionQuestionsState(
            index: total == 0 ? 0 : nextIndex % total,
            extraQuestion: c.extraQuestion,
          );
        },
      );

  void setFormat(String? key, ConnectionResponseFormat value) =>
      _edit(key, (c) => c.copyWith(format: value, attachment: ''));
  void setText(String? key, String value) =>
      _edit(key, (c) => c.copyWith(text: value));
  void setAttachment(String? key, String value) =>
      _edit(key, (c) => c.copyWith(attachment: value));
  void markShared(String? key) =>
      _edit(key, (c) => c.copyWith(shared: true));
}

final pcsConnectionQuestionsControllerProvider = NotifierProvider<
    PcsConnectionQuestionsController,
    Map<String, PcsConnectionQuestionsState>>(
  PcsConnectionQuestionsController.new,
);

/// Recorrido en vivo del `JourneyState` para la pantalla del PCS.
final pcsConnectionJourneyProvider = StreamProvider.autoDispose<JourneyState>(
  (ref) => ref.watch(journeyRepositoryProvider).watchJourney(),
);