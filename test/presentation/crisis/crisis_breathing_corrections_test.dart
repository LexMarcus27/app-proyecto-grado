// Pruebas de las correcciones Wave 11 del modo crisis y respiración:
// "Línea ayuda" y "Contactar a alguien" abren una respuesta simulada (no son
// acciones vacías) y la animación de respiración es perceptible y conmutable.

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

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await LocalJourneyRepository(prefs).save(createDemoJourney());
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  container.read(sessionControllerProvider.notifier).setSession(
        const Session(userId: 'demo-pcs', role: UserRole.pcs),
      );
  return container;
}

Future<void> _pump(WidgetTester tester, ProviderContainer container, String path) async {
  tester.view.physicalSize = const Size(700, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  container.read(routerProvider).go(path);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const ContigoApp(),
  ));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('modo crisis: "Línea ayuda" abre una respuesta simulada',
      (tester) async {
    final container = await _container();
    addTearDown(container.dispose);
    await _pump(tester, container, AppPath.crisisMode);

    await tester.tap(find.text('Línea ayuda'));
    await tester.pumpAndSettle();
    expect(find.text('Línea de ayuda'), findsOneWidget);
    expect(find.textContaining('no se realiza'), findsOneWidget);
  });

  testWidgets('respiración: "Contactar a alguien" abre opciones de contacto',
      (tester) async {
    final container = await _container();
    addTearDown(container.dispose);
    await _pump(tester, container, AppPath.breathing);

    final contact = find.text('Contactar a alguien');
    await tester.scrollUntilVisible(contact, 200);
    await tester.pump();
    await tester.tap(contact);
    // El controlador de respiración anima en bucle, por lo que no se usa
    // pumpAndSettle (no asienta): se bombea un tiempo acotado para abrir la hoja.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Se abre la hoja de opciones simuladas (reutilizada del modo crisis).
    expect(find.text('Enviar un mensaje'), findsOneWidget);
    expect(find.text('Llamar'), findsOneWidget);
  });

  testWidgets('respiración: la animación es perceptible y se puede conmutar',
      (tester) async {
    final container = await _container();
    addTearDown(container.dispose);
    await _pump(tester, container, AppPath.breathing);

    // Localiza el círculo central (terracota) y mide su tamaño en dos instantes
    // separados dentro del ciclo; debe cambiar (la animación se ejecuta).
    Size innerSize() {
      final sizes = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.constraints?.maxWidth)
          .whereType<double>()
          .toList();
      // El círculo central parte de 140 * innerScale (0.78..1.0) => ~109..140.
      final candidates = sizes.where((w) => w >= 100 && w <= 140).toList()
        ..sort();
      return Size(candidates.isEmpty ? 0 : candidates.last, 0);
    }

    await tester.pump(const Duration(milliseconds: 200));
    final first = innerSize().width;
    await tester.pump(const Duration(milliseconds: 1600));
    final second = innerSize().width;
    expect(first == second, isFalse,
        reason: 'El círculo central debe cambiar de tamaño (animación visible)');

    // Conmutar a "Reducir movimiento": se detiene y el tamaño deja de cambiar.
    await tester.tap(find.text('Reducir movimiento'));
    await tester.pump();
    final stoppedA = innerSize().width;
    await tester.pump(const Duration(milliseconds: 1600));
    final stoppedB = innerSize().width;
    expect(stoppedA, stoppedB,
        reason: 'Con el movimiento reducido el tamaño no cambia');
    expect(find.text('Activar animación'), findsOneWidget);
  });
}