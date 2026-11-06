import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/journey/journey.dart';
import '../authorization/gating.dart';

/// Recorrido en vivo para el inicio del PCS (tarea 3.4). Reutiliza el flujo de
/// gating compartido para reaccionar a cambios del recorrido (onboarding,
/// personas del mapa, vínculos).
final pcsHomeJourneyProvider = Provider.autoDispose<AsyncValue<JourneyState>>(
  (ref) => ref.watch(gatingJourneyProvider),
);