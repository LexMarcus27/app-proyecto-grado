// Auditoría 1, S1-H03: los datos del journey (nombres de la red y respuestas
// por relación) no deben salir del teléfono por la copia de Android ni por la
// transferencia entre dispositivos.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _res = 'android/app/src/main/res/xml';
const _domains11 = ['root', 'file', 'database', 'sharedpref', 'external'];
const _domains12 = [
  ..._domains11,
  'device_root',
  'device_file',
  'device_database',
  'device_sharedpref',
];

String _section(String xml, String tag) {
  final match = RegExp('<$tag>([\\s\\S]*?)</$tag>').firstMatch(xml);
  expect(match, isNotNull, reason: 'falta <$tag>');
  return match!.group(1)!;
}

void _expectExcludesAll(String body, List<String> domains) {
  expect(body, isNot(contains('<include')));
  for (final domain in domains) {
    expect(body, contains('<exclude domain="$domain" path="." />'),
        reason: 'el dominio $domain debe quedar excluido');
  }
}

void main() {
  test('el manifiesto desactiva la copia y declara las reglas', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(manifest,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'));
  });

  test('Android 12+: ni copia en la nube ni transferencia entre dispositivos',
      () {
    final xml = File('$_res/data_extraction_rules.xml').readAsStringSync();
    _expectExcludesAll(_section(xml, 'cloud-backup'), _domains12);
    _expectExcludesAll(_section(xml, 'device-transfer'), _domains12);
  });

  test('Android 11 o inferior: la copia automática queda vacía', () {
    final xml = File('$_res/backup_rules.xml').readAsStringSync();
    _expectExcludesAll(_section(xml, 'full-backup-content'), _domains11);
  });
}
