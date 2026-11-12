import 'package:contigo/app/di.dart';
import 'package:contigo/app/theme.dart';
import 'package:contigo/domain/ema/ema.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/domain/repositories/repositories.dart';
import 'package:contigo/presentation/network/network_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// `JourneyRepository` falso de solo lectura: emite el recorrido semilla fijo.
///
/// Solo [watchJourney]/[loadJourney] se ejercitan en estas pruebas; el resto de
/// operaciones no se usan y lanzan para evidenciar cualquier uso inesperado.
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

/// Monta [NetworkMapScreen] bajo un `GoRouter` mínimo con una ruta de origen,
/// para que `context.canPop()`/`context.pop()` funcionen igual que en la app
/// (la pantalla se abre empujada desde el inicio del PCS).
Widget _host({
  required JourneyRepository journeyRepository,
  required EmaReferenceStore referenceStore,
}) {
  final router = GoRouter(
    initialLocation: '/mapa-red',
    routes: [
      GoRoute(
        path: '/origen',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('origen'))),
      ),
      GoRoute(
        path: '/mapa-red',
        builder: (context, state) => const NetworkMapScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      journeyRepositoryProvider.overrideWithValue(journeyRepository),
      emaReferenceStoreProvider.overrideWithValue(referenceStore),
    ],
    child: MaterialApp.router(
      theme: ContigoTheme.light(),
      routerConfig: router,
    ),
  );
}

void main() {
  group('NetworkMapScreen', () {
    testWidgets(
      'con vínculo activo lista demo-m y confirmar guarda la Referencia_EMA',
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

        // El título del mapa y la persona vinculada activa están presentes.
        expect(find.text('Tu mapa de red'), findsOneWidget);
        expect(find.text('M.'), findsOneWidget);

        // Toca la acción de selección → abre el diálogo de confirmación, pero
        // NO persiste todavía.
        await tester.tap(find.text('Seleccionar para registro EMA'));
        await tester.pumpAndSettle();

        expect(
          find.text('Seleccionar persona para el registro EMA'),
          findsOneWidget,
        );
        expect(
          store.saved,
          isEmpty,
          reason: 'abrir el diálogo no debe persistir nada',
        );

        // Confirma explícitamente → persiste la referencia.
        await tester.tap(find.text('Confirmar selección para EMA'));
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

    testWidgets('tocar y luego CANCELAR no persiste ninguna referencia', (
      tester,
    ) async {
      final journey = seedForScenario(DemoScenario.withActiveLink);
      final store = _FakeEmaReferenceStore();

      await tester.pumpWidget(
        _host(
          journeyRepository: _FakeJourneyRepository(journey),
          referenceStore: store,
        ),
      );
      await tester.pumpAndSettle();

      // Toca la persona (abre el diálogo) pero cancela sin confirmar.
      await tester.tap(find.text('Seleccionar para registro EMA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(
        store.saved,
        isEmpty,
        reason: 'sin confirmación explícita no se guarda nada',
      );
    });

    testWidgets(
      'mapa generado sin vínculo activo: no ofrece referencia pero sí el mapa',
      (tester) async {
        // "Sin referencia EMA elegible" (distinto de "sin red"): el mapa está
        // generado, así que se muestran los resultados; pero sin ninguna
        // Asociacion_Activa no se ofrece seleccionar referencia EMA.
        final journey = seedForScenario(DemoScenario.withoutActiveLink);
        final store = _FakeEmaReferenceStore();

        await tester.pumpWidget(
          _host(
            journeyRepository: _FakeJourneyRepository(journey),
            referenceStore: store,
          ),
        );
        await tester.pumpAndSettle();

        // El mapa (red generada) sí está disponible.
        expect(find.text('Mapa de cercanía'), findsOneWidget);
        expect(find.text('Sin persona de referencia elegible'), findsOneWidget);
        // Sin asociación activa no hay acción de selección de referencia EMA.
        expect(find.text('Seleccionar para registro EMA'), findsNothing);
        expect(store.saved, isEmpty);
      },
    );

    testWidgets(
      'sin red generada ofrece construir el mapa',
      (tester) async {
        // "Sin red": no hay mapa generado; se ofrece construirlo.
        final store = _FakeEmaReferenceStore();

        await tester.pumpWidget(
          _host(
            journeyRepository: _FakeJourneyRepository(emptyJourney),
            referenceStore: store,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tu mapa todavía no está generado'), findsOneWidget);
        expect(find.text('Construir mi mapa'), findsOneWidget);
        expect(find.text('Seleccionar para registro EMA'), findsNothing);
      },
    );
  });
}
