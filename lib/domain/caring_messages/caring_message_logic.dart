import '../../content/caring_messages_content.dart';
import '../journey/caregiver.dart';
import '../journey/journey_demo.dart';
import '../journey/journey_state.dart';
import 'caring_message.dart';

/// Lógica de los mensajes de cuidado, portada verbatim del prototipo
/// (`src/caring-messages.ts`). Dart puro, sin dependencias de Flutter.

/// Crea un borrador vacío (portado de `createCaringDraft`).
CaringMessageDraft createCaringDraft() => const CaringMessageDraft();

/// Inserta una idea **de forma aditiva** en el borrador (portado de
/// `appendCaringIdea`, Requirement 8.4): añade la idea sin sobrescribir el texto
/// existente. Si el borrador ya tiene texto, separa con una línea en blanco; si
/// la idea está vacía (solo espacios), devuelve el borrador sin cambios.
CaringMessageDraft appendCaringIdea(CaringMessageDraft draft, String idea) {
  final trimmedIdea = idea.trim();
  if (trimmedIdea.isEmpty) return draft;
  final existing = draft.text.trimRight();
  final newText =
      draft.text.trim().isNotEmpty ? '$existing\n\n$trimmedIdea' : trimmedIdea;
  return draft.copyWith(text: newText);
}

/// Alterna la selección de la pregunta de reflexión [index] (portado de
/// `toggleCaringQuestion`). Ignora índices fuera de rango. La lista de
/// seleccionadas se mantiene en orden ascendente.
CaringMessageDraft toggleCaringQuestion(CaringMessageDraft draft, int index) {
  if (index < 0 || index >= CaringContent.questions.length) return draft;
  final selected = [...draft.selectedQuestions];
  if (selected.contains(index)) {
    selected.remove(index);
  } else {
    selected.add(index);
    selected.sort();
  }
  return draft.copyWith(selectedQuestions: selected);
}

/// Crea el registro de un mensaje de cuidado "enviado" (portado de
/// `createSimulatedCaringMessage`).
///
/// Devuelve `null` si no hay vínculo de cuidado vigente, si el texto está vacío
/// o si el id está vacío. El registro conserva **solo** los identificadores de
/// la tupla, el texto y el estado de entrega simulado; **nunca** incluye notas
/// privadas ni las preguntas de reflexión (Requirement 8.5).
SimulatedCaringMessage? createSimulatedCaringMessage(
  JourneyState state,
  String caregiverId,
  String text,
  String id,
) {
  final context = caregiverContext(state, caregiverId);
  if (context == null || text.trim().isEmpty || id.trim().isEmpty) {
    return null;
  }
  return SimulatedCaringMessage(
    id: id,
    caregiverId: context.caregiverId,
    caregiverName: context.caregiverName,
    pcsId: context.pcsId,
    pcsName: context.pcsName,
    personId: context.personId,
    associationId: context.associationId,
    text: text.trim(),
    delivery: 'simulated',
  );
}

/// Filtra los mensajes **visibles** para el PCS (portado de
/// `visibleCaringMessages`): solo los de entrega simulada cuyo vínculo de
/// cuidado sigue vigente y cuya tupla (pcsId, personId, associationId) coincide
/// con el contexto actual del cuidador. Tras una revocación, el mensaje deja de
/// ser visible (Requirement 4.5, 8.6).
List<SimulatedCaringMessage> visibleCaringMessages(
  JourneyState state,
  List<SimulatedCaringMessage> messages, {
  String pcsId = currentPcsId,
}) {
  return messages.where((message) {
    final context = caregiverContext(state, message.caregiverId);
    return message.delivery == 'simulated' &&
        context != null &&
        message.pcsId == pcsId &&
        context.pcsId == message.pcsId &&
        context.personId == message.personId &&
        context.associationId == message.associationId;
  }).toList();
}