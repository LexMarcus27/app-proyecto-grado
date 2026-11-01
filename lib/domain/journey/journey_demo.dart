import 'care_association.dart';
import 'invitation_status.dart';
import 'journey_state.dart';
import 'network_person.dart';
import 'onboarding_status.dart';
import 'person_status.dart';
import 'relationship_type.dart';

/// Identificador del PCS actual del prototipo.
///
/// Portado verbatim del prototipo (`src/journey.ts`, `CURRENT_PCS_ID`). La
/// cadena `pcs-sofia` se preserva exactamente porque la autorización por tupla,
/// las pruebas portadas y el dominio EMA dependen de ella.
const String currentPcsId = 'pcs-sofia';

/// Recorrido vacío inicial.
///
/// Portado verbatim del prototipo (`src/journey.ts`, `EMPTY_JOURNEY`).
const JourneyState emptyJourney = JourneyState(
  mapStarted: false,
  mapGenerated: false,
  people: <NetworkPerson>[],
  selectedPersonId: null,
  associations: <CareAssociation>[],
  onboardingStatus: OnboardingStatus.notStarted,
  onboardingWelcomeShown: false,
  activityInProgress: false,
  dailyCheckInPending: true,
);

/// Cinco personas ficticias de demostración.
///
/// Portado verbatim del prototipo (`src/journey.ts`, `DEMO_PEOPLE`). Los
/// identificadores, respuestas (`answers`), tipos de relación, estado e invitación
/// se preservan exactamente como en el prototipo.
final List<NetworkPerson> demoPeople = List<NetworkPerson>.unmodifiable([
  const NetworkPerson(
    id: 'demo-m',
    name: 'M.',
    relationshipType: RelationshipType.familia,
    answers: [6, 5, 5, 5, 5, 2, 5, 1, 6, 6, 2, 6, 5, 6, 2, 2, 1, 2],
    status: PersonStatus.complete,
    invitationStatus: InvitationStatus.accepted,
    caregiverId: 'caregiver-m',
  ),
  const NetworkPerson(
    id: 'demo-alex',
    name: 'Alex',
    relationshipType: RelationshipType.amistades,
    answers: [5, 4, 5, 4, 5, 3, 5, 2, 5, 5, 3, 5, 5, 5, 3, 2, 2, 3],
    status: PersonStatus.complete,
    invitationStatus: InvitationStatus.pending,
  ),
  const NetworkPerson(
    id: 'demo-carmen',
    name: 'Carmen',
    relationshipType: RelationshipType.trabajoOEstudio,
    answers: [4, 3, 3, 3, 4, 4, 3, 4, 4, 3, 4, 3, 3, 4, 4, 4, 3, 4],
    status: PersonStatus.complete,
    invitationStatus: InvitationStatus.accepted,
    caregiverId: 'caregiver-carmen',
  ),
  const NetworkPerson(
    id: 'demo-lu',
    name: 'Lu',
    relationshipType: RelationshipType.comunidadServicioOCredo,
    answers: [4, 2, 4, 4, 3, 2, 4, 2, 4, 4, 2, 4, 4, 4, 2, 2, 2, 2],
    status: PersonStatus.complete,
    invitationStatus: InvitationStatus.notInvited,
  ),
  const NetworkPerson(
    id: 'demo-sam',
    name: 'Sam',
    relationshipType: RelationshipType.amistades,
    answers: [5, 4, 4, 3, 4, 5, 3, 5, 4, 4, 5, 4, 3, 4, 5, 5, 4, 5],
    status: PersonStatus.complete,
    invitationStatus: InvitationStatus.declined,
  ),
]);

/// Construye el recorrido de demostración.
///
/// Portado verbatim del prototipo (`src/journey.ts`, `createDemoJourney`).
/// Produce el mismo estado demo: `mapStarted`/`mapGenerated` en `true`, las
/// cinco personas de [demoPeople] (con sus respuestas copiadas), las dos
/// asociaciones `association-demo-m` (activa) y `association-demo-carmen`
/// (inactiva), onboarding `completed` con bienvenida mostrada y check-in diario
/// pendiente.
JourneyState createDemoJourney() {
  return JourneyState(
    mapStarted: true,
    mapGenerated: true,
    people: [
      for (final person in demoPeople)
        person.copyWith(answers: List<int?>.from(person.answers)),
    ],
    selectedPersonId: null,
    associations: const [
      CareAssociation(
        id: 'association-demo-m',
        pcsId: currentPcsId,
        caregiverId: 'caregiver-m',
        personId: 'demo-m',
        active: true,
      ),
      CareAssociation(
        id: 'association-demo-carmen',
        pcsId: currentPcsId,
        caregiverId: 'caregiver-carmen',
        personId: 'demo-carmen',
        active: false,
      ),
    ],
    onboardingStatus: OnboardingStatus.completed,
    onboardingWelcomeShown: true,
    activityInProgress: false,
    dailyCheckInPending: true,
  );
}
