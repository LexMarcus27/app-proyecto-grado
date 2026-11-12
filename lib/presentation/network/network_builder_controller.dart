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

  /// Agrega una persona capturada por el generador de nombres **sin tipo de
  /// relación** (se define después, en el paso 1 de la caracterización). Evita
  /// duplicados por nombre normalizado (acentos/mayúsculas); si ya existe, no
  /// agrega y devuelve la persona existente. Portado de `appendPerson`/`addPerson`.
  Future<NetworkPerson> addNamedPerson(String name) async {
    final journey = await _repository.loadJourney();
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'El nombre no puede estar vacío');
    }
    final normalized = trimmed.toLowerCase();
    for (final existing in journey.people) {
      if (existing.name.trim().toLowerCase() == normalized) {
        return existing; // no duplica
      }
    }
    final id = 'person-${DateTime.now().microsecondsSinceEpoch}';
    final person = NetworkPerson(
      id: id,
      name: trimmed,
      answers: List<int?>.filled(relationshipItemCount, null),
      status: PersonStatus.pending,
      invitationStatus: InvitationStatus.notInvited,
    );
    await _repository.save(
      journey.copyWith(mapStarted: true, people: [...journey.people, person]),
    );
    return person;
  }

  /// Define el tipo de relación de [personId] (paso 1 de la caracterización,
  /// "¿Quién es {nombre} para ti?") y marca la persona como `inProgress`.
  Future<void> setRelationshipType(
    String personId,
    RelationshipType type,
  ) async {
    final journey = await _repository.loadJourney();
    final people = [
      for (final p in journey.people)
        if (p.id == personId)
          p.copyWith(relationshipType: type, status: PersonStatus.inProgress)
        else
          p,
    ];
    await _repository.save(journey.copyWith(people: people));
  }

  /// Renombra a [personId] (revisión de la lista). Ignora nombres vacíos.
  Future<void> renamePerson(String personId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final journey = await _repository.loadJourney();
    final people = [
      for (final p in journey.people)
        if (p.id == personId) p.copyWith(name: trimmed) else p,
    ];
    await _repository.save(journey.copyWith(people: people));
  }

  /// Elimina a [personId] de la lista (revisión).
  Future<void> removePerson(String personId) async {
    final journey = await _repository.loadJourney();
    await _repository.save(journey.copyWith(
      people: [for (final p in journey.people) if (p.id != personId) p],
    ));
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

  /// Simula el envío de una invitación a [personId] (Funcion_Simulada): deja la
  /// invitación como `pending` y persiste el recorrido. No crea ni activa
  /// ninguna asociación, por lo que no habilita acciones de asociación activa.
  /// Devuelve `true` si el estado cambió.
  Future<bool> invite(String personId) async {
    final journey = await _repository.loadJourney();
    final next = simulateInvite(journey, personId);
    if (identical(next, journey)) return false;
    await _repository.save(next);
    return true;
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