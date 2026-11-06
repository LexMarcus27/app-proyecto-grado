// Prueba del inicio del cuidador con gating (tarea 3.5): con vínculo activo los
// tiles dependientes de asociación están habilitados; al simular revocación se
// deshabilitan y la tarjeta de vínculo deja de mostrar la persona vinculada.

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
        const Session(userId: 'demo-cuidador', role: UserRole.cuidador),
      );
  return container;
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  container.read(routerProvider).go(AppPath.caregiverHome);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const ContigoApp(),
  ));
  await tester.pumpAndSettle();
}


void main() {
  testWidgets('con vínculo activo habilita los tiles dependientes',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Escenario con vínculo activo de Marta.
    final seed = simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.active);
    final container = await _container(seed);
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.text('Inicio Cuidador'), findsOneWidget);
    // El tile de aprendizaje siempre está habilitado.
    expect(find.text('Aprendiendo a tejer vínculos'), findsOneWidget);
    // Sin el aviso de "Necesitas un vínculo activo" cuando hay vínculo.
    expect(find.text('Necesitas un vínculo activo'), findsNothing);
    // La tarjeta muestra el vínculo con el PCS (Sofía).
    expect(find.textContaining('Sofía'), findsWidgets);
  });

  testWidgets('sin vínculo activo deshabilita los tiles dependientes',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Escenario revocado: invitación cancelada y asociación inactiva.
    final seed = simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.revoked);
    final container = await _container(seed);
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.text('Inicio Cuidador'), findsOneWidget);
    // Los tiles dependientes muestran el aviso de vínculo requerido.
    expect(find.text('Necesitas un vínculo activo'), findsWidgets);
    // La tarjeta de vínculo indica que no hay persona vinculada.
    expect(find.text('Aún no hay una persona vinculada'), findsOneWidget);
  });

  testWidgets('simular revocación deshabilita en vivo los tiles',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final seed = simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.active);
    final container = await _container(seed);
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.text('Necesitas un vínculo activo'), findsNothing);

    final revoke = find.text('Simular revocación del vínculo');
    await tester.ensureVisible(revoke);
    await tester.pumpAndSettle();
    await tester.tap(revoke);
    await tester.pumpAndSettle();

    // Tras revocar, los tiles dependientes quedan deshabilitados en vivo.
    expect(find.text('Necesitas un vínculo activo'), findsWidgets);
  });
}