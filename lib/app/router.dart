import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/auth/session.dart';
import '../domain/auth/user_role.dart';
import '../presentation/ema/ema_flow_screen.dart';
import '../presentation/ema/ema_reference_selection_screen.dart';
import '../presentation/ema/ema_stale_reference_screen.dart';
import '../presentation/demo/demo_scenario_controls_screen.dart';
import '../presentation/network/network_map_screen.dart';
import '../presentation/shell/activation_screen.dart';
import '../presentation/shell/component_gallery_screen.dart';
import '../presentation/shell/placeholder_screen.dart';
import '../presentation/shell/unsupported_role_screen.dart';
import 'session_controller.dart';

/// Nombres de ruta de la app (rutas nombradas por pantalla).
///
/// No existe ninguna ruta para el panel del investigador/administrador: queda
/// excluido de la app móvil (Requirement 1.4).
abstract final class AppRoute {
  static const activation = 'activation';

  // Pantalla de desarrollo para revisar los componentes de la Etapa 1.
  static const componentGallery = 'ver-componentes';

  // Pantalla de desarrollo para alternar entre los escenarios demo (tarea 2.10).
  static const demoControls = 'demo-controls';
  static const unsupportedRole = 'unsupported-role';

  // Inicio por rol.
  static const pcsHome = 'pcs-home';
  static const caregiverHome = 'caregiver-home';

  // Entrada mínima a "Tu mapa de red" para confirmar la Referencia_EMA (PCS).
  static const networkMap = 'network-map';

  // Flujo EMA de extremo a extremo (registro diario) (PCS).
  static const ema = 'ema';

  // Selección de la Referencia_EMA antes del primer registro (PCS).
  static const emaReference = 'ema-reference';

  // Revisión de una Referencia_EMA obsoleta (PCS).
  static const emaStaleReference = 'ema-stale-reference';
}

/// Paths asociados a cada ruta nombrada.
abstract final class AppPath {
  static const activation = '/';
  static const componentGallery = '/ver-componentes';
  static const demoControls = '/demo';
  static const unsupportedRole = '/unsupported-role';
  static const pcsHome = '/pcs';
  static const caregiverHome = '/cuidador';
  static const networkMap = '/mapa-red';
  static const ema = '/ema';
  static const emaReference = '/ema/referencia';
  static const emaStaleReference = '/ema/revisar-referencia';
}

/// Provider del `GoRouter` de la app.
///
/// El router observa [sessionControllerProvider] para redirigir según el estado
/// de sesión y el rol:
/// - Sin sesión → pantalla de activación.
/// - Sesión con rol no soportado → pantalla de rol no soportado (Requirement
///   1.3): se conserva la sesión sin cargar datos de otros roles.
/// - Sesión con rol soportado → inicio correspondiente al rol, impidiendo el
///   acceso al inicio del otro rol (Requirement 1.2).
final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _SessionRefreshListenable(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: AppPath.activation,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      return _guard(session, state.matchedLocation);
    },
    routes: [
      GoRoute(
        name: AppRoute.activation,
        path: AppPath.activation,
        builder: (context, state) => const ActivationScreen(),
      ),
      GoRoute(
        name: AppRoute.componentGallery,
        path: AppPath.componentGallery,
        builder: (context, state) => const ComponentGalleryScreen(),
      ),
      GoRoute(
        name: AppRoute.demoControls,
        path: AppPath.demoControls,
        builder: (context, state) => const DemoScenarioControlsScreen(),
      ),
      GoRoute(
        name: AppRoute.unsupportedRole,
        path: AppPath.unsupportedRole,
        builder: (context, state) => const UnsupportedRoleScreen(),
      ),
      GoRoute(
        name: AppRoute.pcsHome,
        path: AppPath.pcsHome,
        builder: (context, state) => PlaceholderScreen(
          title: 'Inicio PCS',
          // Entrada mínima y temporal al flujo EMA de extremo a extremo (tarea
          // 2.17) mientras el home real del PCS (tarea 3.4) sigue pendiente.
          actions: [
            PlaceholderAction(
              label: 'Ir a mi registro EMA',
              onPressed: () => context.goNamed(AppRoute.ema),
            ),
          ],
        ),
      ),
      GoRoute(
        name: AppRoute.caregiverHome,
        path: AppPath.caregiverHome,
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Inicio Cuidador'),
      ),
      GoRoute(
        name: AppRoute.networkMap,
        path: AppPath.networkMap,
        builder: (context, state) => const NetworkMapScreen(),
      ),
      GoRoute(
        name: AppRoute.ema,
        path: AppPath.ema,
        builder: (context, state) => const EmaFlowScreen(),
      ),
      GoRoute(
        name: AppRoute.emaReference,
        path: AppPath.emaReference,
        builder: (context, state) => const EmaReferenceSelectionScreen(),
      ),
      GoRoute(
        name: AppRoute.emaStaleReference,
        path: AppPath.emaStaleReference,
        builder: (context, state) => const EmaStaleReferenceScreen(),
      ),
    ],
  );
});

