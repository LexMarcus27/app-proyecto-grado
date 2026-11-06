import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../domain/caring_messages/caring_messages.dart';
import '../authorization/gating.dart';

/// Borrador de mensaje de cuidado del cuidador (sesión), por vínculo.
///
/// Se mantiene un borrador asociado al contexto de cuidado vigente. Las notas
/// privadas y las preguntas seleccionadas viven aquí y **no** se incluyen en el
/// registro enviado (Requirement 8.5).
class CaringDraftController extends Notifier<CaringMessageDraft> {
  @override
  CaringMessageDraft build() => createCaringDraft();

  void setText(String text) => state = state.copyWith(text: text);

  void appendIdea(String idea) => state = appendCaringIdea(state, idea);

  void toggleQuestion(int index) => state = toggleCaringQuestion(state, index);

  void setNote(int index, String note) {
    final notes = {...state.notes, index: note};
    state = state.copyWith(notes: notes);
  }

  void reset() => state = createCaringDraft();
}

/// Provider del borrador de mensaje de cuidado del cuidador.
final caringDraftControllerProvider =
    NotifierProvider<CaringDraftController, CaringMessageDraft>(
  CaringDraftController.new,
);

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
  Future<bool> simulateSend(String caregiverId, String text) async {
    // Lee el recorrido autoritativo del repositorio (no el valor cacheado del
    // stream de gating, que puede no haber emitido aún).
    final journey = await _ref.read(journeyRepositoryProvider).loadJourney();
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