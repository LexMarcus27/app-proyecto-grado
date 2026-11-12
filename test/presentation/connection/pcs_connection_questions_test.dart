// E3-W13-01: recorrido conversacional de "Preguntas para conectar" del PCS
// (MobileScreen14, role pcs): selección/contexto de persona vinculada activa,
// seis preguntas, respuestas texto/audio/foto simuladas, autorización y
// aislamiento del estado por vínculo. Separado de la evaluación de 9 preguntas.

import 'package:contigo/app/app.dart';
import 'package:contigo/app/di.dart';
import 'package:contigo/app/router.dart';
import 'package:contigo/app/session_controller.dart';
import 'package:contigo/data/journey/local_journey_repository.dart';
import 'package:contigo/domain/auth/session.dart';
import 'package:contigo/domain/auth/user_role.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/presentation/caregiver_journeys/caregiver_journeys_content.dart';
import 'package:contigo/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(JourneyState seed) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await LocalJourneyRepository(prefs).save(seed);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  c.read(sessionControllerProvider.notifier).setSession(
        const Session(userId: 'demo-pcs', role: UserRole.pcs),
      );
  return c;
}

Future<void> _pump(WidgetTester tester, ProviderContainer c, String path) async {
  tester.view.physicalSize = const Size(760, 2200);
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

/// Recorrido demo con demo-m como persona seleccionada (vinculada activa).
JourneyState get _withSelected =>
    createDemoJourney().copyWith(selectedPersonId: 'demo-m');

void main() {
  testWidgets('la pantalla usa la persona vinculada activa y recorre las seis preguntas',
      (tester) async {
    final c = await _container(_withSelected);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.pcsConnectionQuestions);

    expect(find.text('Preguntas para conectar'), findsOneWidget);
    expect(find.textContaining('Una conversación entre tú y M.'), findsOneWidget);

    // "Ver otra" recorre las seis preguntas.
    final seen = <String>{};
    for (var i = 0; i < connectionQuestions.length; i++) {
      for (final q in connectionQuestions) {
        if (tester.any(find.text(q))) seen.add(q);
      }
      await tester.tap(find.text('Ver otra'));
      await tester.pumpAndSettle();
    }
    expect(seen, containsAll(connectionQuestions));
  });

  testWidgets('audio/foto muestran adjuntos simulados', (tester) async {
    final c = await _container(_withSelected);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.pcsConnectionQuestions);
    await tester.tap(find.text('Audio'));
    await tester.pumpAndSettle();
    expect(find.byType(SimulationIndicator), findsWidgets);
    expect(find.text('Grabar audio'), findsOneWidget);
  });

  testWidgets('sin persona vinculada activa exige vínculo (autorización)',
      (tester) async {
    // Todas las asociaciones inactivas: ninguna persona vinculada activa.
    final noLinks = createDemoJourney().copyWith(
      selectedPersonId: 'demo-m',
      associations: [
        for (final a in createDemoJourney().associations)
          a.copyWith(active: false),
      ],
    );
    final c = await _container(noLinks);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.pcsConnectionQuestions);
    expect(find.text('Necesitas un vínculo activo'), findsOneWidget);
    expect(find.text('Ver otra'), findsNothing);
  });

  testWidgets('el estado se aísla por vínculo (otra persona empieza vacía)',
      (tester) async {
    // Activa también la asociación de Carmen para tener dos vínculos activos.
    final base = createDemoJourney();
    final twoActive = base.copyWith(
      selectedPersonId: 'demo-m',
      associations: [
        for (final a in base.associations)
          a.personId == 'demo-carmen' ? a.copyWith(active: true) : a,
      ],
    );
    final c = await _container(twoActive);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.pcsConnectionQuestions);

    const sample = 'Respuesta de prueba para M.';
    await tester.enterText(find.byType(TextField), sample);
    await tester.pumpAndSettle();
    expect(find.text(sample), findsOneWidget);

    // Cambia la persona seleccionada a Carmen (también vinculada activa).
    final repo = c.read(journeyRepositoryProvider);
    await repo.save((await repo.loadJourney())
        .copyWith(selectedPersonId: 'demo-carmen'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Una conversación entre tú y Carmen'),
        findsOneWidget);
    // El texto de M. no se traslada a Carmen.
    expect(find.text(sample), findsNothing);
  });

  testWidgets('abrir con pregunta inicial conserva esa pregunta', (tester) async {
    final c = await _container(_withSelected);
    addTearDown(c.dispose);
    final question = connectionQuestions[4];
    await _pump(tester, c,
        '${AppPath.pcsConnectionQuestions}?q=${Uri.encodeComponent(question)}');
    expect(find.text(question), findsOneWidget);
  });
}