// Prueba de los recorridos del cuidador dependientes de asociación (tarea 3.19):
// con vínculo activo abren su contenido; sin vínculo activo quedan bloqueados.
// Los adjuntos de audio/foto son simulados (indicador de simulación).

import 'package:contigo/app/app.dart';
import 'package:contigo/app/di.dart';
import 'package:contigo/app/router.dart';
import 'package:contigo/app/session_controller.dart';
import 'package:contigo/data/journey/local_journey_repository.dart';
import 'package:contigo/domain/auth/session.dart';
import 'package:contigo/domain/auth/user_role.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/presentation/widgets/widgets.dart';
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
        const Session(userId: 'demo-cuidador', role: UserRole.cuidador),
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

JourneyState get _active =>
    simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.active);
JourneyState get _revoked =>
    simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.revoked);

void main() {
  testWidgets('plan de acompañamiento muestra el plan con vínculo activo',
      (tester) async {
    final c = await _container(_active);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.caregiverSupportPlan);
    expect(find.text('Plan de acompañamiento'), findsOneWidget);
    expect(find.textContaining('Solo lectura'), findsOneWidget);
    expect(find.text('Acompañar paso a paso'), findsOneWidget);
  });

  testWidgets('registro de vínculo pide contacto y es gated',
      (tester) async {
    final c = await _container(_active);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.caregiverLinkCheckIn);
    expect(find.textContaining('¿Tuviste contacto con'), findsOneWidget);
  });

  testWidgets('evaluación de encuentro conserva los marcadores pendientes',
      (tester) async {
    final c = await _container(_active);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.caregiverEncounter);
    expect(find.textContaining('por validar con el equipo investigador'),
        findsWidgets);
    expect(find.text('[[Mín.]]'), findsOneWidget);
    expect(find.text('[[Máx.]]'), findsOneWidget);
  });

  testWidgets('preguntas para conectar ofrece audio/foto simulados',
      (tester) async {
    final c = await _container(_active);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.caregiverConnectionQuestions);
    expect(find.text('Preguntas para conectar'), findsOneWidget);
    // Elegir "Audio" muestra el indicador de simulación de adjuntos.
    await tester.tap(find.text('Audio'));
    await tester.pumpAndSettle();
    expect(find.byType(SimulationIndicator), findsWidgets);
    expect(find.text('Grabar audio'), findsOneWidget);
  });

  testWidgets('sin vínculo activo los recorridos quedan bloqueados',
      (tester) async {
    final c = await _container(_revoked);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.caregiverSupportPlan);
    expect(find.text('Necesitas un vínculo activo'), findsOneWidget);
    expect(find.text('Acompañar paso a paso'), findsNothing);
  });

  testWidgets('mensaje íntimo conserva las orientaciones y prepara borrador',
      (tester) async {
    final c = await _container(_active);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.caregiverIntimateMessage);
    expect(find.textContaining('Mensaje íntimo para'), findsOneWidget);
    expect(find.text('Antes de guardar, recuerda'), findsOneWidget);
    expect(
      find.textContaining('pendientes de validación final por el equipo'),
      findsOneWidget,
    );
    // Sin texto, "Preparar borrador" está deshabilitado.
    final blocked = tester.widget<ContigoButton>(
      find.widgetWithText(ContigoButton, 'Preparar borrador'),
    );
    expect(blocked.onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Pensé en ti hoy.');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preparar borrador'));
    await tester.pumpAndSettle();
    expect(find.text('Borrador de prueba preparado'), findsOneWidget);
    expect(find.text('No se ha enviado.'), findsOneWidget);
  });

  testWidgets('mensaje íntimo queda bloqueado sin vínculo activo',
      (tester) async {
    final c = await _container(_revoked);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.caregiverIntimateMessage);
    expect(find.text('Necesitas un vínculo activo'), findsOneWidget);
    expect(find.textContaining('Mensaje íntimo para'), findsNothing);
  });
}