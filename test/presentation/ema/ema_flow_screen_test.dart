import 'package:contigo/app/di.dart';
import 'package:contigo/app/theme.dart';
import 'package:contigo/domain/ema/ema.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/domain/repositories/repositories.dart';
import 'package:contigo/presentation/ema/ema_flow_gating.dart';
import 'package:contigo/presentation/ema/ema_flow_screen.dart';
import 'package:contigo/presentation/ema/widgets/ema_items.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `JourneyRepository` falso de solo lectura: emite el recorrido semilla fijo.
class _FakeJourneyRepository implements JourneyRepository {
  _FakeJourneyRepository(this._journey);

  final JourneyState _journey;

  @override
  JourneyState? get currentOrNull => _journey;

  @override
  Stream<JourneyState> watchJourney() => Stream.value(_journey);

  @override
  Future<JourneyState> loadJourney() async => _journey;

  @override
  Future<void> save(JourneyState journey) => throw UnimplementedError();

  @override
  Future<void> updateAssociations(List associations) =>
      throw UnimplementedError();

  @override
  Future<void> updateInvitationStatus(String personId, status) =>
      throw UnimplementedError();

  @override
  Future<void> resetDemo() => throw UnimplementedError();
}

/// `EmaReferenceStore` en memoria con una referencia guardada opcional.
class _FakeEmaReferenceStore implements EmaReferenceStore {
  _FakeEmaReferenceStore([this._reference]);

  EmaReference? _reference;
  final List<EmaReference> saved = [];

  @override
  Future<EmaReference?> loadReference() async => _reference;

  @override
  Future<void> saveReference(EmaReference reference) async {
    saved.add(reference);
    _reference = reference;
  }

  @override
  Future<void> clear() async {
    _reference = null;
  }
}

/// `EmaDraftStore` de sesión que registra cada `saveDraft`. Admite un borrador
/// inicial (p. ej. el borrador omitido del camino de 6 ítems).
class _FakeEmaDraftStore implements EmaDraftStore {
  _FakeEmaDraftStore([this._draft]);

  EmaDraft? _draft;
  final List<EmaDraft> saved = [];

  @override
  Future<EmaDraft?> loadTodayDraft() async => _draft;

  @override
  Future<void> saveDraft(EmaDraft draft) async {
    saved.add(draft);
    _draft = draft;
  }

  @override
  Future<void> clear() async {
    _draft = null;
  }
}

/// Monta [EmaFlowScreen] bajo un `GoRouter` mínimo con rutas de destino
/// (inicio del PCS y mapa de red) para que `context.pop()`/`context.goNamed(...)`
/// funcionen como en la app.
Widget _host({
  required JourneyRepository journeyRepository,
  required EmaReferenceStore referenceStore,
  required EmaDraftStore draftStore,
  required SharedPreferences prefs,
}) {
  final router = GoRouter(
    initialLocation: '/ema',
    routes: [
      GoRoute(
        name: 'pcs-home',
        path: '/pcs',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('inicio-pcs'))),
      ),
      GoRoute(
        name: 'network-map',
        path: '/mapa-red',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('mapa-red'))),
      ),
      GoRoute(path: '/ema', builder: (context, state) => const EmaFlowScreen()),
    ],
  );

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      journeyRepositoryProvider.overrideWithValue(journeyRepository),
      emaReferenceStoreProvider.overrideWithValue(referenceStore),
      emaDraftStoreProvider.overrideWithValue(draftStore),
    ],
    child: MaterialApp.router(
      theme: ContigoTheme.light(),
      routerConfig: router,
    ),
  );
}

