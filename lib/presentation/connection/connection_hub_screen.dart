import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/connection/connection.dart';
import '../../domain/journey/journey.dart';
import '../authorization/gating.dart';
import '../widgets/widgets.dart';

/// Hub de conexión del PCS "Tejiendo vínculos" (tarea 3.20), portado de
/// `ConnectionHubScreen` (`src/screens/connection-hub.tsx`).
///
/// Presenta un paso destacado ("Un paso para hoy") y "Otro paso"/"Un paso para
/// hoy" que **rota cíclicamente** sin exigir completar el paso actual
/// (Requirement 8.9). Las acciones dirigidas a una persona (mensaje/contacto/
/// encuentro) pasan por el gating de autorización (`connectionLaunch`): se
/// deshabilitan si no hay una Asociacion_Activa válida (Requirement 8.10). La
/// bandeja de recibidos no tiene gating (Requirement 8.11).
class ConnectionHubScreen extends ConsumerStatefulWidget {
  const ConnectionHubScreen({super.key});

  @override
  ConsumerState<ConnectionHubScreen> createState() =>
      _ConnectionHubScreenState();
}

class _ConnectionHubScreenState extends ConsumerState<ConnectionHubScreen> {
  ConnectionStep _step = ConnectionStep.message;

  static const Map<ConnectionStep, IconData> _icons = {
    ConnectionStep.message: Icons.chat_bubble_outline,
    ConnectionStep.received: Icons.favorite_border,
    ConnectionStep.contact: Icons.people_outline,
    ConnectionStep.meeting: Icons.event_outlined,
    ConnectionStep.skills: Icons.menu_book_outlined,
  };

