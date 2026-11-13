// Pruebas de fidelidad de navegación al prototipo activo (`src/App.tsx`):
// centro de ayuda (M20), destinos del plan (M5), tarjeta del vínculo del
// cuidador (M12), hub del cuidador (M23), conexión PCS con una persona (M8),
// resultado del EMA (M4) y notificaciones (banner separado del historial).

import 'package:contigo/app/app.dart';
import 'package:contigo/app/di.dart';
import 'package:contigo/app/router.dart';
import 'package:contigo/app/session_controller.dart';
import 'package:contigo/data/journey/local_journey_repository.dart';
import 'package:contigo/domain/auth/session.dart';
import 'package:contigo/domain/auth/user_role.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/domain/notifications/notifications.dart';
import 'package:contigo/presentation/connection/connection_person_screen.dart';
import 'package:contigo/presentation/notifications/notifications_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(
  JourneyState seed, {
  UserRole role = UserRole.pcs,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await LocalJourneyRepository(prefs).save(seed);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  container.read(sessionControllerProvider.notifier).setSession(
        Session(
          userId: role == UserRole.pcs ? 'demo-pcs' : 'demo-cuidador',
          role: role,
        ),
      );
  return container;
}

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container,
  String location, {
  Size size = const Size(412, 1400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  container.read(routerProvider).go(location);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const ContigoApp(),
  ));
  await tester.pumpAndSettle();
}

String _path(ProviderContainer c) =>
    c.read(routerProvider).state.uri.path;

