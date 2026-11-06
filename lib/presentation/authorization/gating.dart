import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../domain/journey/journey.dart';

/// Flujo en vivo del `JourneyState` para las decisiones de autorización/gating
/// compartidas (tarea 3.6).
///
/// Expone [JourneyRepository.watchJourney] como `StreamProvider` para que tanto
/// los flujos del Cuidador como los del PCS reaccionen a cambios del vínculo
/// (p. ej. una revocación) sin recomputar la autorización a mano.
final gatingJourneyProvider = StreamProvider.autoDispose<JourneyState>(
  (ref) => ref.watch(journeyRepositoryProvider).watchJourney(),
);

/// Decisión de gating por tupla de cuidado, derivada de la autorización de
/// dominio (`canStrengthenRelationship`, Requirement 4.1, 4.2, 4.5).
///
/// Es el punto único que las pantallas del Cuidador y del PCS consultan para
/// **deshabilitar** las acciones de mensaje/contacto/encuentro y para **ocultar**
/// el contenido de cuidado tras una revocación. No reimplementa la regla: la
/// toma del dominio sobre un `JourneyState` concreto.
class CareGating {
  const CareGating(this._state);

  final JourneyState _state;

  /// `true` si la tupla exacta (`pcsId`, `caregiverId`, `personId`) de [personId]
  /// tiene invitación `accepted` y asociación `active` (autorización vigente).
  /// Mientras sea `true`, las acciones dirigidas a esa persona están habilitadas.
  bool canStrengthen(String? personId, {String pcsId = currentPcsId}) {
    return canStrengthenRelationship(_state, personId, pcsId: pcsId);
  }

  /// `true` si una acción de cuidado dirigida a [personId] debe quedar
  /// **deshabilitada** (no hay autorización vigente). Es el complemento de
  /// [canStrengthen], nombrado desde la perspectiva de la UI.
  bool isActionDisabled(String? personId, {String pcsId = currentPcsId}) {
    return !canStrengthen(personId, pcsId: pcsId);
  }

  /// `true` si el contenido de cuidado asociado a [personId] debe **ocultarse**
  /// (Requirement 4.5): tras una revocación —invitación no `accepted` o
  /// asociación inactiva— la autorización deja de estar vigente y el contenido
  /// dependiente del vínculo no se muestra.
  bool isCareContentHidden(String? personId, {String pcsId = currentPcsId}) {
    return !canStrengthen(personId, pcsId: pcsId);
  }

  /// Resuelve el [CaregiverContext] vigente de [caregiverId], o `null` si el
  /// vínculo no está activo. Útil para los flujos del Cuidador que necesitan la
  /// tupla completa cuando la acción está habilitada.
  CaregiverContext? contextFor(String caregiverId) {
    return caregiverContext(_state, caregiverId);
  }

  /// Personas con autorización vigente (vínculo activo) en el recorrido actual.
  List<NetworkPerson> get authorizedPeople => validCaregivers(_state);
}

/// Provider de las decisiones de gating sobre el recorrido en vivo.
///
/// Las pantallas lo observan para habilitar/deshabilitar acciones y ocultar
/// contenido de cuidado de forma reactiva ante revocaciones.
final careGatingProvider = Provider.autoDispose<AsyncValue<CareGating>>((ref) {
  return ref.watch(gatingJourneyProvider).whenData(CareGating.new);
});