import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/journey/journey.dart';
import '../notifications/notification_card.dart';
import '../notifications/notifications_controller.dart';
import '../notifications/notifications_screen.dart';
import '../widgets/widgets.dart';
import 'pcs_home_controller.dart';

/// Inicio del PCS (home hub de rol), portado de `MobileHomeScreen`
/// (`src/screens/home.tsx`), tarea 3.4.
///
/// Reemplaza el placeholder temporal del PCS: expone los tiles reales de
/// navegación (registro EMA, plan de seguridad, mapa de red, tejiendo vínculos y
/// bandeja de mensajes de cuidado), avatares derivados de `journey.people` y la
/// ramificación por estado de onboarding. Presenta la notificación simulada
/// in-app como banner (Funcion_Simulada) con indicador de simulación.
///
/// Conserva el rótulo "Inicio PCS" (contrato de pruebas de enrutamiento).
class PcsHomeScreen extends ConsumerWidget {
  const PcsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final journeyAsync = ref.watch(pcsHomeJourneyProvider);

    return Scaffold(
      backgroundColor: ContigoColors.canvasLight,
      body: SafeArea(
        child: journeyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('No se pudo cargar el inicio: $e')),
          data: (journey) => _HomeBody(journey: journey, textTheme: textTheme),
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.journey, required this.textTheme});

  final JourneyState journey;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showWelcome = shouldShowOnboardingWelcome(journey);
    final notifications = ref.watch(notificationsControllerProvider);
    final latest = notifications.inbox.isEmpty ? null : notifications.inbox.last;
    final people = journey.people.take(4).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StatusBar(),
          // Banner de notificación simulada in-app (solo si ya no hay bienvenida).
          if (!showWelcome && latest != null) ...[
            Semantics(
              container: true,
              label: 'Notificación simulada',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SimulationIndicator.forFeature(
                    NotificationsScreen.featureLayer,
                  ),
                  const SizedBox(height: 8),
                  NotificationCard(
                    notification: latest,
                    onOpen: () => context.goNamed(AppRoute.notifications),
                    onDismiss: () =>
                        ref.read(notificationsControllerProvider.notifier).clear(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          Text('Inicio PCS', style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            '¡Hola, Sofía! Qué bueno verte.',
            style: (textTheme.bodyMedium ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
          if (showWelcome) ...[
            const SizedBox(height: 16),
            _OnboardingPrompt(
              onStart: () => context.goNamed(AppRoute.pcsOnboarding),
            ),
          ],
          const SizedBox(height: 20),
          // Mis vínculos: avatares derivados de journey.people.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mis vínculos', style: textTheme.titleMedium),
              TextButton(
                onPressed: () => context.goNamed(AppRoute.networkMap),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _AvatarRow(
            people: people,
            onTap: () => context.goNamed(AppRoute.networkMap),
          ),
          const SizedBox(height: 20),
          Text('Herramientas principales', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          _HomeTile(
            title: '¿Cómo estoy hoy?',
            description: 'Registra cómo te sientes',
            icon: Icons.wb_sunny_outlined,
            onTap: () => context.goNamed(AppRoute.ema),
          ),
          _HomeTile(
            title: '¿En dónde tejer?',
            description: 'Relaciones para conectar',
            icon: Icons.hub_outlined,
            onTap: () => context.goNamed(AppRoute.networkMap),
          ),
          _HomeTile(
            title: 'Tejiendo vínculos',
            description: 'Cuida tus relaciones',
            icon: Icons.link,
            onTap: () => context.goNamed(AppRoute.connectionHub),
          ),
          _HomeTile(
            title: 'Mensajes de cuidado',
            description: 'Palabras que otras personas han guardado para ti',
            icon: Icons.favorite_border,
            onTap: () => context.goNamed(AppRoute.caringInbox),
          ),
          _HomeTile(
            title: 'Necesito ayuda',
            description: 'Crisis y plan de seguridad',
            icon: Icons.health_and_safety_outlined,
            onTap: () => context.goNamed(AppRoute.crisisMode),
          ),
          _HomeTile(
            title: 'Mi plan para desenredar',
            description: 'Plan de seguridad "Las crisis también pasan"',
            icon: Icons.menu_book_outlined,
            onTap: () => context.goNamed(AppRoute.safetyPlanStory),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // "Más para ti": simular/ver notificaciones.
          Text('Más para ti', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          ContigoButton(
            label: 'Simular notificación',
            variant: ContigoButtonVariant.secondary,
            fullWidth: true,
            icon: const Icon(Icons.notifications_none),
            onPressed: () =>
                ref.read(notificationsControllerProvider.notifier).simulate(),
          ),
          const SizedBox(height: 8),
          ContigoButton(
            label: notifications.inbox.isEmpty
                ? 'Ver notificaciones simuladas'
                : 'Ver notificaciones simuladas (${notifications.inbox.length})',
            variant: ContigoButtonVariant.tertiary,
            fullWidth: true,
            onPressed: () => context.goNamed(AppRoute.notifications),
          ),
          const SizedBox(height: 20),
          // Accesos de desarrollo (galería y controles de demostración).
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: () => context.goNamed(AppRoute.componentGallery),
                  child: const Text('Ver componentes'),
                ),
                TextButton(
                  onPressed: () => context.goNamed(AppRoute.demoControls),
                  child: const Text('Controles de demostración'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso de bienvenida cuando el onboarding no ha comenzado.
class _OnboardingPrompt extends StatelessWidget {
  const _OnboardingPrompt({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ContigoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Antes de empezar, reconoce tu red', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Construye tu mapa de red y, al terminar, invita a las personas '
            'cercanas con quienes quieras compartir la aplicación o fortalecer '
            'tu relación.',
            style: (textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
          const SizedBox(height: 12),
          ContigoButton(
            label: 'Construir mi mapa',
            fullWidth: true,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

/// Fila de avatares de las personas de la red (hasta cuatro), con "Añadir"
/// cuando faltan. Todos abren el mapa de red.
class _AvatarRow extends StatelessWidget {
  const _AvatarRow({required this.people, required this.onTap});

  final List<NetworkPerson> people;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: Semantics(
              button: true,
              label: i < people.length
                  ? 'Ver a ${people[i].name} en mi mapa'
                  : 'Agregar persona a mi mapa',
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: i < people.length
                            ? ContigoColors.notifQuestionsBg
                            : ContigoColors.notifReminderBg,
                        child: Icon(
                          i < people.length ? Icons.person : Icons.add,
                          color: ContigoColors.terracotta,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        i < people.length ? people[i].name : 'Añadir',
                        overflow: TextOverflow.ellipsis,
                        style: (textTheme.bodySmall ?? const TextStyle())
                            .copyWith(color: ContigoColors.inkMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Tile de navegación del inicio del PCS.
class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ContigoActionCard(
        semanticLabel: '$title. $description',
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, color: ContigoColors.sage),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: (textTheme.bodySmall ?? const TextStyle())
                        .copyWith(color: ContigoColors.inkMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ContigoColors.inkMuted),
          ],
        ),
      ),
    );
  }
}