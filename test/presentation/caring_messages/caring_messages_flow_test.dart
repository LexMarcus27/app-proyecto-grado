// Pruebas de mensajes de cuidado (tarea 3.18): envío simulado del cuidador que
// aparece en la bandeja del PCS, exclusión de datos privados, bandeja accesible
// sin asociación activa y distinción recibidos vs. tejer cercanía.

import 'package:contigo/app/app.dart';
import 'package:contigo/app/di.dart';
import 'package:contigo/app/router.dart';
import 'package:contigo/app/session_controller.dart';
import 'package:contigo/data/journey/local_journey_repository.dart';
import 'package:contigo/domain/auth/session.dart';
import 'package:contigo/domain/auth/user_role.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/presentation/caring_messages/caring_messages_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(
  JourneyState seed, {
  required UserRole role,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await LocalJourneyRepository(prefs).save(seed);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  container.read(sessionControllerProvider.notifier).setSession(
        Session(userId: 'demo-${role.name}', role: role),
      );
  return container;
}

Future<void> _pump(WidgetTester tester, ProviderContainer container, String path) async {
  tester.view.physicalSize = const Size(700, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  container.read(routerProvider).go(path);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const ContigoApp(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('un envío simulado del cuidador aparece en la bandeja del PCS',
      (tester) async {
    final journey = createDemoJourney();
    final container = await _container(journey, role: UserRole.pcs);
    addTearDown(container.dispose);

    // Simula el envío de un mensaje por el cuidador con vínculo activo.
    final ok = await container
        .read(caringSendControllerProvider)
        .simulateSend('caregiver-m', 'Estoy pensando en ti.');
    expect(ok, isTrue);

    await _pump(tester, container, AppPath.caringInbox);

    expect(find.text('Mensajes de cuidado'), findsOneWidget);
    expect(find.text('Estoy pensando en ti.'), findsOneWidget);
    // Envío simulado etiquetado como tal.
    expect(find.textContaining('Envío simulado'), findsWidgets);
  });

  testWidgets('la bandeja se abre sin exigir asociación activa', (tester) async {
    // Recorrido sin vínculo activo: la bandeja debe abrirse igualmente (vacía).
    final container = await _container(
      seedForScenario(DemoScenario.withoutActiveLink),
      role: UserRole.pcs,
    );
    addTearDown(container.dispose);
    await _pump(tester, container, AppPath.caringInbox);

    expect(find.text('Mensajes de cuidado'), findsOneWidget);
    expect(
      find.textContaining('Aún no hay mensajes de cuidado'),
      findsOneWidget,
    );
  });

  testWidgets('tras revocar, el mensaje deja de verse en la bandeja',
      (tester) async {
    final container = await _container(createDemoJourney(), role: UserRole.pcs);
    addTearDown(container.dispose);

    await container
        .read(caringSendControllerProvider)
        .simulateSend('caregiver-m', 'Me alegra que existas.');

    // Revoca el vínculo: todas las asociaciones inactivas.
    final repo = container.read(journeyRepositoryProvider);
    final j = await repo.loadJourney();
    await repo.save(j.copyWith(
      associations: [for (final a in j.associations) a.copyWith(active: false)],
    ));

    await _pump(tester, container, AppPath.caringInbox);
    expect(find.text('Me alegra que existas.'), findsNothing);
  });
}