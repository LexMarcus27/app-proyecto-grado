// Prueba de la pantalla de notificaciones simuladas (tarea 3.28): "Simular
// notificación" agrega una tarjeta; sin red activa solo aparecen recordatorios.

import 'package:contigo/app/app.dart';
import 'package:contigo/app/di.dart';
import 'package:contigo/app/router.dart';
import 'package:contigo/app/session_controller.dart';
import 'package:contigo/data/journey/local_journey_repository.dart';
import 'package:contigo/domain/auth/session.dart';
import 'package:contigo/domain/auth/user_role.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/presentation/notifications/notification_card.dart';
import 'package:contigo/presentation/widgets/widgets.dart';
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
  tester.view.physicalSize = const Size(700, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  container.read(routerProvider).go(AppPath.notifications);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const ContigoApp(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la pantalla muestra el indicador de simulación', (tester) async {
    final container = await _container(createDemoJourney());
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.text('Notificaciones simuladas'), findsOneWidget);
    expect(find.byType(SimulationIndicator), findsWidgets);
    expect(
      find.textContaining('No envía notificaciones reales'),
      findsOneWidget,
    );
  });

  testWidgets('simular agrega una tarjeta de notificación', (tester) async {
    final container = await _container(createDemoJourney());
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.byType(NotificationCard), findsNothing);
    await tester.tap(find.text('Simular notificación'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationCard), findsWidgets);
  });

  testWidgets('sin red activa anuncia que solo habrá recordatorios',
      (tester) async {
    final container = await _container(
      seedForScenario(DemoScenario.withoutActiveLink),
    );
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(
      find.textContaining('Sin personas vinculadas'),
      findsOneWidget,
    );
  });
}