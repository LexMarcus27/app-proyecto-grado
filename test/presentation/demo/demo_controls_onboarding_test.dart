// Prueba de la corrección Wave 11: el control de demostración ofrece el
// escenario de PCS nueva y abre la bienvenida del onboarding, desde la que se
// pueden comprobar "Construir mi mapa"/"Hacerlo después" y la persistencia.

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

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await LocalJourneyRepository(prefs).save(createDemoJourney());
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  container.read(sessionControllerProvider.notifier).setSession(
        const Session(userId: 'demo-pcs', role: UserRole.pcs),
      );
  return container;
}

void main() {
  testWidgets('elegir "PCS nueva" abre la bienvenida del onboarding y persiste',
      (tester) async {
    tester.view.physicalSize = const Size(700, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await _container();
    addTearDown(container.dispose);
    container.read(routerProvider).go(AppPath.demoControls);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const ContigoApp(),
    ));
    await tester.pumpAndSettle();

    final choice = find.text('PCS nueva (onboarding no iniciado)');
    await tester.ensureVisible(choice);
    await tester.pumpAndSettle();
    await tester.tap(choice);
    await tester.pumpAndSettle();

    // Preparó el escenario (onboarding sin iniciar) y abrió la bienvenida.
    expect(find.text('Antes de empezar, reconoce tu red'), findsOneWidget);
    final journey =
        await container.read(journeyRepositoryProvider).loadJourney();
    expect(journey.onboardingStatus, OnboardingStatus.notStarted);

    // "Hacerlo después" aplaza y persiste la decisión.
    await tester.tap(find.text('Hacerlo después'));
    await tester.pumpAndSettle();
    final after =
        await container.read(journeyRepositoryProvider).loadJourney();
    expect(after.onboardingStatus, OnboardingStatus.deferred);
  });
}