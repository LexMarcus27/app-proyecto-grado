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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Inter', 'Lora']) {
      final loader = FontLoader(family);
      loader.addFont(rootBundle.load('assets/fonts/$family-Variable.ttf'));
      await loader.load();
    }
  });
  testWidgets('El cuidador puede enviar y pasar a la bandeja PCS desde la interfaz', (tester) async {
    final c = await _container(simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.active), UserRole.cuidador);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.caregiverHome);
    const sample = 'Mensaje ficticio para la prueba de cambio de rol.';
    await _tapLabel(tester, 'Tejiendo vínculos');
    await _tapLabel(tester, 'Crear un mensaje');
    await tester.enterText(find.byType(TextFormField), sample);
    await tester.pumpAndSettle();
    await _tapLabel(tester, 'Revisar mensaje');
    await _tapLabel(tester, 'Simular envío');
    expect((await c.read(caringMessageRepositoryProvider).loadMessages()).single.text, sample);
    await _tapLabel(tester, 'Salir del recurso');
    await _tapLabel(tester, 'Controles de demostración');
    await _tapLabel(tester, 'Entrar como PCS');
    if (tester.any(find.text('Cambiar de rol (demo)'))) {
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
    }
    await _tapLabel(tester, 'Mensajes de cuidado');
    expect(find.text(sample), findsOneWidget);
  });
  testWidgets('Una asociación nueva para el mismo cuidador no hereda el borrador anterior', (tester) async {
    final seed = simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.active);
    final c = await _container(seed, UserRole.cuidador);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.caregiverHome);
    await _tapLabel(tester, 'Tejiendo vínculos');
    await _tapLabel(tester, 'Crear un mensaje');
    await tester.enterText(find.byType(TextFormField), 'Borrador ficticio del vínculo anterior');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Volver a Tejiendo vínculos'));
    await tester.pumpAndSettle();
    final before = caregiverContext(seed, DemoCaregiver.id)!;
    final updated = seed.copyWith(associations: [
      for (final association in seed.associations)
        association.id == before.associationId
          ? association.copyWith(id: 'asociacion-demo-nueva')
          : association,
    ]);
    await c.read(journeyRepositoryProvider).save(updated);
    await tester.pumpAndSettle();
    expect(caregiverContext(updated, DemoCaregiver.id)?.associationId, 'asociacion-demo-nueva');
    await _tapLabel(tester, 'Tejiendo vínculos');
    expect(find.text('Continuar mi borrador'), findsNothing);
    expect(find.text('Crear un mensaje'), findsOneWidget);
  });
}
