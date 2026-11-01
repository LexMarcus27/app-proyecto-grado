import 'dart:async';

import 'package:contigo/app/di.dart';
import 'package:contigo/app/theme.dart';
import 'package:contigo/domain/ema/ema.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/domain/repositories/repositories.dart';
import 'package:contigo/presentation/ema/ema_flow_screen.dart';
import 'package:contigo/presentation/ema/widgets/ema_items.dart';
import 'package:contigo/presentation/network/network_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `JourneyRepository` falso **mutable**: emite por un `StreamController` para
/// poder cambiar el recorrido en vivo (p. ej. revocar un vínculo mientras el
/// cuestionario está visible) y re-emitirlo a quien observe `watchJourney`.
class _MutableJourneyRepository implements JourneyRepository {
  _MutableJourneyRepository(this._journey);

  JourneyState _journey;
  final StreamController<JourneyState> _controller =
      StreamController<JourneyState>.broadcast();

  /// Empuja un nuevo recorrido a los observadores y a `loadJourney`.
  void emit(JourneyState next) {
    _journey = next;
    _controller.add(next);
  }

  @override
  Stream<JourneyState> watchJourney() async* {
    yield _journey;
    yield* _controller.stream;
  }

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

/// `EmaReferenceStore` en memoria **mutable**.
class _FakeEmaReferenceStore implements EmaReferenceStore {
  _FakeEmaReferenceStore([this._reference]);

  EmaReference? _reference;
  final List<EmaReference> saved = [];

