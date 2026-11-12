import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/journey/journey.dart';
import '../widgets/widgets.dart';
import 'caregiver_home_controller.dart';

/// Inicio del cuidador (home hub con gating), portado de `CaregiverHomeScreen`
/// (`src/screens/caregiver-home.tsx`), tarea 3.5.
///
/// Muestra la tarjeta de vínculo y los tiles de los recorridos. Los tiles
/// **dependientes de asociación** (plan de acompañamiento, tejiendo vínculos y
/// registro de la relación) quedan **deshabilitados** salvo que exista una
/// Asociacion_Activa válida (gating por asociación activa, Requirement 8.1,
/// 8.2); el recurso de aprendizaje está siempre disponible. Incluye el selector
/// de perfil y el panel demo para alternar los estados del vínculo
/// (`active` | `accepted-only` | `revoked`), que opera en la Capa_Simulada.
///
/// Conserva el rótulo "Inicio Cuidador" como título de la pantalla.
class CaregiverHomeScreen extends ConsumerWidget {
  const CaregiverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final contextAsync = ref.watch(caregiverContextProvider);

    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: contextAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('No se pudo cargar el inicio: $e')),
          data: (careContext) {
            final linked = careContext != null;
            final pcsName = careContext?.pcsName;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const StatusBar(),
                  const SizedBox(height: 4),
                  Text('Inicio Cuidador', style: textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    '¡Hola, ${DemoCaregiver.name}! Qué bueno verte.',
                    style: (textTheme.bodyMedium ?? const TextStyle())
                        .copyWith(color: ContigoColors.inkMuted),
                  ),
                  const SizedBox(height: 20),
                  _LinkCard(linked: linked, pcsName: pcsName),
                  if (!linked) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Puedes explorar los recursos para aprender. El plan, los '
                      'mensajes y el registro de la relación estarán disponibles '
                      'cuando tengas un vínculo activo.',
                      style: (textTheme.bodySmall ?? const TextStyle())
                          .copyWith(color: ContigoColors.inkMuted),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Recurso de aprendizaje: siempre disponible.
                  _CaregiverTile(
                    title: 'Aprendiendo a tejer vínculos',
                    subtitle: pcsName != null
                        ? 'Lo que puedo saber para cuidar mi relación con $pcsName'
                        : 'Lo que puedo saber para cuidar a quienes quiero',
                    icon: Icons.menu_book_outlined,
                    enabled: true,
                    onTap: () => _openLearning(context),
                  ),
                  // Tiles dependientes de asociación: deshabilitados sin vínculo.
                  _CaregiverTile(
                    title: pcsName != null
                        ? 'Cómo puedo acompañar a $pcsName'
                        : 'Cómo puedo acompañar',
                    subtitle: 'Qué puedo hacer en una crisis',
                    icon: Icons.favorite_border,
                    enabled: linked,
                    onTap: () => context.goNamed(AppRoute.caregiverSupportPlan),
                  ),
                  _CaregiverTile(
                    title: 'Tejiendo vínculos',
                    subtitle: 'Cuidando mis relaciones',
                    icon: Icons.link,
                    enabled: linked,
                    // Con vínculo activo abre la redacción de un mensaje para
                    // tejer cercanía (tarea 3.18); desde ahí se alcanzan las
                    // preguntas para conectar y el registro de encuentro (3.19).
                    onTap: () => context.goNamed(AppRoute.caringCompose),
                  ),
                  _CaregiverTile(
                    title: pcsName != null
                        ? '¿Cómo está el tejido con $pcsName ahora?'
                        : '¿Cómo está el tejido ahora?',
                    subtitle: 'Registra cómo está la relación',
                    icon: Icons.insights_outlined,
                    enabled: linked,
                    onTap: () => context.goNamed(AppRoute.caregiverLinkCheckIn),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _CaregiverDemoPanel(),
                  const SizedBox(height: 12),
                  // Acceso visible a los controles de demostración (incluye el
                  // conmutador de rol PCS/Cuidador), para recorrer el flujo
                  // Cuidador -> envío simulado -> PCS -> bandeja sin reiniciar.
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          context.goNamed(AppRoute.demoControls),
                      child: const Text('Controles de demostración'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Abre el recurso de aprendizaje del cuidador ("Aprendiendo a tejer
  /// vínculos"), disponible sin depender de un vínculo activo (portado del
  /// prototipo). Lista las opciones del prototipo; su contenido lo valida el
  /// equipo investigador.
  void _openLearning(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final textTheme = Theme.of(sheetContext).textTheme;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Aprendiendo a tejer vínculos', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              // Opciones del prototipo.
              for (final resource in const [
                'Validación',
                'Habilidades interpersonales',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ContigoButton(
                    label: resource,
                    variant: ContigoButtonVariant.secondary,
                    fullWidth: true,
                    icon: const Icon(Icons.menu_book_outlined),
                    onPressed: () => _openLearningResource(sheetContext, resource),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'Los recursos serán proporcionados y validados por el equipo '
                'investigador.',
                style: (textTheme.bodySmall ?? const TextStyle())
                    .copyWith(color: ContigoColors.inkMuted),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Muestra el contenido (pendiente de validación) de un recurso de
  /// aprendizaje, sin inventar material clínico.
  void _openLearningResource(BuildContext context, String title) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final textTheme = Theme.of(sheetContext).textTheme;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                'Este contenido será proporcionado y validado por el equipo '
                'investigador.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ContigoButton(
                label: 'Volver a aprender',
                variant: ContigoButtonVariant.secondary,
                fullWidth: true,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Explicación temporal para los recorridos del cuidador cuyas pantallas
}

/// Tarjeta del vínculo del cuidador con el PCS. Deshabilitada si no hay vínculo.
class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.linked, required this.pcsName});

  final bool linked;
  final String? pcsName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final caption = linked ? 'Mi vínculo con' : 'Tu vínculo';
    final name = pcsName ?? 'Aún no hay una persona vinculada';
    final card = ContigoCard(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: ContigoColors.notifQuestionsBg,
            child: Icon(Icons.person, color: ContigoColors.terracotta),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  style: (textTheme.bodySmall ?? const TextStyle())
                      .copyWith(color: ContigoColors.inkMuted),
                ),
                Text(name, style: textTheme.titleSmall),
              ],
            ),
          ),
          if (linked)
            const Icon(Icons.chevron_right, color: ContigoColors.inkMuted),
        ],
      ),
    );
    return Opacity(opacity: linked ? 1 : 0.6, child: card);
  }
}

