import 'app_media.dart';

/// Página del relato narrativo del plan de seguridad ("Las crisis también
/// pasan"), portada verbatim del prototipo (`SafetyPlanStoryPage`,
/// `src/safety-plan-story.ts`).
///
/// El texto se preserva carácter por carácter y las páginas conservan su orden
/// e identificadores (Requirement 7.6): no se altera, trunca ni reordena.
class SafetyPlanStoryPage {
  const SafetyPlanStoryPage({
    required this.id,
    required this.title,
    this.video,
    this.paragraphs = const [],
    this.listHeading,
    this.items,
    this.closing,
  });

  /// Identificador/orden de la página.
  final int id;

  /// Título de la página (verbatim).
  final String title;

  /// Ruta del video asociado a la página, si lo hay (de [AppMedia]).
  final String? video;

  /// Párrafos de la página, verbatim y en orden.
  final List<String> paragraphs;

  /// Encabezado opcional de la lista.
  final String? listHeading;

  /// Ítems de lista, verbatim y en orden.
  final List<String>? items;

  /// Texto de cierre opcional.
  final String? closing;
}

/// Título del relato del plan de seguridad, verbatim
/// (`SAFETY_PLAN_STORY_TITLE`).
const String safetyPlanStoryTitle = 'Las crisis también pasan';

/// Relato del plan de seguridad (solo el relato del PCS), portado verbatim del
/// prototipo (`SAFETY_PLAN_STORY`). El contenido narrativo suministrado se
/// preserva sin alterar ni reordenar, incluidos sus videos; no son nuevas
/// reglas clínicas (Requirement 2.5, 7.6).
const List<SafetyPlanStoryPage> safetyPlanStory = [
  SafetyPlanStoryPage(
    id: 1,
    title: 'Conoce el plan para desenredar',
    video: AppMedia.safetyPlanStoryVideo1,
    paragraphs: [],
  ),
  SafetyPlanStoryPage(
    id: 2,
    title: 'Cuando aparece una crisis',
    paragraphs: [
      'La ideación suicida y las crisis emocionales son como una curva que sube y baja. Lo que buscamos es que, cuando la crisis llegue a su punto más alto, la persona no actúe sobre el impulso de hacerse daño. Así se abre espacio para que desarrolle otras estrategias, afronte el malestar de otra manera y la situación pueda cambiar.',
      'Durante una crisis, las habilidades para resolver problemas y afrontar las dificultades se reducen. No es que no las tengas: es que, con el malestar al máximo, cuesta más acceder a ellas.',
    ],
  ),
  SafetyPlanStoryPage(
    id: 3,
    title: 'Otras formas de afrontar el malestar',
    paragraphs: [
      'Recuerda que la conducta suicida puede dar un alivio breve, pero no resuelve lo que duele. Además, deja menos espacio para otras estrategias más efectivas y, a veces, empeora el problema que originó el malestar.',
      'Esto no significa que dejemos de sentir malestar. Significa que podemos aprender a afrontarlo de otra manera, para que la curva baje y podamos lidiar con la situación sin hacernos daño.',
    ],
  ),
  SafetyPlanStoryPage(
    id: 4,
    title: 'Prepararnos para los momentos difíciles',
    video: AppMedia.safetyPlanStoryVideo2,
    paragraphs: [],
  ),
  SafetyPlanStoryPage(
    id: 5,
    title: 'Un plan para los momentos de malestar',
    paragraphs: [
      'Hemos visto que se pueden aprender formas más efectivas de actuar en una crisis. También vimos que las habilidades suelen estar ahí, pero que cuesta recurrir a ellas cuando el malestar es muy intenso. Por eso es igual de importante aprender a reconocer cómo empiezan las crisis. No siempre es fácil darse cuenta de qué las desencadena.',
      'Una forma de prepararnos es construir un plan para los momentos de malestar: un plan de seguridad, o plan para desenredar. En él aprendemos a:',
    ],
    items: [
      'Identificar cuándo aparece la crisis.',
      'Reconocer qué estrategias podemos usar.',
      'Saber en quién apoyarnos y cómo mantenernos en contacto con esas personas.',
      'Alejarnos de lo que aumenta el riesgo.',
      'Tener a la mano contactos profesionales y de emergencia.',
      'Recordar nuestras razones para mantenernos a salvo.',
    ],
  ),
  SafetyPlanStoryPage(
    id: 6,
    title: 'El plan para desenredar',
    paragraphs: [
      'Tener este plan nos hace sentir más capaces de afrontar los momentos en que aparece un nudo en el tejido.',
    ],
    listHeading: '¿Por qué sirve el plan para desenredar?',
    items: [
      'El malestar sube y baja. Si logramos tolerarlo, podemos actuar de forma más efectiva.',
      'Durante una crisis, las habilidades para resolver problemas y afrontar las dificultades se reducen.',
      'Puede ser difícil identificar cuándo empieza una crisis.',
      'Tener un plan nos ayuda a actuar de forma más efectiva ante el malestar, y usarlo aumenta la confianza en nosotros mismos para enfrentarlo.',
    ],
    closing:
        'Aquí podemos construir el plan para desenredar. Siempre lo tendremos a la mano.',
  ),
  SafetyPlanStoryPage(
    id: 7,
    title: 'Tu plan puede seguir creciendo',
    paragraphs: [
      'Aquí puedes construir tu plan. Encontrarás algunas estrategias que pueden ayudar y también un espacio para que identifiques y escribas lo que te sirve a ti.',
      'No es un plan final. Como cualquier tejido, se va ajustando con el tiempo: puedes volver a él, cambiarlo y seguir tejiéndolo.',
    ],
  ),
];