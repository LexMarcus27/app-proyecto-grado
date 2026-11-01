// Pruebas del mecanismo de carga de Contenido_Clinico verbatim (tarea 1.6).
// Dart puro, ejecutable con `dart test`.
import 'package:contigo/content/content.dart';
import 'package:test/test.dart';

ClinicalContentFragment _fragment(String key, String body) =>
    ClinicalContentFragment(
      contentType: ClinicalContentType.safetyPlanStory,
      key: key,
      body: body,
    );

void main() {
  group('ClinicalContentLoader', () {
    test('lanza StateError si no hay fuente registrada para el tipo', () {
      final loader = ClinicalContentLoader();
      expect(loader.hasSource(ClinicalContentType.emaBank), isFalse);
      expect(
        () => loader.load(ClinicalContentType.emaBank),
        throwsStateError,
      );
    });

    test('carga los fragmentos verbatim y en el mismo orden (Req 2.1)', () {
      // Texto con mayúsculas, acentos, saltos de línea y espacios al inicio/fin:
      // el cargador no debe alterarlo, truncarlo ni reordenarlo.
      final page1 = _fragment('1', '  Las crisis también PASAN.\nLínea dos.  ');
      final page2 = _fragment('2', 'Respira.\n\nEstás a salvo.');
      final page3 = _fragment('3', 'Ñandú — fin del relato.');

      final loader = ClinicalContentLoader();
      loader.registerSource(
        ClinicalContentType.safetyPlanStory,
        InMemoryClinicalContentSource([page1, page2, page3]),
      );

      final loaded = loader.load(ClinicalContentType.safetyPlanStory);

      // Mismo número de fragmentos, mismo orden y cuerpo idéntico carácter a
      // carácter.
      expect(loaded.map((f) => f.key).toList(), ['1', '2', '3']);
      expect(loaded[0].body, '  Las crisis también PASAN.\nLínea dos.  ');
      expect(loaded[1].body, 'Respira.\n\nEstás a salvo.');
      expect(loaded[2].body, 'Ñandú — fin del relato.');
    });

    test('preserva fragmentos vacíos y no colapsa espacios', () {
      final loader = ClinicalContentLoader();
      loader.registerSource(
        ClinicalContentType.crisisModeText,
        InMemoryClinicalContentSource([
          ClinicalContentFragment(
            contentType: ClinicalContentType.crisisModeText,
            key: 'a',
            body: '',
          ),
          ClinicalContentFragment(
            contentType: ClinicalContentType.crisisModeText,
            key: 'b',
            body: '   ',
          ),
        ]),
      );

      final loaded = loader.load(ClinicalContentType.crisisModeText);
      expect(loaded[0].body, '');
      expect(loaded[1].body, '   ');
    });

    test('la lista devuelta es no modificable (no se reordena desde fuera)',
        () {
      final loader = ClinicalContentLoader();
      loader.registerSource(
        ClinicalContentType.safetyPlanStory,
        InMemoryClinicalContentSource([_fragment('1', 'uno')]),
      );
      final loaded = loader.load(ClinicalContentType.safetyPlanStory);
      expect(
        () => loaded.add(_fragment('2', 'dos')),
        throwsUnsupportedError,
      );
    });

    test('expone el metadato de validación por tipo de contenido', () {
      final loader = ClinicalContentLoader();
      final emaMeta = loader.validationMetadataFor(ClinicalContentType.emaBank);
      expect(emaMeta, isNotNull);
      expect(
        emaMeta!.status,
        ContentValidationStatus.suppliedAfterEvaluatorReview,
      );
    });
  });
}
