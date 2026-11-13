import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../domain/connection/connection.dart';

/// Guarda [personId] como persona seleccionada del recorrido
/// (`journey.selectedPersonId`), igual que `setJourney({...selectedPersonId})`
/// del prototipo al abrir una conexión o una notificación dirigida.
Future<void> selectConnectionPerson(WidgetRef ref, String personId) async {
  final repo = ref.read(journeyRepositoryProvider);
  final journey = await repo.loadJourney();
  if (journey.selectedPersonId != personId) {
    await repo.save(journey.copyWith(selectedPersonId: personId));
  }
}

/// Convierte el parámetro de consulta `a` de la ruta de conexión en una
/// [ConnectionAction]; `null` si falta o no es válido.
ConnectionAction? connectionActionFromQuery(String? value) {
  for (final action in ConnectionAction.values) {
    if (action.wireValue == value) return action;
  }
  return null;
}

/// Convierte el parámetro de consulta `s` del hub en un [ConnectionStep];
/// `null` si falta o no es válido.
ConnectionStep? connectionStepFromQuery(String? value) {
  for (final step in ConnectionStep.values) {
    if (step.wireValue == value) return step;
  }
  return null;
}