/// Responde el ítem actual (binario → "Sí"; rango → toca el centro de la barra)
/// y luego avanza con el botón primario.
Future<void> _answerCurrentAndAdvance(WidgetTester tester) async {
  final yes = find.text('Sí');
  if (tester.any(yes)) {
    // Binario: toca "Sí".
    await tester.ensureVisible(yes);
    await tester.pumpAndSettle();
    await tester.tap(yes);
    await tester.pumpAndSettle();
  } else {
    // Rango: toca el centro de la barra (mapea a ~50) para responder. El
    // restyle (tarjeta blanca + indicador) hace la escala más alta, por lo que
    // primero se asegura visible dentro del `ListView`.
    final slider = find.byType(EmaRangeItem);
    expect(slider, findsOneWidget);
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();
    final paint = find
        .descendant(of: slider, matching: find.byType(CustomPaint))
        .first;
    await tester.tapAt(tester.getCenter(paint));
    await tester.pumpAndSettle();
  }

  // Avanza / termina con el botón primario. Tras el restyle el botón puede
  // quedar bajo el pliegue en la ventana de prueba: se desplaza a la vista.
  final advance = find.text('Tejer y seguir');
  final target = tester.any(advance) ? advance : find.text('Tejer y terminar');
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  group('resolveEmaFlowGate', () {
    test('referenceSelection: sin referencia y con personas activas', () {
      final journey = seedForScenario(DemoScenario.withActiveLink);
      final draft = createEmaDraft();
      expect(
        resolveEmaFlowGate(
          savedReference: null,
          journey: journey,
          draft: draft,
        ),
        EmaFlowGate.referenceSelection,
      );
    });

    test('noLinkFirstRun: sin referencia y sin personas activas', () {
      final journey = seedForScenario(DemoScenario.withoutActiveLink);
      final draft = createEmaDraft();
      expect(
        resolveEmaFlowGate(
          savedReference: null,
          journey: journey,
          draft: draft,
        ),
        EmaFlowGate.noLinkFirstRun,
      );
    });

    test('questionnaire: con referencia activa guardada', () {
      final journey = seedForScenario(DemoScenario.withActiveLink);
      final reference = emaReferenceForPerson(journey, 'demo-m')!;
      final draft = createEmaDraft(reference);
      expect(
        resolveEmaFlowGate(
          savedReference: reference,
          journey: journey,
          draft: draft,
        ),
        EmaFlowGate.questionnaire,
      );
    });

    test('staleReference: referencia guardada que ya no está activa', () {
      final journey = seedForScenario(DemoScenario.withoutActiveLink);
      final reference = EmaReference(
        pcsId: currentPcsId,
        personId: 'demo-m',
        caregiverId: 'caregiver-m',
        associationId: 'association-demo-m',
      );
      final draft = createEmaDraft(reference);
      expect(
        resolveEmaFlowGate(
          savedReference: reference,
          journey: journey,
          draft: draft,
        ),
        EmaFlowGate.staleReference,
      );
    });

    test('questionnaire: borrador ya omitido salta cualquier revisión', () {
      final journey = seedForScenario(DemoScenario.withoutActiveLink);
      final reference = EmaReference(
        pcsId: currentPcsId,
        personId: 'demo-m',
        caregiverId: 'caregiver-m',
        associationId: 'association-demo-m',
      );
      final omitted = omitEmaRelationship(createEmaDraft(), journey);
      expect(
        resolveEmaFlowGate(
          savedReference: reference,
          journey: journey,
          draft: omitted,
        ),
        EmaFlowGate.questionnaire,
      );
    });
  });

  group('EmaFlowScreen · camino de 9 ítems', () {
    testWidgets(
      'con referencia activa: 9 hilos, el bloque de relación muestra el nombre '
      'y completar muestra el resultado 9 de 9',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final journey = seedForScenario(DemoScenario.withActiveLink);
        final reference = emaReferenceForPerson(journey, 'demo-m')!;
        final referenceStore = _FakeEmaReferenceStore(reference);
        final draftStore = _FakeEmaDraftStore();

        await tester.pumpWidget(
          _host(
            journeyRepository: _FakeJourneyRepository(journey),
            referenceStore: referenceStore,
            draftStore: draftStore,
            prefs: prefs,
          ),
        );
        await tester.pumpAndSettle();

        // Banner y progreso del primer hilo de nueve.
        expect(find.text('Tu tejido de hoy'), findsOneWidget);
        expect(find.text('Hilo 1 de 9'), findsOneWidget);

        var sawRelationshipName = false;
        // Responder los 9 ítems presentados, avanzando en cada uno.
        for (var position = 1; position <= 9; position++) {
          expect(find.text('Hilo $position de 9'), findsOneWidget);
          // El bloque de relación (hilos 4-6) muestra el nombre de referencia.
          if (find
              .textContaining('relación con M.')
              .evaluate()
              .isNotEmpty) {
            expect(find.textContaining('relación con M.'), findsWidgets);
            sawRelationshipName = true;
          }
          await _answerCurrentAndAdvance(tester);
        }

        expect(
          sawRelationshipName,
          isTrue,
          reason: 'los ítems de relación deben mostrar el nombre de referencia',
        );

        // Vista de resultado con el resumen 9 de 9.
        expect(find.text('Tu registro de hoy'), findsOneWidget);
        await _expandEmaReview(tester);
        expect(find.text('9 de 9 hilos respondidos.'), findsOneWidget);
        expect(
          find.textContaining('Persona de referencia: M.'),
          findsOneWidget,
        );

        // El borrador final se guardó en la sesión y quedó completado.
        expect(draftStore.saved, isNotEmpty);
        final last = draftStore.saved.last;
        expect(last.completed, isTrue);
        expect(answeredEmaCount(last), 9);

        // Las respuestas EMA NO se escribieron en shared_preferences (sesión).
        expect(prefs.getKeys().where((k) => k.contains('answer')), isEmpty);
        expect(prefs.getKeys().where((k) => k.contains('draft')), isEmpty);
      },
    );
  });

  group('EmaFlowScreen · camino de 6 ítems', () {
    testWidgets(
      'sin vínculo activo con borrador omitido: 6 hilos, omite el bloque de '
      'relación y completa 6 de 6',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final journey = seedForScenario(DemoScenario.withoutActiveLink);
        // Borrador ya omitido (resultado del camino sin vínculo / revisión).
        final omitted = omitEmaRelationship(createEmaDraft(), journey);
        expect(omitted.relationshipOmission, 'no-active-link');
        final referenceStore = _FakeEmaReferenceStore();
        final draftStore = _FakeEmaDraftStore(omitted);

        await tester.pumpWidget(
          _host(
            journeyRepository: _FakeJourneyRepository(journey),
            referenceStore: referenceStore,
            draftStore: draftStore,
            prefs: prefs,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hilo 1 de 6'), findsOneWidget);

        // Ningún ítem presentado debe ser del bloque de relación.
        for (var position = 1; position <= 6; position++) {
          expect(find.text('Hilo $position de 6'), findsOneWidget);
          expect(find.textContaining('Sobre tu relación con'), findsNothing);
          await _answerCurrentAndAdvance(tester);
        }

        await _expandEmaReview(tester);
        expect(find.text('6 de 6 hilos respondidos.'), findsOneWidget);
        expect(
          find.text(
            'Hoy no se incluyó el bloque sobre una persona cercana vinculada.',
          ),
          findsOneWidget,
        );

        final last = draftStore.saved.last;
        expect(last.completed, isTrue);
        expect(last.relationshipOmission, 'no-active-link');
        expect(answeredEmaCount(last), 6);

        // Sesión: nada de respuestas en disco.
        expect(prefs.getKeys().where((k) => k.contains('draft')), isEmpty);
      },
    );
  });

  group('EmaFlowScreen · acciones del cuestionario', () {
    testWidgets(
      'el botón primario está deshabilitado hasta responder el ítem actual',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final journey = seedForScenario(DemoScenario.withActiveLink);
        final reference = emaReferenceForPerson(journey, 'demo-m')!;

        await tester.pumpWidget(
          _host(
            journeyRepository: _FakeJourneyRepository(journey),
            referenceStore: _FakeEmaReferenceStore(reference),
            draftStore: _FakeEmaDraftStore(),
            prefs: prefs,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hilo 1 de 9'), findsOneWidget);

        // Antes de responder: tocar "Tejer y seguir" no avanza (deshabilitado).
        final advanceBtn = find.text('Tejer y seguir');
        await tester.ensureVisible(advanceBtn);
        await tester.pumpAndSettle();
        await tester.tap(advanceBtn, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(
          find.text('Hilo 1 de 9'),
          findsOneWidget,
          reason: 'sin responder no debe avanzar',
        );

        // Al responder, avanza.
        await _answerCurrentAndAdvance(tester);
        expect(find.text('Hilo 2 de 9'), findsOneWidget);
      },
    );

    testWidgets('"Hilo anterior" retrocede al ítem presentado previo', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final journey = seedForScenario(DemoScenario.withActiveLink);
      final reference = emaReferenceForPerson(journey, 'demo-m')!;

      await tester.pumpWidget(
        _host(
          journeyRepository: _FakeJourneyRepository(journey),
          referenceStore: _FakeEmaReferenceStore(reference),
          draftStore: _FakeEmaDraftStore(),
          prefs: prefs,
        ),
      );
      await tester.pumpAndSettle();

      // Avanzar al hilo 2.
      await _answerCurrentAndAdvance(tester);
      expect(find.text('Hilo 2 de 9'), findsOneWidget);

      // "Hilo anterior" vuelve al hilo 1.
      expect(find.text('Hilo anterior'), findsOneWidget);
      await tester.ensureVisible(find.text('Hilo anterior'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hilo anterior'));
      await tester.pumpAndSettle();
      expect(find.text('Hilo 1 de 9'), findsOneWidget);
    });
  });
}

/// Despliega el resumen «Tu registro de hoy» del resultado del EMA.
Future<void> _expandEmaReview(WidgetTester tester) async {
  final review = find.text('Tu registro de hoy');
  await tester.ensureVisible(review);
  await tester.pumpAndSettle();
  await tester.tap(review);
  await tester.pumpAndSettle();
}
