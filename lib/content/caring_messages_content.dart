/// Contenido educativo de los mensajes de cuidado (segundo relato del cuidador),
/// portado **verbatim** del prototipo (`CARING_CONTENT`, `src/caring-messages.ts`).
///
/// Es Contenido_Clinico suministrado: se preserva carácter por carácter, sin
/// alterar, truncar ni reordenar (Requirement 2.5, 8.3). Las imágenes de la
/// sección de orígenes se referencian por su nombre de archivo del prototipo.
library;

/// Un bloque de "características" con título y párrafos.
class CaringCharacteristic {
  const CaringCharacteristic({required this.title, required this.paragraphs});
  final String title;
  final List<String> paragraphs;
}

/// Un grupo de ejemplos de mensajes con su título.
class CaringExampleGroup {
  const CaringExampleGroup({required this.title, required this.messages});
  final String title;
  final List<String> messages;
}

/// Una entrada de la sección de orígenes (historia de Motto).
class CaringOrigin {
  const CaringOrigin({
    required this.title,
    required this.image,
    required this.alt,
    required this.paragraphs,
  });
  final String title;

  /// Nombre de archivo de la imagen del prototipo (verbatim).
  final String image;
  final String alt;
  final List<String> paragraphs;
}

/// Contenido educativo de los mensajes de cuidado, verbatim.
abstract final class CaringContent {
  static const List<String> videoScript = [
    'Imagina que estás en medio del océano. Llevas un montón de tiempo ahí y ya no te quedan fuerzas. Has tomado agua, has pataleado buscando algo de qué agarrarte, un respiro, una orilla. De tanto luchar por mantener la cabeza fuera del agua, empiezas a olvidar cómo se siente pisar tierra firme. Ya no es solo que no puedas nadar hasta la orilla: a veces ni te acuerdas de que existe.',
    'Los mensajes de cuidado son como un flotador que alguien te lanza justo ahí: algo firme de lo que agarrarte.',
    'Un flotador no te lleva a la orilla, pero sí puede ayudarte a mantenerte a flote un rato mientras recuperas el aire. Y tú decides si te apoyas en él, cuándo y por cuánto tiempo. Tal vez nunca te ofrecieron algo que te ayudara a sostenerte, tal vez nadie te dijo que se puede aguantar a flote, o tal vez se te olvidó que ahogarse no es inevitable. Estos mensajes son para cualquier persona que esté pasando por un momento muy duro. Cada uno es un recordatorio de que la orilla existe y de que no estás solx en el agua.',
  ];

  static const List<String> definition = [
    '¿Qué son? Son mensajes cortos que te llegan de vez en cuando, con cariño y sin pedirte nada a cambio. Te dicen que hay gente pensando en ti, que tienes un lugar en el mundo y que hay esperanza. No te van a decir "deberías volver a terapia" ni te van a decir lo que deberías o no deberías sentir. Solo están ahí, flotando a tu lado.',
    'Son mensajes de cuidado y apoyo que te ayudan a sentirte conectado/a con otras personas. Te recuerdan que hay esperanza y que perteneces, que tienes un lugar en el mundo.',
  ];

  static const String notAdvice =
      'No son consejos. No te dicen qué hacer ni cómo deberías sentirte.';

  static const List<CaringCharacteristic> characteristics = [
    CaringCharacteristic(
      title: 'No piden algo a cambio',
      paragraphs: [
        'No mensajes de "cuéntame cómo estás" ni "respóndeme".',
        'Nada de preguntas ni tareas.',
        'No hace falta que respondan.',
        'Así los mensajes no abruman y solo buscan acompañar y conectar.',
      ],
    ),
    CaringCharacteristic(
      title: 'Pertenencia',
      paragraphs: [
        'Buscan que sientas que tienes un lugar y que hay gente cerca. Son un recordatorio de que nadie está solo en esto y de que se puede recorrer el camino en compañía.',
      ],
    ),
    CaringCharacteristic(
      title: 'Son cortos',
      paragraphs: [
        'Se leen en un segundo y se quedan contigo. Fáciles de recordar y de volver a leer cuando quieras. Menos palabras, más directo, más efecto.',
      ],
    ),
    CaringCharacteristic(
      title: 'Son constantes',
      paragraphs: [
        'Parte de la magia es que no llegan una sola vez. Son un flotador que vuelve a aparecer y te recuerda que hay conexión. Lo ideal son 8 mensajes o más. La conexión se teje poco a poco, y tejer una relación lleva tiempo.',
        'Un mensaje, y otro, y otro.',
      ],
    ),
  ];

  static const List<CaringExampleGroup> examples = [
    CaringExampleGroup(
      title: 'Mostrar cuidado',
      messages: [
        'Estoy pensando en ti.',
        'Hoy me acordé de ti y quise decírtelo.',
      ],
    ),
    CaringExampleGroup(
      title: 'Reconocer lo difícil',
      messages: [
        'Imagino que estos días no han sido fáciles.',
        'Se nota que estás cargando con mucho.',
        'Está bien sentirse como te sientes ahora.',
      ],
    ),
    CaringExampleGroup(
      title: 'Celebrar los avances',
      messages: [
        'Te mando buenas vibras y muchos deseos de que todo vaya bien.',
        'Me alegra que sigas adelante. Ojalá todo siga mejorando.',
      ],
    ),
    CaringExampleGroup(
      title: 'Dar ánimo',
      messages: [
        'El mundo es más bonito porque estás en él. No lo olvides.',
        'Me alegra que existas.',
        'Gracias por ser parte de mi vida.',
      ],
    ),
    CaringExampleGroup(
      title: 'Recordar la relación',
      messages: [
        'Me acordé de (un recuerdo que compartieron). Me hizo sonreír.',
        'Vi (algo) que me recordó a ti.',
        'Ojalá podamos vernos pronto.',
        'Me haces falta por aquí. Te quiero.',
        'Estaba pensando en lo mucho que admiro (una fortaleza).',
      ],
    ),
  ];

