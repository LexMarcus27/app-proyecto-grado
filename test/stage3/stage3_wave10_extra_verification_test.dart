// Verificación externa: no cambia lib/ ni las pruebas mantenidas por Kiro.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:contigo/app/app.dart';
import 'package:contigo/app/di.dart';
import 'package:contigo/app/router.dart';
import 'package:contigo/app/session_controller.dart';
import 'package:contigo/content/safety_plan_story.dart';
import 'package:contigo/data/journey/demo_seeder.dart';
import 'package:contigo/domain/auth/session.dart';
import 'package:contigo/domain/auth/user_role.dart';
import 'package:contigo/domain/journey/demo_scenario.dart';
import 'package:contigo/domain/notifications/notifications.dart';
import 'package:contigo/presentation/safety_plan/safety_plan_controller.dart';
import 'package:contigo/presentation/safety_plan/widgets/story_video.dart';
import 'package:contigo/presentation/widgets/contigo_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

// Fallo nativo explícito después de crear el reproductor: no depende de que
// el entorno flutter_test tenga un complemento de video registrado.
class _FailedVideoPlatform extends VideoPlayerPlatform {
  _FailedVideoPlatform({this.failCreation = false});
  final bool failCreation;
  final Map<int, StreamController<VideoEvent>> _streams = {};
  int _nextPlayer = 0;
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    if (failCreation) {
      throw PlatformException(code: 'simulated-create-failure', message: 'Fallo de creación de prueba');
    }
    final id = _nextPlayer++;
    final stream = StreamController<VideoEvent>();
    _streams[id] = stream;
    stream.addError(PlatformException(
      code: 'simulated-video-error', message: 'Video no disponible en esta prueba',
    ));
    return id;
  }
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    return _streams[playerId]!.stream;
  }
  @override
  Future<void> dispose(int playerId) async {}
}

