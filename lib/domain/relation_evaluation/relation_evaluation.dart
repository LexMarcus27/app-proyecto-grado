/// Dominio de la evaluación de relación (tarea 3.23), portado del prototipo
/// (`MobileScreen13` en `src/screens/social.tsx`). Dart puro.
///
/// El recorrido avanza por los pasos **en orden** y **solo cuando el paso
/// actual está completo** (avance monótono, Property 19). La puntuación y los
/// umbrales son **Contenido_Validacion_Pendiente** (orientación demostrativa,
/// Requirement 10.2): no constituyen un resultado clínico definitivo.
library;

/// Una pregunta de la evaluación de relación, con su polaridad (si una
/// puntuación alta cuenta a favor o en contra del apoyo).
class RelationEvaluationQuestion {
  const RelationEvaluationQuestion({required this.text, required this.positive});
  final String text;

  /// `true` si una puntuación alta es "positiva" (suma); `false` si se invierte
  /// (`7 - answer`) al calcular la orientación.
  final bool positive;
}

/// Preguntas de la evaluación de relación, verbatim y en orden
/// (`relationshipQuestions` en `social.tsx`).
const List<RelationEvaluationQuestion> relationEvaluationQuestions = [
  RelationEvaluationQuestion(
    text: '¿Sientes que esta persona te ha apoyado?',
    positive: true,
  ),
  RelationEvaluationQuestion(
    text: '¿Te sientes unido/a a esta persona?',
    positive: true,
  ),
  RelationEvaluationQuestion(
    text: '¿Te has sentido entendido/a por esta persona?',
    positive: true,
  ),
  RelationEvaluationQuestion(
    text:
        '¿La relación con esta persona se caracteriza por compañía y afecto?',
    positive: true,
  ),
  RelationEvaluationQuestion(
    text:
        '¿La relación se caracteriza por exigencia, frustración, desconsideración o competencia?',
    positive: false,
  ),
  RelationEvaluationQuestion(
    text:
        '¿Qué tanto esta relación es una fuente significativa de estrés para ti?',
    positive: false,
  ),
  RelationEvaluationQuestion(
    text: '¿Con qué frecuencia tienes contacto con esta persona?',
    positive: true,
  ),
  RelationEvaluationQuestion(
    text:
        '¿En qué grado esta relación interfiere con el apoyo que recibes de otras personas?',
    positive: false,
  ),
  RelationEvaluationQuestion(
    text:
        '¿Con qué frecuencia esta relación te genera sentimientos encontrados?',
    positive: false,
  ),
];

/// Escala de respuesta (6 opciones), verbatim (`relationshipScale`).
const List<String> relationEvaluationScale = [
  'Nada',
  'Un poco',
  'A veces',
  'Moderadamente',
  'Mucho',
  'Extremadamente',
];

/// `true` si, dadas las [answers] hasta ahora, el paso [index] puede avanzar:
/// solo cuando el paso actual tiene respuesta. Garantiza el avance monótono
/// (no se salta un paso sin completarlo, Property 19).
bool canAdvanceEvaluationStep(List<int?> answers, int index) {
  if (index < 0 || index >= answers.length) return false;
  return answers[index] != null;
}

/// Puntuación **provisional** de orientación (promedio con polaridad invertida
/// en las preguntas negativas), portada de `provisionalScore`. Es orientación
/// demostrativa: el umbral y la puntuación final están **pendientes de
/// validación** (Requirement 10.2). Devuelve 0 si no hay ninguna respuesta.
double provisionalRelationScore(List<int?> answers) {
  if (answers.isEmpty) return 0;
  var total = 0.0;
  for (var i = 0; i < relationEvaluationQuestions.length && i < answers.length; i++) {
    final answer = answers[i];
    if (answer == null) continue;
    total += relationEvaluationQuestions[i].positive ? answer : 7 - answer;
  }
  return total / relationEvaluationQuestions.length;
}

/// `true` si la orientación **demostrativa** sugiere una relación de apoyo
/// (`provisionalScore >= 4`). Umbral pendiente de validación (Requirement 10.2).
bool relationSeemsSupportive(List<int?> answers) {
  return provisionalRelationScore(answers) >= 4;
}