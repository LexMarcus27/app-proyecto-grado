import 'package:flutter/services.dart';
import 'package:contigo/domain/notifications/notifications.dart';
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
// ignore: unused_import
import 'package:contigo/presentation/caregiver_journeys/caregiver_journeys_content.dart';
// ignore: unused_import
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

Future<void> _tapLabel(WidgetTester tester, String label) async {
  final f = find.text(label);
  expect(f, findsOneWidget);
  await tester.ensureVisible(f);
  await tester.tap(f);
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
  testWidgets('Continuar registra el nombre escrito antes de avanzar', (tester) async {
    final c = await _container(emptyJourney);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.networkBuilder);
    await tester.enterText(find.byType(TextField), 'Nora Demo');
    await tester.pumpAndSettle();
    await _tapLabel(tester, 'Continuar');
    expect(find.text('Pregunta 2 de 10'), findsOneWidget);
    final journey = await c.read(journeyRepositoryProvider).loadJourney();
    expect(journey.people.map((p) => p.name), contains('Nora Demo'), reason: 'Continuar no debe descartar silenciosamente un nombre escrito');
  });
  testWidgets('La pregunta real de una notificación se conserva aunque no esté entre las seis', (tester) async {
    final c = await _container(_withSelected);
    addTearDown(c.dispose);
    final q = notificationTemplates.firstWhere((t) => t.id == 'questions-animals').question!;
    await _pump(tester, c, '${AppPath.pcsConnectionQuestions}?q=${Uri.encodeComponent(q)}');
    expect(find.text(q), findsOneWidget, reason: 'MobileScreen14 incluye la pregunta inicial de la notificación aunque no pertenezca al banco de seis');
  });
  testWidgets('Una asociación nueva con la misma persona no hereda la respuesta PCS', (tester) async {
    final seed = _withSelected;
    final c = await _container(seed);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.pcsConnectionQuestions);
    const sample = 'Respuesta ficticia del vínculo PCS anterior';
    await tester.enterText(find.byType(TextField), sample);
    await tester.pumpAndSettle();
    final repo = c.read(journeyRepositoryProvider);
    final next = seed.copyWith(associations: [
      for (final link in seed.associations)
        link.personId == 'demo-m' ? link.copyWith(id: 'asociacion-pcs-nueva') : link,
    ]);
    expect(canStrengthenRelationship(next, 'demo-m'), isTrue);
    await repo.save(next);
    await tester.pumpAndSettle();
    expect(find.text(sample), findsNothing, reason: 'El aislamiento exige el contexto completo, no solo personId');
  });
}