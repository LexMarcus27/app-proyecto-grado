import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/notifications/notifications.dart';

/// Etiquetas de tipo de notificación (portadas de `NOTIFICATION_STYLES.label`).
const Map<String, String> _notificationLabels = {
  'reminder': 'Recordatorio para conexión',
  'questions': 'Preguntas para conectar',
  'intimate': 'Mensaje íntimo',
  'social': 'Contacto social',
  'meeting': 'Encuentro personal',
  'closeness': 'Tejiendo cercanía',
};

/// Resuelve el par de color de la notificación desde el tema por su clave de
/// estilo (subtipo o tipo). El contraste texto/fondo y acento/fondo verifica
/// ≥ 4.5:1 (garantizado por el tema y el contrast_test, Requirement 12.5).
NotificationPalette _paletteFor(BuildContext context, String styleKey) {
  final theme = Theme.of(context).extension<ContigoNotificationTheme>()!;
  switch (styleKey) {
    case 'reminder':
      return theme.reminder;
    case 'questions':
      return theme.questions;
    case 'intimate':
      return theme.intimate;
    case 'social':
      return theme.social;
    case 'meeting':
      return theme.meeting;
    case 'closeness':
      return theme.closeness;
    default:
      return theme.reminder;
  }
}

/// Tarjeta de notificación simulada (portada de `NotificationCard`,
/// `src/components/notification-card.tsx`).
///
/// Usa los pares de color del tema ([ContigoNotificationTheme]) con contraste
/// WCAG ≥ 4.5:1 (Requirement 12.5). Muestra la etiqueta de tipo cuando la
/// plantilla lo indica (`showType`), el texto de la notificación y, de forma
/// opcional, un botón de cierre.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onOpen,
    this.onDismiss,
  });

  final DemoNotification notification;
  final VoidCallback onOpen;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = _paletteFor(context, notification.styleKey);

    final baseLabel =
        _notificationLabels[notification.styleKey] ?? 'Notificación';
    // Para el subtipo "closeness" el prototipo antepone la etiqueta del tipo.
    final label = notification.template.subtype != null
        ? '${_notificationLabels[notification.template.type.wireValue]} · $baseLabel'
        : baseLabel;
    final semantics =
        '$label${notification.personName != null ? ' con ${notification.personName}' : ''}. '
        '${notification.text}. Abrir herramienta';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: palette.accent, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: semantics,
              child: InkWell(
                onTap: onOpen,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (notification.template.showType) ...[
                          Text(
                            label,
                            style: (textTheme.labelMedium ?? const TextStyle())
                                .copyWith(
                              color: palette.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          notification.text,
                          style: (textTheme.bodyMedium ?? const TextStyle())
                              .copyWith(color: palette.text),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Cerrar notificación',
              color: palette.accent,
            ),
        ],
      ),
    );
  }
}