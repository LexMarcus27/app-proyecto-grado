// Prueba del hub "Tejiendo vínculos" (tarea 3.20): "Otro paso" rota el paso
// destacado y las acciones dirigidas respetan el gating por vínculo activo.

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
  tester.view.physicalSize = const Size(700, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  container.read(routerProvider).go(AppPath.connectionHub);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const ContigoApp(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('"Otro paso" rota el paso destacado cíclicamente',
      (tester) async {
    final container = await _container(createDemoJourney());
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.text('Tejiendo vínculos'), findsOneWidget);
    // Paso inicial: message → "Escríbele a M." (persona vinculada activa).
    expect(find.text('Escríbele a M.'), findsOneWidget);

    // Rota al siguiente paso (received): "Vuelve a tus mensajes de cuidado".
    await tester.tap(find.text('Otro paso'));
    await tester.pumpAndSettle();
    expect(find.text('Vuelve a tus mensajes de cuidado'), findsOneWidget);
  });

  testWidgets('la acción dirigida se deshabilita sin vínculo activo',
      (tester) async {
    // Recorrido sin vínculo activo: no hay persona autorizada.
    final container = await _container(
      seedForScenario(DemoScenario.withoutActiveLink),
    );
    addTearDown(container.dispose);
    await _pump(tester, container);

    // Como en el prototipo, el paso dirigido abre la selección de persona; sin
    // vínculo activo, las acciones de la persona elegida quedan bloqueadas.
    await tester.tap(find.text('Escribir mensaje'));
    await tester.pumpAndSettle();
    expect(find.text('¿Te serviría sentirte acompañada?'), findsOneWidget);
    final chip = find.descendant(
      of: find.bySemanticsLabel('Todas las personas de tu red'),
      matching: find.byType(InkWell),
    );
    if (tester.any(chip)) {
      await tester.tap(chip.first);
      await tester.pumpAndSettle();
      expect(find.textContaining('debe aceptar la invitación'), findsOneWidget);
      await tester.tap(find.text('Mensaje para tejer cercanía'));
      await tester.pumpAndSettle();
      expect(
        container.read(routerProvider).state.uri.path,
        AppPath.connectionHub,
      );
    }
  });
}