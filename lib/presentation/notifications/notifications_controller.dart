import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/journey/journey.dart';
import '../../domain/notifications/notifications.dart';
import '../authorization/gating.dart';

/// Estado de la bandeja de notificaciones simuladas de la sesión (tarea 3.28).
class NotificationsState {
  const NotificationsState({
    this.inbox = const [],
    this.lastTemplateId,
    this.visible,
  });

  /// Notificaciones generadas en la sesión (más recientes al final).
  final List<DemoNotification> inbox;

  /// Aviso mostrado como banner en el inicio (`visibleNotification` del
  /// prototipo). Ocultarlo no borra el historial de [inbox].
  final DemoNotification? visible;

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
    final inbox = [...state.inbox, notification];
    state = NotificationsState(
      // El prototipo conserva como máximo los 12 avisos más recientes.
      inbox: inbox.length > 12 ? inbox.sublist(inbox.length - 12) : inbox,
      lastTemplateId: notification.template.id,
      visible: notification,
    );
  }

  /// Oculta el banner sin tocar el historial de la bandeja.
  void dismissVisible() {
    if (state.visible == null) return;
    state = NotificationsState(
      inbox: state.inbox,
      lastTemplateId: state.lastTemplateId,
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