/// Sembrado de la sesión demo sobre el [JourneyRepository] (tarea 2.10).
///
/// Mantiene la decisión de "qué sembrar" fuera de [LocalJourneyRepository] (que
/// permanece genérico): aquí se conocen los escenarios demo y se escriben a
/// través de la interfaz del repositorio.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../domain/journey/demo_scenario.dart';
import '../../domain/journey/journey_demo.dart';
import '../../domain/repositories/repositories.dart';

/// Siembra el escenario demo [scenario] **solo si** el almacenamiento está
/// vacío (es decir, si [JourneyRepository.loadJourney] devuelve `emptyJourney`).
///
/// Pensado para el arranque de la app: deja el recorrido en un estado usable la
/// primera vez, sin sobrescribir nunca un recorrido ya almacenado por el
/// usuario. Devuelve `true` si sembró, `false` si ya había algo guardado.
///
/// Respeta el comportamiento mínimo de 2.7: la decisión de sembrar vive en la
/// composición/capa de datos de la demo, no en [LocalJourneyRepository].
Future<bool> seedDemoIfEmpty(
  JourneyRepository repository, {
  DemoScenario scenario = DemoScenario.withActiveLink,
}) async {
  final current = await repository.loadJourney();
  if (current != emptyJourney) {
    return false;
  }
  await repository.save(seedForScenario(scenario));
  return true;
}

/// Reemplaza el recorrido almacenado por la semilla del escenario demo elegido.
///
/// A diferencia de [seedDemoIfEmpty], **siempre** escribe: sirve para alternar
/// de forma explícita entre los escenarios con y sin vínculo activo desde la UI
/// o las pruebas (reinicialización de escenario, en la línea de `resetDemo`).
Future<void> applyDemoScenario(
  JourneyRepository repository,
  DemoScenario scenario,
) {
  return repository.save(seedForScenario(scenario));
}

/// Controlador de Riverpod para seleccionar el escenario demo activo.
///
/// Expone la capacidad de alternar entre [DemoScenario.withActiveLink] y
/// [DemoScenario.withoutActiveLink] escribiendo la semilla correspondiente a
/// través del [journeyRepositoryProvider]. Es el punto de entrada mínimo que
/// usarán las tareas 2.11/2.16 y las pruebas manuales en el emulador; no
/// construye ninguna pantalla de ajustes.
class DemoScenarioController extends Notifier<DemoScenario> {
  @override
  DemoScenario build() => DemoScenario.withActiveLink;

  /// Aplica [scenario]: persiste su semilla y actualiza el estado expuesto.
  Future<void> select(DemoScenario scenario) async {
    await applyDemoScenario(ref.read(journeyRepositoryProvider), scenario);
    state = scenario;
  }
}

/// Provider del escenario demo activo y de su conmutación.
final demoScenarioControllerProvider =
    NotifierProvider<DemoScenarioController, DemoScenario>(
  DemoScenarioController.new,
);
