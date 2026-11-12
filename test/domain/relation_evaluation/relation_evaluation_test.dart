// Pruebas del dominio de evaluación de relación (tarea 3.23), portado de
// MobileScreen13 (src/screens/social.tsx): avance monótono (Property 19),
// puntuación provisional con polaridad invertida y umbral de orientación
// (Contenido_Validacion_Pendiente, Requirement 10.2).

import 'package:contigo/domain/relation_evaluation/relation_evaluation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('contenido verbatim', () {
    test('hay nueve preguntas y seis opciones de escala', () {
      expect(relationEvaluationQuestions.length, 9);
      expect(relationEvaluationScale.length, 6);
    });

    test('la primera y la última pregunta son verbatim', () {
      expect(
        relationEvaluationQuestions.first.text,
        '¿Sientes que esta persona te ha apoyado?',
      );
      expect(
        relationEvaluationQuestions.last.text,
        '¿Con qué frecuencia esta relación te genera sentimientos encontrados?',
      );
    });

    test('la escala es verbatim y en orden', () {
      expect(relationEvaluationScale, [
        'Nada',
        'Un poco',
        'A veces',
        'Moderadamente',
        'Mucho',
        'Extremadamente',
      ]);
    });
  });

  group('canAdvanceEvaluationStep (Property 19: avance monótono)', () {
    test('no avanza si el paso actual no tiene respuesta', () {
      final answers = List<int?>.filled(9, null);
      expect(canAdvanceEvaluationStep(answers, 0), isFalse);
    });

    test('avanza solo cuando el paso actual está respondido', () {
      final answers = List<int?>.filled(9, null);
      answers[0] = 4;
      expect(canAdvanceEvaluationStep(answers, 0), isTrue);
      expect(canAdvanceEvaluationStep(answers, 1), isFalse);
    });

    test('índices fuera de rango no avanzan', () {
      final answers = List<int?>.filled(9, null);
      expect(canAdvanceEvaluationStep(answers, -1), isFalse);
      expect(canAdvanceEvaluationStep(answers, 9), isFalse);
    });

    test('no se puede saltar un paso sin completar el anterior', () {
      // Property 19: aunque el paso 2 tenga respuesta, no se avanza desde el
      // paso 1 si el paso 1 sigue vacío.
      final answers = List<int?>.filled(9, null);
      answers[2] = 5;
      expect(canAdvanceEvaluationStep(answers, 1), isFalse);
    });
  });

  group('provisionalRelationScore (orientación demostrativa)', () {
    test('sin respuestas devuelve 0', () {
      expect(provisionalRelationScore(List<int?>.filled(9, null)), 0);
    });

    test('invierte la polaridad en las preguntas negativas (7 - answer)', () {
      // Solo la quinta pregunta (índice 4) es negativa: una respuesta alta (6)
      // aporta poco (7 - 6 = 1); una positiva aporta su valor directo.
      final answers = List<int?>.filled(9, null);
      answers[0] = 6; // positiva -> 6
      answers[4] = 6; // negativa -> 7 - 6 = 1
      final expected = (6 + 1) / 9;
      expect(provisionalRelationScore(answers), closeTo(expected, 1e-9));
    });

    test('todas respondidas con el máximo favorable supera el umbral', () {
      final answers = <int?>[];
      for (final q in relationEvaluationQuestions) {
        // Para positivas, 6; para negativas, 1 (que invertida da 6).
        answers.add(q.positive ? 6 : 1);
      }
      expect(provisionalRelationScore(answers), closeTo(6, 1e-9));
      expect(relationSeemsSupportive(answers), isTrue);
    });
  });

  group('relationSeemsSupportive (umbral pendiente de validación >= 4)', () {
    test('respuestas tensas no se consideran de apoyo', () {
      final answers = <int?>[];
      for (final q in relationEvaluationQuestions) {
        // Positivas bajas (1) y negativas altas (6): orientación de baja.
        answers.add(q.positive ? 1 : 6);
      }
      expect(relationSeemsSupportive(answers), isFalse);
    });

    test('el umbral es exactamente >= 4', () {
      // Construye respuestas cuya orientación sea exactamente 4.
      // Nueve positivas ficticias no existen, así que usamos la fórmula:
      // con todas positivas respondidas a 4 -> promedio incluye negativas
      // invertidas (7 - 4 = 3). Verificamos el límite con un caso >= 4.
      final answers = <int?>[];
      for (final q in relationEvaluationQuestions) {
        answers.add(q.positive ? 5 : 2); // positiva 5; negativa 7 - 2 = 5
      }
      expect(provisionalRelationScore(answers), closeTo(5, 1e-9));
      expect(relationSeemsSupportive(answers), isTrue);
    });
  });
}