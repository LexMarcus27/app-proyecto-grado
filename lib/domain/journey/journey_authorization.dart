import 'invitation_status.dart';
import 'journey_demo.dart';
import 'journey_state.dart';
import 'network_person.dart';

/// Autorización por asociación activa (núcleo del dominio).
///
/// Portado verbatim del prototipo (`src/journey.ts`, `canStrengthenRelationship`).
///
/// Devuelve `true` **solo si** la persona existe, su invitación es
/// [InvitationStatus.accepted], tiene un `caregiverId` y existe una asociación
/// que coincide en la tupla exacta (`personId`, `pcsId`, `caregiverId`) y está
/// activa. [pcsId] por defecto es [currentPcsId].
bool canStrengthenRelationship(
  JourneyState state,
  String? personId, {
  String pcsId = currentPcsId,
}) {
  if (personId == null) return false;

  NetworkPerson? person;
  for (final candidate in state.people) {
    if (candidate.id == personId) {
      person = candidate;
      break;
    }
  }

  if (person == null ||
      person.invitationStatus != InvitationStatus.accepted ||
      person.caregiverId == null) {
    return false;
  }

  return state.associations.any(
    (association) =>
        association.personId == person!.id &&
        association.pcsId == pcsId &&
        association.caregiverId == person.caregiverId &&
        association.active,
  );
}

/// Personas de la red para las que [canStrengthenRelationship] es `true`.
///
/// Portado verbatim del prototipo (`src/journey.ts`, `validCaregivers`). Usa el
/// PCS por defecto ([currentPcsId]).
List<NetworkPerson> validCaregivers(JourneyState state) {
  return state.people
      .where((person) => canStrengthenRelationship(state, person.id))
      .toList();
}
