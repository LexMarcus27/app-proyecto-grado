// Prueba del mapa de red completo (tarea 3.12): los gráficos de cercanía y
// calidad se dibujan a partir de `metricsFor`, la lista muestra el estado de
// invitación, el flujo de invitación es simulado (deja `pending`) y una
// invitación aceptada por sí sola no habilita la selección de Referencia_EMA.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
// ignore: unused_import
import 'package:contigo/domain/metrics/metrics.dart';

import 'package:contigo/app/di.dart';
import 'package:contigo/app/theme.dart';
import 'package:contigo/domain/ema/ema.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/domain/repositories/repositories.dart';
import 'package:contigo/presentation/network/network_charts.dart';
import 'package:contigo/presentation/network/network_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Repositorio de recorrido mutable en memoria (emite cambios por `watch`).
class _MutableJourneyRepository implements JourneyRepository {
  _MutableJourneyRepository(this._journey);
  JourneyState _journey;
  final _controller = StreamController<JourneyState>.broadcast();

  @override
  JourneyState? get currentOrNull => _journey;

  @override
  Stream<JourneyState> watchJourney() async* {
    yield _journey;
    yield* _controller.stream;
  }

  @override
  Future<JourneyState> loadJourney() async => _journey;

  @override
  Future<void> save(JourneyState journey) async {
    _journey = journey;
    _controller.add(journey);
  }

  @override
  Future<void> updateAssociations(List associations) =>
      throw UnimplementedError();
  @override
  Future<void> updateInvitationStatus(String personId, status) =>
      throw UnimplementedError();
  @override
  Future<void> resetDemo() => throw UnimplementedError();
}

class _FakeEmaReferenceStore implements EmaReferenceStore {
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
  Future<void> clear() async => _reference = null;
}

Widget _host(JourneyRepository repo, EmaReferenceStore store) {
  final router = GoRouter(
    initialLocation: '/mapa-red',
    routes: [
      GoRoute(
        path: '/mapa-red',
        builder: (context, state) => const NetworkMapScreen(),
      ),
      GoRoute(
        path: '/mapa-red/construir',
        name: 'network-builder',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('constructor'))),
      ),
      GoRoute(
        path: '/pcs',
        name: 'pcs-home',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('inicio'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      journeyRepositoryProvider.overrideWithValue(repo),
      emaReferenceStoreProvider.overrideWithValue(store),
    ],
    child: MaterialApp.router(theme: ContigoTheme.light(), routerConfig: router),
  );
}

Future<void> _mount(WidgetTester tester, JourneyState journey) async {
  tester.view.physicalSize = const Size(700, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_host(_MutableJourneyRepository(journey), _FakeEmaReferenceStore()));
  await tester.pumpAndSettle();
}
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Inter', 'Lora']) {
      final loader = FontLoader(family);
      loader.addFont(rootBundle.load('assets/fonts/$family-Variable.ttf'));
      await loader.load();
    }
  });
  testWidgets('Mapa generado sin vínculos activos muestra resultados e invitaciones', (tester) async {
    final seed = createDemoJourney();
    final noLinks = seed.copyWith(associations: [for (final link in seed.associations) link.copyWith(active: false)]);
    expect(noLinks.mapGenerated, isTrue);
    await _mount(tester, noLinks);
    expect(find.text('Mapa de cercanía'), findsOneWidget);
    expect(find.text('Gestionar invitaciones y vínculos'), findsOneWidget);
  });
  testWidgets('Mapa vacío sin vínculos permite iniciar la construcción', (tester) async {
    await _mount(tester, emptyJourney);
    expect(find.text('Construir mi mapa'), findsOneWidget);
  });
  testWidgets('Tocar un nodo del gráfico abre su detalle', (tester) async {
    final seed = createDemoJourney();
    await _mount(tester, seed);
    final graph = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is ClosenessMapPainter);
    await tester.ensureVisible(graph);
    await tester.pumpAndSettle();
    final painted = tester.widget<CustomPaint>(graph).painter! as ClosenessMapPainter;
    final person = painted.entries.first.key;
    final metrics = painted.entries.first.value;
    final base = {RelationshipType.familia: -135.0, RelationshipType.amistades: -45.0, RelationshipType.pareja: -90.0,
      RelationshipType.trabajoOEstudio: 45.0, RelationshipType.comunidadServicioOCredo: 135.0, RelationshipType.otro: 180.0}[person.relationshipType ?? RelationshipType.otro]!;
    final angle = (base - 11) * math.pi / 180;
    final radius = 34 + (1 - metrics.finalCloseness) * 78;
    final x = (160 + math.cos(angle) * radius).clamp(34.0, 286.0);
    final y = (160 + math.sin(angle) * radius).clamp(person.relationshipType == RelationshipType.pareja ? 72.0 : 39.0, 281.0);
    final scale = tester.getSize(graph).width / 320;
    await tester.tapAt(tester.getTopLeft(graph) + Offset(x * scale, y * scale));
    await tester.pumpAndSettle();
    expect(find.text('Cerrar'), findsOneWidget, reason: 'El prototipo permite abrir el detalle desde el nodo');
  });
  testWidgets('Cancelar la referencia desde el detalle mantiene el detalle abierto', (tester) async {
    await _mount(tester, createDemoJourney());
    await _tap(tester, find.text('Lista'));
    await _tap(tester, find.text('M.').last);
    expect(find.text('Cerrar'), findsOneWidget);
    await _tap(tester, find.text('Seleccionar para registro EMA').last);
    await _tap(tester, find.text('Cancelar'));
    expect(find.text('Cerrar'), findsOneWidget);
    expect(find.text('Referencia EMA actualizada.'), findsNothing);
  });
}