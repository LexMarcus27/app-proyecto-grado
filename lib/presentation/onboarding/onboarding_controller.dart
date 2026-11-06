import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../domain/journey/journey.dart';
import '../../domain/repositories/repositories.dart';
import '../authorization/gating.dart';

/// Flujo en vivo del recorrido para el onboarding del PCS (tarea 3.3).
///
/// Reutiliza [gatingJourneyProvider] para observar el `JourneyState` vigente, de
/// modo que la bienvenida y la ramificación por estado de onboarding reaccionen
/// a los cambios persistidos.
final onboardingJourneyProvider = Provider.autoDispose<AsyncValue<JourneyState>>(
  (ref) => ref.watch(gatingJourneyProvider),
);

/// `true` si debe mostrarse la bienvenida del onboarding para el recorrido
/// actual (estado `not-started`), o `null` mientras carga.
final shouldShowOnboardingWelcomeProvider = Provider.autoDispose<bool?>((ref) {
  return ref.watch(onboardingJourneyProvider).whenOrNull(
        data: shouldShowOnboardingWelcome,
      );
});

/// Controlador de las transiciones del onboarding del PCS.
///
/// Aplica las transiciones de dominio (`startOnboarding`, `deferOnboarding`) y
/// **persiste** el `JourneyState` a través del [JourneyRepository], de modo que
/// el estado del onboarding sobreviva a la navegación (coherente con
/// `home.tsx`, Requirement 8.7).
///
/// Captura la instancia del repositorio al construirse (no un `Ref`), de forma
/// que las operaciones asíncronas puedan completar aunque la pantalla —y su
/// provider `autoDispose`— se desmonte al navegar tras `start()`/`defer()`.
class OnboardingController {
  OnboardingController(this._repository);

  final JourneyRepository _repository;

  /// Marca el onboarding en progreso y persiste. La navegación al mapa la hace
  /// la pantalla tras `await` de este método.
  Future<void> start() async {
    await _repository.save(startOnboarding(await _repository.loadJourney()));
  }

  /// Marca el onboarding aplazado y persiste.
  Future<void> defer() async {
    await _repository.save(deferOnboarding(await _repository.loadJourney()));
  }
}

/// Provider del controlador del onboarding.
final onboardingControllerProvider = Provider.autoDispose<OnboardingController>(
  (ref) => OnboardingController(ref.read(journeyRepositoryProvider)),
);