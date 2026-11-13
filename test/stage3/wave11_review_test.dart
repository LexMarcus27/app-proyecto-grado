// Prueba de la pantalla de notificaciones simuladas (tarea 3.28): "Simular
// notificación" agrega una tarjeta; sin red activa solo aparecen recordatorios.

import 'package:contigo/app/app.dart';
import 'package:contigo/app/di.dart';
import 'package:contigo/app/router.dart';
import 'package:contigo/app/session_controller.dart';
import 'package:contigo/data/journey/local_journey_repository.dart';
import 'package:contigo/domain/auth/session.dart';
import 'package:contigo/domain/auth/user_role.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/presentation/notifications/notification_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(JourneyState seed) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repo = LocalJourneyRepository(prefs);
  await repo.save(seed);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  container.read(sessionControllerProvider.notifier).setSession(
        const Session(userId: 'demo-pcs', role: UserRole.pcs),
      );
  return container;
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(700, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  container.read(routerProvider).go(AppPath.notifications);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
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
  testWidgets('Notificacion recordatorio abre Tejiendo vinculos', (tester) async {
    final c = await _container(seedForScenario(DemoScenario.withoutActiveLink));
    addTearDown(c.dispose);
    await _pump(tester, c);
    await tester.tap(find.text('Simular notificación'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(NotificationCard).first);
    await tester.tap(find.byType(NotificationCard).first);
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).routeInformationProvider.value.uri.path,
      AppPath.connectionHub, reason: 'La tarjeta promete abrir la herramienta; el recordatorio tiene destino ya implementado');
  });
  testWidgets('Recurso de aprendizaje del cuidador responde', (tester) async {
    final c = await _container(simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.active));
    addTearDown(c.dispose);
    c.read(sessionControllerProvider.notifier).setSession(const Session(userId: 'demo-cuidador', role: UserRole.cuidador));
    await _pump(tester, c);
    await tester.tap(find.text('Aprendiendo a tejer vínculos'));
    await tester.pumpAndSettle();
    expect(find.text('Validación'), findsOneWidget, reason: 'El prototipo abre el recurso de aprendizaje, disponible sin depender de Waves posteriores');
  });
  testWidgets('Otros pasos tambien deshabilita mensaje sin vinculo', (tester) async {
    final c = await _container(seedForScenario(DemoScenario.withoutActiveLink));
    addTearDown(c.dispose);
    await _pump(tester, c);
    c.read(routerProvider).go(AppPath.connectionHub);
    await tester.pumpAndSettle();
    // «Otros pasos» abre la selección de persona; sin vínculo activo, la acción
    // dirigida no abre la conexión con la persona.
    await tester.tap(find.text('Escribir mensaje para tejer cercanía'));
    await tester.pumpAndSettle();
    expect(find.text('¿Te serviría sentirte acompañada?'), findsOneWidget);
    final action = find.text('Mensaje para tejer cercanía');
    if (tester.any(action)) {
      await tester.tap(action);
      await tester.pumpAndSettle();
    }
    expect(c.read(routerProvider).routeInformationProvider.value.uri.path,
      AppPath.connectionHub, reason: 'La accion dirigida debe quedar deshabilitada tambien en Otros pasos');
  });
  testWidgets('Modo crisis conserva opciones de avance del prototipo', (tester) async {
    final c = await _container(createDemoJourney());
    addTearDown(c.dispose);
    await _pump(tester, c);
    c.read(routerProvider).go(AppPath.crisisMode);
    await tester.pumpAndSettle();
    expect(find.text('Elegir otra opción'), findsOneWidget);
    expect(find.text('No puedo ahora'), findsOneWidget);
    await tester.tap(find.text('Elegir otra opción'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 2 de 6'), findsWidgets);
  });
}