/// Guarda por rol. Devuelve el path al que redirigir, o `null` para permitir la
/// ubicación actual.
///
/// Se expone para pruebas unitarias de la lógica de enrutamiento.
String? _guard(Session? session, String location) {
  // La galería de componentes es una pantalla de desarrollo (revisión visual
  // de la Etapa 1): se permite siempre, con o sin sesión.
  if (location == AppPath.componentGallery) {
    return null;
  }

  // Los controles de demostración son otra pantalla de desarrollo (alternar los
  // escenarios demo de la tarea 2.10): se permiten siempre, igual que la
  // galería de componentes, con o sin sesión.
  if (location == AppPath.demoControls) {
    return null;
  }

  // Sin sesión: solo se permite la pantalla de activación.
  if (session == null) {
    return location == AppPath.activation ? null : AppPath.activation;
  }

  // Sesión con rol no soportado: se conserva la sesión y se dirige a la
  // pantalla de rol no soportado, sin acceso a ninguna otra pantalla.
  if (!session.hasSupportedRole) {
    return location == AppPath.unsupportedRole ? null : AppPath.unsupportedRole;
  }

  final home = homePathForRole(session.role!);

  // Con sesión soportada, la pantalla de activación y la de rol no soportado
  // redirigen al inicio del rol.
  if (location == AppPath.activation || location == AppPath.unsupportedRole) {
    return home;
  }

  // "Tu mapa de red" es una pantalla del PCS (confirma la Referencia_EMA). Un
  // Cuidador no accede a ella: se le redirige a su propio inicio. El PCS la
  // alcanza sin redirección (necesario para que la revisión de referencia
  // obsoleta de 2.12 navegue aquí como acción primaria).
  if (location == AppPath.networkMap && session.role != UserRole.pcs) {
    return home;
  }

  // El flujo EMA de extremo a extremo (registro diario) es una pantalla del
  // PCS. Un Cuidador no accede a él: se le redirige a su propio inicio.
  if (location == AppPath.ema && session.role != UserRole.pcs) {
    return home;
  }

  // La selección de la Referencia_EMA es una pantalla del PCS (antes del primer
  // registro). Un Cuidador no accede a ella: se le redirige a su propio inicio.
  if (location == AppPath.emaReference && session.role != UserRole.pcs) {
    return home;
  }

  // La revisión de la Referencia_EMA obsoleta es una pantalla del PCS. Un
  // Cuidador no accede a ella: se le redirige a su propio inicio.
  if (location == AppPath.emaStaleReference && session.role != UserRole.pcs) {
    return home;
  }

  // Deniega el acceso al inicio del otro rol: redirige al inicio propio.
  final otherHome = homePathForRole(
    session.role == UserRole.pcs ? UserRole.cuidador : UserRole.pcs,
  );
  if (location == otherHome) {
    return home;
  }

  return null;
}

/// Path de inicio correspondiente a un rol soportado.
String homePathForRole(UserRole role) =>
    role == UserRole.pcs ? AppPath.pcsHome : AppPath.caregiverHome;

/// Guarda por rol expuesta para pruebas. Ver [_guard].
@visibleForTesting
String? guardForTest(Session? session, String location) =>
    _guard(session, location);

/// Puente entre el estado de sesión de Riverpod y `refreshListenable` de
/// `go_router`: notifica al router cuando cambia la sesión para re-evaluar las
/// guardas.
class _SessionRefreshListenable extends ChangeNotifier {
  _SessionRefreshListenable(Ref ref) {
    _removeListener = ref
        .listen<Session?>(
          sessionControllerProvider,
          (previous, next) => notifyListeners(),
        )
        .close;
  }

  late final void Function() _removeListener;

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }
}
