// Pruebas de mensajes de cuidado (tarea 3.18): envío simulado del cuidador que
// aparece en la bandeja del PCS, exclusión de datos privados, bandeja accesible
// sin asociación activa y distinción recibidos vs. tejer cercanía.

import 'package:contigo/app/app.dart';
import 'package:contigo/app/di.dart';
import 'package:contigo/app/router.dart';
import 'package:contigo/app/session_controller.dart';
import 'package:contigo/data/journey/local_journey_repository.dart';
import 'package:contigo/domain/auth/session.dart';
import 'package:contigo/domain/auth/user_role.dart';
import 'package:contigo/domain/journey/journey.dart';
import 'package:contigo/presentation/caring_messages/caring_messages_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(
  JourneyState seed, {
  required UserRole role,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await LocalJourneyRepository(prefs).save(seed);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  container.read(sessionControllerProvider.notifier).setSession(
        Session(userId: 'demo-${role.name}', role: role),
      );
  return container;
}

Future<void> _pump(WidgetTester tester, ProviderContainer container, String path) async {
  tester.view.physicalSize = const Size(700, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  container.read(routerProvider).go(path);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const ContigoApp(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Inter', 'Lora']) {
      final loader = FontLoader(family);
      loader.addFont(rootBundle.load('assets/fonts/$family-Variable.ttf'));
      await loader.load();
    }
  });

  testWidgets('El mapa puede construirse después de aplazar la bienvenida', (tester) async {
    final c = await _container(emptyJourney, role: UserRole.pcs);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.pcsHome);
    await tester.tap(find.text('Construir mi mapa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hacerlo después'));
    await tester.pumpAndSettle();
    final journey = await c.read(journeyRepositoryProvider).loadJourney();
    expect(journey.onboardingStatus, OnboardingStatus.deferred);
    expect(journey.mapGenerated, isFalse);
    await tester.tap(find.text('¿En dónde tejer?'));
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).routeInformationProvider.value.uri.path,
      AppPath.networkBuilder, reason: 'El acceso de red debe permitir iniciar la construcción si se aplazó');
  });

  testWidgets('El cuidador puede abrir mensajes de cuidado al ancho del telefono', (tester) async {
    final c = await _container(simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.active), role: UserRole.cuidador);
    addTearDown(c.dispose);
    await _pump(tester, c, AppPath.caregiverHome);
    tester.view.physicalSize = const Size(412, 900);
    await tester.pumpAndSettle();
    final entry = find.text('Tejiendo vínculos');
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escribir un mensaje de cuidado'));
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).routeInformationProvider.value.uri.path, AppPath.caringCompose);
    expect(tester.takeException(), isNull, reason: 'La pantalla de bienvenida debe dibujarse sin ancho infinito');
    expect(find.text('Conocer los mensajes de cuidado'), findsOneWidget);
  });

  testWidgets('La redacción abierta deja de exponer el borrador tras revocar el vínculo', (tester) async {
    final c = await _container(simulateCaregiverLink(createDemoJourney(), CaregiverDemoMode.active), role: UserRole.cuidador);
    addTearDown(c.dispose);
    // Carga primero un vínculo válido para que el contexto de cuidado se
    // resuelva antes de preparar el borrador (el borrador siempre se asocia a
    // una clave de vínculo completa; sin vínculo no se puede editar).
    await c.read(journeyRepositoryProvider).loadJourney();
    expect(c.read(currentCaringContextProvider), isNotNull);
    c.read(caringDraftControllerProvider.notifier).setText('Borrador ficticio anterior');
    await _pump(tester, c, AppPath.caringCompose);
    final resume = find.text('Continuar mi borrador');
    expect(resume, findsOneWidget);
    final repo = c.read(journeyRepositoryProvider);
    final journey = await repo.loadJourney();
    await repo.save(journey.copyWith(associations: [
      for (final link in journey.associations) link.copyWith(active: false),
    ]));
    await tester.pumpAndSettle();
    expect(resume, findsNothing, reason: 'Una pantalla abierta no debe seguir permitiendo abrir el borrador del vínculo revocado');
  });

  testWidgets('La bandeja abierta actualiza mensajes al revocar el vínculo', (tester) async {
    final c = await _container(createDemoJourney(), role: UserRole.pcs);
    addTearDown(c.dispose);
    const sample = 'Mensaje ficticio para probar revocación en vivo.';
    expect(await c.read(caringSendControllerProvider).simulateSend('caregiver-m', sample), isTrue);
    await _pump(tester, c, AppPath.caringInbox);
    expect(find.text(sample), findsOneWidget);
    final repo = c.read(journeyRepositoryProvider);
    final journey = await repo.loadJourney();
    await repo.save(journey.copyWith(associations: [
      for (final link in journey.associations) link.copyWith(active: false),
    ]));
    await tester.pumpAndSettle();
    expect(find.text(sample), findsNothing);
    expect(find.text('Mensajes de cuidado'), findsOneWidget);
  });
}
