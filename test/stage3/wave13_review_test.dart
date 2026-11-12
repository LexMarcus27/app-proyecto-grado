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
  testWidgets('Preguntas para conectar permite recorrer las seis preguntas', (tester) async {
    final c = await _container(_active);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.caregiverConnectionQuestions);
    final seen = <String>{};
    for (var i = 0; i < connectionQuestions.length; i++) {
      for (final question in connectionQuestions) {
        if (tester.any(find.text(question))) seen.add(question);
      }
      await _tapLabel(tester, 'Ver otra');
    }
    expect(seen, containsAll(connectionQuestions));
  });
  testWidgets('Revocar y reactivar la misma asociación conserva el registro en curso', (tester) async {
    final seed = _active;
    final c = await _container(seed);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.caregiverLinkCheckIn);
    await _tapLabel(tester, 'Sí');
    expect(find.text('¿Cómo calificarías la calidad de la interacción?'), findsOneWidget);
    final repo = c.read(journeyRepositoryProvider);
    await repo.save(simulateCaregiverLink(seed, CaregiverDemoMode.revoked));
    await tester.pumpAndSettle();
    expect(find.text('Necesitas un vínculo activo'), findsOneWidget);
    await repo.save(seed);
    await tester.pumpAndSettle();
    expect(find.text('¿Cómo calificarías la calidad de la interacción?'), findsOneWidget,
      reason: 'Bloquear el contenido no debe borrar el estado del registro');
  });
  testWidgets('Ver otra limpia la respuesta visible de la pregunta anterior', (tester) async {
    final c = await _container(_active);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.caregiverConnectionQuestions);
    const sample = 'Respuesta ficticia de la primera pregunta';
    await tester.enterText(find.byType(TextField), sample);
    await tester.pumpAndSettle();
    await _tapLabel(tester, 'Ver otra');
    expect(find.text(sample), findsNothing);
  });
  testWidgets('Invitar una relación pide el contacto y permite reconsiderar', (tester) async {
    final c = await _container(_active);
    addTearDown(c.dispose);
    c.read(sessionControllerProvider.notifier).setSession(const Session(userId: 'demo-pcs', role: UserRole.pcs));
    await _pump(tester, c, AppPath.relationEvaluation);
    await tester.enterText(find.byType(TextField), 'Persona ficticia');
    await tester.pumpAndSettle();
    await _tapLabel(tester, 'Comenzar preguntas');
    for (var i = 0; i < 9; i++) {
      await _tapLabel(tester, 'Mucho');
      await _tapLabel(tester, i == 8 ? 'Ver orientación' : 'Siguiente');
    }
    expect(find.text('Esta relación parece importante y también compleja'), findsOneWidget);
    expect(find.text('Pensar en otra persona'), findsOneWidget);
    expect(find.text('Ver recurso sobre relaciones'), findsOneWidget);
    await _tapLabel(tester, 'Continuar con la invitación');
    expect(find.text('Número o correo'), findsOneWidget);
    final send = tester.widget<ContigoButton>(find.widgetWithText(ContigoButton, 'Enviar invitación'));
    expect(send.onPressed, isNull, reason: 'El prototipo exige un contacto antes de confirmar la invitación simulada');
  });
}