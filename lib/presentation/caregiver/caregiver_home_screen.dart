import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/journey/journey.dart';
import '../widgets/widgets.dart';
import 'caregiver_home_controller.dart';
import 'caregiver_views.dart';

/// Inicio del cuidador (home hub con gating), portado de `CaregiverHomeScreen`
/// (`src/screens/caregiver-home.tsx`), vista `home`.
///
/// Reproduce la composición del prototipo: título serif grande con planta,
/// tarjeta «Mi vínculo con…» pulsable (abre el registro de la relación, M12),
/// rejilla de dos columnas con los cuatro recorridos, botón flotante «Proveer
/// apoyo» y navegación inferior (Inicio, Aprender, Vínculos, Perfil).
///
/// Los tiles **dependientes de asociación** (plan de acompañamiento, tejiendo
/// vínculos y registro de la relación) quedan **deshabilitados** salvo que
/// exista una Asociacion_Activa válida (Requirement 8.1, 8.2); el recurso de
/// aprendizaje está siempre disponible. Incluye el panel demo plegable para
/// alternar los estados del vínculo (Capa_Simulada).
class CaregiverHomeScreen extends ConsumerWidget {
  const CaregiverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextAsync = ref.watch(caregiverContextProvider);
    final linked = contextAsync.value != null;

    return CaregiverScaffold(
      active: CaregiverTab.inicio,
      supportEnabled: linked,
      child: contextAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudo cargar el inicio: $e')),
        data: (careContext) {
          final linked = careContext != null;
          final pcsName = careContext?.pcsName;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const StatusBar(),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned(
                      right: -5,
                      top: 6,
                      child: CaregiverPlant(width: 112, height: 118),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          caregiverDateLabel(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 13,
                            height: 18 / 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: ContigoColors.sage,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Inicio',
                          key: Key('caregiver-home-title'),
                          style: caregiverHeroTitleStyle,
                        ),
                        const SizedBox(height: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 230),
                          child: Text(
                            '¡Hola, ${DemoCaregiver.name}! Qué bueno verte.',
                            style: const TextStyle(
                              fontSize: 16,
                              height: 23 / 16,
                              color: ContigoColors.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _LinkCard(
                linked: linked,
                pcsName: pcsName,
                onTap: () => context.pushNamed(AppRoute.caregiverLinkCheckIn),
              ),
              if (!linked)
                const Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 18),
                  child: Text(
                    'Puedes explorar los recursos para aprender. El plan, los '
                    'mensajes y el registro de la relación estarán disponibles '
                    'cuando tengas un vínculo activo.',
                    style: caregiverNoteStyle,
                  ),
                )
              else
                const SizedBox(height: 18),
              // Rejilla de dos columnas (`.caregiver-grid`).
              ContigoTileGrid(
                children: [
                  _CaregiverTile(
                    title: 'Aprendiendo a tejer vínculos',
                    subtitle: pcsName != null
                        ? 'Lo que puedo saber para cuidar mi relación con $pcsName'
                        : 'Lo que puedo saber para cuidar a quienes quiero',
                    icon: Icons.menu_book_outlined,
                    enabled: true,
                    onTap: () => context.pushNamed(AppRoute.caregiverLearning),
                  ),
                  _CaregiverTile(
                    title: pcsName != null
                        ? 'Cómo puedo acompañar a $pcsName'
                        : 'Cómo puedo acompañar',
                    subtitle: 'Qué puedo hacer en una crisis',
                    icon: Icons.support,
                    help: true,
                    enabled: linked,
                    onTap: () => context.pushNamed(AppRoute.caregiverSupportPlan),
                  ),
                  _CaregiverTile(
                    title: 'Tejiendo vínculos',
                    subtitle: 'Cuidando mis relaciones',
                    icon: Icons.link,
                    enabled: linked,
                    onTap: () => context.pushNamed(AppRoute.caregiverConnections),
                  ),
                  _CaregiverTile(
                    title: pcsName != null
                        ? '¿Cómo está el tejido con $pcsName ahora?'
                        : '¿Cómo está el tejido ahora?',
                    subtitle: 'Registra cómo está la relación',
                    icon: Icons.trending_up,
                    enabled: linked,
                    onTap: () => context.pushNamed(AppRoute.caregiverLinkCheckIn),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const CaregiverDemoPanel(),
            ],
          );
        },
      ),
    );
  }
}

//// Fecha del encabezado del inicio del cuidador («LUNES 16 DE NOVIEMBRE»).
String caregiverDateLabel(DateTime date) {
  const days = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
  ];
  const months = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
    'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];
  return '${days[date.weekday - 1]} ${date.day} de ${months[date.month - 1]}'
      .toUpperCase();
}

