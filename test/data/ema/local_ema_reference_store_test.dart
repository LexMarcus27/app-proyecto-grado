import 'dart:convert';

import 'package:contigo/data/ema/local_ema_reference_store.dart';
import 'package:contigo/domain/ema/ema_reference.dart';
import 'package:contigo/domain/journey/journey_demo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Referencia de muestra del PCS actual.
const _reference = EmaReference(
  pcsId: currentPcsId,
  personId: 'demo-m',
  caregiverId: 'caregiver-m',
  associationId: 'association-demo-m',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalEmaReferenceStore', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    test('loadReference devuelve null cuando no hay nada almacenado', () async {
      final store = LocalEmaReferenceStore(prefs);
      expect(await store.loadReference(), isNull);
    });

    test('saveReference seguido de loadReference hace round-trip de los 4 IDs',
        () async {
      final store = LocalEmaReferenceStore(prefs);

      await store.saveReference(_reference);
      final loaded = await store.loadReference();

      expect(loaded, _reference);
      expect(loaded!.pcsId, currentPcsId);
      expect(loaded.personId, 'demo-m');
      expect(loaded.caregiverId, 'caregiver-m');
      expect(loaded.associationId, 'association-demo-m');
    });

    test('el JSON persistido contiene SOLO los 4 IDs (sin respuestas ni avance)',
        () async {
      final store = LocalEmaReferenceStore(prefs);
      await store.saveReference(_reference);

      final raw = prefs.getString(LocalEmaReferenceStore.defaultStorageKey);
      expect(raw, isNotNull);

      // Nunca debe aparecer contenido clínico ni avance del borrador.
      expect(raw, isNot(contains('answers')));
      expect(raw, isNot(contains('questionIndex')));
      expect(raw, isNot(contains('completed')));
      expect(raw, isNot(contains('relationshipOmission')));

      // El objeto tiene exactamente las cuatro claves de identificadores.
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(
        decoded.keys.toSet(),
        {'pcsId', 'personId', 'caregiverId', 'associationId'},
      );
    });

    test('un store nuevo lee lo que otro guardó (persistencia real)', () async {
      final writer = LocalEmaReferenceStore(prefs);
      await writer.saveReference(_reference);

      final reader = LocalEmaReferenceStore(prefs);
      expect(await reader.loadReference(), _reference);
    });

    test('loadReference degrada a null ante JSON malformado', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalEmaReferenceStore.defaultStorageKey: 'no-es-json {',
      });
      final corrupt = await SharedPreferences.getInstance();
      final store = LocalEmaReferenceStore(corrupt);

      expect(await store.loadReference(), isNull);
    });

    test('loadReference degrada a null si el PCS no es el actual', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalEmaReferenceStore.defaultStorageKey: jsonEncode(<String, String>{
          'pcsId': 'otro-pcs',
          'personId': 'demo-m',
          'caregiverId': 'caregiver-m',
          'associationId': 'association-demo-m',
        }),
      });
      final other = await SharedPreferences.getInstance();
      final store = LocalEmaReferenceStore(other);

      expect(await store.loadReference(), isNull);
    });

    test('loadReference degrada a null si algún identificador está vacío',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalEmaReferenceStore.defaultStorageKey: jsonEncode(<String, String>{
          'pcsId': currentPcsId,
          'personId': '',
          'caregiverId': 'caregiver-m',
          'associationId': 'association-demo-m',
        }),
      });
      final empty = await SharedPreferences.getInstance();
      final store = LocalEmaReferenceStore(empty);

      expect(await store.loadReference(), isNull);
    });

    test('clear elimina la referencia persistida', () async {
      final store = LocalEmaReferenceStore(prefs);
      await store.saveReference(_reference);
      expect(await store.loadReference(), isNotNull);

      await store.clear();

      expect(await store.loadReference(), isNull);
      expect(
        prefs.getString(LocalEmaReferenceStore.defaultStorageKey),
        isNull,
      );
    });
  });
}
