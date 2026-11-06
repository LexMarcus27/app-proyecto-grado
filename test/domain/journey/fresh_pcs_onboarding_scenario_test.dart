// Prueba del escenario demo de PCS nueva (corrección Wave 11): prepara un
// recorrido con onboarding "not-started" para ejercitar la bienvenida.

import 'package:contigo/domain/journey/journey.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('freshPcsOnboarding deja el onboarding sin iniciar y sin mapa', () {
    final seed = seedForScenario(DemoScenario.freshPcsOnboarding);
    expect(seed.onboardingStatus, OnboardingStatus.notStarted);
    expect(shouldShowOnboardingWelcome(seed), isTrue);
    expect(seed.mapGenerated, isFalse);
    expect(seed.mapStarted, isFalse);
  });

  test('no introduce vínculos activos (validCaregivers vacío)', () {
    final seed = seedForScenario(DemoScenario.freshPcsOnboarding);
    expect(validCaregivers(seed), isEmpty);
    expect(scenarioHasActiveLink(DemoScenario.freshPcsOnboarding), isFalse);
  });

  test('los escenarios existentes se conservan', () {
    expect(
      seedForScenario(DemoScenario.withActiveLink).onboardingStatus,
      OnboardingStatus.completed,
    );
    expect(
      validCaregivers(seedForScenario(DemoScenario.withActiveLink)),
      isNotEmpty,
    );
    expect(
      validCaregivers(seedForScenario(DemoScenario.withoutActiveLink)),
      isEmpty,
    );
  });
}