  /// `true` si el paso es una acción dirigida a persona (mensaje/contacto/
  /// encuentro), que requiere vínculo activo. `received` y `skills` no lo son.
  bool _isDirectedStep(ConnectionStep step) =>
      step == ConnectionStep.message ||
      step == ConnectionStep.contact ||
      step == ConnectionStep.meeting;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final gatingAsync = ref.watch(careGatingProvider);

    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: gatingAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
          data: (gating) {
            final people = gating.authorizedPeople;
            final NetworkPerson? person = people.isEmpty ? null : people.first;
            final featured = connectionStepContent(_step, name: person?.name);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StatusBar(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.goNamed(AppRoute.pcsHome),
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Volver al inicio',
                      ),
                      const Icon(Icons.link, color: ContigoColors.sage),
                      const SizedBox(width: 6),
                      Text('Tejiendo vínculos', style: textTheme.titleMedium),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CompanionNote(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tejer vínculos se hace paso a paso y de muchas '
                                'formas.',
                                style: textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '¿Qué paso quieres dar hoy?',
                                style: textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                        _FeaturedStep(
                          step: _step,
                          content: featured,
                          icon: _icons[_step]!,
                          gating: gating,
                          person: person,
                          onPrimary: () => _openStep(context, _step, gating),
                          onOther: () => setState(
                            () => _step = nextConnectionStep(_step),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Otros pasos', style: textTheme.titleMedium),
                        const SizedBox(height: 12),
                        for (final item in ConnectionStep.values)
                          _StepTile(
                            label: connectionStepContent(item).tile,
                            icon: _icons[item]!,
                            // Las acciones dirigidas a persona (mensaje/contacto/
                            // encuentro) quedan deshabilitadas sin vínculo activo,
                            // también en "Otros pasos". Recibidos y habilidades
                            // permanecen disponibles (Requirement 8.10, 8.11).
                            enabled: !_isDirectedStep(item) || person != null,
                            onTap: () => _openStep(context, item, gating),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openStep(BuildContext context, ConnectionStep step, CareGating gating) {
    switch (step) {
      case ConnectionStep.received:
        // La bandeja de recibidos no tiene gating (Requirement 8.11): abre la
        // bandeja de mensajes de cuidado del PCS (tarea 3.18).
        context.goNamed(AppRoute.caringInbox);
      case ConnectionStep.skills:
        _showPending(
          context,
          'Habilidades interpersonales',
          'Este contenido será proporcionado y validado por el equipo '
              'investigador.',
        );
      case ConnectionStep.message:
      case ConnectionStep.contact:
      case ConnectionStep.meeting:
        _launchPersonAction(context, step, gating);
    }
  }

  void _launchPersonAction(
    BuildContext context,
    ConnectionStep step,
    CareGating gating,
  ) {
    final people = gating.authorizedPeople;
    final action = switch (step) {
      ConnectionStep.contact => ConnectionAction.contact,
      ConnectionStep.meeting => ConnectionAction.meeting,
      _ => ConnectionAction.message,
    };
    if (people.isEmpty) {
      _showPending(
        context,
        'Necesitas un vínculo activo',
        'Esta acción requiere una persona cercana vinculada con asociación '
            'activa.',
      );
      return;
    }
    // Reevalúa la autorización exacta en el lanzamiento (incluida revocación).
    final launch = gating.isActionDisabled(people.first.id)
        ? null
        : ConnectionAction.values.contains(action)
            ? action
            : null;
    if (launch == null) {
      _showPending(
        context,
        'Acción no disponible',
        'El vínculo con esta persona ya no está activo.',
      );
      return;
    }
    _showPending(
      context,
      connectionStepContent(step, name: people.first.name).button,
      'Esta acción de conexión (${action.wireValue}) se completa en las '
          'pantallas dirigidas a la persona, disponibles en esta sección.',
    );
  }

  void _showPending(BuildContext context, String title, String body) {
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
              Text(body, style: textTheme.bodyMedium),
              const SizedBox(height: 16),
              ContigoButton(
                label: 'Volver',
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
}

/// Paso destacado "Un paso para hoy" con acción primaria y "Otro paso".
class _FeaturedStep extends StatelessWidget {
  const _FeaturedStep({
    required this.step,
    required this.content,
    required this.icon,
    required this.gating,
    required this.person,
    required this.onPrimary,
    required this.onOther,
  });

  final ConnectionStep step;
  final ConnectionStepContent content;
  final IconData icon;
  final CareGating gating;
  final NetworkPerson? person;
  final VoidCallback onPrimary;
  final VoidCallback onOther;

  bool get _isPersonAction =>
      step == ConnectionStep.message ||
      step == ConnectionStep.contact ||
      step == ConnectionStep.meeting;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Las acciones dirigidas a persona se deshabilitan sin vínculo activo.
    final disabled =
        _isPersonAction && (person == null || gating.isActionDisabled(person!.id));
    return ContigoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Un paso para hoy',
            style: (textTheme.labelMedium ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: ContigoColors.terracotta),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(content.title, style: textTheme.titleSmall),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      content.description,
                      style: (textTheme.bodySmall ?? const TextStyle())
                          .copyWith(color: ContigoColors.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ContigoButton(
                  label: content.button,
                  fullWidth: true,
                  onPressed: disabled ? null : onPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ContigoButton(
                  label: 'Otro paso',
                  variant: ContigoButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: onOther,
                ),
              ),
            ],
          ),
          if (disabled) ...[
            const SizedBox(height: 8),
            Text(
              'Necesitas un vínculo activo',
              style: (textTheme.labelMedium ?? const TextStyle()).copyWith(
                color: ContigoColors.clay,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tile de un paso en la rejilla "Otros pasos".
class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  /// Si es `false`, el tile se atenúa y no es pulsable (gating por asociación).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Semantics(
          button: true,
          enabled: enabled,
          label: enabled ? label : '$label. Necesitas un vínculo activo',
          child: ContigoCard(
            onTap: enabled ? onTap : null,
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Icon(icon, color: ContigoColors.sage),
                  const SizedBox(width: 12),
                  Expanded(child: Text(label, style: textTheme.titleSmall)),
                  if (!enabled)
                    Text(
                      'Necesitas un vínculo activo',
                      style: (textTheme.labelMedium ?? const TextStyle())
                          .copyWith(
                        color: ContigoColors.clay,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const Icon(Icons.chevron_right,
                        color: ContigoColors.inkMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}