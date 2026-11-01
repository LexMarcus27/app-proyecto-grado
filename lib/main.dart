import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'data/journey/demo_seeder.dart';

Future<void> main() async {
  // Necesario para usar plugins (shared_preferences) antes de `runApp`.
  WidgetsFlutterBinding.ensureInitialized();

  // `shared_preferences` se resuelve de forma asíncrona una sola vez y se
  // inyecta en el `ProviderScope`. Las implementaciones locales (p. ej.
  // `LocalJourneyRepository`) lo consumen de forma síncrona vía
  // `sharedPreferencesProvider`.
  final prefs = await SharedPreferences.getInstance();

  // Overrides de la composición de la app (Capa_Local). Se declaran una vez y
  // se reutilizan en el `ProviderContainer` de arranque y en el `ProviderScope`
  // para que el sembrado y la app compartan exactamente la misma instancia de
  // repositorio/almacenamiento.
  final overrides = [
    // Instancia local de almacenamiento compartida por las implementaciones
    // de la Capa_Local. `journeyRepositoryProvider` construye
    // `LocalJourneyRepository` sobre esta instancia por defecto.
    sharedPreferencesProvider.overrideWithValue(prefs),
    // TODO: inyectar las demás implementaciones (p. ej.):
    // authServiceProvider.overrideWithValue(SimulatedAuthService()),
  ];

  // Sembrado de la sesión demo en el primer arranque (tarea 2.10): si no hay
  // nada almacenado, inicializa el escenario CON vínculo activo para que la app
  // abra con un mapa usable. No sobrescribe un recorrido ya guardado. La
  // decisión de qué sembrar vive aquí/en `data/journey/demo_seeder.dart`, no en
  // `LocalJourneyRepository`, que permanece genérico (coherente con 2.7).
  final bootstrap = ProviderContainer(overrides: overrides);
  await seedDemoIfEmpty(bootstrap.read(journeyRepositoryProvider));
  bootstrap.dispose();

  runApp(
    // La composición de la app vive en `ProviderScope`. Aquí se sobreescriben
    // (override) los providers declarados en `lib/app/di.dart` con su
    // implementación/valor activo. Al habilitar la Capa_Firebase basta cambiar
    // el override correspondiente sin tocar las pantallas (ver design.md).
    ProviderScope(overrides: overrides, child: const ContigoApp()),
  );
}
