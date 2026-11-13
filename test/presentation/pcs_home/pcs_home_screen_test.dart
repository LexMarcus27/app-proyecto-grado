// Prueba del inicio real del PCS (tarea 3.4): tiles reales, avatares del mapa y
// acceso a los recorridos ya verificados (EMA, mapa, tejiendo vínculos, bandeja,
// plan, notificaciones).

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

Future<ProviderContainer> _container(JourneyState seed) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await LocalJourneyRepository(prefs).save(seed);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  container.read(sessionControllerProvider.notifier).setSession(
        const Session(userId: 'demo-pcs', role: UserRole.pcs),
      );
  return container;
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(700, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  container.read(routerProvider).go(AppPath.pcsHome);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const ContigoApp(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra los tiles reales y los avatares de la red',
      (tester) async {
    final container = await _container(createDemoJourney());
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.byKey(const Key('pcs-home-title')), findsOneWidget);
    expect(find.text('¿Cómo estoy hoy?'), findsOneWidget);
    expect(find.text('Tejiendo vínculos'), findsOneWidget);
    expect(find.text('Mensajes de cuidado'), findsOneWidget);
    expect(find.text('Necesito ayuda'), findsOneWidget);
    // Avatares derivados de journey.people (demo incluye a M.).
    expect(find.text('M.'), findsWidgets);
  });

  testWidgets('el tile de EMA abre el registro', (tester) async {
    final container = await _container(createDemoJourney());
    addTearDown(container.dispose);
    await _pump(tester, container);

    await tester.tap(find.text('¿Cómo estoy hoy?'));
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).state.uri.path,
      AppPath.ema,
    );
  });

  testWidgets('la bandeja de mensajes abre la bandeja de recibidos del PCS',
      (tester) async {
    final container = await _container(createDemoJourney());
    addTearDown(container.dispose);
    await _pump(tester, container);

    await tester.tap(find.text('Mensajes de cuidado'));
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).state.uri.path,
      AppPath.caringInbox,
    );
  });

  testWidgets('con onboarding no iniciado muestra la bienvenida en el inicio',
      (tester) async {
    final container = await _container(emptyJourney);
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.text('Antes de empezar, reconoce tu red'), findsOneWidget);
    expect(find.text('Construir mi mapa'), findsOneWidget);
  });
}