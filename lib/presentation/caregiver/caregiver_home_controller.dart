import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../domain/journey/journey.dart';
import '../../domain/repositories/repositories.dart';
import '../authorization/gating.dart';

/// Perfil ficticio del cuidador para el selector demo (tarea 3.5).
class CaregiverProfile {
  const CaregiverProfile({required this.id, required this.name});
  final String id;
  final String name;
}

/// Perfiles de demostración del cuidador. El único vínculo simulable del
/// prototipo es el de Marta con Sofía; los demás perfiles son placeholders del
/// selector y no cambian el vínculo real.
const List<CaregiverProfile> caregiverDemoProfiles = [
  CaregiverProfile(id: DemoCaregiver.id, name: DemoCaregiver.name),
];

/// `CaregiverContext` vigente del cuidador de demostración, derivado del
/// recorrido en vivo. `null` si no hay vínculo activo (gating, Requirement 8.2).
final caregiverContextProvider = Provider.autoDispose<AsyncValue<CaregiverContext?>>(
  (ref) => ref
      .watch(gatingJourneyProvider)
      .whenData((journey) => caregiverContext(journey, DemoCaregiver.id)),
);

/// Controlador de los estados demo del vínculo del cuidador (tarea 3.5).
///
/// Aplica `simulateCaregiverLink` para alternar entre los escenarios
/// `active` | `accepted-only` | `revoked` y **persiste** el `JourneyState`, de
/// modo que el gating del home del cuidador reaccione. Captura la instancia del
/// repositorio para que la operación sobreviva a la navegación.
class CaregiverDemoController {
  CaregiverDemoController(this._repository);

  final JourneyRepository _repository;

  /// Simula el vínculo con el [mode] indicado y persiste el recorrido.
  Future<void> simulate(CaregiverDemoMode mode) async {
    final current = await _repository.loadJourney();
    await _repository.save(simulateCaregiverLink(current, mode));
  }
}

/// Provider del controlador de estados demo del cuidador.
final caregiverDemoControllerProvider =
    Provider.autoDispose<CaregiverDemoController>(
  (ref) => CaregiverDemoController(ref.read(journeyRepositoryProvider)),
);