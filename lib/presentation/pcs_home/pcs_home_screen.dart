import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/journey/journey.dart';
import '../authorization/gating.dart';
import '../notifications/notification_card.dart';
import '../notifications/notification_dispatch.dart';
import '../notifications/notifications_controller.dart';
import '../notifications/notifications_screen.dart';
import '../widgets/widgets.dart';
import 'pcs_home_controller.dart';

/// Inicio del PCS, portado de `MobileHomeScreen` (`src/screens/home.tsx`).
///
/// Reproduce la composición del prototipo: título serif «Inicio» con planta,
/// «Mis vínculos» con avatares ilustrados, rejilla 2×2 de herramientas
/// principales (red, conexión, ayuda y EMA, en ese orden), «Más para ti»,
/// botón flotante «Necesito apoyo» y navegación inferior (Inicio, Vínculos,
/// Mi día y Perfil).
///
/// Los accesos adicionales que Flutter conserva para revisión (preguntas para
/// conectar, evaluar una relación —acordado expresamente—, mensajes de cuidado
/// y el relato del plan) se ubican en «Más para ti», para no alterar la
/// jerarquía de las cuatro tarjetas principales.
class PcsHomeScreen extends ConsumerWidget {
  const PcsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyAsync = ref.watch(pcsHomeJourneyProvider);

