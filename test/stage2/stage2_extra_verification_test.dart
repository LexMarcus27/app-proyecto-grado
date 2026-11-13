// Verificación externa de Etapa 2. No modifica lib/ ni la aplicación.
// Ejecutar desde app-proyecto-grado con flutter test --packages
// .dart_tool/package_config.json <ruta absoluta de este archivo>.
import 'package:contigo/app/app.dart';
import 'package:contigo/app/di.dart';
import 'package:contigo/app/router.dart';
import 'package:contigo/data/auth/simulated_auth_service.dart';
import 'package:contigo/data/ema/in_memory_ema_draft_store.dart';
import 'package:contigo/data/ema/local_ema_reference_store.dart';
import 'package:contigo/data/journey/local_journey_repository.dart';
import 'package:contigo/domain/ema/ema.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Fixture {
  Fixture(this.prefs, this.repo, this.refs, this.drafts, this.container);
  final SharedPreferences prefs;
  final LocalJourneyRepository repo;
  final LocalEmaReferenceStore refs;
  final InMemoryEmaDraftStore drafts;
  final ProviderContainer container;
  GoRouter get router => container.read(routerProvider);
}

Future<Fixture> start(WidgetTester tester, {bool twoActive = false}) async {
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repo = LocalJourneyRepository(prefs);
  var journey = createDemoJourney();
  if (twoActive) {
    journey = journey.copyWith(associations: [
      for (final a in journey.associations) a.copyWith(active: true),
    ]);
  }
  await repo.save(journey);
  final refs = LocalEmaReferenceStore(prefs);
  final reference = emaReferenceForPerson(journey, 'demo-m')!;
  await refs.saveReference(reference);
  final drafts = InMemoryEmaDraftStore();
  await drafts.saveDraft(createEmaDraft(reference).copyWith(
    answers: [false, false, false, 20, 30, 40, 50, null, null],
    questionIndex: 7,
  ));
  await tester.pumpWidget(ProviderScope(overrides: [
    authServiceProvider.overrideWithValue(
      SimulatedAuthService(verifyDelay: Duration.zero),
    ),
    sharedPreferencesProvider.overrideWithValue(prefs),
    journeyRepositoryProvider.overrideWithValue(repo),
    emaReferenceStoreProvider.overrideWithValue(refs),
    emaDraftStoreProvider.overrideWithValue(drafts),
  ], child: const ContigoApp()));
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(tester.element(find.byType(ContigoApp)));
  await tester.enterText(find.byType(TextField), 'A3K9X2');
  await tester.pump();
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('¿Cómo estoy hoy?'));
  await tester.pumpAndSettle();
  expect(find.text('Hilo 8 de 9'), findsOneWidget);
  return Fixture(prefs, repo, refs, drafts, container);
}

Future<void> clickText(WidgetTester tester, String label) async {
  final target = find.text(label);
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Ahem, la fuente de prueba predeterminada, altera los anchos de las etiquetas.
    // Cargar las fuentes reales para no confundir sus desbordamientos artificiales
    // con un fallo de la app a anchura de móvil.
    for (final family in ['Inter', 'Lora']) {
      final loader = FontLoader(family);
      loader.addFont(rootBundle.load('assets/fonts/$family-Variable.ttf'));
      await loader.load();
    }
  });
  testWidgets('Req 5.7: desde un EMA activo hay acceso visible a cambiar la referencia', (tester) async {
    await start(tester, twoActive: true);
    expect(
      find.textContaining(RegExp(r'mapa|cambiar.*persona|cambiar.*referencia', caseSensitive: false)),
      findsWidgets,
      reason: 'Debe existir una entrada visible al mapa/cambio de referencia sin revocar un vínculo ni usar el router desde una prueba.',
    );
  });

  testWidgets('Mapa real: cancelar conserva M.; confirmar Carmen conserva respuestas ajenas a relación', (tester) async {
    final f = await start(tester, twoActive: true);
    // La entrada se fuerza por router porque no existe una acción visible en EMA.
    f.router.pushNamed(AppRoute.networkMap);
    await tester.pumpAndSettle();
    await clickText(tester, 'Seleccionar para registro EMA');
    await clickText(tester, 'Cancelar');
    expect((await f.refs.loadReference())!.personId, 'demo-m');
    await clickText(tester, 'Seleccionar para registro EMA');
    await clickText(tester, 'Confirmar cambio para EMA');
    final after = (await f.drafts.loadTodayDraft())!;
    expect(after.reference!.personId, 'demo-carmen');
    expect(after.answers.sublist(0, 3), [false, false, false]);
    expect(after.answers.sublist(3, 6), [null, null, null]);
    expect(after.answers[6], 50);
    expect(after.questionIndex, 3);
    expect(find.text('Hilo 4 de 9'), findsOneWidget);
  });

  testWidgets('Revocación A real: continuar transforma a seis y conserva la preferencia M.', (tester) async {
    final f = await start(tester);
    final j = await f.repo.loadJourney();
    await f.repo.updateAssociations([for (final a in j.associations) a.copyWith(active: false)]);
    await tester.pumpAndSettle();
    expect(find.text('Revisa la persona de tu registro'), findsOneWidget);
    await clickText(tester, 'Continuar con el registro de hoy');
    final after = (await f.drafts.loadTodayDraft())!;
    expect(emaQuestionIndices(after), [0, 1, 2, 6, 7, 8]);
    expect(after.answers.sublist(3, 6), [null, null, null]);
    expect(after.answers.sublist(0, 3), [false, false, false]);
    expect((await f.refs.loadReference())!.personId, 'demo-m');
    expect(find.text('Hilo 5 de 6'), findsOneWidget);
  });

  testWidgets('Revocación B con router y mapa reales: confirma Carmen y continúa EMA', (tester) async {
    final f = await start(tester, twoActive: true);
    final j = await f.repo.loadJourney();
    await f.repo.updateAssociations([
      for (final a in j.associations)
        a.personId == 'demo-m' ? a.copyWith(active: false) : a,
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Revisa la persona de tu registro'), findsOneWidget);
    expect(find.text('Continuar con el registro de hoy'), findsNothing);
    await clickText(tester, 'Ir a Tu mapa de red');
    debugPrint('REVIEW_B_ROUTE=${f.router.state.uri}');
    debugPrint('REVIEW_B_TEXTS=${find.byType(Text).evaluate().map((e) => (e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText()).toList()}');
    expect(find.text('Tu mapa de red'), findsOneWidget);
    await clickText(tester, 'Seleccionar para registro EMA');
    await clickText(tester, 'Confirmar cambio para EMA');
    expect((await f.refs.loadReference())!.personId, 'demo-carmen');
    // Si el mapa queda como raíz, volver y entrar al EMA como haría el usuario.
    if (find.text('Tu mapa de red').evaluate().isNotEmpty) {
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
    }
    if (find.text('¿Cómo estoy hoy?').evaluate().isNotEmpty) {
      await clickText(tester, '¿Cómo estoy hoy?');
    }
    final after = (await f.drafts.loadTodayDraft())!;
    expect(after.reference!.personId, 'demo-carmen');
    expect(after.answers.sublist(0, 3), [false, false, false]);
    expect(after.answers.sublist(3, 6), [null, null, null]);
    expect(find.text('Hilo 4 de 9'), findsOneWidget);
  });
}
