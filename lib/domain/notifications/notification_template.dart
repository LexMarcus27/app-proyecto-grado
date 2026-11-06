import 'package:equatable/equatable.dart';

/// Tipo de notificación (portado verbatim del prototipo, `NotificationType` en
/// `src/notifications.ts`). Las cadenas se preservan como clave de estilo.
enum NotificationType {
  reminder('reminder'),
  questions('questions'),
  intimate('intimate'),
  social('social'),
  meeting('meeting');

  const NotificationType(this.wireValue);

  final String wireValue;
}

/// Acción asociada a una notificación (portado de `NotificationAction`).
///
/// `relationships` es la única acción que **no** requiere una persona vinculada
/// activa (son los recordatorios); el resto apunta a una persona.
enum NotificationAction {
  relationships('relationships'),
  questions('questions'),
  message('message'),
  contact('contact'),
  meeting('meeting');

  const NotificationAction(this.wireValue);

  final String wireValue;
}

/// Clave de subtipo del prototipo: solo `closeness` ("Tejiendo cercanía").
/// Cuando está presente, determina el estilo en vez del [NotificationType].
const String notificationSubtypeCloseness = 'closeness';

/// Plantilla de notificación (portado de `NotificationTemplate`).
///
/// El texto se preserva **verbatim**, incluido el marcador `XXX` que se
/// sustituye por el nombre de una persona vinculada activa (Requirement 12.3).
class NotificationTemplate extends Equatable {
  const NotificationTemplate({
    required this.id,
    required this.type,
    required this.text,
    required this.showType,
    required this.action,
    this.subtype,
    this.question,
  });

  final String id;
  final NotificationType type;

  /// Subtipo opcional; el único valor del prototipo es
  /// [notificationSubtypeCloseness].
  final String? subtype;

  /// Texto de la notificación, verbatim (puede contener el marcador `XXX`).
  final String text;

  /// Si se muestra la etiqueta de tipo.
  final bool showType;

  final NotificationAction action;

  /// Pregunta asociada (solo en plantillas de tipo `questions`).
  final String? question;

  /// Clave de estilo: el subtipo si existe, o el valor del tipo.
  String get styleKey => subtype ?? type.wireValue;

  @override
  List<Object?> get props => [id, type, subtype, text, showType, action, question];
}

/// Notificación de demostración resuelta: una plantilla con la persona a la que
/// apunta (si corresponde) y el texto con el marcador ya sustituido.
class DemoNotification extends Equatable {
  const DemoNotification({
    required this.template,
    required this.text,
    this.personId,
    this.personName,
  });

  /// Plantilla de origen.
  final NotificationTemplate template;

  /// Texto final (marcador `XXX` sustituido por el nombre, o eliminado).
  final String text;

  /// Identificador de la persona destino, si la notificación apunta a una.
  final String? personId;

  /// Nombre de la persona destino, si la notificación apunta a una.
  final String? personName;

  /// Clave de estilo heredada de la plantilla.
  String get styleKey => template.styleKey;

  @override
  List<Object?> get props => [template, text, personId, personName];
}

/// Plantillas de notificación del prototipo, portadas **verbatim** y en orden
/// (`NOTIFICATION_TEMPLATES`, `src/notifications.ts`). No se afirma nada sobre
/// uso medido, conversaciones pasadas ni otras personas: es una simulación.
const List<NotificationTemplate> notificationTemplates = [
  NotificationTemplate(
    id: 'reminder-directions',
    type: NotificationType.reminder,
    text:
        'Los vínculos se alimentan en las dos direcciones. Hoy puedes escribirle a alguien o dejar que alguien te acompañe.',
    showType: false,
    action: NotificationAction.relationships,
  ),
  NotificationTemplate(
    id: 'reminder-return',
    type: NotificationType.reminder,
    text:
        'A todos se nos pasan días. Retomar puede ser tan simple como un mensaje corto.',
    showType: true,
    action: NotificationAction.relationships,
  ),
  NotificationTemplate(
    id: 'questions-animals',
    type: NotificationType.questions,
    text:
        'Si los animales pudieran hablar, ¿cuál sería el más bocón? Pregúntale a XXX qué piensa.',
    showType: false,
    action: NotificationAction.questions,
    question: 'Si los animales pudieran hablar, ¿cuál sería el más bocón?',
  ),
  NotificationTemplate(
    id: 'questions-movie',
    type: NotificationType.questions,
    text:
        '¿Qué película te marcó? Cuéntale a XXX por qué y pregúntale cuál es la suya.',
    showType: true,
    action: NotificationAction.questions,
    question: '¿Qué película te marcó y por qué?',
  ),
  NotificationTemplate(
    id: 'questions-closeness',
    type: NotificationType.questions,
    subtype: notificationSubtypeCloseness,
    text: '¿Qué es lo que más valoras en una amistad?',
    showType: true,
    action: NotificationAction.questions,
    question: '¿Qué es lo que más valoras en una amistad?',
  ),
  NotificationTemplate(
    id: 'intimate-write',
    type: NotificationType.intimate,
    text:
        '¿Le escribimos a XXX algo cercano? Te ayudo a armarlo en un minuto.',
    showType: false,
    action: NotificationAction.message,
  ),
  NotificationTemplate(
    id: 'intimate-weave',
    type: NotificationType.intimate,
    text:
        'Tejer cercanía con XXX puede empezar con un mensaje. ¿Lo armamos juntos?',
    showType: true,
    action: NotificationAction.message,
  ),
  NotificationTemplate(
    id: 'social-hello',
    type: NotificationType.social,
    text: '¿Y si saludas a XXX? Un “hola, ¿cómo vas?” basta.',
    showType: false,
    action: NotificationAction.contact,
  ),
  NotificationTemplate(
    id: 'social-check',
    type: NotificationType.social,
    text: '¿Y si le preguntas a XXX cómo está?',
    showType: true,
    action: NotificationAction.contact,
  ),
  NotificationTemplate(
    id: 'meeting-invite',
    type: NotificationType.meeting,
    text:
        '¿Y si invitas a XXX a hacer algo esta semana? Te ayudo a escribir la invitación.',
    showType: true,
    action: NotificationAction.meeting,
  ),
  NotificationTemplate(
    id: 'meeting-see',
    type: NotificationType.meeting,
    text: '¿Qué tal invitar a XXX a que se vean esta semana? Un rato basta.',
    showType: false,
    action: NotificationAction.meeting,
  ),
];