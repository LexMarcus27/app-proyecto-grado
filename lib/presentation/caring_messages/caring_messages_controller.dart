import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../domain/caring_messages/caring_messages.dart';
import '../../domain/journey/caregiver.dart';
import '../authorization/gating.dart';

/// Cuidador de demostración cuyo vínculo se compone en la demo.
const String demoCaregiverId = DemoCaregiver.id;

/// [CaregiverContext] vigente del cuidador de demostración, derivado del
/// recorrido en vivo. `null` si no hay vínculo activo (revocación incluida). La
/// pantalla de redacción lo observa para ocultar el borrador y bloquear el
/// envío cuando el vínculo deja de estar activo (Requirement 4.5).
final currentCaringContextProvider =
    Provider.autoDispose<CaregiverContext?>((ref) {
  // Observa el recorrido en vivo para reaccionar a revocaciones; además, para
  // resolver el contexto incluso antes de que el `Stream` emita (p. ej. al
  // editar un borrador recién abierto), cae al valor síncrono del repositorio.
  final live = ref.watch(gatingJourneyProvider).value;
  final journey = live ?? ref.watch(journeyRepositoryProvider).currentOrNull;
  if (journey == null) return null;
  return caregiverContext(journey, demoCaregiverId);
});

/// Borradores de mensaje de cuidado **aislados por vínculo** (sesión).
///
/// Cada borrador se guarda bajo la clave del contexto de cuidado
/// (`caringDraftKey`), de modo que un borrador pertenece a una tupla exacta
/// (cuidador, PCS, persona, asociación). Las notas privadas y las preguntas
/// seleccionadas viven aquí y **no** se incluyen en el registro enviado
/// (Requirement 8.5). Al revocarse el vínculo, el contexto deja de resolverse y
/// su borrador deja de ser accesible desde la pantalla (queda aislado).
class CaringDraftController extends Notifier<Map<String, CaringMessageDraft>> {
  @override
  Map<String, CaringMessageDraft> build() => const {};

  /// Clave del vínculo vigente: el `caringDraftKey` del **contexto completo**
  /// (cuidador, PCS, persona, asociación), o `null` si no hay vínculo válido.
  /// Sin contexto no hay clave y **no se edita**: una escritura sin vínculo no
  /// se guarda y, por tanto, no puede atribuirse a una asociación posterior.
  String? get _currentKey {
    final context = ref.read(currentCaringContextProvider);
    return context == null ? null : caringDraftKey(context);
  }

  CaringMessageDraft _draftFor(String key) => state[key] ?? createCaringDraft();

  void _set(String key, CaringMessageDraft draft) {
    state = {...state, key: draft};
  }

  /// Aplica [edit] al borrador del vínculo vigente. Si no hay contexto válido,
  /// es un no-op: no se permite editar sin vínculo (el borrador debe asociarse
  /// siempre a una clave de vínculo completa).
  void _edit(CaringMessageDraft Function(CaringMessageDraft current) edit) {
    final key = _currentKey;
    if (key == null) return;
    _set(key, edit(_draftFor(key)));
  }

  void setText(String text) => _edit((current) => current.copyWith(text: text));

  void appendIdea(String idea) => _edit((current) => appendCaringIdea(current, idea));

  void toggleQuestion(int index) =>
      _edit((current) => toggleCaringQuestion(current, index));

  void setNote(int index, String note) => _edit(
        (current) => current.copyWith(notes: {...current.notes, index: note}),
      );

  void reset() {
    final key = _currentKey;
    if (key == null) return;
    final next = {...state}..remove(key);
    state = next;
  }
}

/// Provider del mapa de borradores por vínculo.
final caringDraftControllerProvider =
    NotifierProvider<CaringDraftController, Map<String, CaringMessageDraft>>(
  CaringDraftController.new,
);