  /// Fija la referencia guardada directamente (simula la confirmación desde el
  /// mapa, cuyo guardado real vive en `NetworkMapScreen`).
  void setReference(EmaReference? reference) => _reference = reference;

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

/// `EmaDraftStore` de sesión que registra cada `saveDraft`.
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

/// Recorrido demo con `demo-m` **y** `demo-carmen` activos (dos personas con
/// vínculo activo), para ejercitar un cambio de referencia de una activa a otra.
JourneyState _journeyWithTwoActive() {
  final base = createDemoJourney();
  return base.copyWith(
    associations: [
      for (final association in base.associations)
        association.copyWith(active: true),
    ],
  );
}

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

/// Responde el ítem de rango actual tocando el centro de la barra (≈50).
Future<void> _answerCurrentRange(WidgetTester tester) async {
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

/// Avanza con el botón primario del hilo.
Future<void> _advance(WidgetTester tester) async {
  final advance = find.text('Tejer y seguir');
  final target = tester.any(advance) ? advance : find.text('Tejer y terminar');
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Lee el borrador vigente del `EmaDraftStore` de sesión.
Future<EmaDraft> _currentDraft(EmaDraftStore store) async {
  final draft = await store.loadTodayDraft();
  expect(draft, isNotNull);
  return draft!;
}

void main() {
  // === CORRECCIÓN 1: confirmar una referencia distinta actualiza el borrador ===
  group('Corrección 1 · cambio de referencia en curso', () {
    testWidgets(
      'confirmar otra persona activa reinicia el bloque de relación, cambia la '
      'referencia y recorta questionIndex a ≤ 3',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final journey = _journeyWithTwoActive();
        final referenceM = emaReferenceForPerson(journey, 'demo-m')!;
        final referenceCarmen = emaReferenceForPerson(journey, 'demo-carmen')!;

        final referenceStore = _FakeEmaReferenceStore(referenceM);
        final draftStore = _FakeEmaDraftStore();

        final widget = _host(
          journeyRepository: _MutableJourneyRepository(journey),
          referenceStore: referenceStore,
          draftStore: draftStore,
          prefs: prefs,
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Avanza por los tres ítems binarios (0,1,2) hasta el primer ítem de
        // relación (índice 3) y respóndelo.
        expect(find.text('Hilo 1 de 9'), findsOneWidget);
        for (var i = 1; i <= 3; i++) {
          await tester.ensureVisible(find.text('Sí'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Sí'));
          await tester.pumpAndSettle();
          await _advance(tester);
        }
        // Hilo 4 (índice 3): primer ítem del bloque de relación.
        expect(find.text('Hilo 4 de 9'), findsOneWidget);
        expect(find.textContaining('Sobre tu relación con'), findsOneWidget);
        await _answerCurrentRange(tester);

        // El borrador tiene la respuesta de relación en el índice 3.
        final before = await _currentDraft(draftStore);
        expect(before.answers[3], isNotNull);
        expect(before.reference, referenceM);

        // Simula confirmar OTRA persona activa desde el mapa: cambia la
        // referencia guardada e invalida el provider observado por el flujo.
        referenceStore.setReference(referenceCarmen);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(EmaFlowScreen)),
        );
        container.invalidate(savedEmaReferenceProvider);
        await tester.pumpAndSettle();

        // El borrador se actualizó vía changeEmaReference:
        final after = await _currentDraft(draftStore);
        // (a) referencia cambiada,
        expect(after.reference, referenceCarmen);
        // (b) respuestas del bloque de relación reiniciadas (null),
        expect(after.answers[3], isNull);
        expect(after.answers[4], isNull);
        expect(after.answers[5], isNull);
        // (c) questionIndex recortado a ≤ 3.
        expect(after.questionIndex, lessThanOrEqualTo(3));
      },
    );

    test(
      'un borrador COMPLETADO u OMITIDO no cambia con changeEmaReference',
      () {
        final journey = _journeyWithTwoActive();
        final referenceM = emaReferenceForPerson(journey, 'demo-m')!;
        final referenceCarmen = emaReferenceForPerson(journey, 'demo-carmen')!;

        // Completado: changeEmaReference es no-op.
        final completed = createEmaDraft(referenceM).copyWith(completed: true);
        expect(changeEmaReference(completed, referenceCarmen), completed);

        // Omitido: changeEmaReference es no-op. (omitEmaRelationship solo surte
        // efecto cuando NO hay vínculo activo, así que se construye el borrador
        // omitido con el escenario sin vínculo.)
        final omitted = omitEmaRelationship(
          createEmaDraft(),
          seedForScenario(DemoScenario.withoutActiveLink),
        );
        expect(omitted.relationshipOmission, 'no-active-link');
        expect(changeEmaReference(omitted, referenceCarmen), omitted);
      },
    );
  });

  // === CORRECCIÓN 2: revocación del vínculo DURANTE el cuestionario ===
  group('Corrección 2 · revocación mid-cuestionario', () {
    testWidgets('CASO A (sin otras personas activas): muestra la revisión y ofrece '
        '"Continuar con el registro de hoy"', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      // Solo demo-m activo (el resto inactivos).
      final journey = createDemoJourney();
      final referenceM = emaReferenceForPerson(journey, 'demo-m')!;
      final repo = _MutableJourneyRepository(journey);
      final draftStore = _FakeEmaDraftStore();

      await tester.pumpWidget(
        _host(
          journeyRepository: repo,
          referenceStore: _FakeEmaReferenceStore(referenceM),
          draftStore: draftStore,
          prefs: prefs,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hilo 1 de 9'), findsOneWidget);

      // Revoca el vínculo de demo-m mientras el cuestionario está visible.
      final revoked = journey.copyWith(
        associations: [
          for (final association in journey.associations)
            association.copyWith(active: false),
        ],
      );
      repo.emit(revoked);
      await tester.pumpAndSettle();

      // Se bloquea el registro de relación y se muestra la revisión obsoleta.
      expect(find.text('Revisa la persona de tu registro'), findsOneWidget);
      // Caso A: ofrece continuar hoy con 6 preguntas (sin bloque de relación).
      expect(find.text('Ir a Tu mapa de red'), findsOneWidget);
      expect(find.text('Continuar con el registro de hoy'), findsOneWidget);
    });

    testWidgets(
      'CASO B (otra persona activa): dirige al mapa y NO ofrece la omisión de '
      '6 preguntas',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        // demo-m y demo-carmen activos.
        final journey = _journeyWithTwoActive();
        final referenceM = emaReferenceForPerson(journey, 'demo-m')!;
        final repo = _MutableJourneyRepository(journey);
        final draftStore = _FakeEmaDraftStore();

        await tester.pumpWidget(
          _host(
            journeyRepository: repo,
            referenceStore: _FakeEmaReferenceStore(referenceM),
            draftStore: draftStore,
            prefs: prefs,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Hilo 1 de 9'), findsOneWidget);

        // Revoca SOLO el vínculo de demo-m; demo-carmen sigue activa.
        final revoked = journey.copyWith(
          associations: [
            for (final association in journey.associations)
              association.personId == 'demo-m'
                  ? association.copyWith(active: false)
                  : association,
          ],
        );
        repo.emit(revoked);
        await tester.pumpAndSettle();

        // Revisión obsoleta visible (Caso B): dirige al mapa, sin ofrecer la
        // omisión del bloque.
        expect(find.text('Revisa la persona de tu registro'), findsOneWidget);
        expect(find.text('Ir a Tu mapa de red'), findsOneWidget);
        expect(find.text('Continuar con el registro de hoy'), findsNothing);
        expect(
          find.textContaining(
            'También puedes continuar hoy con seis preguntas',
          ),
          findsNothing,
        );
      },
    );
  });

  // === CORRECCIÓN 3: cambio de día al reanudar ===
  group('Corrección 3 · reinicio por cambio de día al reanudar', () {
    testWidgets('un borrador de sesión con day = ayer se reinicia a un borrador fresco de '
        'hoy al reanudar, conservando la referencia guardada', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final journey = seedForScenario(DemoScenario.withActiveLink);
      final referenceM = emaReferenceForPerson(journey, 'demo-m')!;

      // Borrador "viejo": día de ayer, con avance y una respuesta.
      final yesterday = emaDayKey(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      final stale = createEmaDraft(referenceM, yesterday).copyWith(
        answers: [true, for (var i = 1; i < emaItems.length; i++) null],
        questionIndex: 1,
      );
      expect(stale.day, isNot(emaDayKey()));
      expect(answeredEmaCount(stale), 1);

      final draftStore = _FakeEmaDraftStore(stale);

      await tester.pumpWidget(
        _host(
          journeyRepository: _MutableJourneyRepository(journey),
          referenceStore: _FakeEmaReferenceStore(referenceM),
          draftStore: draftStore,
          prefs: prefs,
        ),
      );
      await tester.pumpAndSettle();

      // Al reanudar, el borrador se reinició a hoy: fresco (0 respondidos,
      // questionIndex 0) conservando la referencia guardada.
      final resumed = await _currentDraft(draftStore);
      expect(resumed.day, emaDayKey());
      expect(answeredEmaCount(resumed), 0);
      expect(resumed.questionIndex, 0);
      expect(resumed.reference, referenceM);

      // La UI arranca en el primer hilo de nuevo.
      expect(find.text('Hilo 1 de 9'), findsOneWidget);
    });
  });
}
