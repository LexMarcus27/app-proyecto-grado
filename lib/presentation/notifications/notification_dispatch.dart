import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../domain/connection/connection.dart';
import '../../domain/journey/journey.dart';
import '../../domain/notifications/notifications.dart';
import '../authorization/gating.dart';
import '../connection/connection_selection.dart';
import 'notifications_controller.dart';

/// `true` si [notification] puede mostrarse con la autorización vigente: los
/// avisos sin persona siempre; los dirigidos, solo mientras el vínculo esté
/// activo (`availableNotifications` del prototipo).
bool isNotificationAvailable(JourneyState? journey, DemoNotification notification) {
  final personId = notification.personId;
  if (personId == null) return true;
  if (journey == null) return false;
  return canStrengthenRelationship(journey, personId);
}

/// Abre el destino de una notificación simulada (`openNotification` de
/// `App.tsx`):
///
/// - Recordatorios (`relationships`) → «Tejiendo vínculos».
/// - Se reevalúa la autorización exacta al abrir (incluidas notificaciones
///   creadas antes de una revocación): sin vínculo activo → «Tejiendo
///   vínculos».
/// - Preguntas → preguntas para conectar, con la pregunta del aviso.
/// - Mensaje/contacto/encuentro → conexión con la persona (M8) con esa
///   intención.
Future<void> openDemoNotification(
  BuildContext context,
  WidgetRef ref,
  DemoNotification notification,
) async {
  ref.read(notificationsControllerProvider.notifier).dismissVisible();
  final action = notification.template.action;
  if (action == NotificationAction.relationships) {
    context.goNamed(AppRoute.connectionHub);
    return;
  }
  final journey = ref.read(gatingJourneyProvider).value;
  final personId = notification.personId;
  if (personId == null ||
      journey == null ||
      !canStrengthenRelationship(journey, personId)) {
    context.goNamed(AppRoute.connectionHub);
    return;
  }

  await selectConnectionPerson(ref, personId);
  if (!context.mounted) return;

  if (action == NotificationAction.questions) {
    final question = notification.template.question;
    context.goNamed(
      AppRoute.pcsConnectionQuestions,
      queryParameters: question == null ? const {} : {'q': question},
    );
    return;
  }

  final connectionAction = switch (action) {
    NotificationAction.contact => ConnectionAction.contact,
    NotificationAction.meeting => ConnectionAction.meeting,
    _ => ConnectionAction.message,
  };
  context.goNamed(
    AppRoute.connectionPerson,
    queryParameters: {'p': personId, 'a': connectionAction.wireValue},
  );
}
