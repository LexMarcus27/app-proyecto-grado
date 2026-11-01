import '../../domain/ema/ema.dart';
import '../../domain/journey/journey.dart';

/// Regla de presentación de la pantalla de selección de Referencia_EMA.
///
/// Portado de la condición `choosing` del prototipo (`src/screens/ema.tsx`),
/// acotada al caso de la Etapa 2 (antes del primer registro): en el prototipo
/// `choosing = !referencePreference && !showResult && !omittedRelationship`.
/// Aquí se expone la parte que decide si **presentar** la pantalla de selección:
/// solo cuando **no** hay una [savedReference] todavía y existe al menos una
/// persona con vínculo activo ([validCaregivers] no vacío).
///
/// Devuelve:
/// - `true` cuando no hay referencia guardada y hay personas con vínculo activo:
///   el PCS abre el EMA por primera vez y debe elegir su Referencia_EMA
///   (Requirement 5.5).
/// - `false` cuando ya hay una referencia guardada —la elección se recuerda
///   entre registros y la pantalla no vuelve a presentarse (Requirement 5.6)—,
///   o cuando no hay ninguna persona con vínculo activo —ese es el camino sin
///   vínculo de la tarea 2.16, no esta pantalla—.
///
/// Es una función pura para que el flujo EMA de extremo a extremo (tarea 2.17)
/// pueda decidir el gating sin montar la UI y para poder probarla en aislamiento.
bool shouldShowEmaReferenceSelection(
  EmaReference? savedReference,
  List<NetworkPerson> activeCaregivers,
) {
  return savedReference == null && activeCaregivers.isNotEmpty;
}

/// Regla del **primer registro sin persona vinculada** (tarea 2.16).
///
/// Portado de la rama `choosing` del prototipo (`src/screens/ema.tsx`) cuando no
/// hay personas con vínculo activo (`!referencePreference && people.length ===
/// 0`): esa es la superficie del camino sin vínculo del primer registro, que
/// ofrece "Ir a Tu mapa de red" (primaria) y "Continuar con el registro de hoy"
/// (secundaria) omitiendo el bloque de relación solo ese día.
///
/// Devuelve `true` cuando **no** hay una [savedReference] todavía (primer
/// registro, sin elección recordada) y **no** existe ninguna persona con
/// vínculo activo ([validCaregivers] vacío). Es el complemento de
/// [shouldShowEmaReferenceSelection]: con referencia guardada el flujo recuerda
/// la elección (o entra a la revisión de referencia obsoleta de 2.12), y con
/// personas activas la superficie correcta es la selección de 2.11.
///
/// Función pura (sin UI ni efectos) para que el flujo EMA de extremo a extremo
/// (tarea 2.17) decida el enrutamiento sin montar la UI y para poder probarla en
/// aislamiento.
bool isEmaNoLinkFirstRun(EmaReference? savedReference, JourneyState journey) {
  return savedReference == null && validCaregivers(journey).isEmpty;
}
