import 'package:contigo/data/ema/in_memory_ema_draft_store.dart';
import 'package:contigo/domain/ema/ema_logic.dart';
import 'package:contigo/domain/ema/ema_reference.dart';
import 'package:contigo/domain/journey/journey_demo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _reference = EmaReference(
  pcsId: currentPcsId,
  personId: 'demo-m',
  caregiverId: 'caregiver-m',
  associationId: 'association-demo-m',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InMemoryEmaDraftStore', () {
    test('loadTodayDraft devuelve null cuando no se ha guardado nada',
        () async {
      final store = InMemoryEmaDraftStore();
      expect(await store.loadTodayDraft(), isNull);
    });

    test('saveDraft seguido de loadTodayDraft devuelve el mismo borrador',
        () async {
      final store = InMemoryEmaDraftStore();
      // Borrador con avance (questionIndex) para verificar que se conserva.
      final draft = createEmaDraft(_reference, '2024-01-15')
          .copyWith(questionIndex: 4);

      await store.saveDraft(draft);
      final loaded = await store.loadTodayDraft();

      expect(loaded, draft);
      expect(loaded!.questionIndex, 4);
      expect(loaded.reference, _reference);
    });

    test('saveDraft reemplaza el borrador anterior', () async {
      final store = InMemoryEmaDraftStore();
      final first = createEmaDraft(_reference, '2024-01-15');
      final second = createEmaDraft(_reference, '2024-01-16')
          .copyWith(questionIndex: 2);

      await store.saveDraft(first);
      await store.saveDraft(second);

      expect(await store.loadTodayDraft(), second);
    });

    test('clear vacía el borrador conservado', () async {
      final store = InMemoryEmaDraftStore();
      await store.saveDraft(createEmaDraft(_reference, '2024-01-15'));
      expect(await store.loadTodayDraft(), isNotNull);

      await store.clear();

      expect(await store.loadTodayDraft(), isNull);
    });

    test('saveDraft NO escribe en shared_preferences (solo sesión)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();

      final store = InMemoryEmaDraftStore();
      final draft = createEmaDraft(_reference, '2024-01-15')
          .copyWith(questionIndex: 3);

      await store.saveDraft(draft);

      // El almacén de sesión no debe tocar el disco: sin claves EMA (ni de
      // respuestas ni de avance) tras guardar.
      expect(prefs.getKeys(), isEmpty);
    });
  });
}
