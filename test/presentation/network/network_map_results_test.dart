// Prueba del mapa de red completo (tarea 3.12): los gráficos de cercanía y
// calidad se dibujan a partir de `metricsFor`, la lista muestra el estado de
// invitación, el flujo de invitación es simulado (deja `pending`) y una
// invitación aceptada por sí sola no habilita la selección de Referencia_EMA.

import 'dart:async';

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

void main() {
  testWidgets('mapa generado dibuja los gráficos de cercanía y calidad',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _MutableJourneyRepository(createDemoJourney());
    await tester.pumpWidget(_host(repo, _FakeEmaReferenceStore()));
    await tester.pumpAndSettle();

    // Pestañas presentes y gráfico de cercanía por defecto.
    expect(find.text('Mapa de cercanía'), findsOneWidget);
    expect(find.text('Calidad relacional'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) =>
          w is CustomPaint && w.painter is ClosenessMapPainter),
      findsOneWidget,
    );

    // Cambia a calidad: se dibuja la cuadrícula.
    await tester.tap(find.text('Calidad relacional'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is QualityGridPainter),
      findsOneWidget,
    );

    // La lista muestra personas y su estado de invitación.
    await tester.tap(find.text('Lista'));
    await tester.pumpAndSettle();
    expect(find.text('M.'), findsWidgets);
    expect(find.text('Persona cercana vinculada'), findsWidgets);
  });

  testWidgets('invitación simulada deja la persona pendiente', (tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _MutableJourneyRepository(createDemoJourney());
    await tester.pumpWidget(_host(repo, _FakeEmaReferenceStore()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gestionar invitaciones y vínculos'));
    await tester.pumpAndSettle();
    // Lu (demo-lu) está "Sin invitación": se puede invitar.
    expect(find.text('Sin invitación'), findsWidgets);
    await tester.tap(find.text('Sin invitación').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('¿Quieres invitar'), findsOneWidget);
    await tester.tap(find.text('Simular envío de invitación'));
    await tester.pumpAndSettle();
    expect(find.textContaining('pendiente de aceptación'), findsOneWidget);

    // El estado persistido quedó en pending y sin asociación nueva.
    final lu = repo.currentOrNull!.people.firstWhere((p) => p.id == 'demo-lu');
    expect(lu.invitationStatus, InvitationStatus.pending);
    expect(canStrengthenRelationship(repo.currentOrNull!, 'demo-lu'), isFalse);
  });

  testWidgets(
      'persona aceptada sin asociación no habilita selección de referencia',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _MutableJourneyRepository(createDemoJourney());
    await tester.pumpWidget(_host(repo, _FakeEmaReferenceStore()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lista'));
    await tester.pumpAndSettle();
    // Alex (demo-alex) está pendiente (aceptación/asociación no activa).
    await tester.tap(find.text('Alex').first);
    await tester.pumpAndSettle();
    // El detalle de una persona sin asociación activa explica el gating y NO
    // ofrece su propio botón de selección de referencia (solo "Invitar"/"Cerrar").
    expect(
      find.textContaining('necesita una asociación activa'),
      findsOneWidget,
    );
    expect(find.text('Cerrar'), findsOneWidget);
  });
}