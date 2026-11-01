import '../../domain/ema/ema.dart';
import '../../domain/journey/journey.dart';
import 'ema_reference_selection.dart';
import 'ema_stale_reference.dart';

/// Decisión de compuerta (gating) del flujo EMA de extremo a extremo (tarea
/// 2.17).
///
/// Describe, de forma **pura y testeable**, qué superficie debe presentar el
/// flujo EMA cuando entra, a partir de la [EmaReference] guardada y el
/// `JourneyState` vigente. Compone las reglas puras ya existentes
/// ([emaStaleReferenceMode], [shouldShowEmaReferenceSelection],
/// [isEmaNoLinkFirstRun]) en el **mismo orden de precedencia** que el prototipo
/// (`src/screens/ema.tsx`), para que el widget del flujo solo tenga que
/// enrutar/presentar la superficie resultante.
enum EmaFlowGate {
  /// Hay una referencia guardada que ya **no** está activa: hay que revisar la
  /// elección antes de registrar (pantalla de revisión de referencia obsoleta,
  /// tarea 2.12). El modo concreto (con/sin personas activas) lo sigue
  /// decidiendo [emaStaleReferenceMode] dentro de esa pantalla.
  staleReference,

  /// No hay referencia guardada y existe al menos una persona con vínculo
  /// activo: hay que presentar la selección de Referencia_EMA antes del primer
  /// registro (tarea 2.11).
  referenceSelection,

  /// No hay referencia guardada y **no** existe ninguna persona con vínculo
  /// activo: primer registro sin vínculo (tarea 2.16), que ofrece ir al mapa o
  /// continuar hoy con seis preguntas (omitiendo el bloque de relación).
  noLinkFirstRun,

  /// Hay una referencia activa guardada (o el borrador ya trae la omisión del
  /// día resuelta): entrar directamente al cuestionario.
  questionnaire,
}

/// Decide la [EmaFlowGate] a partir de la referencia guardada, el recorrido
/// vigente y el borrador del día ya preparado.
///
/// Orden de precedencia (fiel al prototipo `src/screens/ema.tsx`):
/// 1. Si el borrador del día **ya** trae la omisión del bloque de relación
///    (`relationshipOmission == "no-active-link"`, resultado de la revisión
///    obsoleta de 2.12 o del camino sin vínculo de 2.16) → [questionnaire]
///    directamente: la decisión de omitir ya se tomó para hoy y no debe
///    re-gatillarse la revisión/selección.
/// 2. Si hay una referencia guardada que ya no está activa
///    ([emaStaleReferenceMode] != none) → [staleReference].
/// 3. Si procede presentar la selección de referencia
///    ([shouldShowEmaReferenceSelection]) → [referenceSelection].
/// 4. Si es el primer registro sin vínculo ([isEmaNoLinkFirstRun]) →
///    [noLinkFirstRun].
/// 5. En otro caso (referencia activa guardada) → [questionnaire].
EmaFlowGate resolveEmaFlowGate({
  required EmaReference? savedReference,
  required JourneyState journey,
  required EmaDraft draft,
}) {
  // La omisión del día ya está resuelta en el borrador: ir al cuestionario.
  if (draft.relationshipOmission == 'no-active-link') {
    return EmaFlowGate.questionnaire;
  }

  if (emaStaleReferenceMode(savedReference, journey) !=
      EmaReferenceReviewMode.none) {
    return EmaFlowGate.staleReference;
  }

  if (shouldShowEmaReferenceSelection(
    savedReference,
    validCaregivers(journey),
  )) {
    return EmaFlowGate.referenceSelection;
  }

  if (isEmaNoLinkFirstRun(savedReference, journey)) {
    return EmaFlowGate.noLinkFirstRun;
  }

  return EmaFlowGate.questionnaire;
}