Future<void> _settleVideo(WidgetTester tester) async {
  // La cancelación del stream del complemento puede completar fuera del reloj
  // falso de los widgets. Dejarla terminar antes de evaluar la interfaz.
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
  await tester.pumpAndSettle();
}

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'))).load();
    await (FontLoader('Lora')..addFont(rootBundle.load('assets/fonts/Lora-Variable.ttf'))).load();
  });
  // Fixture copiado verbatim del informe de verificación a test/stage3/,
  // conservando las expectativas de las pruebas externas.
  final fixture = jsonDecode(File(
    'test/stage3/stage3_wave10_prototype.json',
  ).readAsStringSync()) as Map<String, dynamic>;

  test('siete páginas: contenido y orden iguales al prototipo', () {
    final actual = safetyPlanStory.map((p) => <String, Object?>{
      'id': p.id,
      'title': p.title,
      if (p.video != null) 'video': p.video!.split('/').last,
      'paragraphs': p.paragraphs,
      if (p.listHeading != null) 'listHeading': p.listHeading,
      if (p.items != null) 'items': p.items,
      if (p.closing != null) 'closing': p.closing,
    }).toList();
    expect(actual, fixture['story']);
  });

  test('once plantillas: todos los campos iguales al prototipo', () {
    final actual = notificationTemplates.map((p) => <String, Object?>{
      'id': p.id,
      'type': p.type.wireValue,
      if (p.subtype != null) 'subtype': p.subtype,
      'text': p.text,
      'showType': p.showType,
      'action': p.action.wireValue,
      if (p.question != null) 'question': p.question,
    }).toList();
    expect(actual, fixture['notifications']);
  });

  test('aislamiento a través del controlador real y retorno al escenario', () async {
    final container = await _container();
    addTearDown(container.dispose);
    await container.read(safetyPlanControllerProvider.future);
    final controller = container.read(safetyPlanControllerProvider.notifier);
    await controller.setStepText(0, 'Ejemplo ficticio A');
    await controller.addActivity('Actividad ficticia A');
    await container.read(demoScenarioControllerProvider.notifier)
        .select(DemoScenario.withoutActiveLink);
    final b = await container.read(safetyPlanControllerProvider.future);
    expect(b.stepTexts.first, isEmpty);
    expect(b.activities, isEmpty);
    await container.read(safetyPlanControllerProvider.notifier)
        .setEnvironment('Entorno ficticio B');
    await container.read(demoScenarioControllerProvider.notifier)
        .select(DemoScenario.withActiveLink);
    final a = await container.read(safetyPlanControllerProvider.future);
    expect(a.stepTexts.first, 'Ejemplo ficticio A');
    expect(a.activities, ['Actividad ficticia A']);
    expect(a.environment, isEmpty);
    await container.read(demoScenarioControllerProvider.notifier)
        .select(DemoScenario.withoutActiveLink);
    expect((await container.read(safetyPlanControllerProvider.future)).environment,
        'Entorno ficticio B');
  });

  testWidgets('verificación breve: botón deshabilitado y destino cuidador', (tester) async {
    final container = await _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container, child: const ContigoApp(),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'c1d2e3');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'C1D2E3');
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    final button = tester.widget<ContigoButton>(find.byType(ContigoButton));
    expect(button.label, 'Verificando...');
    expect(button.onPressed, isNull);
    await tester.pump(const Duration(milliseconds: 899));
    expect(find.text('Activa tu cuenta'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('caregiver-home-title')), findsOneWidget);
  });

  testWidgets('relato: respaldo de video, siete páginas y entrada al editor', (tester) async {
    final originalPlatform = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = _FailedVideoPlatform();
    addTearDown(() => VideoPlayerPlatform.instance = originalPlatform);
    // Vista amplia para separar navegación/contenido del chequeo móvil siguiente.
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = await _container();
    addTearDown(container.dispose);
    container.read(sessionControllerProvider.notifier).setSession(
      const Session(userId: 'demo-pcs', role: UserRole.pcs),
    );
    final router = container.read(routerProvider);
    router.go(AppPath.safetyPlanStory);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container, child: const ContigoApp(),
    ));
    await _settleVideo(tester);
    expect(find.textContaining('No pudimos cargar el video.'), findsOneWidget);
    expect(find.text('Pantalla 1 de 7'), findsOneWidget);
    for (var page = 2; page <= 7; page++) {
      await tester.tap(find.text('Siguiente'));
      await _settleVideo(tester);
      expect(find.text('Pantalla $page de 7'), findsOneWidget);
      expect(find.text(safetyPlanStory[page - 1].title), findsOneWidget);
      if (page == 4) {
        expect(find.textContaining('No pudimos cargar el video.'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.text('Construir mi plan para desenredar'));
    await tester.pumpAndSettle();
    expect(find.text('Mi plan de seguridad'), findsOneWidget);
    expect(router.state.uri.path, AppPath.safetyPlanEditor);
    expect(tester.takeException(), isNull);
  });

  testWidgets('relato: botones sin desbordamiento a 412 px', (tester) async {
    final originalPlatform = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = _FailedVideoPlatform();
    addTearDown(() => VideoPlayerPlatform.instance = originalPlatform);
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = await _container();
    addTearDown(container.dispose);
    container.read(sessionControllerProvider.notifier).setSession(
      const Session(userId: 'demo-pcs', role: UserRole.pcs),
    );
    container.read(routerProvider).go(AppPath.safetyPlanStory);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container, child: const ContigoApp(),
    ));
    await _settleVideo(tester);
    for (var page = 2; page <= 7; page++) {
      await tester.tap(find.text('Siguiente'));
      await _settleVideo(tester);
    }
    expect(tester.takeException(), isNull,
        reason: 'Las acciones del relato deben caber en una pantalla móvil');
  });

  testWidgets('video: respaldo si falla la creación nativa del reproductor', (tester) async {
    final originalPlatform = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = _FailedVideoPlatform(failCreation: true);
    addTearDown(() => VideoPlayerPlatform.instance = originalPlatform);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: StoryVideo(
      asset: 'assets/media/plan-desenredo/plan-desenredo-1.mp4',
      title: 'Video de prueba ficticia',
    ))));
    // Tiempo acotado: evita confundir un spinner permanente con pumpAndSettle.
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('No pudimos cargar el video.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('editor: pasos, permiso simulado, actividad, entorno y sesión', (tester) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = await _container();
    addTearDown(container.dispose);
    container.read(sessionControllerProvider.notifier).setSession(
      const Session(userId: 'demo-pcs', role: UserRole.pcs),
    );
    container.read(routerProvider).go(AppPath.safetyPlanEditor);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container, child: const ContigoApp(),
    ));
    await tester.pumpAndSettle();
    Future<void> tapVisible(String label) async {
      final target = find.text(label);
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
    Future<void> saveDialog(String text) async {
      await tester.enterText(find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(TextField),
      ), text);
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.text('Guardar'),
      ));
      await tester.pumpAndSettle();
    }
    await tapVisible('Señales y situaciones que reconozco');
    await tapVisible('Editar');
    await saveDialog('Ejemplo ficticio de prueba');
    expect(find.text('Ejemplo ficticio de prueba'), findsOneWidget);
    expect(find.text('Completo'), findsOneWidget);
    await tapVisible('Agregar desde mis contactos');
    await tapVisible('No permitir');
    expect((await container.read(safetyPlanControllerProvider.future)).contacts, isEmpty);
    await tapVisible('Agregar desde mis contactos');
    await tapVisible('Permitir acceso');
    expect(find.text('Dra. Valentina Ríos'), findsOneWidget);
    await tapVisible('Agregar actividad');
    await saveDialog('Actividad ficticia de prueba');
    expect(find.text('Actividad ficticia de prueba'), findsOneWidget);
    final environment = find.byType(TextField);
    await tester.ensureVisible(environment);
    await tester.pumpAndSettle();
    await tester.enterText(environment, 'Entorno ficticio de prueba');
    await tapVisible('Guardar');
    final draft = await container.read(safetyPlanControllerProvider.future);
    expect(draft.stepTexts.first, 'Ejemplo ficticio de prueba');
    expect(draft.contacts.single.name, 'Dra. Valentina Ríos');
    expect(draft.activities, ['Actividad ficticia de prueba']);
    expect(draft.environment, 'Entorno ficticio de prueba');
    expect(tester.takeException(), isNull);
    // Nueva sesión con las mismas preferencias locales: el plan no debe persistir.
    final nextSession = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(container.read(sharedPreferencesProvider)),
    ]);
    addTearDown(nextSession.dispose);
    final fresh = await nextSession.read(safetyPlanControllerProvider.future);
    expect(fresh.stepTexts.every((text) => text.isEmpty), isTrue);
    expect(fresh.contacts, isEmpty);
    expect(fresh.activities, isEmpty);
    expect(fresh.environment, isEmpty);
  });
}
