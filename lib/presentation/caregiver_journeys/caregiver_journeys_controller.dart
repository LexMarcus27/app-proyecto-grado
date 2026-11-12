import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/caring_messages/caring_messages.dart';
import '../../domain/journey/caregiver.dart';
import '../caring_messages/caring_messages_controller.dart';

/// Clave de sesión del contexto de cuidado **completo** (cuidador, PCS, persona,
/// asociación). Reutiliza `caringDraftKey`, de modo que el estado en curso de
/// cada recorrido se aísla por la tupla exacta del vínculo: una asociación
/// distinta comienza con su propio estado y **no hereda** texto, notas,
/// respuestas ni adjuntos simulados. Devuelve `null` si no hay vínculo válido.
String? currentCareContextKey(CaregiverContext? context) =>
    context == null ? null : caringDraftKey(context);

/// Notifier de sesión genérico de estado en curso por recorrido, **aislado por
/// contexto completo**. Solo vive en memoria de sesión (no se persiste) y
/// **sobrevive a una revocación**: al bloquear el recorrido no se borra nada; si
/// la **misma** asociación se reactiva, se recupera lo diligenciado. Sin vínculo
/// válido las escrituras son no-op (no pueden atribuirse a una asociación que
/// aún no existe ni trasladarse a otra).
abstract class _CareJourneyNotifier<T> extends Notifier<Map<String, T>> {
  T get empty;

  @override
  Map<String, T> build() => const {};

  String? get _key =>
      currentCareContextKey(ref.read(currentCaringContextProvider));

  T stateForKey(String key) => state[key] ?? empty;

  void edit(T Function(T current) update) {
    final key = _key;
    if (key == null) return;
    state = {...state, key: update(stateForKey(key))};
  }
}

// ─── Registro de la relación (MobileScreen12) ───────────────────────────────

/// Estado en curso del **registro de la relación** (check-in diario) del
/// cuidador. Portado del formulario de `MobileScreen12`.
class LinkCheckInState {
  const LinkCheckInState({
    this.hadContact,
    this.quality,
    this.initiator,
    this.saved = false,
  });

  /// '`si`' | '`no`' | '`prefiero`'.
  final String? hadContact;
  final int? quality;

  /// '`yo`' | '`otro`' | '`ambos`'.
  final String? initiator;
  final bool saved;

  LinkCheckInState copyWith({
    Object? hadContact = _unset,
    Object? quality = _unset,
    Object? initiator = _unset,
    bool? saved,
  }) {
    return LinkCheckInState(
      hadContact:
          hadContact == _unset ? this.hadContact : hadContact as String?,
      quality: quality == _unset ? this.quality : quality as int?,
      initiator: initiator == _unset ? this.initiator : initiator as String?,
      saved: saved ?? this.saved,
    );
  }

  static const Object _unset = Object();
}

class LinkCheckInController extends _CareJourneyNotifier<LinkCheckInState> {
  @override
  LinkCheckInState get empty => const LinkCheckInState();

  void setHadContact(String value) =>
      edit((current) => current.copyWith(hadContact: value));
  void setQuality(int value) =>
      edit((current) => current.copyWith(quality: value));
  void setInitiator(String value) =>
      edit((current) => current.copyWith(initiator: value));
  void markSaved() => edit((current) => current.copyWith(saved: true));
}

final linkCheckInControllerProvider =
    NotifierProvider<LinkCheckInController, Map<String, LinkCheckInState>>(
  LinkCheckInController.new,
);

final currentLinkCheckInProvider =
    Provider.autoDispose<LinkCheckInState?>((ref) {
  final key = currentCareContextKey(ref.watch(currentCaringContextProvider));
  if (key == null) return null;
  return ref.watch(linkCheckInControllerProvider)[key] ??
      const LinkCheckInState();
});

// ─── Evaluación de encuentros (MobileScreen09A) ─────────────────────────────

/// Estado en curso de la **evaluación de un encuentro**: puntuación 1–7 y tres
/// valoraciones adicionales. Portado de `MobileScreen09A`.
class EncounterState {
  EncounterState({this.rating, List<int?>? additional, this.saved = false})
      : additional = additional ?? const [null, null, null];

  final int? rating;
  final List<int?> additional;
  final bool saved;

  bool get allAnswered =>
      rating != null && additional.every((r) => r != null);

  EncounterState copyWith({
    Object? rating = _unset,
    List<int?>? additional,
    bool? saved,
  }) {
    return EncounterState(
      rating: rating == _unset ? this.rating : rating as int?,
      additional: additional ?? this.additional,
      saved: saved ?? this.saved,
    );
  }

  static const Object _unset = Object();
}

