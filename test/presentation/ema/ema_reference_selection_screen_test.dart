import 'package:contigo/app/di.dart';
import 'package:contigo/app/theme.dart';
import 'package:contigo/domain/ema/ema.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/domain/repositories/repositories.dart';
import 'package:contigo/presentation/ema/ema_reference_selection.dart';
import 'package:contigo/presentation/ema/ema_reference_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// `JourneyRepository` falso de solo lectura: emite el recorrido semilla fijo.
///
/// Solo [watchJourney]/[loadJourney] se ejercitan aquí; el resto lanza para
/// evidenciar cualquier uso inesperado.
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

/// `EmaReferenceStore` en memoria que registra cada `saveReference`.
class _FakeEmaReferenceStore implements EmaReferenceStore {
  _FakeEmaReferenceStore();

  EmaReference? _reference;

  /// Historial de llamadas a [saveReference] (para aserciones).
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

/// `EmaDraftStore` de sesión que registra cada `saveDraft` (para aserciones del
/// camino sin vínculo del primer registro, tarea 2.16).
class _FakeEmaDraftStore implements EmaDraftStore {
  EmaDraft? _draft;

  /// Historial de llamadas a [saveDraft].
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

/// Monta [EmaReferenceSelectionScreen] bajo un `GoRouter` mínimo con rutas de
/// destino (origen, mapa de red e inicio del PCS) para que `context.canPop()`,
/// `context.pop()` y `context.goNamed(...)` funcionen como en la app (la
/// pantalla se abre empujada desde el flujo EMA).
Widget _host({
  required JourneyRepository journeyRepository,
  required EmaReferenceStore referenceStore,
  EmaDraftStore? draftStore,
}) {
  final router = GoRouter(
    initialLocation: '/ema/referencia',
    routes: [
      GoRoute(
        name: 'pcs-home',
        path: '/origen',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('origen'))),
      ),
      GoRoute(
        name: 'network-map',
        path: '/mapa-red',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('mapa-red'))),
      ),
      GoRoute(
        path: '/ema/referencia',
        builder: (context, state) => const EmaReferenceSelectionScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      journeyRepositoryProvider.overrideWithValue(journeyRepository),
      emaReferenceStoreProvider.overrideWithValue(referenceStore),
      if (draftStore != null)
        emaDraftStoreProvider.overrideWithValue(draftStore),
    ],
    child: MaterialApp.router(
      theme: ContigoTheme.light(),
      routerConfig: router,
    ),
  );
}

