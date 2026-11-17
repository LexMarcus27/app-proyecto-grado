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
/// Sigue la propuesta visual A «Papel cálido»: tarjeta de bienvenida con
/// «¿Cómo estás hoy?», planta y acceso al registro diario; «Mi red» con
/// avatares unidos por un hilo; rejilla 2×2 de herramientas principales (red,
/// conexión, ayuda y EMA); «Más para ti» como lista agrupada; herramientas de
/// demostración plegadas; botón flotante «Necesito apoyo» y navegación
/// inferior (Inicio, Vínculos, Mi día y Perfil).
///
/// Los accesos adicionales que Flutter conserva (preguntas para conectar,
/// evaluar una relación —acordado expresamente—, mensajes de cuidado, el
/// relato del plan y las notificaciones) se ubican en «Más para ti», para no
/// alterar la jerarquía de las cuatro tarjetas principales.
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
      builder: (sheetContext) => SingleChildScrollView(
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
                context.pushNamed(AppRoute.notifications);
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

  void _openMap(BuildContext context) => context.pushNamed(
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
        const SizedBox(height: 12),
        // Tarjeta de bienvenida con el registro del día (propuesta A).
        _HeroCard(onCheckIn: () => context.pushNamed(AppRoute.ema)),
        const SizedBox(height: 22),
        if (showWelcome) ...[
          _OnboardingPrompt(
            onStart: () => context.pushNamed(AppRoute.pcsOnboarding),
          ),
          const SizedBox(height: 18),
        ],
        // Mi red.
        Row(
          children: [
            const Expanded(child: Text('Mi red', style: _sectionTitle)),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: ContigoColors.violet,
                textStyle: const TextStyle(
                  fontFamily: ContigoTheme.bodyFontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => _openMap(context),
              child: const Text('Ver mi mapa'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _NetworkRow(people: journey.people, onTap: () => _openMap(context)),
        const SizedBox(height: 22),
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
                onTap: () => context.pushNamed(AppRoute.connectionHub),
              ),
              _HomeTile(
                title: 'Necesito ayuda',
                description: 'Crisis y plan de seguridad',
                icon: Icons.support,
                palette: _TilePalette.help,
                onTap: () => context.pushNamed(AppRoute.helpHub),
              ),
              _HomeTile(
                title: '¿Cómo estoy hoy?',
                description: 'Registra cómo te sientes',
                icon: Icons.wb_sunny_outlined,
                palette: _TilePalette.checkin,
                onTap: () => context.pushNamed(AppRoute.ema),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        // Más para ti: lista agrupada.
        const Text('Más para ti', style: _sectionTitle),
        const SizedBox(height: 12),
        _MoreGroup(
          rows: [
            if (journey.onboardingStatus == OnboardingStatus.deferred &&
                !journey.mapGenerated)
              _MoreRow(
                title: 'Tu mapa te espera',
                subtitle: 'Retoma la construcción de tu red',
                icon: Icons.map_outlined,
                onTap: () => context.pushNamed(AppRoute.networkBuilder),
              ),
            _MoreRow(
              title: 'Mensajes de cuidado',
              subtitle: 'Lo que te han escrito',
              icon: Icons.favorite_border,
              onTap: () => context.pushNamed(AppRoute.caringInbox),
            ),
            _MoreRow(
              title: 'Preguntas para conectar',
              subtitle: 'Para conversar y conocerse',
              icon: Icons.chat_bubble_outline,
              onTap: () => context.pushNamed(AppRoute.pcsConnectionQuestions),
            ),
            _MoreRow(
              title: 'Evaluar una relación',
              subtitle: 'Nueve preguntas sobre un vínculo',
              icon: Icons.trending_up,
              onTap: () => context.pushNamed(AppRoute.relationEvaluation),
            ),
            _MoreRow(
              title: 'Mi plan para desenredar',
              subtitle: 'El relato de tu plan',
              icon: Icons.eco_outlined,
              onTap: () => context.pushNamed(AppRoute.safetyPlanStory),
            ),
            _MoreRow(
              title: 'Notificaciones',
              subtitle: available == 0
                  ? 'Avisos simulados recibidos'
                  : 'Avisos simulados recibidos ($available)',
              icon: Icons.notifications_none,
              onTap: () {
                ref
                    .read(notificationsControllerProvider.notifier)
                    .dismissVisible();
                context.pushNamed(AppRoute.notifications);
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Simulaciones y accesos de desarrollo, plegados.
        DemoToolsPanel(
          children: [
            ContigoButton(
              label: 'Simular notificación',
              variant: ContigoButtonVariant.secondary,
              small: true,
              fullWidth: true,
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () =>
                  ref.read(notificationsControllerProvider.notifier).simulate(),
            ),
            const SizedBox(height: 8),
            Text(
              'Muestra un aviso aleatorio dentro de la app. No envía '
              'notificaciones reales ni analiza tus datos.'
              '${validCaregivers(live).isEmpty ? ' Sin personas vinculadas, verás recordatorios generales.' : ''}',
              style: const TextStyle(
                fontSize: 12,
                height: 18 / 12,
                color: ContigoColors.inkMuted,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: () => context.pushNamed(AppRoute.componentGallery),
                  child: const Text('Ver componentes'),
                ),
                TextButton(
                  onPressed: () => context.pushNamed(AppRoute.demoControls),
                  child: const Text('Controles de demostración'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

const TextStyle _sectionTitle = TextStyle(
  fontSize: 19,
  height: 24 / 19,
  fontWeight: FontWeight.w800,
  color: Color(0xFF242126),
);

/// Azul de la acción del registro diario (familia del EMA).
const Color _checkInBlue = Color(0xFF2F72A0);

/// Tarjeta superior: saludo, «¿Cómo estás hoy?», planta y acceso directo al
/// registro diario (propuesta A «Papel cálido»).
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onCheckIn});

  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ContigoColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D3A3238),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            top: -10,
            right: -8,
            child: HomePlant(width: 104, height: 98),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 70),
                child: Text(
                  '¡Hola, Sofía! Qué bueno verte.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 21 / 15,
                    color: Color(0xFF555158),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.only(right: 80),
                child: Text(
                  '¿Cómo estás hoy?',
                  key: Key('pcs-home-title'),
                  style: TextStyle(
                    fontFamily: ContigoTheme.displayFontFamily,
                    fontFamilyFallback: ContigoTheme.displayFontFallback,
                    fontSize: 36,
                    height: 1.08,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    color: Color(0xFF242126),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _checkInBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontFamily: ContigoTheme.bodyFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: onCheckIn,
                icon: const Icon(Icons.wb_sunny_outlined, size: 22),
                label: const Text('Registrar cómo me siento'),
              ),
              const SizedBox(height: 14),
              const Text(
                'Toma unos minutos. Puedes hacerlo después.',
                style: TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  color: ContigoColors.inkMuted,
                ),
              ),
            ],
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

/// «Mi red»: hasta tres personas unidas por un hilo punteado y «Añadir».
/// Todas abren el mapa de red.
class _NetworkRow extends StatelessWidget {
  const _NetworkRow({required this.people, required this.onTap});

  final List<NetworkPerson> people;
  final VoidCallback onTap;

  static const double _avatar = 62;

  @override
  Widget build(BuildContext context) {
    final shown = people.take(3).toList();
    final slots = shown.length + 1;
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 4,
          height: _avatar,
          child: ExcludeSemantics(
            child: CustomPaint(painter: _ThreadPainter(slots: slots)),
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < shown.length; i++)
              Expanded(
                child: _NetworkSlot(
                  label: 'Ver a ${shown[i].name} en mi mapa',
                  name: shown[i].name,
                  onTap: onTap,
                  avatar: HomeAvatar(index: i, size: _avatar),
                ),
              ),
            Expanded(
              child: _NetworkSlot(
                label: 'Agregar persona a mi mapa',
                name: 'Añadir',
                accent: true,
                onTap: onTap,
                avatar: DashedBorder(
                  color: ContigoColors.violet.withValues(alpha: 0.6),
                  circle: true,
                  child: Container(
                    width: _avatar,
                    height: _avatar,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 28,
                      color: ContigoColors.violet,
                    ),
                  ),
                ),
              ),
            ),
            // Conserva el ancho de cuatro columnas aunque haya menos personas.
            for (var i = slots; i < 4; i++) const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}

class _NetworkSlot extends StatelessWidget {
  const _NetworkSlot({
    required this.label,
    required this.name,
    required this.onTap,
    required this.avatar,
    this.accent = false,
  });

  final String label;
  final String name;
  final VoidCallback onTap;
  final Widget avatar;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              avatar,
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 19 / 14,
                  fontWeight: FontWeight.w600,
                  color: accent ? ContigoColors.violet : const Color(0xFF3A3238),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hilo punteado ondulado que une los avatares de «Mi red».
class _ThreadPainter extends CustomPainter {
  _ThreadPainter({required this.slots});

  final int slots;

  @override
  void paint(Canvas canvas, Size size) {
    final slotWidth = size.width / 4;
    final y = size.height / 2;
    var previous = Offset(0, y + 6);
    final path = Path()..moveTo(previous.dx, previous.dy);
    for (var i = 0; i < slots; i++) {
      final point = Offset(slotWidth * (i + 0.5), y);
      final control = Offset(
        (previous.dx + point.dx) / 2,
        i.isEven ? y + 16 : y - 16,
      );
      path.quadraticBezierTo(control.dx, control.dy, point.dx, point.dy);
      previous = point;
    }
    final paint = Paint()
      ..color = const Color(0xFFB9AEDF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 0.1), paint);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ThreadPainter old) => old.slots != slots;
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

/// Tarjeta principal del inicio del PCS (`.home-tile`), con chevrón.
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
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 176),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: palette.iconBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 24, color: palette.icon),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, size: 22, color: palette.icon),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: ContigoTheme.displayFontFamily,
                      fontFamilyFallback: ContigoTheme.displayFontFallback,
                      fontSize: 21,
                      height: 25 / 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: palette.title ?? const Color(0xFF242126),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
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

/// Tarjeta blanca que agrupa las filas de «Más para ti» con divisores.
class _MoreGroup extends StatelessWidget {
  const _MoreGroup({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ContigoColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFEAE3DC)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF0EAE4)),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// Fila de «Más para ti»: ícono en cuadro lila, título, descripción y chevrón.
class _MoreRow extends StatelessWidget {
  const _MoreRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEBF8),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 21, color: ContigoColors.violet),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 21 / 16,
                        fontWeight: FontWeight.w700,
                        color: ContigoColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 18 / 13,
                        color: ContigoColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 22, color: ContigoColors.violet),
            ],
          ),
        ),
      ),
    );
  }
}
