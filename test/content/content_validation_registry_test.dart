// Pruebas del registro de Estado_Validacion_Contenido por tipo de contenido
// (tarea 1.6). Dart puro, ejecutable con `dart test`.
import 'package:contigo/content/content.dart';
import 'package:test/test.dart';

void main() {
  group('ContentValidationRegistry.defaults', () {
    final registry = ContentValidationRegistry.defaults;

    test('registra una entrada por cada tipo de contenido (Req 2.4)', () {
      for (final type in ClinicalContentType.values) {
        expect(
          registry.metadataFor(type),
          isNotNull,
          reason: 'Falta la entrada de validación para $type',
        );
      }
      expect(registry.entries.length, ClinicalContentType.values.length);
    });

    test('el banco EMA es daily-nine-v2 suministrado tras revisión del '
        'evaluador (Req 2.5)', () {
      expect(ContentValidationRegistry.emaVersion, 'daily-nine-v2');
      final ema = registry.metadataFor(ClinicalContentType.emaBank)!;
      expect(ema.status, ContentValidationStatus.suppliedAfterEvaluatorReview);
      expect(ema.sourceLabel, contains('daily-nine-v2'));
      expect(ema.isValidationPending, isFalse);
    });

    test('los textos narrativos suministrados son verbatim (Req 2.5)', () {
      final story = registry.metadataFor(
        ClinicalContentType.safetyPlanStory,
      )!;
      final guide = registry.metadataFor(
        ClinicalContentType.caringMessagesGuide,
      )!;
      expect(story.status, ContentValidationStatus.suppliedVerbatim);
      expect(guide.status, ContentValidationStatus.suppliedVerbatim);
    });

    test('umbrales y cortes quedan como Contenido_Validacion_Pendiente '
        '(Req 2.6, 9.6, 10.2)', () {
      final thresholds = registry.metadataFor(
        ClinicalContentType.relationEvaluationThresholds,
      )!;
      final cutoffs = registry.metadataFor(
        ClinicalContentType.networkMetricsCutoffs,
      )!;
      expect(thresholds.isValidationPending, isTrue);
      expect(cutoffs.isValidationPending, isTrue);

      final pendingTypes =
          registry.pendingEntries.map((e) => e.contentType).toSet();
      expect(pendingTypes, {
        ClinicalContentType.relationEvaluationThresholds,
        ClinicalContentType.networkMetricsCutoffs,
      });
    });

    test('el contenido verbatim no se marca como pendiente', () {
      final verbatimTypes = {
        ClinicalContentType.emaBank,
        ClinicalContentType.safetyPlanStory,
        ClinicalContentType.caringMessagesGuide,
        ClinicalContentType.crisisModeText,
      };
      for (final type in verbatimTypes) {
        expect(
          registry.metadataFor(type)!.isValidationPending,
          isFalse,
          reason: '$type no debe marcarse como pendiente',
        );
      }
    });
  });
}
