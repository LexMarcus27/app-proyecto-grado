import 'package:equatable/equatable.dart';

import 'invitation_status.dart';
import 'person_status.dart';
import 'relationship_type.dart';

/// Persona de la red de apoyo del PCS.
///
/// Portado del prototipo (`src/journey.ts`, interfaz `NetworkPerson`). Modelo
/// inmutable con igualdad por valor.
///
/// `answers` corresponde a `(number | null)[]` del prototipo: las respuestas de
/// la evaluación de la relación, donde `null` representa un ítem sin responder.
class NetworkPerson extends Equatable {
  const NetworkPerson({
    required this.id,
    required this.name,
    required this.answers,
    required this.status,
    required this.invitationStatus,
    this.relationshipType,
    this.caregiverId,
  });

  /// Identificador estable de la persona (p. ej. `demo-m`).
  final String id;

  /// Nombre visible de la persona.
  final String name;

  /// Tipo de relación, opcional (puede no estar definido aún).
  final RelationshipType? relationshipType;

  /// Respuestas de la evaluación de la relación. `null` = ítem sin responder.
  final List<int?> answers;

  /// Estado de avance de la evaluación de la persona.
  final PersonStatus status;

  /// Estado de la invitación de cuidado.
  final InvitationStatus invitationStatus;

  /// Identificador del cuidador asociado, opcional.
  final String? caregiverId;

  /// Devuelve una copia con los campos indicados reemplazados.
  ///
  /// Nota: `relationshipType` y `caregiverId` no pueden borrarse (volverse
  /// `null`) con `copyWith`; omitir un parámetro conserva el valor actual.
  NetworkPerson copyWith({
    String? id,
    String? name,
    RelationshipType? relationshipType,
    List<int?>? answers,
    PersonStatus? status,
    InvitationStatus? invitationStatus,
    String? caregiverId,
  }) {
    return NetworkPerson(
      id: id ?? this.id,
      name: name ?? this.name,
      relationshipType: relationshipType ?? this.relationshipType,
      answers: answers ?? this.answers,
      status: status ?? this.status,
      invitationStatus: invitationStatus ?? this.invitationStatus,
      caregiverId: caregiverId ?? this.caregiverId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    relationshipType,
    answers,
    status,
    invitationStatus,
    caregiverId,
  ];
}
