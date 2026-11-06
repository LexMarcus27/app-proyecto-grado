import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../widgets/widgets.dart';

/// Modo crisis (tarea 3.28), portado de `MobileScreen06` (`src/screens/mobile.tsx`).
///
/// Presenta el contenido textual **verbatim** del prototipo (encabezados,
/// secciones y acciones) y conserva los marcadores de contenido pendiente de
/// validación (`[[...]]`). Las acciones de contacto/emergencia son simuladas
/// (no realizan llamadas ni envíos reales). El número de emergencias lo
/// configura el equipo clínico (no se codifica aquí).
class CrisisModeScreen extends ConsumerStatefulWidget {
  const CrisisModeScreen({super.key});

  @override
  ConsumerState<CrisisModeScreen> createState() => _CrisisModeScreenState();
}

class _CrisisModeScreenState extends ConsumerState<CrisisModeScreen> {
  static const int _totalSteps = 6;

  /// Paso actual del indicador (1..6). Avanza con "Elegir otra opción"/"No puedo
  /// ahora", sin pasar del total, como en el prototipo.
  int _step = 1;

  void _advanceStep() {
    setState(() => _step = _step < _totalSteps ? _step + 1 : _step);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra superior mínima: salir + paso.
            Container(
              color: ContigoColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _confirmExit,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Salir'),
                  ),
                  Text(
                    'Paso $_step de $_totalSteps',
                    style: (textTheme.bodySmall ?? const TextStyle())
                        .copyWith(color: ContigoColors.inkMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estás aquí.\nVamos paso a paso.',
                      style: textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No tienes que hacerlo todo. Empecemos por una opción.',
                      style: (textTheme.bodyMedium ?? const TextStyle())
                          .copyWith(color: ContigoColors.inkMuted),
                    ),
                    const SizedBox(height: 24),
                    _section(
                      context,
                      'Qué puedo hacer por mi cuenta',
                      _SelfHelpCard(
                        step: _step,
                        totalSteps: _totalSteps,
                        onOpenSkill: () => context.goNamed(AppRoute.breathing),
                        onChooseOther: _advanceStep,
                        onCannotNow: _advanceStep,
                      ),
                    ),
                    _section(
                      context,
                      'Actividades sociales que pueden ayudarme',
                      Column(
                        children: const [
                          _ActivityRow('Caminar juntos en el parque'),
                          _ActivityRow('Tomar un café'),
                        ],
                      ),
                    ),
                    _section(
                      context,
                      'Cómo puedo hacer mi entorno más seguro',
                      _MutedBox(
                        '[[Información guardada en tu plan de seguridad — '
                        'pendiente de completar]]',
                      ),
                    ),
                    _section(
                      context,
                      'Personas a quienes puedo pedir ayuda',
                      Column(
                        children: [
                          _ContactRow(
                            name: 'Mamá',
                            label: 'Familiar',
                            onContact: () => _showContactOptions(context),
                          ),
                          _ContactRow(
                            name: 'Jorge',
                            label: 'Amigo de confianza',
                            onContact: () => _showContactOptions(context),
                          ),
                          _ContactRow(
                            name: 'Dra. Valentina Ríos',
                            label: 'Terapeuta',
                            onContact: () => _showContactOptions(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Acciones persistentes de emergencia (simuladas).
            Container(
              color: ContigoColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Text(
                    'También puedes',
                    style: (textTheme.bodySmall ?? const TextStyle())
                        .copyWith(color: ContigoColors.inkMuted),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ContigoButton(
                          label: 'Mamá',
                          variant: ContigoButtonVariant.secondary,
                          small: true,
                          fullWidth: true,
                          onPressed: () => _showContactOptions(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ContigoButton(
                          label: 'Línea ayuda',
                          variant: ContigoButtonVariant.secondary,
                          small: true,
                          fullWidth: true,
                          onPressed: () => _showHelpLine(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ContigoButton(
                          label: 'Emergencias',
                          variant: ContigoButtonVariant.critical,
                          small: true,
                          fullWidth: true,
                          onPressed: () => _showEmergency(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, Widget child) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: (textTheme.labelMedium ?? const TextStyle()).copyWith(
              color: ContigoColors.inkMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  void _confirmExit() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Salir del plan?'),
        content: const Text(
          'Tu plan estará disponible cuando lo necesites, incluso sin conexión.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.goNamed(AppRoute.pcsHome);
            },
            child: const Text('Salir'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Seguir con el plan'),
          ),
        ],
      ),
    );
  }

  void _showHelpLine(BuildContext context) {
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
              Text('Línea de ayuda', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                'Esta opción conecta con una línea de atención. El número lo '
                'configura el equipo clínico. En esta demostración no se realiza '
                'ninguna llamada.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ContigoButton(
                label: 'Entendido',
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
  void _showContactOptions(BuildContext context) {
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
              Text('Contactar', style: textTheme.titleLarge),
              const SizedBox(height: 16),
              ContigoButton(
                label: 'Enviar un mensaje',
                fullWidth: true,
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
              const SizedBox(height: 10),
              ContigoButton(
                label: 'Llamar',
                variant: ContigoButtonVariant.secondary,
                fullWidth: true,
                icon: const Icon(Icons.call_outlined),
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
              const SizedBox(height: 10),
              ContigoButton(
                label: 'Ahora no',
                variant: ContigoButtonVariant.tertiary,
                fullWidth: true,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
  void _showEmergency(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Llamar a emergencias'),
        content: const Text(
          'Esta llamada conecta con el servicio de emergencias. El número lo '
          'configura el equipo clínico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Llamar a emergencias'),
          ),
        ],
      ),
    );
  }
}

class _SelfHelpCard extends StatelessWidget {
  const _SelfHelpCard({
    required this.step,
    required this.totalSteps,
    required this.onOpenSkill,
    required this.onChooseOther,
    required this.onCannotNow,
  });

  final int step;
  final int totalSteps;
  final VoidCallback onOpenSkill;
  final VoidCallback onChooseOther;
  final VoidCallback onCannotNow;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ContigoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paso $step de $totalSteps',
            style: (textTheme.labelMedium ?? const TextStyle()).copyWith(
              color: ContigoColors.terracotta,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text('Prueba una habilidad que elegiste', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text('Respiración pausada', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Ve a tu ritmo. Puedes detenerte cuando lo necesites.',
            style: (textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
          const SizedBox(height: 14),
          ContigoButton(
            label: 'Abrir esta habilidad',
            fullWidth: true,
            onPressed: onOpenSkill,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ContigoButton(
                  label: 'Elegir otra opción',
                  variant: ContigoButtonVariant.secondary,
                  small: true,
                  fullWidth: true,
                  onPressed: onChooseOther,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ContigoButton(
                  label: 'No puedo ahora',
                  variant: ContigoButtonVariant.ghost,
                  small: true,
                  fullWidth: true,
                  onPressed: onCannotNow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ContigoColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ContigoColors.notifMeetingBg),
      ),
      child: Text(text, style: textTheme.bodyMedium),
    );
  }
}

class _MutedBox extends StatelessWidget {
  const _MutedBox(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ContigoColors.notifReminderBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
          color: ContigoColors.inkMuted,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.name,
    required this.label,
    required this.onContact,
  });
  final String name;
  final String label;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ContigoColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ContigoColors.notifMeetingBg),
      ),
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
                Text(name, style: textTheme.titleSmall),
                Text(
                  label,
                  style: (textTheme.bodySmall ?? const TextStyle())
                      .copyWith(color: ContigoColors.inkMuted),
                ),
              ],
            ),
          ),
          ContigoButton(
            label: 'Contactar',
            variant: ContigoButtonVariant.secondary,
            small: true,
            onPressed: onContact,
          ),
        ],
      ),
    );
  }
}