import 'package:contigo/presentation/caring_messages/caring_messages_controller.dart';
// Pruebas de correcciones Wave 12 (findings 4 y 5): "Cómo empezó todo" solo tras
// recorrer la guía completa, y el conmutador de rol de la demo.

import 'package:contigo/app/app.dart';
import 'package:contigo/app/di.dart';
import 'package:contigo/app/router.dart';
import 'package:contigo/app/session_controller.dart';
import 'package:contigo/data/journey/local_journey_repository.dart';
import 'package:contigo/domain/auth/session.dart';
import 'package:contigo/domain/auth/user_role.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(JourneyState seed, UserRole role) async {
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

Future<void> _pump(WidgetTester tester, ProviderContainer c, String path) async {
  tester.view.physicalSize = const Size(700, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  c.read(routerProvider).go(path);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: const ContigoApp(),
  ));
  await tester.pumpAndSettle();
}


void main() {
  testWidgets('Una escritura sin vínculo no se atribuye a una asociación posterior', (tester) async {
    final seed = simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.revoked);
    final c = await _container(seed, UserRole.cuidador);
    addTearDown(c.dispose);
    final repo = c.read(journeyRepositoryProvider);
    await repo.loadJourney();
    await _pump(tester, c, AppPath.caringCompose);
    expect(c.read(currentCaringContextProvider), isNull);
    c.read(caringDraftControllerProvider.notifier).setText('Texto ficticio sin asociación');
    c.read(caringDraftControllerProvider.notifier).setNote(0, 'Nota ficticia sin asociación');
    final active = simulateCaregiverLink(seed, CaregiverDemoMode.active);
    await repo.save(active.copyWith(associations: [
      for (final link in active.associations)
        link.caregiverId == DemoCaregiver.id ? link.copyWith(id: 'asociacion-ficticia-distinta') : link,
    ]));
    await tester.pumpAndSettle();
    final draft = c.read(currentCaringDraftProvider)!;
    expect(draft.text, isEmpty);
    expect(draft.notes, isEmpty);
  });
}