  static const List<String> preparation = [
    'Respira profundo, llevando el aire hacia la barriga.',
    'Suelta los hombros.',
    'Piensa en esa persona con la que estás conectando',
  ];

  static const String avatarLine =
      'Unas pocas palabras tuyas pueden ser un hilo fuerte en un día difícil.';

  static const List<String> intentions = [
    'Hacer que el cuidado se sienta como algo que se construye entre ambas personas.',
    'Reducir el aislamiento y la soledad.',
    'Recordar sus habilidades.',
    'Darle esperanza.',
  ];

  static const List<String> whatTheyShow = [
    'Ves su fortaleza y sus recursos personales.',
    'Te agrada esa persona y esperas volver a compartir con ella.',
    'Recuerdas lo que te ha contado.',
    'Te importa, porque hay algo real en la relación.',
  ];

  static const List<String> questions = [
    '¿Qué fortaleza has visto en esa persona o has oído de otras?',
    '¿Qué recuerdo de lxs dos te saca una sonrisa o te hace sentir algo de calidez, aunque sea un poquito?',
    '¿Qué te dijo alguna vez que se te quedó grabado?',
    '¿Qué habilidad suya te ha servido a ti o a otras personas?',
    '¿Qué es lo que más te gusta de estar con ella?',
    '¿Qué te gustaría volver a hacer o compartir con ella?',
    '¿Qué cosa difícil ha enfrentado que te haya hecho admirarla?',
    '¿Qué te alegra de que esté en tu vida?',
  ];

  static const String honesty =
      'Recuerda: no escribas nada que no sientas o que no creas que es verdad. Un mensaje sencillo y sincero vale más que uno perfecto.';

  static const String writingInvitation =
      '¿Te animas a escribirle un mensaje de cuidado? Vamos a redactarlo aquí abajo.';

  static const List<CaringOrigin> origins = [
    CaringOrigin(
      title: 'Cómo empezó todo',
      image: 'historia-bastogne.png',
      alt:
          'El avatar acompaña a soldados que reciben suministros en Bastogne.',
      paragraphs: [
        'Diciembre de 1944, Segunda Guerra Mundial. Jerome Motto era un joven teniente de 23 años, a cargo de una compañía de camiones del ejército. Llevaba días atrapado con sus compañeros en una casa de campo en Bastogne, Bélgica, rodeado por fuerzas enemigas. Lo que los mantenía con vida eran los aviones que, de vez en cuando, les lanzaban comida, ropa y medicinas en paracaídas.',
      ],
    ),
    CaringOrigin(
      title: 'Cartas que acompañaban',
      image: 'historia-cartas.jpeg',
      alt: 'Un soldado lee una carta y recuerda a la persona que le escribe.',
      paragraphs: [
        'En medio de todo eso, lo que más consuelo le daba eran las cartas de una mujer a la que casi no conocía. Habían salido unas seis veces durante su entrenamiento en Arkansas, y cuando él partió a la guerra, ella empezó a escribirle. Las cartas seguían llegando, contestara él o no. No eran cartas de amor: hablaban de cosas cotidianas, como lo que hizo en el día, el frío que empezaba a sentirse o las canciones de moda. Pero alguien que escribe con tanta constancia, pensaba él, tiene que estar de verdad interesado en ti.',
      ],
    ),
    CaringOrigin(
      title: 'De las cartas a la ciencia',
      image: 'historia-conexion.png',
      alt: 'Cartas conectan a dos personas, acompañadas por el avatar.',
      paragraphs: [
        'Años después, ya como psiquiatra en San Francisco, Motto notó algo: muchas personas que salían del hospital tras una crisis suicida rechazaban el tratamiento y quedaban sin ningún vínculo con el sistema de salud, justo cuando más riesgo tenían. Recordó las cartas de la guerra y se hizo una pregunta simple: si no quieren venir, ¿podemos al menos mantener el contacto?',
        'A finales de los años 60 diseñó un estudio. Las personas que rechazaban el tratamiento se dividieron al azar en dos grupos. A ambos les hicieron una entrevista a fondo, pero solo un grupo recibió cartas breves y cálidas, primero cada mes y luego cada vez más espaciadas, hasta llegar a una cada tres meses. Decían algo como: "Han pasado unos meses desde que estuviste en el hospital y esperamos que estés bien. Si quieres escribirnos, nos daría gusto saber de ti". No pedían nada, no daban consejos y no exigían respuesta. El otro grupo no recibió ninguna.',
        'En los primeros años hubo menos muertes por suicidio en el grupo que recibió cartas. Motto y Bostrom publicaron los resultados en 2001.',
        'Desde entonces, la idea se ha adaptado a postales, correos, mensajes de texto y llamadas, y se ha probado con población militar, veteranos y otros grupos. Lo esencial sigue igual: mensajes breves, sin exigencias y constantes, un mensaje, y otro, y otro.',
      ],
    ),
  ];
}