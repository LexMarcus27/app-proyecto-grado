import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/journey/journey.dart';
import '../../domain/notifications/notifications.dart';
import '../authorization/gating.dart';

/// Estado de la bandeja de notificaciones simuladas de la sesión (tarea 3.28).
class NotificationsState {
  const NotificationsState({this.inbox = const [], this.lastTemplateId});

  /// Notificaciones generadas en la sesión (más recientes al final).
  final List<DemoNotification> inbox;

  /// Id de la última plantilla usada, para evitar repetir la anterior.
  final String? lastTemplateId;
}

/// Controlador de las notificaciones simuladas (Capa_Simulada): genera avisos
/// in-app con `createRandomNotification` sobre el recorrido vigente, **sin
/// enviar nada** externamente (Requirement 12.1). Vive solo en la sesión.
class NotificationsController extends Notifier<NotificationsState> {
  @override
  NotificationsState build() => const NotificationsState();

  /// Genera una notificación aleatoria coherente con la elegibilidad actual
  /// (sin red activa, solo recordatorios) y la agrega a la bandeja.
  void simulate() {
    final journey =
        ref.read(gatingJourneyProvider).value ?? emptyJourney;
    final notification = createRandomNotification(
      journey,
      previousTemplateId: state.lastTemplateId,
    );
    state = NotificationsState(
      inbox: [...state.inbox, notification],
      lastTemplateId: notification.template.id,
    );
  }

  /// Vacía la bandeja de la sesión.
  void clear() => state = const NotificationsState();
}

/// Provider del controlador de notificaciones simuladas.
final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
  NotificationsController.new,
);

/// `true` si no hay personas vinculadas activas (solo se verán recordatorios).
final notificationsWithoutActiveNetworkProvider = Provider<bool>((ref) {
  final journey = ref.watch(gatingJourneyProvider).value;
  if (journey == null) return true;
  return validCaregivers(journey).isEmpty;
});