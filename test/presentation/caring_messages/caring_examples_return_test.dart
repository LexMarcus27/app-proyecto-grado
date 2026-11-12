// E3-W12-01: al abrir "Consultar ejemplos" desde el editor, ofrecer "Volver a
// mi mensaje" y conservar el texto original y la idea añadida. Desde la
// bienvenida, la guía mantiene su navegación normal (sin ese atajo).

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

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await LocalJourneyRepository(prefs)
      .save(simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.active));
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  container.read(sessionControllerProvider.notifier).setSession(
        const Session(userId: 'demo-cuidador', role: UserRole.cuidador),
      );
  return container;
}

Future<void> _pump(WidgetTester tester, ProviderContainer c) async {
  tester.view.physicalSize = const Size(700, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  c.read(routerProvider).go(AppPath.caringCompose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: const ContigoApp(),
  ));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
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

  testWidgets('"Consultar ejemplos" desde el editor permite volver y conserva '
      'texto e idea', (tester) async {
    final c = await _container();
    addTearDown(c.dispose);
    await _pump(tester, c);

    await _tap(tester, 'Crear un mensaje');
    const original = 'Mi texto original.';
    await tester.enterText(find.byType(TextFormField), original);
    await tester.pumpAndSettle();

    await _tap(tester, 'Consultar ejemplos');
    // En la parte de ejemplos, añade una idea al borrador (hay varias; toma la
    // primera, "Estoy pensando en ti.").
    final addIdea = find.text('Añadir idea al borrador').first;
    await tester.ensureVisible(addIdea);
    await tester.pumpAndSettle();
    await tester.tap(addIdea);
    await tester.pumpAndSettle();
    // Hay un regreso directo al mensaje.
    expect(find.text('Volver a mi mensaje'), findsOneWidget);
    await _tap(tester, 'Volver a mi mensaje');

    // De vuelta en el editor: el texto original se conserva y la idea se añadió.
    final field =
        tester.widget<TextFormField>(find.byType(TextFormField).first);
    final text = field.controller?.text ?? field.initialValue ?? '';
    expect(text.contains(original), isTrue);
    expect(text.contains('Estoy pensando en ti.'), isTrue);
  });

  testWidgets('desde la bienvenida la guía no ofrece "Volver a mi mensaje"',
      (tester) async {
    final c = await _container();
    addTearDown(c.dispose);
    await _pump(tester, c);

    await _tap(tester, 'Conocer los mensajes de cuidado');
    expect(find.text('Volver a mi mensaje'), findsNothing);
    // Navegación normal de la guía.
    expect(find.text('Siguiente'), findsOneWidget);
    expect(find.text('Anterior'), findsOneWidget);
  });
}