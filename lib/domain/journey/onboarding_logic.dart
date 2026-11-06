import 'journey_state.dart';
import 'onboarding_status.dart';

/// Transiciones del recorrido de onboarding del PCS, portadas verbatim del
/// prototipo (`src/screens/home.tsx`: `showWelcome`, `startMap`, `deferMap`).
/// Dart puro, sin dependencias de Flutter.

/// `true` si debe mostrarse la bienvenida del onboarding: ocurre cuando el
/// estado es [OnboardingStatus.notStarted] (`showWelcome` del prototipo).
bool shouldShowOnboardingWelcome(JourneyState state) {
  return state.onboardingStatus == OnboardingStatus.notStarted;
}

/// Marca el onboarding como **en progreso** y la bienvenida como vista
/// (`startMap` del prototipo), sin tocar el resto del recorrido. La navegación
/// al mapa (intro) la realiza la capa de presentación.
JourneyState startOnboarding(JourneyState state) {
  return state.copyWith(
    onboardingStatus: OnboardingStatus.inProgress,
    onboardingWelcomeShown: true,
  );
}

/// Marca el onboarding como **aplazado** y la bienvenida como vista
/// (`deferMap` del prototipo).
JourneyState deferOnboarding(JourneyState state) {
  return state.copyWith(
    onboardingStatus: OnboardingStatus.deferred,
    onboardingWelcomeShown: true,
  );
}

/// `true` si debe ofrecerse el recordatorio "Tu mapa te espera" (el onboarding
/// quedó aplazado y el mapa aún no se ha generado), tal como en el prototipo.
bool shouldOfferDeferredMap(JourneyState state) {
  return state.onboardingStatus == OnboardingStatus.deferred &&
      !state.mapGenerated;
}