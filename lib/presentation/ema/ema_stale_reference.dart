import '../../domain/ema/ema.dart';
import '../../domain/journey/journey.dart';

/// Modo de la revisión de la Referencia_EMA obsoleta (tarea 2.12).
///
/// Describe, de forma pura y testeable, qué debe presentar el flujo EMA cuando
/// comprueba la [EmaReference] guardada contra el `JourneyState` vigente, antes
/// de abrir el registro del día. Portado de la rama del prototipo
/// (`src/screens/ema.tsx`) que se activa cuando `!activeReference &&
/// !omittedRelationship`: si la referencia guardada ya no corresponde a un
/// vínculo activo hay que **revisar** la elección sin cambiarla automáticamente
/// (Requirements 5.7, 5.8, 5.9, 5.10).
///
/// El prototipo distingue dos variantes de esa revisión por `people.length`
/// (donde `people === validCaregivers(journey)`):
/// - `people.length === 0` → además de "Ir a Tu mapa de red" ofrece el enlace
///   secundario "Continuar con el registro de hoy" que omite el bloque de
///   relación solo ese día ([reviewNoActivePeople]).
/// - `people.length > 0` → solo dirige a "Tu mapa de red" para confirmar otra
///   persona, sin ofrecer la omisión ([reviewOtherActivePeople]).
enum EmaReferenceReviewMode {
  /// La referencia guardada sigue activa, o no hay ninguna guardada: no hay
  /// nada que revisar en este punto del flujo (el camino sin referencia previa
  /// es la selección de 2.11 / el primer registro sin vínculo de 2.16, no esta
  /// revisión).
  none,

  /// Hay una referencia guardada que ya **no** está activa y **no** existe
  /// ninguna persona con vínculo activo ([validCaregivers] vacío). Caso A: la
  /// revisión ofrece "Ir a Tu mapa de red" (primaria) y, además, "Continuar con
  /// el registro de hoy" (secundaria) que omite el bloque de relación solo ese
  /// día sin alterar la referencia guardada.
  reviewNoActivePeople,

  /// Hay una referencia guardada que ya **no** está activa pero **sí** existen
  /// otras personas con vínculo activo ([validCaregivers] no vacío). Caso B: la
  /// revisión dirige a "Tu mapa de red" para confirmar una nueva referencia,
  /// **sin** ofrecer la omisión del bloque (no hay "Continuar con el registro
  /// de hoy").
  reviewOtherActivePeople,
}

/// Decide el [EmaReferenceReviewMode] a partir de la referencia guardada y el
/// recorrido vigente.
///
/// Función pura (sin UI ni efectos) para que el flujo EMA de extremo a extremo
/// (tarea 2.17) gatille la revisión correctamente y para poder probarla en
/// aislamiento:
/// - Si no hay [savedReference] o sigue activa ([isEmaReferenceActive]) →
///   [EmaReferenceReviewMode.none].
/// - Si hay una guardada que ya no está activa → se mira
///   [validCaregivers]: vacío ⇒ [EmaReferenceReviewMode.reviewNoActivePeople];
///   no vacío ⇒ [EmaReferenceReviewMode.reviewOtherActivePeople].
EmaReferenceReviewMode emaStaleReferenceMode(
  EmaReference? savedReference,
  JourneyState journey,
) {
  if (savedReference == null || isEmaReferenceActive(journey, savedReference)) {
    return EmaReferenceReviewMode.none;
  }
  return validCaregivers(journey).isEmpty
      ? EmaReferenceReviewMode.reviewNoActivePeople
      : EmaReferenceReviewMode.reviewOtherActivePeople;
}