/// Borrador del vínculo **vigente**, o `null` si no hay vínculo activo.
///
/// Se resuelve a partir del contexto de cuidado actual: si el vínculo se revoca,
/// devuelve `null` y la pantalla oculta el borrador y bloquea el envío.
final currentCaringDraftProvider =
    Provider.autoDispose<CaringMessageDraft?>((ref) {
  final context = ref.watch(currentCaringContextProvider);
  if (context == null) return null; // vínculo revocado: borrador oculto
  final drafts = ref.watch(caringDraftControllerProvider);
  // Solo la clave completa del vínculo: no hay respaldo provisional compartido,
  // de modo que una escritura sin vínculo nunca respalda a otra asociación.
  return drafts[caringDraftKey(context)] ?? createCaringDraft();
});

/// Contador de envíos de la sesión, para generar ids estables de mensaje.
final _caringSendSequenceProvider =
    NotifierProvider<_CaringSendSequence, int>(_CaringSendSequence.new);

class _CaringSendSequence extends Notifier<int> {
  @override
  int build() => 0;
  int next() {
    state = state + 1;
    return state;
  }
}

/// Acciones de envío simulado del mensaje de cuidado (Capa_Simulada).
class CaringSendController {
  CaringSendController(this._ref);
  final Ref _ref;

  /// Simula el envío de [text] del cuidador [caregiverId]: crea el registro
  /// (sin datos privados) y lo agrega al repositorio. Devuelve `true` si se
  /// "envió"; `false` si no hay vínculo vigente o el texto está vacío.
  ///
  /// Si se indica [expectedAssociationId] (la asociación que el usuario estaba
  /// revisando), el envío solo procede cuando el vínculo vigente coincide con
  /// esa misma asociación: así no se envía con un contexto distinto del que se
  /// revisó (p. ej. si cambió o se revocó entre la revisión y el envío).
  Future<bool> simulateSend(
    String caregiverId,
    String text, {
    String? expectedAssociationId,
  }) async {
    // Lee el recorrido autoritativo del repositorio (no el valor cacheado del
    // stream de gating, que puede no haber emitido aún).
    final journey = await _ref.read(journeyRepositoryProvider).loadJourney();
    final context = caregiverContext(journey, caregiverId);
    if (context == null) return false;
    if (expectedAssociationId != null &&
        context.associationId != expectedAssociationId) {
      // El contexto vigente ya no es el que se estaba revisando.
      return false;
    }
    final id = 'caring-${_ref.read(_caringSendSequenceProvider.notifier).next()}';
    final message = createSimulatedCaringMessage(journey, caregiverId, text, id);
    if (message == null) return false;
    await _ref.read(caringMessageRepositoryProvider).addMessage(message);
    return true;
  }
}

/// Provider del controlador de envío simulado.
final caringSendControllerProvider = Provider<CaringSendController>(
  CaringSendController.new,
);

/// Mensajes de cuidado **visibles** para el PCS (bandeja), derivados del
/// repositorio y del recorrido vigente: solo los de vínculo aún activo
/// (`visibleCaringMessages`). La bandeja se abre sin exigir asociación activa,
/// pero un mensaje cuyo vínculo se revocó deja de mostrarse (Requirement 8.6).
final visibleCaringMessagesProvider =
    StreamProvider.autoDispose<List<SimulatedCaringMessage>>((ref) async* {
  final repo = ref.watch(caringMessageRepositoryProvider);
  await for (final messages in repo.watchMessages()) {
    final journey = ref.watch(gatingJourneyProvider).value;
    if (journey == null) {
      yield const [];
    } else {
      yield visibleCaringMessages(journey, messages);
    }
  }
});
/// Número de mensajes de cuidado visibles para el PCS (para el contador
/// «Ver mensajes de cuidado (n)» del hub de conexión).
final visibleCaringMessagesCountProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(visibleCaringMessagesProvider).value?.length ?? 0,
);

/// Vínculos (clave completa `caringDraftKey`) cuya guía de mensajes de cuidado
/// ya se recorrió en esta sesión (`caringGuidesReviewed` de `App.tsx`, F10).
/// Vive solo en memoria; otra asociación no hereda la lectura.
class CaringGuidesReviewedController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  void markReviewed(String key) {
    if (state.contains(key)) return;
    state = {...state, key};
  }
}

/// Provider de las guías revisadas por vínculo en la sesión.
final caringGuidesReviewedProvider =
    NotifierProvider<CaringGuidesReviewedController, Set<String>>(
  CaringGuidesReviewedController.new,
);
