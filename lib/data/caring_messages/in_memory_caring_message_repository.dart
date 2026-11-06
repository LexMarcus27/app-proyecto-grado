import 'dart:async';

import '../../domain/caring_messages/caring_message.dart';
import '../../domain/repositories/repositories.dart';

/// Implementación en memoria de [CaringMessageRepository] (Capa_Simulada).
///
/// Los mensajes "enviados" viven solo en la sesión: no se persisten y se pierden
/// al recargar. El registro conserva lo que el dominio produjo
/// (`createSimulatedCaringMessage`), que ya excluye notas privadas y preguntas
/// de reflexión (Requirement 8.5).
class InMemoryCaringMessageRepository implements CaringMessageRepository {
  final List<SimulatedCaringMessage> _messages = [];
  final StreamController<List<SimulatedCaringMessage>> _controller =
      StreamController<List<SimulatedCaringMessage>>.broadcast();

  @override
  Stream<List<SimulatedCaringMessage>> watchMessages() async* {
    yield List.unmodifiable(_messages);
    yield* _controller.stream;
  }

  @override
  Future<List<SimulatedCaringMessage>> loadMessages() async {
    return List.unmodifiable(_messages);
  }

  @override
  Future<void> addMessage(SimulatedCaringMessage message) async {
    _messages.add(message);
    _controller.add(List.unmodifiable(_messages));
  }
}