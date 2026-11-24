// Verificación en Android, sesión 4, G8: con la fuente de Android al 200 % y
// unos 411 dp de ancho, las pantallas revisadas no deben desbordarse.
// Recorre cada pantalla desplazándola hasta el final con las fuentes reales.

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

Future<ProviderContainer> _container(UserRole role) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await LocalJourneyRepository(prefs).save(createDemoJourney());
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  container.read(sessionControllerProvider.notifier).setSession(Session(
        userId: role == UserRole.pcs ? 'demo-pcs' : 'demo-cuidador',
        role: role,
      ));
  return container;
}

/// Abre [location] a 411 × 914 dp con la fuente al 200 % y la recorre hasta el
/// final; devuelve los errores de diseño encontrados.
Future<List<String>> _sweep(
  WidgetTester tester,
  String location, {
  UserRole role = UserRole.pcs,
}) async {
  tester.view.physicalSize = const Size(411, 914);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 2.0;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final c = await _container(role);
  addTearDown(c.dispose);
  c.read(routerProvider).go(location);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: const ContigoApp(),
  ));
  await tester.pumpAndSettle();

  final errors = <String>[];
  void collect() {
    for (Object? e = tester.takeException();
        e != null;
        e = tester.takeException()) {
      errors.add(e.toString().split('\n').first);
    }
  }

  collect();
  final scrollable = find.byType(Scrollable).first;
  for (var i = 0; i < 12; i++) {
    await tester.drag(scrollable, const Offset(0, -500), warnIfMissed: false);
    await tester.pumpAndSettle();
    collect();
  }
  return errors;
}

void main() {
  setUpAll(() async {
    for (final family in ['Inter', 'Lora']) {
      final loader = FontLoader(family);
      loader.addFont(rootBundle.load('assets/fonts/$family-Variable.ttf'));
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  group('G8 · fuente al 200 % sin desbordamientos', () {
    testWidgets('Inicio PCS', (tester) async {
      expect(await _sweep(tester, AppPath.pcsHome), isEmpty);
    });

    testWidgets('Inicio Cuidador (S4-H02)', (tester) async {
      expect(
        await _sweep(tester, AppPath.caregiverHome, role: UserRole.cuidador),
        isEmpty,
      );
    });

    testWidgets('M5 · editor del plan de seguridad', (tester) async {
      expect(await _sweep(tester, AppPath.safetyPlanEditor), isEmpty);
    });

    testWidgets('M8 · programar un encuentro', (tester) async {
      final person = validCaregivers(createDemoJourney()).first;
      expect(
        await _sweep(
          tester,
          '${AppPath.connectionPerson}?p=${person.id}&a=meeting',
        ),
        isEmpty,
      );
    });
  });
}
