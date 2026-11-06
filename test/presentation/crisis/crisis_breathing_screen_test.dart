// Prueba de las pantallas de modo crisis y respiración (tarea 3.28): contenido
// textual verbatim presente y conmutador de movimiento en la respiración.

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
  testWidgets('modo crisis muestra el texto verbatim del prototipo',
      (tester) async {
    final container = await _container();
    addTearDown(container.dispose);
    await _pump(tester, container, AppPath.crisisMode);

    expect(find.textContaining('Vamos paso a paso.'), findsOneWidget);
    expect(
      find.text('No tienes que hacerlo todo. Empecemos por una opción.'),
      findsOneWidget,
    );
    // Conserva el marcador de contenido pendiente de validación del entorno.
    expect(find.textContaining('pendiente de completar'), findsOneWidget);
  });

  testWidgets('respiración muestra el texto verbatim y conmuta el movimiento',
      (tester) async {
    final container = await _container();
    addTearDown(container.dispose);
    await _pump(tester, container, AppPath.breathing);

    expect(find.text('Respiración pausada'), findsOneWidget);
    expect(find.text('Inhala'), findsOneWidget);
    // Marcador de instrucciones por validar, preservado verbatim.
    expect(
      find.textContaining('INSTRUCCIONES CLÍNICAS BREVES POR VALIDAR'),
      findsOneWidget,
    );
    // Conmutador de accesibilidad: alterna entre reducir y activar.
    expect(find.text('Reducir movimiento'), findsOneWidget);
    await tester.tap(find.text('Reducir movimiento'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Activar animación'), findsOneWidget);
  });
}