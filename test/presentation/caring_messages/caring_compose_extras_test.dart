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
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Inter', 'Lora']) {
      final loader = FontLoader(family);
      loader.addFont(rootBundle.load('assets/fonts/$family-Variable.ttf'));
      await loader.load();
    }
  });

  testWidgets('"Cómo empezó todo" solo aparece tras recorrer las 6 partes',
      (tester) async {
    final c = await _container(
      simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.active),
      UserRole.cuidador,
    );
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.caringCompose);

    // En la bienvenida aún no está disponible.
    expect(find.text('Cómo empezó todo'), findsNothing);

    await tester.tap(find.text('Conocer los mensajes de cuidado'));
    await tester.pumpAndSettle();
    // Recorre las 6 partes con "Siguiente".
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
    }
    // En la última parte ya aparece el acceso a los orígenes.
    expect(find.text('Cómo empezó todo'), findsWidgets);
    await tester.tap(find.text('Cómo empezó todo').first);
    await tester.pumpAndSettle();
    // Los orígenes muestran sus títulos verbatim.
    expect(find.text('Cartas que acompañaban'), findsOneWidget);
  });

  testWidgets('el conmutador de rol cambia PCS <-> Cuidador sin reiniciar',
      (tester) async {
    final c = await _container(createDemoJourney(), UserRole.pcs);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.demoControls);

    final toCaregiver = find.text('Entrar como Cuidador');
    await tester.ensureVisible(toCaregiver);
    await tester.pumpAndSettle();
    await tester.tap(toCaregiver);
    await tester.pumpAndSettle();
    expect(c.read(sessionControllerProvider)?.role, UserRole.cuidador);
  });
}
