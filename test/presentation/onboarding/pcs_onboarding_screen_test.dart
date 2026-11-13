// Prueba de la bienvenida del onboarding del PCS (tarea 3.3): "Construir mi
// mapa" marca in-progress y abre el mapa; "Hacerlo después" aplaza y vuelve al
// inicio. El estado se persiste en el JourneyState.

import 'package:contigo/app/app.dart';
import 'package:contigo/app/di.dart';
import 'package:contigo/app/router.dart';
import 'package:contigo/app/session_controller.dart';
import 'package:contigo/data/journey/local_journey_repository.dart';
import 'package:contigo/domain/auth/session.dart';
import 'package:contigo/domain/auth/user_role.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(JourneyState seed) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repo = LocalJourneyRepository(prefs);
  await repo.save(seed);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  container.read(sessionControllerProvider.notifier).setSession(
        const Session(userId: 'demo-pcs', role: UserRole.pcs),
      );
  return container;
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  container.read(routerProvider).go(AppPath.pcsOnboarding);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const ContigoApp(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('"Construir mi mapa" marca in-progress y abre el mapa',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _container(emptyJourney);
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.text('Antes de empezar, reconoce tu red'), findsOneWidget);
    await tester.tap(find.text('Construir mi mapa'));
    await tester.pumpAndSettle();

    // Dejó la bienvenida y navegó al mapa (ruta de "Tu mapa de red").
    expect(find.text('Antes de empezar, reconoce tu red'), findsNothing);
    expect(
      container.read(routerProvider).state.uri.path,
      AppPath.networkBuilder,
    );
    final journey =
        await container.read(journeyRepositoryProvider).loadJourney();
    expect(journey.onboardingStatus, OnboardingStatus.inProgress);
    expect(journey.onboardingWelcomeShown, isTrue);
  });

  testWidgets('"Hacerlo después" aplaza y vuelve al inicio del PCS',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _container(emptyJourney);
    addTearDown(container.dispose);
    await _pump(tester, container);

    await tester.tap(find.text('Hacerlo después'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pcs-home-title')), findsOneWidget);
    final journey =
        await container.read(journeyRepositoryProvider).loadJourney();
    expect(journey.onboardingStatus, OnboardingStatus.deferred);
  });

  testWidgets('si el onboarding ya no está not-started, redirige al inicio',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _container(
      startOnboarding(emptyJourney),
    );
    addTearDown(container.dispose);
    await _pump(tester, container);

    // No muestra la bienvenida; ha redirigido al inicio del PCS.
    expect(find.text('Antes de empezar, reconoce tu red'), findsNothing);
    expect(find.byKey(const Key('pcs-home-title')), findsOneWidget);
  });
}