// Prueba de las transiciones de onboarding del PCS (tarea 3.3), portadas de
// src/screens/home.tsx (showWelcome, startMap, deferMap).

import 'package:contigo/domain/journey/journey.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('onboarding', () {
    test('muestra la bienvenida solo si está not-started', () {
      expect(shouldShowOnboardingWelcome(emptyJourney), isTrue);
      expect(shouldShowOnboardingWelcome(startOnboarding(emptyJourney)), isFalse);
    });

    test('startOnboarding marca in-progress y bienvenida vista', () {
      final s = startOnboarding(emptyJourney);
      expect(s.onboardingStatus, OnboardingStatus.inProgress);
      expect(s.onboardingWelcomeShown, isTrue);
    });

    test('deferOnboarding marca deferred y bienvenida vista', () {
      final s = deferOnboarding(emptyJourney);
      expect(s.onboardingStatus, OnboardingStatus.deferred);
      expect(s.onboardingWelcomeShown, isTrue);
    });

    test('ofrece el mapa aplazado solo si deferred y sin mapa generado', () {
      final deferred = deferOnboarding(emptyJourney);
      expect(shouldOfferDeferredMap(deferred), isTrue);
      expect(shouldOfferDeferredMap(deferred.copyWith(mapGenerated: true)), isFalse);
      expect(shouldOfferDeferredMap(emptyJourney), isFalse);
    });
  });
}