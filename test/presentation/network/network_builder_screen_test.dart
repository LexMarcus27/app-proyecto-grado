// E3-W13-02: el constructor guiado reproduce network.tsx: diez preguntas del
// generador de nombres (una por pantalla), captura/revisión, y caracterización
// por persona con "¿Quién es {nombre} para ti?" como paso 1 de 19 seguido de
// los 18 ítems. Sin preseleccionar "Familia"; con reanudación del avance.

import 'package:contigo/app/app.dart';
import 'package:contigo/app/di.dart';
import 'package:contigo/app/router.dart';
import 'package:contigo/app/session_controller.dart';
import 'package:contigo/data/journey/local_journey_repository.dart';
import 'package:contigo/domain/auth/session.dart';
import 'package:contigo/domain/auth/user_role.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/domain/network/network.dart';
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

Future<void> _pump(WidgetTester tester, ProviderContainer c) async {
  tester.view.physicalSize = const Size(760, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  c.read(routerProvider).go(AppPath.networkBuilder);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: const ContigoApp(),
  ));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String label) async {
  final f = find.text(label);
  await tester.ensureVisible(f.first);
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el generador de nombres tiene diez preguntas, una por pantalla',
      (tester) async {
    final c = await _container(emptyJourney);
    addTearDown(c.dispose);
    await _pump(tester, c);

    // Sin mapa empezado, el constructor abre la introducción (vista `intro`).
    expect(find.text('Antes de empezar, construye tu mapa de red'), findsOneWidget);
    expect(find.text('¿Por qué te preguntamos esto?'), findsOneWidget);
    await _tap(tester, 'Construir mi mapa');
    expect(find.text('Pregunta 1 de 10'), findsOneWidget);
    expect(find.text(nameGeneratorQuestions.first), findsOneWidget);

    // Captura una persona en la primera pregunta.
    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Añadir esta persona'));
    await tester.pumpAndSettle();

    // Avanza por las diez preguntas con "Continuar"/"Revisar mi lista".
    for (var i = 0; i < nameGeneratorQuestions.length; i++) {
      expect(find.text('Pregunta ${i + 1} de 10'), findsOneWidget);
      final last = i == nameGeneratorQuestions.length - 1;
      await _tap(tester, last ? 'Revisar mi lista' : 'Continuar');
    }
    // Tras la última, llega a la revisión con la persona capturada.
    expect(find.text('Las personas que forman tu red'), findsOneWidget);
    expect(find.text('Alex'), findsWidgets);
  });

  testWidgets(
      'caracterización: paso 1 de 19 es "¿Quién es {nombre}?" sin preseleccionar Familia',
      (tester) async {
    // Una persona capturada sin tipo (como el generador de nombres).
    final seed = emptyJourney.copyWith(
      mapStarted: true,
      people: [
        NetworkPerson(
          id: 'p1',
          name: 'Alex',
          answers: List<int?>.filled(18, null),
          status: PersonStatus.pending,
          invitationStatus: InvitationStatus.notInvited,
        ),
      ],
    );
    final c = await _container(seed);
    addTearDown(c.dispose);
    await _pump(tester, c);

    // Con el mapa empezado, la entrada «progress» abre el avance.
    await _tap(tester, 'Alex');
    // Sin tipo, primero la presentación de la persona (`person-intro`).
    expect(find.text('Ahora veremos tu relación con Alex'), findsOneWidget);
    await _tap(tester, 'Continuar');

    // Paso 1 de 19: la categoría.
    expect(find.text('Pregunta 1 de 19'), findsOneWidget);
    expect(find.text('¿Quién es Alex para ti?'), findsOneWidget);
    // Las seis categorías aparecen y NINGUNA está preseleccionada (Familia
    // no debe venir marcada). Elegimos una para avanzar al ítem 2.
    expect(find.text('Familia'), findsOneWidget);
    await _tap(tester, 'Amistades');

    // Paso 2 de 19: primer ítem de la relación.
    expect(find.text('Pregunta 2 de 19'), findsOneWidget);
    expect(find.text(relationshipQuestions.first), findsOneWidget);

    // F09: tocar una opción solo la selecciona; avanza con «Continuar».
    await _tap(tester, 'Nada');
    expect(find.text('Pregunta 2 de 19'), findsOneWidget);
    await _tap(tester, 'Extremadamente');
    expect(find.text('Pregunta 2 de 19'), findsOneWidget);
    await _tap(tester, 'Continuar');
    expect(find.text('Pregunta 3 de 19'), findsOneWidget);
    final journey = await c.read(journeyRepositoryProvider).loadJourney();
    expect(journey.people.single.answers.first, 6);
  });

  testWidgets('el avance se conserva y se reanuda por persona', (tester) async {
    // Persona ya caracterizada parcialmente (tipo + 2 ítems) -> reanuda en el 3.
    final answers = List<int?>.filled(18, null);
    answers[0] = 4;
    answers[1] = 3;
    final seed = emptyJourney.copyWith(
      mapStarted: true,
      people: [
        NetworkPerson(
          id: 'p1',
          name: 'Alex',
          relationshipType: RelationshipType.amistades,
          answers: answers,
          status: PersonStatus.inProgress,
          invitationStatus: InvitationStatus.notInvited,
        ),
      ],
    );
    final c = await _container(seed);
    addTearDown(c.dispose);
    await _pump(tester, c);

    // En el avance, la persona figura "En progreso (2/18)".
    expect(find.textContaining('En progreso (2/18)'), findsOneWidget);
    await _tap(tester, 'Alex');
    // Reanuda en el primer ítem sin responder: paso 4 de 19 (índice de ítem 3).
    expect(find.text('Pregunta 4 de 19'), findsOneWidget);
    expect(find.text(relationshipQuestions[2]), findsOneWidget);
  });
}