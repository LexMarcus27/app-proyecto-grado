import 'dart:math' as math;

import '../journey/journey_authorization.dart';
import '../journey/journey_state.dart';
import '../journey/network_person.dart';
import 'notification_template.dart';

/// Genera una notificación de demostración a partir del recorrido (portado
/// verbatim de `createRandomNotification`, `src/notifications.ts`).
///
/// Reglas de elegibilidad (Requirement 12.2, 12.3, Properties 21 y 22):
/// - Si no hay personas vinculadas activas (`validCaregivers` vacío) solo son
///   elegibles los recordatorios (acción `relationships`), que no llevan
///   marcador de persona.
/// - El marcador `XXX` se sustituye únicamente por el nombre de una persona
///   vinculada activa; si no existe tal persona, esas plantillas no son
///   elegibles (se omiten), de modo que nunca queda un `XXX` sin resolver.
/// - El tipo se elige primero para que los tres ejemplos de "preguntas" no
///   sesguen las probabilidades del tipo.
///
/// [random] permite inyectar una fuente determinista en pruebas; por defecto
/// usa `Random().nextDouble`. [previousTemplateId] evita repetir la plantilla
/// anterior cuando hay alternativas.
DemoNotification createRandomNotification(
  JourneyState journey, {
  String? previousTemplateId,
  double Function()? random,
}) {
  final rnd = random ?? math.Random().nextDouble;
  final people = validCaregivers(journey);

  final eligible = notificationTemplates
      .where(
        (template) =>
            template.action == NotificationAction.relationships ||
            people.isNotEmpty,
      )
      .toList();

  final alternatives =
      eligible.where((template) => template.id != previousTemplateId).toList();
  final pool = alternatives.isNotEmpty ? alternatives : eligible;

  // Elegir primero el tipo para no sesgar por los tres ejemplos de preguntas.
  final types = <NotificationType>[];
  for (final template in pool) {
    if (!types.contains(template.type)) types.add(template.type);
  }
  final type = types[(rnd() * types.length).floor()];
  final templates = pool.where((template) => template.type == type).toList();
  final template = templates[(rnd() * templates.length).floor()];

  final NetworkPerson? person =
      template.action == NotificationAction.relationships || people.isEmpty
          ? null
          : people[(rnd() * people.length).floor()];

  final resolvedText = template.text.split('XXX').join(person?.name ?? '');

  return DemoNotification(
    template: template,
    text: resolvedText,
    personId: person?.id,
    personName: person?.name,
  );
}