    return Scaffold(
      backgroundColor: ContigoColors.canvasLight,
      floatingActionButton: SupportButton.pcs(context),
      bottomNavigationBar: PcsBottomNav(
        onProfile: () => _showProfileSheet(context),
      ),
      body: SafeArea(
        bottom: false,
        child: journeyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('No se pudo cargar el inicio: $e')),
          data: (journey) => _HomeBody(journey: journey),
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tu perfil', style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text(
              'Desde aquí podrás revisar tu cuenta, privacidad y preferencias '
              'de acompañamiento.',
              style: TextStyle(
                fontSize: 14,
                height: 21 / 14,
                color: ContigoColors.inkMuted,
              ),
            ),
            const SizedBox(height: 18),
            ContigoButton(
              label: 'Ver notificaciones',
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.goNamed(AppRoute.notifications);
              },
            ),
            const SizedBox(height: 9),
            ContigoButton(
              label: 'Cerrar',
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.journey});

  final JourneyState journey;

  void _openMap(BuildContext context) => context.goNamed(
        journey.mapGenerated ? AppRoute.networkMap : AppRoute.networkBuilder,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showWelcome = shouldShowOnboardingWelcome(journey);
    final notifications = ref.watch(notificationsControllerProvider);
    final live = ref.watch(gatingJourneyProvider).value ?? journey;
    final visible = notifications.visible;
    final banner = visible != null && isNotificationAvailable(live, visible)
        ? visible
        : null;
    final available = notifications.inbox
        .where((n) => isNotificationAvailable(live, n))
        .length;
    final people = journey.people.take(4).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, supportContentPadding),
      children: [
        const StatusBar(),
        // Banner de notificación simulada in-app (solo si no hay bienvenida).
        if (!showWelcome && banner != null) ...[
          Semantics(
            container: true,
            liveRegion: true,
            label: 'Notificación simulada',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SimulationIndicator.forFeature(NotificationsScreen.featureLayer),
                const SizedBox(height: 8),
                NotificationCard(
                  notification: banner,
                  onOpen: () => openDemoNotification(context, ref, banner),
                  onDismiss: () => ref
                      .read(notificationsControllerProvider.notifier)
                      .dismissVisible(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 20),
        // Cabecera con planta (`.home-hero`).
        SizedBox(
          height: 134,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                top: -8,
                right: -7,
                child: HomePlant(width: 124, height: 116),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inicio',
                    key: Key('pcs-home-title'),
                    style: TextStyle(
                      fontFamily: ContigoTheme.displayFontFamily,
                      fontFamilyFallback: ContigoTheme.displayFontFallback,
                      fontSize: 50,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.8,
                      color: Color(0xFF242126),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 210),
                    child: const Text(
                      '¡Hola, Sofía! Qué bueno verte.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 23 / 16,
                        color: Color(0xFF555158),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showWelcome) ...[
          _OnboardingPrompt(
            onStart: () => context.goNamed(AppRoute.pcsOnboarding),
          ),
          const SizedBox(height: 16),
        ],
        // Mis vínculos.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: Text('Mis vínculos', style: _sectionTitle)),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: ContigoColors.violet,
                textStyle: const TextStyle(fontFamily: ContigoTheme.bodyFontFamily, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              onPressed: () => _openMap(context),
              child: const Text('Ver todos'),
            ),
          ],
        ),
        _AvatarRow(people: people, onTap: () => _openMap(context)),
        const SizedBox(height: 14),
        // Herramientas principales (`.home-tile-grid`).
        Semantics(
          container: true,
          label: 'Herramientas principales',
          child: ContigoTileGrid(
            children: [
              _HomeTile(
                title: '¿En dónde tejer?',
                description: 'Relaciones para conectar',
                icon: Icons.hub_outlined,
                palette: _TilePalette.network,
                onTap: () => _openMap(context),
              ),
              _HomeTile(
                title: 'Tejiendo vínculos',
                description: 'Cuida tus relaciones',
                icon: Icons.all_inclusive,
                palette: _TilePalette.connection,
                onTap: () => context.goNamed(AppRoute.connectionHub),
              ),
              _HomeTile(
                title: 'Necesito ayuda',
                description: 'Crisis y plan de seguridad',
                icon: Icons.support,
                palette: _TilePalette.help,
                onTap: () => context.goNamed(AppRoute.helpHub),
              ),
              _HomeTile(
                title: '¿Cómo estoy hoy?',
                description: 'Registra cómo te sientes',
                icon: Icons.wb_sunny_outlined,
                palette: _TilePalette.checkin,
                onTap: () => context.goNamed(AppRoute.ema),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Más para ti.
        const Text('Más para ti', style: _sectionTitle),
        _ExtraRow(
          label: 'Simular notificación',
          icon: Icons.chat_bubble_outline,
          highlighted: true,
          onTap: () => ref.read(notificationsControllerProvider.notifier).simulate(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Demostración: muestra un aviso aleatorio dentro de la app. No envía '
            'notificaciones reales ni analiza tus datos.'
            '${validCaregivers(live).isEmpty ? ' Sin personas vinculadas, verás recordatorios generales.' : ''}',
            style: const TextStyle(
              fontSize: 12,
              height: 18 / 12,
              color: ContigoColors.inkMuted,
            ),
          ),
        ),
        _ExtraRow(
          label: available == 0
              ? 'Ver notificaciones simuladas'
              : 'Ver notificaciones simuladas ($available)',
          onTap: () {
            ref.read(notificationsControllerProvider.notifier).dismissVisible();
            context.goNamed(AppRoute.notifications);
          },
        ),
        if (journey.onboardingStatus == OnboardingStatus.deferred &&
            !journey.mapGenerated)
          _ExtraRow(
            label: 'Tu mapa te espera',
            onTap: () => context.goNamed(AppRoute.networkBuilder),
          ),
        _ExtraRow(
          label: 'Mensajes de cuidado',
          onTap: () => context.goNamed(AppRoute.caringInbox),
        ),
        _ExtraRow(
          label: 'Preguntas para conectar',
          onTap: () => context.goNamed(AppRoute.pcsConnectionQuestions),
        ),
        _ExtraRow(
          label: 'Evaluar una relación',
          onTap: () => context.goNamed(AppRoute.relationEvaluation),
        ),
        _ExtraRow(
          label: 'Mi plan para desenredar',
          onTap: () => context.goNamed(AppRoute.safetyPlanStory),
        ),
        const SizedBox(height: 16),
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
    );
  }
}

const TextStyle _sectionTitle = TextStyle(
  fontSize: 18,
  height: 24 / 18,
  fontWeight: FontWeight.w800,
  color: Color(0xFF242126),
);

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

/// Fila de avatares de las personas de la red (hasta cuatro), con «Añadir»
/// cuando faltan. Todos abren el mapa de red.
class _AvatarRow extends StatelessWidget {
  const _AvatarRow({required this.people, required this.onTap});

  final List<NetworkPerson> people;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      HomeAvatar(index: i),
                      const SizedBox(height: 4),
                      Text(
                        i < people.length ? people[i].name : 'Añadir',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 19 / 13,
                          color: Color(0xFF54515A),
                        ),
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

/// Paleta de cada tarjeta principal (`.home-tile--*`).
enum _TilePalette {
  network(Color(0xFFF0EEFA), Color(0xFFE3DDF8), Color(0xFF604BA8), null),
  connection(Color(0xFFFCF0E9), Color(0xFFF6DED0), Color(0xFFB35831), null),
  help(Color(0xFFFCE7E7), Color(0xFFF6CECA), Color(0xFFA83C37), Color(0xFF7D2924)),
  checkin(Color(0xFFE9F1F9), Color(0xFFD4E7F5), Color(0xFF3777A6), null);

  const _TilePalette(this.background, this.iconBackground, this.icon, this.title);

  final Color background;
  final Color iconBackground;
  final Color icon;
  final Color? title;
}

/// Tarjeta principal del inicio del PCS (`.home-tile`).
class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.palette,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final _TilePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $description',
      child: Material(
        color: palette.background,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 166),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: palette.iconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 24, color: palette.icon),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: ContigoTheme.displayFontFamily,
                      fontFamilyFallback: ContigoTheme.displayFontFallback,
                      fontSize: 20,
                      height: 22 / 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: palette.title ?? const Color(0xFF242126),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 18 / 13,
                      color: Color(0xFF5D5960),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila de «Más para ti» (`.home-extra-row`).
class _ExtraRow extends StatelessWidget {
  const _ExtraRow({
    required this.label,
    required this.onTap,
    this.icon = Icons.chevron_right,
    this.highlighted = false,
  });

  final String label;
  final IconData icon;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: highlighted ? const Color(0xFFEEE6F2) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: highlighted ? const Color(0xFF9B84A8) : const Color(0xFFE8DED8),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: ContigoColors.ink,
                    ),
                  ),
                ),
                Icon(icon, size: 18, color: ContigoColors.violet),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
