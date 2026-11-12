import '../journey/journey_authorization.dart';
import '../journey/journey_state.dart';
import '../journey/invitation_status.dart';
import '../journey/network_person.dart';

/// Lógica de invitaciones del mapa de red (tarea 3.12), portada verbatim del
/// prototipo (`invitationLabel`, `invitationVariant` y el cambio de estado al
/// "Simular envío de invitación" en `src/screens/network.tsx`). Dart puro.
///
/// Regla conservada (Requirement 9.9/9.10): una invitación **aceptada por sí
/// sola no habilita** las acciones que requieren una Asociacion_Activa; eso lo
/// decide [canStrengthenRelationship], no el estado de invitación.

/// Variante visual del distintivo de estado de invitación (equivale a los
/// `StatusChip` del prototipo: `ok` | `warn` | `blue` | `default`).
enum InvitationBadgeVariant { ok, warn, blue, defaultVariant }

/// Etiqueta del estado de invitación de [person] en [journey], verbatim.
///
/// Prioriza el vínculo activo ("Persona cercana vinculada") y luego los estados
/// de invitación. Una invitación `accepted` sin asociación activa muestra
/// "Vinculación en proceso" (no habilita acciones de asociación activa).
String invitationLabel(NetworkPerson person, JourneyState journey) {
  if (canStrengthenRelationship(journey, person.id)) {
    return 'Persona cercana vinculada';
  }
  if (person.invitationStatus == InvitationStatus.accepted) {
    return 'Vinculación en proceso';
  }
  switch (person.invitationStatus) {
    case InvitationStatus.notInvited:
      return 'Sin invitación';
    case InvitationStatus.pending:
      return 'Pendiente de aceptación';
    case InvitationStatus.declined:
      return 'Invitación rechazada';
    case InvitationStatus.cancelled:
      return 'Invitación cancelada';
    case InvitationStatus.expired:
      return 'Invitación expirada';
    case InvitationStatus.accepted:
      return 'Vinculación en proceso';
  }
}

/// Variante del distintivo de estado de invitación de [person], verbatim.
InvitationBadgeVariant invitationVariant(
  NetworkPerson person,
  JourneyState journey,
) {
  if (canStrengthenRelationship(journey, person.id)) {
    return InvitationBadgeVariant.ok;
  }
  if (person.invitationStatus == InvitationStatus.pending) {
    return InvitationBadgeVariant.warn;
  }
  if (person.invitationStatus == InvitationStatus.accepted) {
    return InvitationBadgeVariant.blue;
  }
  return InvitationBadgeVariant.defaultVariant;
}

/// `true` si [person] puede recibir una invitación (simulada). En el prototipo
/// la acción aparece para `not-invited` ("Invitar") y para
/// `declined`/`cancelled`/`expired` ("Revisar una nueva invitación").
bool canInvite(NetworkPerson person) {
  switch (person.invitationStatus) {
    case InvitationStatus.notInvited:
    case InvitationStatus.declined:
    case InvitationStatus.cancelled:
    case InvitationStatus.expired:
      return true;
    case InvitationStatus.pending:
    case InvitationStatus.accepted:
      return false;
  }
}

/// Simula el envío de una invitación a [personId]: deja la invitación como
/// `pending` (Funcion_Simulada; no entrega ningún mensaje real), igual que el
/// prototipo (`updatePerson(candidate.id, { invitationStatus: "pending" })`).
///
/// No crea ni activa ninguna asociación: una invitación pendiente **no**
/// habilita las acciones de asociación activa. Si la persona no puede recibir
/// invitación ([canInvite] es `false`), devuelve el estado sin cambios.
JourneyState simulateInvite(JourneyState journey, String personId) {
  NetworkPerson? target;
  for (final person in journey.people) {
    if (person.id == personId) {
      target = person;
      break;
    }
  }
  if (target == null || !canInvite(target)) return journey;

  final people = [
    for (final person in journey.people)
      if (person.id == personId)
        person.copyWith(invitationStatus: InvitationStatus.pending)
      else
        person,
  ];
  return journey.copyWith(mapStarted: true, people: people);
}