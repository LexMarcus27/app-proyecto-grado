import 'package:contigo/app/di.dart';
import 'package:contigo/app/theme.dart';
import 'package:contigo/domain/ema/ema.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/domain/repositories/repositories.dart';
import 'package:contigo/presentation/ema/ema_stale_reference.dart';
import 'package:contigo/presentation/ema/ema_stale_reference_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

/// `EmaReferenceStore` en memoria con una referencia guardada fija. Registra
/// cualquier escritura para poder afirmar que la revisión NO la altera.
class _FakeEmaReferenceStore implements EmaReferenceStore {
  _FakeEmaReferenceStore(this._reference);

  EmaReference? _reference;

  /// Historial de llamadas a [saveReference] (debe quedar vacío en 2.12).
  final List<EmaReference> saved = [];
  int clears = 0;

  @override
  Future<EmaReference?> loadReference() async => _reference;

  @override
  Future<void> saveReference(EmaReference reference) async {
    saved.add(reference);
    _reference = reference;
  }

  @override
  Future<void> clear() async {
    clears++;
    _reference = null;
  }
}

/// `EmaDraftStore` de sesión que registra cada `saveDraft` (para aserciones).
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

/// Monta [EmaStaleReferenceScreen] bajo un `GoRouter` mínimo con rutas de
/// destino (origen, mapa de red e inicio del PCS) para que `context.pop()` y
/// `context.goNamed(...)` funcionen igual que en la app.
Widget _host({
  required JourneyRepository journeyRepository,
  required EmaReferenceStore referenceStore,
  required EmaDraftStore draftStore,
}) {
  final router = GoRouter(
    initialLocation: '/ema/revisar-referencia',
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
      GoRoute(
        path: '/ema/revisar-referencia',
        builder: (context, state) => const EmaStaleReferenceScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
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

/// Referencia guardada que apunta a una persona concreta (solo IDs). Se
/// construye a mano porque [emaReferenceForPerson] solo devuelve referencia
/// cuando la asociación está activa; aquí queremos una referencia guardada que
/// ya NO corresponde a un vínculo activo.
EmaReference _savedReferenceFor({
  required String personId,
  required String caregiverId,
  required String associationId,
}) {
  return EmaReference(
    pcsId: currentPcsId,
    personId: personId,
    caregiverId: caregiverId,
    associationId: associationId,
  );
}

void main() {
  group('emaStaleReferenceMode (helper puro)', () {
    test('referencia guardada inactiva + sin personas activas → '
        'reviewNoActivePeople', () {
      // Escenario sin vínculo activo: todas las asociaciones desactivadas.
      final journey = seedForScenario(DemoScenario.withoutActiveLink);
      expect(validCaregivers(journey), isEmpty);

      // La referencia previamente guardada (demo-m) ya no está activa.
      final saved = _savedReferenceFor(
        personId: 'demo-m',
        caregiverId: 'caregiver-m',
        associationId: 'association-demo-m',
      );
      expect(isEmaReferenceActive(journey, saved), isFalse);

      expect(
        emaStaleReferenceMode(saved, journey),
        EmaReferenceReviewMode.reviewNoActivePeople,
      );
    });

    test('referencia guardada inactiva + otra persona activa → '
        'reviewOtherActivePeople', () {
      // Recorrido demo: demo-m tiene vínculo activo; demo-carmen NO.
      final journey = createDemoJourney();
      final active = validCaregivers(journey);
      expect(active.map((p) => p.id), contains('demo-m'));

      // La referencia guardada apunta a demo-carmen (asociación inactiva).
      final saved = _savedReferenceFor(
        personId: 'demo-carmen',
        caregiverId: 'caregiver-carmen',
        associationId: 'association-demo-carmen',
      );
      expect(isEmaReferenceActive(journey, saved), isFalse);

      expect(
        emaStaleReferenceMode(saved, journey),
        EmaReferenceReviewMode.reviewOtherActivePeople,
      );
    });

    test('referencia guardada que sigue activa → none', () {
      final journey = createDemoJourney();
      final saved = emaReferenceForPerson(journey, 'demo-m');
      expect(saved, isNotNull);
      expect(isEmaReferenceActive(journey, saved), isTrue);

      expect(emaStaleReferenceMode(saved, journey), EmaReferenceReviewMode.none);
    });

    test('sin referencia guardada → none', () {
      final journey = createDemoJourney();
      expect(emaStaleReferenceMode(null, journey), EmaReferenceReviewMode.none);
    });
  });

  group('EmaStaleReferenceScreen', () {
    testWidgets(
      'CASO A (sin personas activas): muestra la copia de revisión, la acción '
      'primaria y el enlace secundario; continuar omite el bloque en el '
      'borrador de sesión sin tocar la referencia guardada',
      (tester) async {
        final journey = seedForScenario(DemoScenario.withoutActiveLink);
        final saved = _savedReferenceFor(
          personId: 'demo-m',
          caregiverId: 'caregiver-m',
          associationId: 'association-demo-m',
        );
        final referenceStore = _FakeEmaReferenceStore(saved);
        final draftStore = _FakeEmaDraftStore();

        await tester.pumpWidget(
          _host(
            journeyRepository: _FakeJourneyRepository(journey),
            referenceStore: referenceStore,
            draftStore: draftStore,
          ),
        );
        await tester.pumpAndSettle();

        // Encabezado y copia verbatim del prototipo.
        expect(find.text('Revisa la persona de tu registro'), findsOneWidget);
        expect(
          find.textContaining('No cambiaremos tu elección automáticamente'),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'En Tu mapa de red puedes revisar el vínculo o confirmar otra '
            'persona para el registro EMA.',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'También puedes continuar hoy con seis preguntas',
          ),
          findsOneWidget,
        );

        // Ambas acciones presentes en el Caso A.
        expect(find.text('Ir a Tu mapa de red'), findsOneWidget);
        final continueFinder = find.text('Continuar con el registro de hoy');
        expect(continueFinder, findsOneWidget);

        // Tocar el enlace secundario aplica la omisión al borrador de sesión.
        await tester.tap(continueFinder);
        await tester.pumpAndSettle();

        expect(draftStore.saved, hasLength(1));
        final omitted = draftStore.saved.single;
        expect(omitted.relationshipOmission, 'no-active-link');
        expect(omitted.reference, isNull);
        // Omisión ⇒ 6 ítems presentados (se omite el bloque de relación).
        expect(emaQuestionIndices(omitted), hasLength(6));

        // La referencia guardada NO se altera (ni guarda ni borra).
        expect(
          referenceStore.saved,
          isEmpty,
          reason: 'la revisión no debe cambiar la referencia guardada',
        );
        expect(referenceStore.clears, 0);

        // Y se vuelve al origen (ya no se ve la pantalla de revisión).
        expect(find.text('Revisa la persona de tu registro'), findsNothing);
      },
    );

    testWidgets(
      'CASO B (otra persona activa): muestra la acción primaria pero NO el '
      'enlace "Continuar con el registro de hoy"',
      (tester) async {
        final journey = createDemoJourney();
        final saved = _savedReferenceFor(
          personId: 'demo-carmen',
          caregiverId: 'caregiver-carmen',
          associationId: 'association-demo-carmen',
        );
        final referenceStore = _FakeEmaReferenceStore(saved);
        final draftStore = _FakeEmaDraftStore();

        await tester.pumpWidget(
          _host(
            journeyRepository: _FakeJourneyRepository(journey),
            referenceStore: referenceStore,
            draftStore: draftStore,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Revisa la persona de tu registro'), findsOneWidget);
        expect(find.text('Ir a Tu mapa de red'), findsOneWidget);
        // En el Caso B no se ofrece la omisión del bloque.
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
}