/// Tile de un recorrido del cuidador. Cuando [enabled] es `false`, se muestra
/// atenuado, no es pulsable y anuncia que se necesita un vínculo activo.
class _CaregiverTile extends StatelessWidget {
  const _CaregiverTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semanticLabel = enabled
        ? '$title. $subtitle'
        : '$title. $subtitle. Necesitas un vínculo activo';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Semantics(
          button: true,
          enabled: enabled,
          label: semanticLabel,
          child: ContigoCard(
            onTap: enabled ? onTap : null,
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: ContigoColors.sage),
                  const SizedBox(height: 8),
                  Text(title, style: textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: (textTheme.bodySmall ?? const TextStyle())
                        .copyWith(color: ContigoColors.inkMuted),
                  ),
                  if (!enabled) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Necesitas un vínculo activo',
                      style: (textTheme.labelMedium ?? const TextStyle())
                          .copyWith(
                        color: ContigoColors.clay,
                        fontWeight: FontWeight.w600,
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

/// Panel de demostración del cuidador: selector de perfil ficticio y botones
/// para simular los estados del vínculo. Opera en la Capa_Simulada.
class _CaregiverDemoPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(caregiverDemoControllerProvider);
    return ContigoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Herramientas de demostración del cuidador',
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
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
        ],
      ),
    );
  }
}

/// Selector de perfil ficticio del cuidador (demo).
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