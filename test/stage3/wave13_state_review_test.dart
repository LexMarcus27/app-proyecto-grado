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
import 'package:flutter/services.dart';
// ignore: unused_import
import 'package:contigo/presentation/caregiver_journeys/caregiver_journeys_content.dart';
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
// ignore: unused_element
JourneyState get _revoked =>
    simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.revoked);

// ignore: unused_element
Future<void> _tapLabel(WidgetTester tester, String label) async {
  final target = find.text(label);
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
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
  for (final entry in {
    'mensaje íntimo': AppPath.caregiverIntimateMessage,
    'preguntas para conectar': AppPath.caregiverConnectionQuestions,
  }.entries) {
    testWidgets('${entry.key} conserva el texto al revocar y reactivar la misma asociación', (tester) async {
      final seed = _active;
      final c = await _container(seed);
      addTearDown(c.dispose);
      await _pump(tester, c, entry.value);
      const sample = 'Respuesta ficticia que debe conservarse en esta asociación.';
      await tester.enterText(find.byType(TextField), sample);
      await tester.pumpAndSettle();
      final repo = c.read(journeyRepositoryProvider);
      await repo.save(simulateCaregiverLink(seed, CaregiverDemoMode.revoked));
      await tester.pumpAndSettle();
      expect(find.text(sample), findsNothing);
      expect(find.text('Necesitas un vínculo activo'), findsOneWidget);
      await repo.save(seed);
      await tester.pumpAndSettle();
      expect(find.text(sample), findsWidgets,
        reason: 'El bloqueo de la misma asociación no debe borrar el texto en curso');
    });
  }
  testWidgets('Encuentro conserva sus respuestas al revocar y reactivar', (tester) async {
    final seed = _active;
    final c = await _container(seed);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.caregiverEncounter);
    for (var index = 0; index < 4; index++) {
      final choice = find.text('4').at(index);
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pumpAndSettle();
    }
    ContigoButton button() => tester.widget<ContigoButton>(find.widgetWithText(ContigoButton, 'Guardar registro'));
    expect(button().onPressed, isNotNull);
    final repo = c.read(journeyRepositoryProvider);
    await repo.save(simulateCaregiverLink(seed, CaregiverDemoMode.revoked));
    await tester.pumpAndSettle();
    expect(find.text('Guardar registro'), findsNothing);
    await repo.save(seed);
    await tester.pumpAndSettle();
    expect(button().onPressed, isNotNull, reason: 'Las cuatro respuestas deben recuperarse para la misma asociación');
  });
}