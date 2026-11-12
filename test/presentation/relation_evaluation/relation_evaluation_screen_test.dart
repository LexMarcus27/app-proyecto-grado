// Prueba de la pantalla de evaluación de relación (tarea 3.23): recorrido
// persona -> preguntas (avance monótono, Property 19) -> orientación
// (marcadores pendientes) -> invitación simulada. La invitación es una
// Funcion_Simulada; el resultado es orientación demostrativa (Requirement 10.2).

import 'package:contigo/app/app.dart';
import 'package:contigo/app/di.dart';
import 'package:contigo/app/router.dart';
import 'package:contigo/app/session_controller.dart';
import 'package:contigo/data/journey/local_journey_repository.dart';
import 'package:contigo/domain/auth/session.dart';
import 'package:contigo/domain/auth/user_role.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/domain/relation_evaluation/relation_evaluation.dart';
import 'package:contigo/presentation/widgets/widgets.dart';
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

Future<void> _pump(WidgetTester tester, ProviderContainer c) async {
  tester.view.physicalSize = const Size(700, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  c.read(routerProvider).go(AppPath.relationEvaluation);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: const ContigoApp(),
  ));
  await tester.pumpAndSettle();
}

Future<void> _enterPerson(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'Mamá');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Comenzar preguntas'));
  await tester.pumpAndSettle();
}

Future<void> _answerAll(WidgetTester tester, {required int option}) async {
  for (var i = 0; i < relationEvaluationQuestions.length; i++) {
    // Selecciona la opción deseada por su etiqueta de escala.
    await tester.tap(find.text(relationEvaluationScale[option - 1]).first);
    await tester.pumpAndSettle();
    final advance = i < relationEvaluationQuestions.length - 1
        ? 'Siguiente'
        : 'Ver orientación';
    await tester.tap(find.text(advance));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('arranca pidiendo la persona y exige un nombre', (tester) async {
    final c = await _container();
    addTearDown(c.dispose);
    await _pump(tester, c);
    expect(find.text('Elegir una relación'), findsOneWidget);
    expect(find.text('Piensa en alguien cercano'), findsOneWidget);
    // Sin nombre, el botón de comenzar está deshabilitado.
    final button = tester.widget<ContigoButton>(
      find.widgetWithText(ContigoButton, 'Comenzar preguntas'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('avance monótono: sin respuesta no avanza (Property 19)',
      (tester) async {
    final c = await _container();
    addTearDown(c.dispose);
    await _pump(tester, c);
    await _enterPerson(tester);
    expect(find.textContaining('Pregunta 1 de'), findsOneWidget);
    // Sin seleccionar opción, el botón "Siguiente" está deshabilitado.
    final next = tester.widget<ContigoButton>(
      find.widgetWithText(ContigoButton, 'Siguiente'),
    );
    expect(next.onPressed, isNull);
  });

  testWidgets('completa el recorrido y muestra marcadores pendientes',
      (tester) async {
    final c = await _container();
    addTearDown(c.dispose);
    await _pump(tester, c);
    await _enterPerson(tester);
    await _answerAll(tester, option: 5);
    // Etapa de orientación con marcador de validación pendiente.
    expect(find.textContaining('Orientación demostrativa'), findsOneWidget);
    expect(find.textContaining('pendientes de validación'), findsOneWidget);
  });

  testWidgets('la invitación simulada exige contacto y luego confirma',
      (tester) async {
    final c = await _container();
    addTearDown(c.dispose);
    await _pump(tester, c);
    await _enterPerson(tester);
    await _answerAll(tester, option: 5);
    await tester.tap(find.text('Continuar con la invitación'));
    await tester.pumpAndSettle();
    expect(find.byType(SimulationIndicator), findsWidgets);
    expect(find.text('Número o correo'), findsOneWidget);
    // Sin contacto, el envío está deshabilitado (regla del prototipo).
    final blocked = tester.widget<ContigoButton>(
      find.widgetWithText(ContigoButton, 'Enviar invitación'),
    );
    expect(blocked.onPressed, isNull);
    // Con contacto, el envío simulado prepara la invitación.
    await tester.enterText(find.byType(TextField), '300 123 4567');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar invitación'));
    await tester.pumpAndSettle();
    expect(find.text('Invitación preparada'), findsOneWidget);
    expect(find.textContaining('simulado'), findsWidgets);
  });

  testWidgets(
      'orientación no favorable ofrece recurso y pensar en otra persona',
      (tester) async {
    final c = await _container();
    addTearDown(c.dispose);
    await _pump(tester, c);
    await _enterPerson(tester);
    // "Mucho" en positivas y negativas da una orientación por debajo del umbral.
    await _answerAll(tester, option: 5);
    expect(find.text('Esta relación parece importante y también compleja'),
        findsOneWidget);
    expect(find.text('Ver recurso sobre relaciones'), findsOneWidget);
    expect(find.text('Pensar en otra persona'), findsOneWidget);
    // "Pensar en otra persona" reinicia el recorrido al paso de persona.
    await tester.tap(find.text('Pensar en otra persona'));
    await tester.pumpAndSettle();
    expect(find.text('Piensa en alguien cercano'), findsOneWidget);
  });
}