import 'package:equatable/equatable.dart';

import 'care_association.dart';
import 'invitation_status.dart';
import 'journey_authorization.dart';
import 'journey_demo.dart';
import 'journey_state.dart';
import 'network_person.dart';

/// Sesión de cuidador ficticia del prototipo (no es autenticación ni control de
/// acceso clínico).
///
/// Portado verbatim del prototipo (`src/caregiver.ts`, `DEMO_CAREGIVER`).
class DemoCaregiver {
  const DemoCaregiver._();

  /// Identificador del cuidador de demostración (`caregiver-home-marta`).
  static const String id = 'caregiver-home-marta';

  /// Nombre del cuidador de demostración (`Marta`).
  static const String name = 'Marta';
}

/// Identificador de la persona vinculada en la demo del cuidador.
///
/// Portado verbatim del prototipo (`src/caregiver.ts`, `DEMO_PERSON_ID`).
const String _demoPersonId = 'demo-home-marta';

/// Identificador de la asociación de la demo del cuidador.
///
/// Portado verbatim del prototipo (`src/caregiver.ts`, `association-home-marta`).
const String _demoAssociationId = 'association-home-marta';

/// Modos de simulación del vínculo de cuidado del prototipo.
///
/// Portado verbatim del prototipo (`src/caregiver.ts`, `CaregiverDemoMode`).
enum CaregiverDemoMode {
  /// Invitación `accepted` y asociación activa.
  active('active'),

  /// Invitación `accepted` pero asociación inactiva.
  acceptedOnly('accepted-only'),

  /// Vínculo revocado: invitación `cancelled` y asociación inactiva.
  revoked('revoked');

  const CaregiverDemoMode(this.wireValue);

  /// Cadena exacta del prototipo (TypeScript).
  final String wireValue;

  /// Resuelve un [CaregiverDemoMode] a partir de su cadena del prototipo.
  static CaregiverDemoMode fromWire(String value) {
    for (final mode in CaregiverDemoMode.values) {
      if (mode.wireValue == value) return mode;
    }
    throw ArgumentError.value(value, 'value', 'CaregiverDemoMode desconocido');
  }
}

/// Contexto resuelto de un cuidador con vínculo activo.
///
/// Portado del prototipo (`src/caregiver.ts`, interfaz `CaregiverContext`).
/// Modelo inmutable con igualdad por valor.
class CaregiverContext extends Equatable {
  const CaregiverContext({
    required this.caregiverId,
    required this.caregiverName,
    required this.personId,
    required this.pcsId,
    required this.pcsName,
    required this.associationId,
  });

  /// Identificador del cuidador.
  final String caregiverId;

  /// Nombre del cuidador (tomado del nombre de la persona vinculada).
  final String caregiverName;

  /// Identificador de la persona vinculada.
  final String personId;

  /// Identificador del PCS.
  final String pcsId;

  /// Nombre del PCS (`Sofía` en el prototipo).
  final String pcsName;

  /// Identificador de la asociación activa.
  final String associationId;

  @override
  List<Object?> get props => [
    caregiverId,
    caregiverName,
    personId,
    pcsId,
    pcsName,
    associationId,
  ];
}

/// Resuelve el [CaregiverContext] de un cuidador, o `null` si no hay vínculo
/// válido.
///
/// Portado verbatim del prototipo (`src/caregiver.ts`, `caregiverContext`).
/// La persona debe satisfacer [canStrengthenRelationship] y debe existir una
/// asociación activa con [currentPcsId] que coincida en la tupla
/// (`personId`, `caregiverId`, `pcsId`). El nombre del PCS es `Sofía`.
CaregiverContext? caregiverContext(JourneyState state, String caregiverId) {
  NetworkPerson? person;
  for (final candidate in state.people) {
    if (candidate.caregiverId == caregiverId &&
        canStrengthenRelationship(state, candidate.id)) {
      person = candidate;
      break;
    }
  }
  if (person == null) return null;

  CareAssociation? association;
  for (final candidate in state.associations) {
    if (candidate.active &&
        candidate.personId == person.id &&
        candidate.caregiverId == caregiverId &&
        candidate.pcsId == currentPcsId) {
      association = candidate;
      break;
    }
  }
  if (association == null) return null;

  return CaregiverContext(
    caregiverId: caregiverId,
    caregiverName: person.name,
    personId: person.id,
    pcsId: association.pcsId,
    pcsName: 'Sofía',
    associationId: association.id,
  );
}

/// Simula el vínculo de cuidado de la demo según [mode], sin mutar [state].
///
/// Portado verbatim del prototipo (`src/caregiver.ts`, `simulateCaregiverLink`).
/// Fusiona únicamente el vínculo de demostración solicitado: conserva el mapa
/// del PCS y las demás personas. La invitación queda `accepted` salvo en modo
/// [CaregiverDemoMode.revoked] (que la vuelve `cancelled`), y la asociación es
/// activa solo en modo [CaregiverDemoMode.active]. No duplica la asociación.
JourneyState simulateCaregiverLink(JourneyState state, CaregiverDemoMode mode) {
  NetworkPerson? existing;
  for (final candidate in state.people) {
    if (candidate.id == _demoPersonId) {
      existing = candidate;
      break;
    }
  }

  final NetworkPerson base = existing ??
      demoPeople[0].copyWith(answers: List<int?>.from(demoPeople[0].answers));

  final NetworkPerson person = base.copyWith(
    id: _demoPersonId,
    name: DemoCaregiver.name,
    caregiverId: DemoCaregiver.id,
    invitationStatus: mode == CaregiverDemoMode.revoked
        ? InvitationStatus.cancelled
        : InvitationStatus.accepted,
  );

  final List<CareAssociation> associations = [
    for (final association in state.associations)
      if (association.id != _demoAssociationId) association,
    CareAssociation(
      id: _demoAssociationId,
      pcsId: currentPcsId,
      caregiverId: DemoCaregiver.id,
      personId: person.id,
      active: mode == CaregiverDemoMode.active,
    ),
  ];

  final List<NetworkPerson> people = existing != null
      ? [
          for (final item in state.people)
            if (item.id == person.id) person else item,
        ]
      : [...state.people, person];

  return state.copyWith(people: people, associations: associations);
}
