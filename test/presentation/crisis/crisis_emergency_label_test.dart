// E3-W12-02: en modo crisis, "Emergencias" se lee como palabra completa al
// ancho del teléfono, sin desbordar ni truncarse; la acción sigue siendo
// simulada (abre el diálogo de confirmación, sin llamar).

import 'package:contigo/app/app.dart';
import 'package:contigo/app/di.dart';
import 'package:contigo/app/router.dart';
import 'package:contigo/app/session_controller.dart';
import 'package:contigo/data/journey/local_journey_repository.dart';
import 'package:contigo/domain/auth/session.dart';
import 'package:contigo/domain/auth/user_role.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Inter', 'Lora']) {
      final loader = FontLoader(family);
      loader.addFont(rootBundle.load('assets/fonts/$family-Variable.ttf'));
      await loader.load();
    }
  });

  testWidgets('"Emergencias" se dibuja completa y sin desbordes a 412 px',
      (tester) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await LocalJourneyRepository(prefs).save(createDemoJourney());
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(c.dispose);
    c.read(sessionControllerProvider.notifier).setSession(
          const Session(userId: 'demo-pcs', role: UserRole.pcs),
        );
    c.read(routerProvider).go(AppPath.crisisMode);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const ContigoApp(),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    // La etiqueta "Emergencias" existe como una sola palabra completa.
    final label = find.text('Emergencias');
    expect(label, findsOneWidget);
    // Sin desbordes de layout en la pantalla.
    expect(tester.takeException(), isNull);

    // La acción es simulada: abre el diálogo de confirmación, sin llamar.
    await tester.ensureVisible(label);
    await tester.pumpAndSettle();
    await tester.tap(label);
    await tester.pumpAndSettle();
    expect(find.text('Llamar a emergencias'), findsWidgets);
    expect(
      find.textContaining('lo configura el equipo clínico'),
      findsOneWidget,
    );
  });
}