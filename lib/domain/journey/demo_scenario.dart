import 'care_association.dart';
import 'journey_authorization.dart';
import 'journey_demo.dart';
import 'journey_state.dart';

/// Escenarios demo para ejercitar el recorrido EMA de extremo a extremo.
///
/// La sesión demo (tarea 2.10) debe poder correr el EMA en dos situaciones
/// distintas respecto al bloque de relación:
///
/// - [withActiveLink]: existe al menos una persona vinculada activa (invitación
///   `accepted` + asociación `active`), de modo que `validCaregivers` **no** es
///   vacío. Ejercita la selección de `Referencia_EMA` y el bloque de relación.
/// - [withoutActiveLink]: no existe ninguna persona vinculada activa, de modo
///   que `validCaregivers` **es** vacío. Ejercita la omisión del bloque de
///   relación (camino de los 6 ítems).
enum DemoScenario {
  /// Escenario con una persona vinculada activa (`demo-m`).
  withActiveLink,

  /// Escenario sin ninguna persona vinculada activa.
  withoutActiveLink,

  /// Escenario de **PCS nueva con onboarding no iniciado**: sin mapa y con el
  /// recorrido de onboarding en `not-started`, para poder ejercitar la
  /// bienvenida del PCS (3.3): "Construir mi mapa", "Hacerlo después" y la
  /// persistencia de la decisión. La construcción completa del mapa es de la
  /// Wave 12; aquí solo se prepara el estado inicial.
  freshPcsOnboarding,
}

/// Semilla (`JourneyState`) para el [scenario] dado.
///
/// Reusa el recorrido demo del prototipo ([createDemoJourney]) como base, de
/// modo que ambos escenarios comparten el mismo mapa de red plausible (cinco
/// personas, onboarding completado) y solo difieren en si hay o no un vínculo
/// activo:
///
/// - [DemoScenario.withActiveLink] → `createDemoJourney()` tal cual: `demo-m`
///   conserva su invitación `accepted` y su asociación activa, por lo que
///   `validCaregivers` contiene a `demo-m`.
/// - [DemoScenario.withoutActiveLink] → el mismo recorrido demo pero con
///   **todas** las asociaciones desactivadas (`active: false`). Se preserva el
///   mapa (las personas y sus invitaciones no cambian) para que el escenario
///   siga siendo plausible, pero `canStrengthenRelationship` falla para toda
///   persona, por lo que `validCaregivers` queda vacío. Se eligió esta opción
///   —en vez de `emptyJourney`— porque ejercita el camino "sin vínculo activo"
///   (omisión del bloque de relación) manteniendo un mapa de red usable, lo que
///   refleja mejor el caso real de una referencia que quedó obsoleta.
JourneyState seedForScenario(DemoScenario scenario) {
  switch (scenario) {
    case DemoScenario.freshPcsOnboarding:
      // PCS nueva: recorrido vacío, onboarding en "not-started" y sin mapa.
      // Es exactamente el estado inicial (emptyJourney), que dispara la
      // bienvenida del onboarding (shouldShowOnboardingWelcome == true).
      return emptyJourney;
    case DemoScenario.withActiveLink:
      return createDemoJourney();
    case DemoScenario.withoutActiveLink:
      final base = createDemoJourney();
      final revoked = [
        for (final association in base.associations)
          association.copyWith(active: false),
      ];
      return base.copyWith(
        associations: List<CareAssociation>.from(revoked),
      );
  }
}

/// `true` si [scenario] deja `validCaregivers` vacío (sin vínculo activo).
///
/// Útil para la presentación y las pruebas: expone en el dominio la invariante
/// que distingue ambos escenarios sin recomputar `validCaregivers` a mano.
bool scenarioHasActiveLink(DemoScenario scenario) {
  return validCaregivers(seedForScenario(scenario)).isNotEmpty;
}
