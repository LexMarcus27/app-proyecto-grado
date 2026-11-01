import 'package:equatable/equatable.dart';

/// Referencia de relación del registro EMA.
///
/// Portado del prototipo (`src/ema.ts`, interfaz `EmaReference`). Modelo
/// inmutable con igualdad por valor. Contiene **únicamente** los cuatro
/// identificadores que ubican la asociación activa (PCS, persona, cuidador,
/// asociación); nunca respuestas clínicas ni avance del borrador.
class EmaReference extends Equatable {
  const EmaReference({
    required this.pcsId,
    required this.personId,
    required this.caregiverId,
    required this.associationId,
  });

  /// Identificador del PCS.
  final String pcsId;

  /// Identificador de la persona de referencia.
  final String personId;

  /// Identificador del cuidador asociado.
  final String caregiverId;

  /// Identificador de la asociación de cuidado activa.
  final String associationId;

  @override
  List<Object?> get props => [pcsId, personId, caregiverId, associationId];
}
