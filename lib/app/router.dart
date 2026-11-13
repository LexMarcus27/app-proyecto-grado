import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/auth/session.dart';
import '../domain/auth/user_role.dart';
import '../presentation/ema/ema_flow_screen.dart';
import '../presentation/ema/ema_reference_selection_screen.dart';
import '../presentation/ema/ema_stale_reference_screen.dart';
import '../presentation/demo/demo_scenario_controls_screen.dart';
import '../presentation/caregiver/caregiver_home_screen.dart';
import '../presentation/caregiver_journeys/caregiver_journey_screens.dart';
import '../presentation/caring_messages/caring_compose_screen.dart';
import '../presentation/caring_messages/caring_inbox_screen.dart';
import '../presentation/caregiver/caregiver_views.dart';
import '../presentation/connection/connection_hub_screen.dart';
import '../presentation/connection/connection_person_screen.dart';
import '../presentation/connection/connection_selection.dart';
import '../presentation/help/help_hub_screen.dart';
import '../presentation/connection/pcs_connection_questions_screen.dart';
import '../presentation/crisis/breathing_screen.dart';
import '../presentation/crisis/crisis_mode_screen.dart';
import '../presentation/notifications/notifications_screen.dart';
import '../presentation/network/network_builder_screen.dart';
import '../presentation/network/network_map_screen.dart';
import '../presentation/pcs_home/pcs_home_screen.dart';
import '../presentation/relation_evaluation/relation_evaluation_screen.dart';
import '../presentation/onboarding/pcs_onboarding_screen.dart';
import '../presentation/safety_plan/safety_plan_editor_screen.dart';
import '../presentation/safety_plan/safety_plan_story_screen.dart';
import '../presentation/shell/activation_screen.dart';
import '../presentation/shell/component_gallery_screen.dart';
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

  // Relato del plan de seguridad (PCS).
  static const safetyPlanStory = 'safety-plan-story';

  // Editor del plan de seguridad (PCS).
  static const safetyPlanEditor = 'safety-plan-editor';

  // Bienvenida del onboarding del PCS (tarea 3.3).
  static const pcsOnboarding = 'pcs-onboarding';

  // Hub de conexión "Tejiendo vínculos" del PCS (tarea 3.20).
  static const connectionHub = 'connection-hub';

  // Notificaciones simuladas, modo crisis y respiración (tarea 3.28).
  static const notifications = 'notifications';
  static const crisisMode = 'crisis-mode';
  static const breathing = 'breathing';

  // Centro "¿Qué necesitas ahora?" (M20, `HelpHubScreen`).
  static const helpHub = 'help-hub';

  // Vistas del cuidador de la navegación inferior (M22, M23, M24).
  static const caregiverLearning = 'caregiver-learning';
  static const caregiverConnections = 'caregiver-connections';
  static const caregiverProfile = 'caregiver-profile';

  // Conexión con una persona (M8) y selección de persona (M21) del PCS.
  static const connectionPerson = 'connection-person';

  // Mensajes de cuidado (tarea 3.18).
  static const caringInbox = 'caring-inbox';
  static const caringCompose = 'caring-compose';

  // Recorridos del cuidador dependientes de asociación (tarea 3.19).
  static const caregiverSupportPlan = 'caregiver-support-plan';
  static const caregiverLinkCheckIn = 'caregiver-link-checkin';
  static const caregiverEncounter = 'caregiver-encounter';
  static const caregiverConnectionQuestions = 'caregiver-connection-questions';
  static const caregiverIntimateMessage = 'caregiver-intimate-message';

  // Preguntas para conectar conversacionales del PCS (tarea 3.19, MobileScreen14).
  static const pcsConnectionQuestions = 'pcs-connection-questions';

  // Evaluación de relación de nueve preguntas (tarea 3.23).
  static const relationEvaluation = 'relation-evaluation';

  // Construcción del mapa de red (tarea 3.11).
  static const networkBuilder = 'network-builder';
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
  static const safetyPlanStory = '/plan-seguridad/relato';
  static const safetyPlanEditor = '/plan-seguridad';
  static const pcsOnboarding = '/pcs/onboarding';
  static const connectionHub = '/tejiendo-vinculos';
  static const notifications = '/notificaciones';
  static const crisisMode = '/necesito-ayuda';
  static const breathing = '/respiracion';
  static const helpHub = '/ayuda';
  static const caregiverLearning = '/cuidador/aprender';
  static const caregiverConnections = '/cuidador/vinculos';
  static const caregiverProfile = '/cuidador/perfil';
  static const connectionPerson = '/tejiendo-vinculos/persona';
  static const caringInbox = '/mensajes-de-cuidado';
  static const caringCompose = '/mensajes-de-cuidado/redactar';
  static const caregiverSupportPlan = '/cuidador/plan-acompanamiento';
  static const caregiverLinkCheckIn = '/cuidador/registro-vinculo';
  static const caregiverEncounter = '/cuidador/encuentro';
  static const caregiverConnectionQuestions = '/cuidador/preguntas-conectar';
  static const caregiverIntimateMessage = '/cuidador/mensaje-intimo';
  static const pcsConnectionQuestions = '/preguntas-conectar';
  static const relationEvaluation = '/evaluar-relacion';
  static const networkBuilder = '/mapa-red/construir';
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
        builder: (context, state) => const PcsHomeScreen(),
      ),
      GoRoute(
        name: AppRoute.caregiverHome,
        path: AppPath.caregiverHome,
        builder: (context, state) => const CaregiverHomeScreen(),
      ),
      GoRoute(
        name: AppRoute.networkBuilder,
        path: AppPath.networkBuilder,
        builder: (context, state) => NetworkBuilderScreen(
          editPersonId: state.uri.queryParameters['edit'],
        ),
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
      GoRoute(
        name: AppRoute.safetyPlanStory,
        path: AppPath.safetyPlanStory,
        builder: (context, state) => const SafetyPlanStoryScreen(),
      ),
      GoRoute(
        name: AppRoute.safetyPlanEditor,
        path: AppPath.safetyPlanEditor,
        builder: (context, state) => const SafetyPlanEditorScreen(),
      ),
      GoRoute(
        name: AppRoute.pcsOnboarding,
        path: AppPath.pcsOnboarding,
        builder: (context, state) => const PcsOnboardingScreen(),
      ),
      GoRoute(
        name: AppRoute.connectionHub,
        path: AppPath.connectionHub,
        builder: (context, state) => ConnectionHubScreen(
          initialStep: connectionStepFromQuery(state.uri.queryParameters['s']),
        ),
      ),
      GoRoute(
        name: AppRoute.notifications,
        path: AppPath.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        name: AppRoute.crisisMode,
        path: AppPath.crisisMode,
        builder: (context, state) => const CrisisModeScreen(),
      ),
      GoRoute(
        name: AppRoute.helpHub,
        path: AppPath.helpHub,
        builder: (context, state) => const HelpHubScreen(),
      ),
      GoRoute(
        name: AppRoute.connectionPerson,
        path: AppPath.connectionPerson,
        builder: (context, state) => ConnectionPersonScreen(
          personId: state.uri.queryParameters['p'],
          initialAction: connectionActionFromQuery(
            state.uri.queryParameters['a'],
          ),
        ),
      ),
      GoRoute(
        name: AppRoute.caregiverLearning,
        path: AppPath.caregiverLearning,
        builder: (context, state) => const CaregiverLearningScreen(),
      ),
      GoRoute(
        name: AppRoute.caregiverConnections,
        path: AppPath.caregiverConnections,
        builder: (context, state) => const CaregiverConnectionsScreen(),
      ),
      GoRoute(
        name: AppRoute.caregiverProfile,
        path: AppPath.caregiverProfile,
        builder: (context, state) => const CaregiverProfileScreen(),
      ),
      GoRoute(
        name: AppRoute.breathing,
        path: AppPath.breathing,
        builder: (context, state) => const BreathingScreen(),
      ),
      GoRoute(
        name: AppRoute.caringInbox,
        path: AppPath.caringInbox,
        builder: (context, state) => const CaringInboxScreen(),
      ),
      GoRoute(
        name: AppRoute.caringCompose,
        path: AppPath.caringCompose,
        builder: (context, state) => const CaringComposeScreen(),
      ),
      GoRoute(
        name: AppRoute.pcsConnectionQuestions,
        path: AppPath.pcsConnectionQuestions,
        builder: (context, state) => PcsConnectionQuestionsScreen(
          initialQuestion: state.uri.queryParameters['q'],
        ),
      ),
      GoRoute(
        name: AppRoute.relationEvaluation,
        path: AppPath.relationEvaluation,
        builder: (context, state) => const RelationEvaluationScreen(),
      ),
      GoRoute(
        name: AppRoute.caregiverSupportPlan,
        path: AppPath.caregiverSupportPlan,
        builder: (context, state) => const CaregiverSupportPlanScreen(),
      ),
      GoRoute(
        name: AppRoute.caregiverLinkCheckIn,
        path: AppPath.caregiverLinkCheckIn,
        builder: (context, state) => const CaregiverLinkCheckInScreen(),
      ),
      GoRoute(
        name: AppRoute.caregiverEncounter,
        path: AppPath.caregiverEncounter,
        builder: (context, state) => const CaregiverEncounterScreen(),
      ),
      GoRoute(
        name: AppRoute.caregiverConnectionQuestions,
        path: AppPath.caregiverConnectionQuestions,
        builder: (context, state) => const CaregiverConnectionQuestionsScreen(),
      ),
      GoRoute(
        name: AppRoute.caregiverIntimateMessage,
        path: AppPath.caregiverIntimateMessage,
        builder: (context, state) => const CaregiverIntimateMessageScreen(),
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

  // La construcción del mapa de red es del PCS.
  if (location == AppPath.networkBuilder && session.role != UserRole.pcs) {
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

  // El plan de seguridad (relato y editor) es del PCS. Un Cuidador no accede;
  // se le redirige a su propio inicio.
  if ((location == AppPath.safetyPlanStory ||
          location == AppPath.safetyPlanEditor) &&
      session.role != UserRole.pcs) {
    return home;
  }

  // El onboarding del PCS es del PCS. Un Cuidador no accede; va a su inicio.
  if (location == AppPath.pcsOnboarding && session.role != UserRole.pcs) {
    return home;
  }

  // El hub de conexión "Tejiendo vínculos" es del PCS. Un Cuidador no accede.
  if (location == AppPath.connectionHub && session.role != UserRole.pcs) {
    return home;
  }

  // Notificaciones, modo crisis y respiración son del PCS.
  if ((location == AppPath.notifications ||
          location == AppPath.helpHub ||
          location == AppPath.connectionPerson ||
          location == AppPath.crisisMode ||
          location == AppPath.breathing) &&
      session.role != UserRole.pcs) {
    return home;
  }

  // Las preguntas para conectar del PCS y la evaluación de relación son del PCS.
  if ((location == AppPath.relationEvaluation ||
          location == AppPath.pcsConnectionQuestions) &&
      session.role != UserRole.pcs) {
    return home;
  }

  // La bandeja de mensajes de cuidado recibidos es del PCS. No exige una
  // Asociacion_Activa para abrirse (Requirement 8.11), solo el rol PCS.
  if (location == AppPath.caringInbox && session.role != UserRole.pcs) {
    return home;
  }

  // La redacción de un mensaje de cuidado es del Cuidador.
  if (location == AppPath.caringCompose &&
      session.role != UserRole.cuidador) {
    return home;
  }

  // Los recorridos del cuidador dependientes de asociación son del Cuidador.
  if ((location == AppPath.caregiverSupportPlan ||
          location == AppPath.caregiverLearning ||
          location == AppPath.caregiverConnections ||
          location == AppPath.caregiverProfile ||
          location == AppPath.caregiverLinkCheckIn ||
          location == AppPath.caregiverEncounter ||
          location == AppPath.caregiverConnectionQuestions ||
          location == AppPath.caregiverIntimateMessage) &&
      session.role != UserRole.cuidador) {
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