void main() {
  group('shouldShowEmaReferenceSelection', () {
    final journey = seedForScenario(DemoScenario.withActiveLink);
    final activePeople = validCaregivers(journey);

    test('true cuando no hay referencia guardada y hay personas activas', () {
      expect(shouldShowEmaReferenceSelection(null, activePeople), isTrue);
    });

    test('false cuando ya hay una referencia guardada', () {
      final saved = emaReferenceForPerson(journey, 'demo-m');
      expect(saved, isNotNull);
      expect(shouldShowEmaReferenceSelection(saved, activePeople), isFalse);
    });

    test('false cuando no hay ninguna persona con vínculo activo', () {
      expect(
        shouldShowEmaReferenceSelection(null, const <NetworkPerson>[]),
        isFalse,
      );
    });
  });

  group('isEmaNoLinkFirstRun', () {
    test('true: sin referencia guardada y sin personas con vínculo activo', () {
      final journey = seedForScenario(DemoScenario.withoutActiveLink);
      expect(validCaregivers(journey), isEmpty);
      expect(isEmaNoLinkFirstRun(null, journey), isTrue);
    });

    test('false cuando hay una referencia guardada', () {
      // Aunque no haya vínculo activo, con referencia guardada el flujo entra
      // a la revisión de referencia obsoleta (2.12), no a este camino.
      final journey = seedForScenario(DemoScenario.withoutActiveLink);
      final saved = EmaReference(
        pcsId: currentPcsId,
        personId: 'demo-m',
        caregiverId: 'caregiver-m',
        associationId: 'association-demo-m',
      );
      expect(isEmaNoLinkFirstRun(saved, journey), isFalse);
    });

    test('false cuando hay personas con vínculo activo', () {
      // Con personas activas la superficie del primer registro es la selección
      // de 2.11, no el camino sin vínculo.
      final journey = seedForScenario(DemoScenario.withActiveLink);
      expect(validCaregivers(journey), isNotEmpty);
      expect(isEmaNoLinkFirstRun(null, journey), isFalse);
    });
  });

  group('EmaReferenceSelectionScreen', () {
    testWidgets(
      'lista demo-m, el botón se habilita al elegir y continuar guarda la '
      'Referencia_EMA correcta',
      (tester) async {
        final journey = seedForScenario(DemoScenario.withActiveLink);
        final store = _FakeEmaReferenceStore();

        await tester.pumpWidget(
          _host(
            journeyRepository: _FakeJourneyRepository(journey),
            referenceStore: store,
          ),
        );
        await tester.pumpAndSettle();

        // Encabezado del prototipo y la persona vinculada activa.
        expect(find.textContaining('escoge una persona'), findsOneWidget);
        expect(find.text('M.'), findsOneWidget);
        // La nota de ayuda verbatim está presente.
        expect(find.text(emaReferenceHelp), findsOneWidget);

        // El botón de continuar existe pero está deshabilitado (sin elegir).
        final continueFinder = find.text('Continuar con la persona elegida');
        expect(continueFinder, findsOneWidget);
        await tester.tap(continueFinder);
        await tester.pumpAndSettle();
        expect(
          store.saved,
          isEmpty,
          reason: 'el botón deshabilitado no debe guardar nada',
        );

        // Elegir la persona en la lista de radio habilita el botón.
        await tester.tap(find.text('M.'));
        await tester.pumpAndSettle();

        await tester.tap(continueFinder);
        await tester.pumpAndSettle();

        expect(store.saved, hasLength(1));
        final reference = store.saved.single;
        expect(reference.pcsId, currentPcsId);
        expect(reference.pcsId, 'pcs-sofia');
        expect(reference.personId, 'demo-m');
        expect(reference.caregiverId, 'caregiver-m');
        expect(reference.associationId, 'association-demo-m');
      },
    );

    testWidgets(
      'sin personas con vínculo activo (primer registro, tarea 2.16) muestra '
      'la copia verbatim, la acción primaria al mapa y el enlace secundario; '
      'continuar omite el bloque en el borrador de sesión sin guardar '
      'referencia',
      (tester) async {
        final journey = seedForScenario(DemoScenario.withoutActiveLink);
        final store = _FakeEmaReferenceStore();
        final draftStore = _FakeEmaDraftStore();

        await tester.pumpWidget(
          _host(
            journeyRepository: _FakeJourneyRepository(journey),
            referenceStore: store,
            draftStore: draftStore,
          ),
        );
        await tester.pumpAndSettle();

        // Copia verbatim del prototipo (rama vacía de `choosing`).
        expect(
          find.text(
            'Aún no tienes personas cercanas vinculadas. Puedes continuar hoy '
            'con seis preguntas, sin el bloque sobre una persona cercana.',
          ),
          findsOneWidget,
        );
        // Acción primaria al mapa y enlace secundario presentes.
        expect(find.text('Ir a Tu mapa de red'), findsOneWidget);
        final continueFinder = find.text('Continuar con el registro de hoy');
        expect(continueFinder, findsOneWidget);
        // No es la selección de 2.11: no hay botón de elegir persona.
        expect(find.text('Continuar con la persona elegida'), findsNothing);

        // Tocar el enlace secundario aplica la omisión al borrador de sesión.
        await tester.tap(continueFinder);
        await tester.pumpAndSettle();

        expect(draftStore.saved, hasLength(1));
        final omitted = draftStore.saved.single;
        expect(omitted.relationshipOmission, 'no-active-link');
        expect(omitted.reference, isNull);
        // Omisión ⇒ 6 ítems presentados (se omite el bloque de relación).
        expect(emaQuestionIndices(omitted), hasLength(6));

        // El camino sin vínculo NO guarda ninguna Referencia_EMA.
        expect(
          store.saved,
          isEmpty,
          reason: 'el primer registro sin vínculo no debe guardar referencia',
        );

        // Y se vuelve al origen (ya no se ve la superficie de selección).
        expect(find.textContaining('escoge una persona'), findsNothing);
      },
    );

    test('invariante del aviso: una persona listada siempre produce referencia '
        'no nula (el aviso "el vínculo cambió" es una defensa)', () {
      // El aviso "El vínculo cambió. Revisa tu red antes de continuar." solo
      // se muestra si `emaReferenceForPerson` devuelve null para la persona
      // elegida. Como la lista de la pantalla son exactamente los
      // `validCaregivers` (mismo predicado `canStrengthenRelationship` que
      // usa `emaReferenceForPerson`), toda persona ofrecida produce una
      // referencia no nula. Por eso el camino del aviso es defensivo y aquí
      // se verifica la invariante que lo respalda, en lugar de forzar un
      // estado imposible con datos consistentes.
      final journey = seedForScenario(DemoScenario.withActiveLink);
      final offered = validCaregivers(journey);

      expect(offered, isNotEmpty);
      for (final person in offered) {
        expect(
          emaReferenceForPerson(journey, person.id),
          isNotNull,
          reason: 'toda persona ofrecida en la selección debe tener referencia',
        );
      }
    });
  });
}