class EncounterController extends _CareJourneyNotifier<EncounterState> {
  @override
  EncounterState get empty => EncounterState();

  void setRating(int value) => edit((current) => current.copyWith(rating: value));
  void setAdditional(int index, int value) => edit((current) {
        final next = [...current.additional];
        next[index] = value;
        return current.copyWith(additional: next);
      });
  void markSaved() => edit((current) => current.copyWith(saved: true));
}

final encounterControllerProvider =
    NotifierProvider<EncounterController, Map<String, EncounterState>>(
  EncounterController.new,
);

final currentEncounterProvider = Provider.autoDispose<EncounterState?>((ref) {
  final key = currentCareContextKey(ref.watch(currentCaringContextProvider));
  if (key == null) return null;
  return ref.watch(encounterControllerProvider)[key] ?? EncounterState();
});

// ─── Preguntas para conectar (MobileScreen14) ───────────────────────────────

/// Formato de respuesta de las preguntas para conectar (texto/audio/foto).
enum ConnectionResponseFormat { text, audio, photo }

/// Estado en curso de **preguntas para conectar**: pregunta actual, formato,
/// texto, adjunto simulado y si ya se compartió. Portado de `MobileScreen14`.
class ConnectionQuestionsState {
  const ConnectionQuestionsState({
    this.index = 0,
    this.format = ConnectionResponseFormat.text,
    this.text = '',
    this.attachment = '',
    this.shared = false,
  });

  final int index;
  final ConnectionResponseFormat format;
  final String text;
  final String attachment;
  final bool shared;

  bool get hasResponse => format == ConnectionResponseFormat.text
      ? text.trim().isNotEmpty
      : attachment.isNotEmpty;

  ConnectionQuestionsState copyWith({
    int? index,
    ConnectionResponseFormat? format,
    String? text,
    String? attachment,
    bool? shared,
  }) {
    return ConnectionQuestionsState(
      index: index ?? this.index,
      format: format ?? this.format,
      text: text ?? this.text,
      attachment: attachment ?? this.attachment,
      shared: shared ?? this.shared,
    );
  }
}

class ConnectionQuestionsController
    extends _CareJourneyNotifier<ConnectionQuestionsState> {
  @override
  ConnectionQuestionsState get empty => const ConnectionQuestionsState();

  /// Reinicia el compositor en la pregunta [nextIndex] (módulo [total]):
  /// limpia formato, texto, adjunto y estado de compartido.
  void reset(int nextIndex, int total) => edit(
        (current) => ConnectionQuestionsState(index: nextIndex % total),
      );

  void setFormat(ConnectionResponseFormat value) => edit(
        (current) => current.copyWith(format: value, attachment: ''),
      );
  void setText(String value) => edit((current) => current.copyWith(text: value));
  void setAttachment(String value) =>
      edit((current) => current.copyWith(attachment: value));
  void markShared() => edit((current) => current.copyWith(shared: true));
}

final connectionQuestionsControllerProvider = NotifierProvider<
    ConnectionQuestionsController, Map<String, ConnectionQuestionsState>>(
  ConnectionQuestionsController.new,
);

final currentConnectionQuestionsProvider =
    Provider.autoDispose<ConnectionQuestionsState?>((ref) {
  final key = currentCareContextKey(ref.watch(currentCaringContextProvider));
  if (key == null) return null;
  return ref.watch(connectionQuestionsControllerProvider)[key] ??
      const ConnectionQuestionsState();
});

// ─── Mensaje íntimo (MobileScreen10, "intimate") ────────────────────────────

/// Estado en curso del **mensaje íntimo**: texto del borrador y si ya se
/// preparó. Portado de `MobileScreen10` con `messageKind == "intimate"`.
class IntimateMessageState {
  const IntimateMessageState({this.text = '', this.saved = false});

  final String text;
  final bool saved;

  IntimateMessageState copyWith({String? text, bool? saved}) =>
      IntimateMessageState(text: text ?? this.text, saved: saved ?? this.saved);
}

class IntimateMessageController
    extends _CareJourneyNotifier<IntimateMessageState> {
  @override
  IntimateMessageState get empty => const IntimateMessageState();

  void setText(String value) => edit((current) => current.copyWith(text: value));
  void markSaved() => edit((current) => current.copyWith(saved: true));
}

final intimateMessageControllerProvider = NotifierProvider<
    IntimateMessageController, Map<String, IntimateMessageState>>(
  IntimateMessageController.new,
);

final currentIntimateMessageProvider =
    Provider.autoDispose<IntimateMessageState?>((ref) {
  final key = currentCareContextKey(ref.watch(currentCaringContextProvider));
  if (key == null) return null;
  return ref.watch(intimateMessageControllerProvider)[key] ??
      const IntimateMessageState();
});