Uri _uri(ProviderContainer c) =>
    c.read(routerProvider).state.uri;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    for (final family in ['Inter', 'Lora']) {
      final loader = FontLoader(family);
      loader.addFont(rootBundle.load('assets/fonts/$family-Variable.ttf'));
      await loader.load();
    }
  });

  mainBlock5();

  group('Centro de ayuda y plan (F03, F04)', () {
    testWidgets('«Necesito ayuda» abre el centro con sus tres opciones',
        (tester) async {
      final c = await _container(createDemoJourney());
      addTearDown(c.dispose);
      await _pump(tester, c, AppPath.pcsHome);

      await _tap(tester, find.text('Necesito ayuda'));
      expect(_path(c), AppPath.helpHub);
      expect(find.text('¿Qué necesitas ahora?'), findsOneWidget);

      await _tap(tester, find.text('Ver plan de seguridad'));
      expect(_path(c), AppPath.safetyPlanEditor);
      // La flecha del plan vuelve al centro de ayuda (React: navigate(20)).
      await _tap(tester, find.byTooltip('Volver a Necesito ayuda'));
      expect(_path(c), AppPath.helpHub);

      await _tap(tester, find.text('Afrontar una crisis'));
      expect(_path(c), AppPath.safetyPlanStory);
      c.read(routerProvider).go(AppPath.helpHub);
      await tester.pumpAndSettle();

      await _tap(tester, find.text('Necesito ayuda ahora'));
      expect(_path(c), AppPath.crisisMode);
    });

    testWidgets('«Usar mi plan ahora» abre el modo crisis', (tester) async {
      final c = await _container(createDemoJourney());
      addTearDown(c.dispose);
      await _pump(tester, c, AppPath.safetyPlanEditor);

      await _tap(tester, find.text('Usar mi plan ahora'));
      expect(_path(c), AppPath.crisisMode);
    });

    testWidgets('el botón flotante «Necesito apoyo» del inicio abre crisis',
        (tester) async {
      final c = await _container(createDemoJourney());
      addTearDown(c.dispose);
      await _pump(tester, c, AppPath.pcsHome);

      await tester.tap(find.bySemanticsLabel('Necesito apoyo'));
      await tester.pumpAndSettle();
      expect(_path(c), AppPath.crisisMode);
    });
  });

  group('Cuidador (F05, F06, V02, V03)', () {
    testWidgets('la tarjeta «Mi vínculo con…» abre el registro de la relación',
        (tester) async {
      final c = await _container(
        simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.active),
        role: UserRole.cuidador,
      );
      addTearDown(c.dispose);
      await _pump(tester, c, AppPath.caregiverHome);

      await _tap(tester, find.text('MI VÍNCULO CON'));
      expect(_path(c), AppPath.caregiverLinkCheckIn);
    });

    testWidgets('«Proveer apoyo» abre el plan y queda bloqueado sin vínculo',
        (tester) async {
      final c = await _container(
        simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.active),
        role: UserRole.cuidador,
      );
      addTearDown(c.dispose);
      await _pump(tester, c, AppPath.caregiverHome);
      await tester.tap(find.bySemanticsLabel('Proveer apoyo'));
      await tester.pumpAndSettle();
      expect(_path(c), AppPath.caregiverSupportPlan);
    });

    testWidgets('sin vínculo, «Proveer apoyo» y la tarjeta no navegan',
        (tester) async {
      final revoked = await _container(
        simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.revoked),
        role: UserRole.cuidador,
      );
      addTearDown(revoked.dispose);
      await _pump(tester, revoked, AppPath.caregiverHome);
      await tester.tap(find.bySemanticsLabel('Proveer apoyo'));
      await tester.pumpAndSettle();
      expect(_path(revoked), AppPath.caregiverHome);
      // La tarjeta sin vínculo tampoco navega.
      await tester.tap(find.text('Aún no hay una persona vinculada'));
      await tester.pumpAndSettle();
      expect(_path(revoked), AppPath.caregiverHome);
    });

    testWidgets('«Tejiendo vínculos» presenta las cuatro opciones paralelas',
        (tester) async {
      final c = await _container(
        simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.active),
        role: UserRole.cuidador,
      );
      addTearDown(c.dispose);
      await _pump(tester, c, AppPath.caregiverHome);

      await _tap(tester, find.text('Tejiendo vínculos'));
      expect(_path(c), AppPath.caregiverConnections);
      for (final (label, route) in [
        ('Escribir un mensaje íntimo', AppPath.caregiverIntimateMessage),
        ('Escribir un mensaje de cuidado', AppPath.caringCompose),
        ('Preguntas para conectar', AppPath.caregiverConnectionQuestions),
        ('Registrar encuentro', AppPath.caregiverEncounter),
      ]) {
        c.read(routerProvider).go(AppPath.caregiverConnections);
        await tester.pumpAndSettle();
        await _tap(tester, find.text(label));
        expect(_path(c), route, reason: label);
      }
    });

    testWidgets('el hub sin asociación activa muestra el bloqueo',
        (tester) async {
      final c = await _container(
        simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.acceptedOnly),
        role: UserRole.cuidador,
      );
      addTearDown(c.dispose);
      await _pump(tester, c, AppPath.caregiverConnections);

      expect(find.text('Escribir un mensaje íntimo'), findsNothing);
      expect(
        find.textContaining('Una invitación aceptada por sí sola no habilita'),
        findsOneWidget,
      );
    });

    testWidgets('la navegación inferior lleva a Aprender, Vínculos y Perfil',
        (tester) async {
      final c = await _container(
        simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.active),
        role: UserRole.cuidador,
      );
      addTearDown(c.dispose);
      await _pump(tester, c, AppPath.caregiverHome);

      await tester.tap(find.bySemanticsLabel('Aprender'));
      await tester.pumpAndSettle();
      expect(_path(c), AppPath.caregiverLearning);
      expect(find.text('Validación'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Perfil'));
      await tester.pumpAndSettle();
      expect(_path(c), AppPath.caregiverProfile);
      expect(find.textContaining('Vínculo activo con'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Vínculos'));
      await tester.pumpAndSettle();
      expect(_path(c), AppPath.caregiverConnections);
    });
  });

  group('Conexión PCS con una persona (F01)', () {
    testWidgets('del hub a la persona elegida y a M8 con la intención',
        (tester) async {
      final seed = createDemoJourney();
      final person = validCaregivers(seed).first;
      final c = await _container(seed);
      addTearDown(c.dispose);
      await _pump(tester, c, AppPath.connectionHub);

      // «Planear un encuentro» en «Otros pasos» abre la selección de persona.
      await _tap(tester, find.text('Planear un encuentro').last);
      expect(find.text('¿Te serviría sentirte acompañada?'), findsOneWidget);

      await _tap(tester, find.bySemanticsLabel('Elegir a ${person.name}'));
      await _tap(tester, find.text('Proponer un encuentro'));

      expect(_path(c), AppPath.connectionPerson);
      expect(_uri(c).queryParameters['p'], person.id);
      expect(_uri(c).queryParameters['a'], 'meeting');
      expect(find.text('Conexión con ${person.name}'), findsOneWidget);
      expect(find.text('Programar un encuentro'), findsOneWidget);

      // La selección queda guardada en el recorrido.
      final journey = await c.read(journeyRepositoryProvider).loadJourney();
      expect(journey.selectedPersonId, person.id);
    });

    testWidgets('el asistente simulado genera, edita y marca un borrador',
        (tester) async {
      final seed = createDemoJourney();
      final person = validCaregivers(seed).first;
      final c = await _container(seed);
      addTearDown(c.dispose);
      await _pump(
        tester,
        c,
        '${AppPath.connectionPerson}?p=${person.id}',
      );

      final help = find.text('Ayúdame a escribirle');
      await tester.ensureVisible(help);
      await tester.pumpAndSettle();
      await tester.tap(help);
      // El indicador de carga anima de forma continua: se avanza por cuadros.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_path(c), AppPath.connectionPerson);
      expect(find.text('Generando un borrador...'), findsOneWidget);
      await tester.pump(simulatedDraftDelay);
      await tester.pumpAndSettle();
      expect(find.textContaining('pensé en ti hoy'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'Hola, te pienso.');
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Marcar borrador como preparado'));
      expect(
        find.text(
          'Borrador preparado para ${person.name} en esta demo. No se ha enviado.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('contacto simula llamada sin realizar ninguna', (tester) async {
      final seed = createDemoJourney();
      final person = validCaregivers(seed).first;
      final c = await _container(seed);
      addTearDown(c.dispose);
      await _pump(
        tester,
        c,
        '${AppPath.connectionPerson}?p=${person.id}&a=contact',
      );

      // La intención «contact» abre directamente las opciones de contacto.
      expect(find.text('Contactar a ${person.name}'), findsOneWidget);
      await _tap(tester, find.text('Simular llamada'));
      expect(
        find.text(
          'Llamada simulada a ${person.name}. No se realizó ninguna llamada.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('el encuentro se prepara, revisa y confirma', (tester) async {
      final seed = createDemoJourney();
      final person = validCaregivers(seed).first;
      final c = await _container(seed);
      addTearDown(c.dispose);
      await _pump(
        tester,
        c,
        '${AppPath.connectionPerson}?p=${person.id}&a=meeting',
      );

      await _tap(tester, find.text('Selecciona una actividad'));
      await _tap(tester, find.text('Tomar un café juntos').last);
      await _tap(tester, find.text('Preparar mensaje'));
      expect(find.text('Invitar a ${person.name}'), findsOneWidget);
      await _tap(tester, find.text('Revisar invitación para ${person.name}'));
      expect(find.text('¿Confirmar este borrador?'), findsOneWidget);
      await _tap(tester, find.text('Marcar borrador como preparado'));
      expect(
        find.textContaining('El envío real está pendiente de integración'),
        findsOneWidget,
      );
    });

    testWidgets('sin vínculo activo M8 bloquea y ofrece volver', (tester) async {
      final seed = seedForScenario(DemoScenario.withoutActiveLink);
      final c = await _container(seed);
      addTearDown(c.dispose);
      await _pump(tester, c, '${AppPath.connectionPerson}?p=demo-m');

      expect(find.text('Conexión con M.'), findsNothing);
      await _tap(tester, find.text('Volver a Tejiendo vínculos'));
      expect(_path(c), AppPath.connectionHub);
    });
  });

  group('Resultado del EMA y notificaciones (F02, F07)', () {
    testWidgets('cerrar el banner no borra el historial', (tester) async {
      final c = await _container(createDemoJourney());
      addTearDown(c.dispose);
      await _pump(tester, c, AppPath.pcsHome);

      await _tap(tester, find.text('Simular notificación'));
      expect(c.read(notificationsControllerProvider).visible, isNotNull);
      await tester.tap(find.byTooltip('Cerrar notificación').first);
      await tester.pumpAndSettle();
      final state = c.read(notificationsControllerProvider);
      expect(state.visible, isNull);
      expect(state.inbox, hasLength(1));
      expect(find.text('Ver notificaciones simuladas (1)'), findsOneWidget);
    });

    testWidgets('una notificación de encuentro abre M8 con esa intención',
        (tester) async {
      final seed = createDemoJourney();
      final person = validCaregivers(seed).first;
      final c = await _container(seed);
      addTearDown(c.dispose);
      await _pump(tester, c, AppPath.pcsHome);

      final template = notificationTemplates.firstWhere(
        (t) => t.action == NotificationAction.meeting,
      );
      final notifier = c.read(notificationsControllerProvider.notifier);
      // Genera hasta obtener una de encuentro dirigida a la persona.
      DemoNotification? meeting;
      for (var i = 0; i < 200 && meeting == null; i++) {
        notifier.simulate();
        final last = c.read(notificationsControllerProvider).inbox.last;
        if (last.template.id == template.id && last.personId == person.id) {
          meeting = last;
        }
      }
      expect(meeting, isNotNull);
      await tester.pumpAndSettle();
      // El banner muestra el último aviso generado: el de encuentro.
      await _tap(tester, find.text(meeting!.text).first);
      expect(_path(c), AppPath.connectionPerson);
      expect(_uri(c).queryParameters['a'], 'meeting');
    });
  });
}

/// Recorre las seis partes de la guía de mensajes de cuidado.
Future<void> _readWholeGuide(WidgetTester tester) async {
  await _tap(tester, find.text('Conocer los mensajes de cuidado'));
  for (var i = 0; i < 5; i++) {
    await _tap(tester, find.text('Siguiente'));
  }
}

void mainBlock5() {
  group('Guía de mensajes y orígenes (F10, F11)', () {
    testWidgets('la guía revisada se conserva al salir y volver al recurso',
        (tester) async {
      final c = await _container(
        simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.active),
        role: UserRole.cuidador,
      );
      addTearDown(c.dispose);
      await _pump(tester, c, AppPath.caringCompose, size: const Size(700, 1800));

      expect(find.text('Cómo empezó todo'), findsNothing);
      await _readWholeGuide(tester);

      // Sale al hub y vuelve: la lectura sigue disponible en la sesión.
      c.read(routerProvider).go(AppPath.caregiverConnections);
      await tester.pumpAndSettle();
      c.read(routerProvider).go(AppPath.caringCompose);
      await tester.pumpAndSettle();
      expect(find.text('Cómo empezó todo'), findsOneWidget);

      // Desde el editor, los orígenes vuelven al mensaje.
      await _tap(tester, find.text('Crear un mensaje'));
      await _tap(tester, find.text('Cómo empezó todo'));
      expect(find.text('Volver a mi mensaje'), findsOneWidget);
      await _tap(tester, find.text('Volver a mi mensaje'));
      expect(find.text('Revisar mensaje'), findsOneWidget);
    });
  });

  group('Mapa: revisar y fortalecer desde resultados (F08)', () {
    testWidgets('«Editar respuestas» abre la caracterización de la persona',
        (tester) async {
      final c = await _container(createDemoJourney());
      addTearDown(c.dispose);
      await _pump(tester, c, '${AppPath.networkBuilder}?edit=demo-m');

      expect(find.text('Pregunta 2 de 19'), findsOneWidget);
      expect(find.text('Guardar y continuar después'), findsOneWidget);
    });
  });

  group('Volver a la pantalla anterior', () {
    testWidgets('desde M8, mensajes y preguntas vuelven a «Conexión con M.»',
        (tester) async {
      final c = await _container(createDemoJourney());
      addTearDown(c.dispose);
      await _pump(tester, c, AppPath.pcsHome);

      await _tap(tester, find.text('Tejiendo vínculos').first);
      await _tap(tester, find.text('Planear un encuentro').last);
      await _tap(tester, find.bySemanticsLabel('Elegir a M.'));
      await _tap(tester, find.text('Proponer un encuentro'));
      expect(_path(c), AppPath.connectionPerson);

      await _tap(tester, find.text('Ver mensajes de cuidado'));
      expect(_path(c), AppPath.caringInbox);
      await _tap(tester, find.byTooltip('Volver'));
      expect(_path(c), AppPath.connectionPerson);

      await _tap(tester, find.text('Preguntas para conectar'));
      expect(_path(c), AppPath.pcsConnectionQuestions);
      await _tap(tester, find.byTooltip('Volver'));
      expect(_path(c), AppPath.connectionPerson);

      // «Ahora no» vuelve a «Tejiendo vínculos» y de ahí al inicio.
      await _tap(tester, find.text('Ahora no'));
      expect(_path(c), AppPath.connectionHub);
    });

    testWidgets('un mapa empezado sale del constructor con una sola flecha',
        (tester) async {
      final c = await _container(
        createDemoJourney().copyWith(mapGenerated: false),
      );
      addTearDown(c.dispose);
      await _pump(tester, c, AppPath.pcsHome);

      await _tap(tester, find.text('¿En dónde tejer?'));
      expect(_path(c), AppPath.networkBuilder);
      expect(find.text('Avance de tu mapa'), findsOneWidget);

      await _tap(tester, find.byTooltip('Volver'));
      expect(_path(c), AppPath.pcsHome);
    });
  });
}
