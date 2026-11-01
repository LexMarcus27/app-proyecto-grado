import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/ema/in_memory_ema_draft_store.dart';
import '../data/ema/local_ema_reference_store.dart';
import '../data/journey/local_journey_repository.dart';
import '../domain/auth/auth_service.dart';
import '../domain/repositories/repositories.dart';

/// Inyección de dependencias de la app (composición en `lib/app`).
///
/// Cada interfaz del dominio se expone mediante un provider declarado con
/// `throw UnimplementedError('override en ProviderScope')`. La implementación
/// activa (simulada/local ahora, Firebase después) se inyecta mediante un
/// `override` en el `ProviderScope` de la composición de la app, sin tocar las
/// pantallas (ver design.md).
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     caringMessageRepositoryProvider.overrideWithValue(
///       SimulatedCaringMessageRepository(),
///     ),
///   ],
///   child: const ContigoApp(),
/// );
/// ```

const String _overrideMessage = 'override en ProviderScope';

/// Instancia de `SharedPreferences` para las implementaciones locales.
///
/// Se declara lanzando por defecto y se sobreescribe en el `ProviderScope` de
/// la composición de la app con la instancia resuelta de forma asíncrona en
/// `main()` (ver `lib/main.dart`). Al promover a Capa_Firebase se retira este
/// override junto con las implementaciones locales que lo consumen.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(_overrideMessage),
);

/// Servicio de activación/login y resolución de rol.
final authServiceProvider = Provider<AuthService>(
  (ref) => throw UnimplementedError(_overrideMessage),
);

/// Lectura/escritura del `JourneyState` (mapa de red, asociaciones).
///
/// Por defecto construye la implementación local
/// ([LocalJourneyRepository]) sobre [sharedPreferencesProvider]. La etapa
/// Firebase sustituye solo este provider con un override, sin tocar pantallas.
final journeyRepositoryProvider = Provider<JourneyRepository>(
  (ref) => LocalJourneyRepository(ref.watch(sharedPreferencesProvider)),
);

/// Lectura/escritura de la `Referencia_EMA` (solo identificadores).
///
/// Por defecto construye la implementación local ([LocalEmaReferenceStore])
/// sobre [sharedPreferencesProvider], que persiste únicamente los cuatro IDs.
/// La etapa Firebase sustituye solo este provider con un override.
final emaReferenceStoreProvider = Provider<EmaReferenceStore>(
  (ref) => LocalEmaReferenceStore(ref.watch(sharedPreferencesProvider)),
);

/// Borrador EMA diario (sesión).
///
/// Implementación en memoria ([InMemoryEmaDraftStore]): el borrador y su avance
/// viven solo en la sesión; las respuestas clínicas no se persisten en disco.
final emaDraftStoreProvider = Provider<EmaDraftStore>(
  (ref) => InMemoryEmaDraftStore(),
);

/// `SafetyPlanDraft` (sesión).
final safetyPlanStoreProvider = Provider<SafetyPlanStore>(
  (ref) => throw UnimplementedError(_overrideMessage),
);

/// Registro/bandeja de mensajes de cuidado.
final caringMessageRepositoryProvider = Provider<CaringMessageRepository>(
  (ref) => throw UnimplementedError(_overrideMessage),
);

/// Envío de mensajes/invitaciones (simulado).
final messageSenderProvider = Provider<MessageSender>(
  (ref) => throw UnimplementedError(_overrideMessage),
);

/// Generación/entrega de notificaciones (simulado/local).
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError(_overrideMessage),
);

/// Importación de contactos del SO (simulado).
final contactsServiceProvider = Provider<ContactsService>(
  (ref) => throw UnimplementedError(_overrideMessage),
);
