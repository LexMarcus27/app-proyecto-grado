/// Implementación local de [EmaReferenceStore] sobre `shared_preferences`.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/ema/ema_logic.dart';
import '../../domain/ema/ema_reference.dart';
import '../../domain/repositories/repositories.dart';

/// [EmaReferenceStore] respaldado por `shared_preferences`.
///
/// Persiste **solo** los cuatro identificadores de la [EmaReference] (PCS,
/// persona, cuidador, asociación) como un objeto JSON bajo una clave estable.
/// Nunca serializa respuestas EMA (`answers`) ni avance del borrador
/// (`questionIndex`): el diseño y el requisito 6 prohíben persistir contenido
/// clínico; ese estado es efímero (de sesión) en modo demo.
///
/// La lectura delega en el dominio [parseEmaReference], de modo que un JSON
/// malformado, de otro PCS o con identificadores vacíos se degrada a `null` en
/// lugar de propagar un error o reconstruir una referencia inválida.
class LocalEmaReferenceStore implements EmaReferenceStore {
  LocalEmaReferenceStore(this._prefs, {this.storageKey = defaultStorageKey});

  /// Clave estable de almacenamiento de la `Referencia_EMA`.
  static const String defaultStorageKey = 'contigo.ema_reference';

  final SharedPreferences _prefs;

  /// Clave bajo la cual se persiste la referencia serializada.
  final String storageKey;

  @override
  Future<EmaReference?> loadReference() async {
    final raw = _prefs.getString(storageKey);
    // `parseEmaReference` acepta `null` y degrada a `null` ante datos
    // malformados, de otro PCS o con identificadores vacíos.
    return parseEmaReference(raw);
  }

  @override
  Future<void> saveReference(EmaReference reference) async {
    // Solo los cuatro identificadores. Nunca respuestas ni `questionIndex`.
    final encoded = jsonEncode(<String, String>{
      'pcsId': reference.pcsId,
      'personId': reference.personId,
      'caregiverId': reference.caregiverId,
      'associationId': reference.associationId,
    });
    await _prefs.setString(storageKey, encoded);
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(storageKey);
  }
}
