import 'package:equatable/equatable.dart';

/// Asociación de cuidado entre un PCS, un cuidador y una persona de la red.
///
/// Portado del prototipo (`src/journey.ts`, interfaz `CareAssociation`). Modelo
/// inmutable con igualdad por valor. [active] distingue una asociación activa de
/// una revocada; es el núcleo de la autorización por asociación activa.
class CareAssociation extends Equatable {
  const CareAssociation({
    required this.id,
    required this.pcsId,
    required this.caregiverId,
    required this.personId,
    required this.active,
  });

  /// Identificador estable de la asociación (p. ej. `association-demo-m`).
  final String id;

  /// Identificador del PCS.
  final String pcsId;

  /// Identificador del cuidador.
  final String caregiverId;

  /// Identificador de la persona de la red.
  final String personId;

  /// `true` si la asociación está activa; `false` si está revocada.
  final bool active;

  /// Devuelve una copia con los campos indicados reemplazados.
  CareAssociation copyWith({
    String? id,
    String? pcsId,
    String? caregiverId,
    String? personId,
    bool? active,
  }) {
    return CareAssociation(
      id: id ?? this.id,
      pcsId: pcsId ?? this.pcsId,
      caregiverId: caregiverId ?? this.caregiverId,
      personId: personId ?? this.personId,
      active: active ?? this.active,
    );
  }

  @override
  List<Object?> get props => [id, pcsId, caregiverId, personId, active];
}
