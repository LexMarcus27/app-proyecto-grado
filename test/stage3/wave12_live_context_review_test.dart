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

Future<void> _tapLabel(WidgetTester tester, String label) async {
  final target = find.text(label);
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

JourneyState _alternateLink(JourneyState seed) {
  final current = caregiverContext(seed, DemoCaregiver.id)!;
  return seed.copyWith(associations: [
    for (final link in seed.associations)
      link.id == current.associationId
        ? link.copyWith(id: 'asociacion-ficticia-nueva')
        : link,
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Inter', 'Lora']) {
      final loader = FontLoader(family);
      loader.addFont(rootBundle.load('assets/fonts/$family-Variable.ttf'));
      await loader.load();
    }
  });
  testWidgets('Cambiar de asociacion con el editor abierto no deja el texto anterior visible', (tester) async {
    final seed = simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.active);
    final c = await _container(seed, UserRole.cuidador);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.caringCompose);
    await _tapLabel(tester, 'Crear un mensaje');
    const text = 'Texto ficticio de la asociación anterior.';
    await tester.enterText(find.byType(TextFormField), text);
    await tester.pumpAndSettle();
    final repo = c.read(journeyRepositoryProvider);
    await repo.save(_alternateLink(seed));
    await tester.pumpAndSettle();
    expect(find.text(text), findsNothing, reason: 'Un cambio de vínculo debe reiniciar o cerrar el formulario anterior');
  });
  testWidgets('Un cambio de asociacion invalida la revision previa al envio', (tester) async {
    final seed = simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.active);
    final next = _alternateLink(seed);
    final c = await _container(next, UserRole.cuidador);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.caringCompose);
    await _tapLabel(tester, 'Crear un mensaje');
    await tester.enterText(find.byType(TextFormField), 'Borrador ficticio B que aún no he revisado');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Volver a Tejiendo vínculos'));
    await tester.pumpAndSettle();
    final repo = c.read(journeyRepositoryProvider);
    await repo.save(seed);
    await tester.pumpAndSettle();
    await _tapLabel(tester, 'Tejiendo vínculos');
    await _tapLabel(tester, 'Escribir un mensaje de cuidado');
    await _tapLabel(tester, 'Crear un mensaje');
    await tester.enterText(find.byType(TextFormField), 'Mensaje ficticio A que estoy revisando');
    await tester.pumpAndSettle();
    await _tapLabel(tester, 'Revisar mensaje');
    expect(find.text('Mensaje ficticio A que estoy revisando'), findsOneWidget);
    await repo.save(next);
    await tester.pumpAndSettle();
    final send = find.text('Simular envío');
    if (tester.any(send)) {
      await tester.tap(send);
      await tester.pumpAndSettle();
    }
    expect(await c.read(caringMessageRepositoryProvider).loadMessages(), isEmpty,
      reason: 'El envío debe exigir volver a revisar después de cambiar de asociación');
  });
}