/// Tarjeta del vínculo del cuidador con el PCS (propuesta A): avatar, «MI
/// VÍNCULO CON», nombre serif y estado del vínculo. Con vínculo activo abre el
/// registro de la relación (M12); sin vínculo queda deshabilitada.
class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.linked,
    required this.pcsName,
    required this.onTap,
  });

  final bool linked;
  final String? pcsName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final caption = linked ? 'Mi vínculo con' : 'Tu vínculo';
    final name = pcsName ?? 'Aún no hay una persona vinculada';
    return Semantics(
      button: linked,
      enabled: linked,
      label: pcsName != null
          ? 'Mi vínculo con $pcsName. Registrar cómo está la relación'
          : 'Todavía no tienes un vínculo activo',
      excludeSemantics: true,
      child: Material(
        color: ContigoColors.surface,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          onTap: linked ? onTap : null,
          borderRadius: BorderRadius.circular(26),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFE6DDD3)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D3A3238),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const HomeAvatar(index: 0, size: 64),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caption.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          height: 18 / 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: ContigoColors.sage,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: ContigoTheme.displayFontFamily,
                          fontFamilyFallback: ContigoTheme.displayFontFallback,
                          fontSize: 26,
                          height: 32 / 26,
                          fontWeight: FontWeight.w700,
                          color: ContigoColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _LinkStatusChip(active: linked),
                    ],
                  ),
                ),
                if (linked)
                  const Icon(Icons.chevron_right, size: 26, color: ContigoColors.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Estado del vínculo: «● Vínculo activo» o «Sin vínculo activo».
class _LinkStatusChip extends StatelessWidget {
  const _LinkStatusChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? ContigoColors.sage : ContigoColors.inkMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE3ECDF) : const Color(0xFFEFEAE3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Vínculo activo' : 'Sin vínculo activo',
            style: TextStyle(
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile de un recorrido del cuidador (`.caregiver-tile`), con chevrón. Cuando
/// [enabled] es `false`, se muestra con fondo neutro, no es pulsable y anuncia
/// que se necesita un vínculo activo.
class _CaregiverTile extends StatelessWidget {
  const _CaregiverTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.help = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final bool help;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = enabled
        ? '$title. $subtitle'
        : '$title. $subtitle. Necesitas un vínculo activo';
    final background = !enabled
        ? const Color(0xFFEFEAE3)
        : help
            ? const Color(0xFFF6E3E2)
            : const Color(0xFFE3ECE0);
    final accent = help ? const Color(0xFFA3474A) : ContigoColors.sage;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(26),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 214),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: help
                              ? const Color(0xFFEED0CD)
                              : const Color(0xFFD3E0CE),
                        ),
                        child: Icon(icon, size: 24, color: accent),
                      ),
                      const Spacer(),
                      if (enabled)
                        Icon(Icons.chevron_right, size: 22, color: accent),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: ContigoTheme.displayFontFamily,
                      fontFamilyFallback: ContigoTheme.displayFontFallback,
                      fontSize: 20,
                      height: 25 / 20,
                      fontWeight: FontWeight.w700,
                      color: help ? const Color(0xFF9A3F3C) : ContigoColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: ContigoColors.inkMuted,
                    ),
                  ),
                  if (!enabled) ...[
                    const Spacer(),
                    const SizedBox(height: 6),
                    const Text(
                      'Necesitas un vínculo activo',
                      style: TextStyle(
                        fontSize: 12,
                        height: 17 / 12,
                        color: ContigoColors.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Panel de demostración del cuidador, plegable como el
/// `<details className="caregiver-demo">` del prototipo: selector de perfil
/// ficticio y botones para simular los estados del vínculo (Capa_Simulada).
class CaregiverDemoPanel extends ConsumerWidget {
  const CaregiverDemoPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(caregiverDemoControllerProvider);
    return DemoToolsPanel(
      children: [
        Text(
          'Datos ficticios. Las simulaciones usan el vínculo de Marta con '
          'Sofía; no representan aceptación, acceso o desvinculación reales.',
          style: (textTheme.bodySmall ?? const TextStyle())
              .copyWith(color: ContigoColors.inkMuted),
        ),
        const SizedBox(height: 12),
        _ProfileSelector(),
        const SizedBox(height: 12),
        ContigoButton(
          label: 'Cargar vínculo de demostración',
          small: true,
          fullWidth: true,
          onPressed: () => controller.simulate(CaregiverDemoMode.active),
        ),
        const SizedBox(height: 8),
        ContigoButton(
          label: 'Simular aceptación sin asociación',
          variant: ContigoButtonVariant.secondary,
          small: true,
          fullWidth: true,
          onPressed: () => controller.simulate(CaregiverDemoMode.acceptedOnly),
        ),
        const SizedBox(height: 8),
        ContigoButton(
          label: 'Simular revocación del vínculo',
          variant: ContigoButtonVariant.secondary,
          small: true,
          fullWidth: true,
          onPressed: () => controller.simulate(CaregiverDemoMode.revoked),
        ),
        const SizedBox(height: 4),
        // Acceso a los controles de demostración (incluye el conmutador de
        // rol PCS/Cuidador).
        Center(
          child: TextButton(
            onPressed: () => context.pushNamed(AppRoute.demoControls),
            child: const Text('Controles de demostración'),
          ),
        ),
      ],
    );
  }
}

// Selector de perfil ficticio del cuidador (demo).
class _ProfileSelector extends StatefulWidget {
  @override
  State<_ProfileSelector> createState() => _ProfileSelectorState();
}

class _ProfileSelectorState extends State<_ProfileSelector> {
  String _selected = caregiverDemoProfiles.first.id;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perfil ficticio',
          style: (textTheme.bodySmall ?? const TextStyle())
              .copyWith(color: ContigoColors.inkMuted),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: _selected,
          decoration: const InputDecoration(
            filled: true,
            fillColor: ContigoColors.surface,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            for (final profile in caregiverDemoProfiles)
              DropdownMenuItem(value: profile.id, child: Text(profile.name)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _selected = value);
          },
        ),
      ],
    );
  }
}
