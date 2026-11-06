import '../journey/journey_state.dart';
import '../journey/network_person.dart';
import '../journey/person_status.dart';

/// Dominio de construcción/generación del mapa de red (tarea 3.11), portado
/// verbatim del prototipo (`src/screens/network.tsx`: `NAME_QUESTIONS`,
/// `RELATIONSHIP_QUESTIONS`, `SCALE`, `generateResults`). Dart puro.
///
/// Es la etapa que **construye** las personas y sus respuestas; distinta de la
/// entrada mínima al mapa (2.15) y del dominio de métricas (3.8), que consume
/// estos datos. El cómputo de resultados es una Funcion_Simulada.

/// Preguntas del generador de nombres, verbatim y en orden (`NAME_QUESTIONS`).
const List<String> nameGeneratorQuestions = [
  'Si salieras de la ciudad, ¿a quién o a quiénes les pedirías que cuidaran tu casa mientras estás fuera?',
  '¿Con quién o con quiénes te reunirías para hablar de pasatiempos o intereses que tienen en común?',
  'Cuando algo personal te preocupa, ¿con quién o con quiénes hablas de eso?',
  '¿La opinión de quién o quiénes consideras seriamente al tomar decisiones importantes?',
  'Si necesitaras reunir una suma grande de dinero, ¿a quién o a quiénes les pedirías ayuda?',
  'Cuando quieres sentirte escuchado o acompañado, ¿a quién o a quiénes se lo contarías?',
  'Si te sintieras enfermo o tuvieras una emergencia médica, ¿a quién buscarías para que te ayudara?',
  '¿Quién o quiénes te permiten sentir que perteneces a una comunidad, equipo o grupo?',
  '¿Hay alguien importante para ti que todavía no aparezca en esta lista?',
  '¿A cuáles de las personas de esta lista sientes especialmente cercanas?',
];

/// Ítems de la evaluación de la relación, verbatim y en orden
/// (`RELATIONSHIP_QUESTIONS`). Son 18 ítems (preguntas 2 a 19 del dominio de
/// métricas).
const List<String> relationshipQuestions = [
  '¿Qué tan significativa es esta relación para tu vida?',
  '¿Con qué frecuencia hablan o se ven?',
  '¿Con qué frecuencia esta persona te escucha cuando le expresas algo?',
  '¿Con qué frecuencia esta persona se interesa por lo que estás sintiendo?',
  '¿Con qué frecuencia puedes contar con esta persona para distraerte de tus preocupaciones cuando estás bajo estrés?',
  '¿Qué tan frecuentemente tienes discusiones o peleas con esta persona?',
  '¿Qué tan satisfecho o satisfecha te sientes en esta relación?',
  '¿Con qué frecuencia sentiste que esta persona fue hostil o te trató mal?',
  '¿Con qué frecuencia sentiste que esta persona fue cálida o cariñosa contigo?',
  '¿La mayor parte del tiempo la relación se caracteriza por compañía y amor?',
  '¿La mayor parte del tiempo la relación se caracteriza por exigencia, frustración, desconsideración o competencia?',
  '¿Sientes que esta persona te ha apoyado?',
  '¿Con qué frecuencia te sientes entendido o entendida por esta persona?',
  '¿La mayor parte del tiempo la relación se caracteriza por compañía y cuidado?',
  '¿La mayor parte del tiempo la relación se caracteriza por frustración?',
  '¿Qué proporción del tiempo esta relación es una fuente significativa de estrés para ti?',
  '¿Con qué frecuencia esta relación interfiere con el apoyo que recibes de otras personas?',
  '¿Con qué frecuencia esta relación te genera sentimientos encontrados?',
];

/// Escala de respuesta de 6 opciones, verbatim (`SCALE`). El índice 0..5 mapea a
/// los valores 1..6 que consume el dominio de métricas (`pomp`).
const List<String> relationshipScale = [
  'Nada',
  'Un poco',
  'A veces',
  'Moderadamente',
  'Mucho',
  'Extremadamente',
];

/// Número de ítems de la evaluación de la relación.
const int relationshipItemCount = 18;

/// `true` si [person] tiene su evaluación completa: `complete`, con los 18 ítems
/// respondidos (ninguno nulo). Alimenta `generateResults` y el dominio de
/// métricas (que excluye a quienes no lo cumplen).
bool isPersonAssessed(NetworkPerson person) {
  if (person.status != PersonStatus.complete) return false;
  if (person.answers.length < relationshipItemCount) return false;
  return person.answers.every((value) => value != null);
}

/// Personas con evaluación completa dentro de [state].
List<NetworkPerson> assessedPeople(JourneyState state) =>
    state.people.where(isPersonAssessed).toList();

/// Genera el mapa de red a partir de las respuestas construidas (portado de
/// `generateResults`): si hay al menos una persona evaluada, marca el recorrido
/// como `mapStarted`/`mapGenerated`. Si no hay ninguna persona evaluada, el
/// estado no cambia (no se puede generar un mapa vacío). El cómputo real de
/// métricas lo hace el dominio de métricas sobre estas personas (3.8).
JourneyState generateResults(JourneyState state) {
  if (assessedPeople(state).isEmpty) return state;
  return state.copyWith(mapStarted: true, mapGenerated: true);
}

/// Aplica la respuesta [value] (1..6) al ítem [index] (0..17) de [person],
/// devolviendo una copia con el avance. Marca la persona como `complete` cuando
/// los 18 ítems quedan respondidos; en otro caso, `inProgress`.
NetworkPerson answerRelationshipItem(
  NetworkPerson person,
  int index,
  int value,
) {
  final answers = List<int?>.from(person.answers);
  // Asegura longitud de 18, rellenando con null los faltantes.
  while (answers.length < relationshipItemCount) {
    answers.add(null);
  }
  if (index < 0 || index >= relationshipItemCount) return person;
  answers[index] = value;
  final complete = answers.length >= relationshipItemCount &&
      answers.take(relationshipItemCount).every((v) => v != null);
  return person.copyWith(
    answers: answers,
    status: complete ? PersonStatus.complete : PersonStatus.inProgress,
  );
}