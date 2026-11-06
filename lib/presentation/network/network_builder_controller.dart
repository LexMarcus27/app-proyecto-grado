import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../domain/journey/journey.dart';
import '../../domain/network/network.dart';
import '../../domain/repositories/repositories.dart';

/// Controlador de la construcción del mapa de red (tarea 3.11).
///
/// Gestiona el flujo del generador de nombres (captura de personas), la
/// evaluación por persona (18 ítems) y la generación de resultados
/// (`generateResults`), persistiendo el `JourneyState` a través del
/// repositorio. El cómputo de resultados es una Funcion_Simulada.
class NetworkBuilderController {
  NetworkBuilderController(this._repository);

  final JourneyRepository _repository;

  /// Agrega una persona capturada por el generador de nombres (estado inicial
  /// `pending`, sin respuestas), marcando el recorrido como `mapStarted`.
  Future<NetworkPerson> addPerson(String name, RelationshipType type) async {
    final journey = await _repository.loadJourney();
    final id = 'person-${DateTime.now().microsecondsSinceEpoch}';
    final person = NetworkPerson(
      id: id,
      name: name.trim(),
      relationshipType: type,
      answers: List<int?>.filled(relationshipItemCount, null),
      status: PersonStatus.pending,
      invitationStatus: InvitationStatus.notInvited,
    );
    await _repository.save(
      journey.copyWith(mapStarted: true, people: [...journey.people, person]),
    );
    return person;
  }

  /// Aplica la respuesta [value] (1..6) al ítem [index] de la persona [personId]
  /// y persiste el avance (marca `complete` al terminar los 18 ítems).
  Future<void> answer(String personId, int index, int value) async {
    final journey = await _repository.loadJourney();
    final people = [
      for (final p in journey.people)
        if (p.id == personId)
          answerRelationshipItem(p, index, value)
        else
          p,
    ];
    await _repository.save(journey.copyWith(people: people));
  }

  /// Genera el mapa si hay al menos una persona evaluada (Funcion_Simulada:
  /// imita el cómputo con un breve retardo) y persiste el resultado.
  Future<bool> generate({
    Duration delay = const Duration(milliseconds: 550),
  }) async {
    final journey = await _repository.loadJourney();
    if (assessedPeople(journey).isEmpty) return false;
    await Future<void>.delayed(delay);
    await _repository.save(generateResults(journey));
    return true;
  }
}

/// Provider del controlador de construcción del mapa.
final networkBuilderControllerProvider =
    Provider.autoDispose<NetworkBuilderController>(
  (ref) => NetworkBuilderController(ref.read(journeyRepositoryProvider)),
);