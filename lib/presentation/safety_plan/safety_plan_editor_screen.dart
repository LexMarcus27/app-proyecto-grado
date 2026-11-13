import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/safety_plan/safety_plan_draft.dart';
import '../widgets/widgets.dart';
import 'safety_plan_controller.dart';

/// Editor del plan de seguridad ("Mi plan de seguridad"), portado de
/// `MobileScreen05` (`src/screens/mobile.tsx`).
///
/// Edita el [SafetyPlanDraft] de sesión: pasos (texto por paso), contactos de
/// apoyo, actividades y entorno más seguro. La importación de contactos es una
/// Funcion_Simulada (permisos fingidos, sin agregar contactos reales) y muestra
/// el indicador de simulación persistente (Requirement 7.4, 3.4). El borrador no
/// se persiste en disco (Requirement 7.1, 7.5).
class SafetyPlanEditorScreen extends ConsumerWidget {
  const SafetyPlanEditorScreen({super.key});

  /// Metadato de capa de la importación de contactos: simulada.
  static const FeatureLayerInfo contactsLayer = FeatureLayerInfo(
    featureId: 'contacts-import',
    layer: FeatureLayer.simulada,
    label:
        'Importación de contactos simulada: no se accede a tus contactos '
        'reales ni se agrega ninguno real.',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final planAsync = ref.watch(safetyPlanControllerProvider);

    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: planAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('No se pudo cargar el plan: $e')),
          data: (plan) => _EditorBody(plan: plan, textTheme: textTheme),
        ),
      ),
    );
  }
}

class _EditorBody extends ConsumerWidget {
  const _EditorBody({required this.plan, required this.textTheme});

  final SafetyPlanDraft plan;
  final TextTheme textTheme;

  SafetyPlanController _controller(WidgetRef ref) =>
      ref.read(safetyPlanControllerProvider.notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StatusBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 20, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.goNamed(AppRoute.helpHub),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Volver a Necesito ayuda',
              ),
              Expanded(
                child: Text('Mi plan de seguridad', style: textTheme.titleLarge),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prepáralo cuando tengas calma. Podrás consultarlo incluso '
                  'sin conexión.',
                  style: (textTheme.bodyMedium ?? const TextStyle())
                      .copyWith(color: ContigoColors.inkMuted),
                ),
                if (safetyPlanHasInformation(plan)) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Información guardada en esta sesión',
                    style: (textTheme.bodySmall ?? const TextStyle())
                        .copyWith(color: ContigoColors.inkMuted),
                  ),
                ],
                const SizedBox(height: 20),
                // Pasos del plan.
                for (var i = 0; i < safetyPlanStepTitles.length; i++)
                  _StepTile(
                    index: i,
                    title: safetyPlanStepTitles[i],
                    text: plan.stepTexts[i],
                    onSave: (value) => _controller(ref).setStepText(i, value),
                  ),
                const SizedBox(height: 28),
                const Divider(height: 1),
                const SizedBox(height: 24),
                // Contactos (importación simulada).
                Text(
                  'Personas a quienes puedo pedir ayuda',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Estas personas aparecerán en tu plan cuando lo necesites.',
                  style: (textTheme.bodySmall ?? const TextStyle())
                      .copyWith(color: ContigoColors.inkMuted),
                ),
                const SizedBox(height: 12),
                SimulationIndicator.forFeature(
                  SafetyPlanEditorScreen.contactsLayer,
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < plan.contacts.length; i++)
                  _ContactTile(
                    contact: plan.contacts[i],
                    onRemove: () => _confirmRemoveContact(context, ref, i),
                  ),
                const SizedBox(height: 4),
                ContigoButton(
                  label: 'Agregar desde mis contactos',
                  variant: ContigoButtonVariant.secondary,
                  fullWidth: true,
                  icon: const Icon(Icons.person_add_alt),
                  onPressed: () => _importContacts(context, ref),
                ),
                const SizedBox(height: 28),
                const Divider(height: 1),
                const SizedBox(height: 24),
                // Actividades.
                Text(
                  'Actividades sociales que pueden ayudarme',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Agrega actividades sencillas que podrías hacer con otra '
                  'persona cuando necesites apoyo.',
                  style: (textTheme.bodySmall ?? const TextStyle())
                      .copyWith(color: ContigoColors.inkMuted),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < plan.activities.length; i++)
                  _ActivityTile(
                    activity: plan.activities[i],
                    onRemove: () => _controller(ref).removeActivity(i),
                  ),
                const SizedBox(height: 4),
                ContigoButton(
                  label: 'Agregar actividad',
                  variant: ContigoButtonVariant.secondary,
                  fullWidth: true,
                  icon: const Icon(Icons.add),
                  onPressed: () => _addActivity(context, ref),
                ),
                const SizedBox(height: 28),
                const Divider(height: 1),
                const SizedBox(height: 24),
                // Entorno.
                Text(
                  'Cómo puedo hacer mi entorno más seguro',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Escribe acciones concretas que te ayuden a reducir riesgos '
                  'en tu entorno.',
                  style: (textTheme.bodySmall ?? const TextStyle())
                      .copyWith(color: ContigoColors.inkMuted),
                ),
                const SizedBox(height: 12),
                _EnvironmentField(
                  value: plan.environment,
                  onSave: (value) => _controller(ref).setEnvironment(value),
                ),
              ],
            ),
          ),
        ),
        // Botón inferior fijo.
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: ContigoColors.surface,
            border: Border(top: BorderSide(color: ContigoColors.notifMeetingBg)),
          ),
          child: ContigoButton(
            label: 'Usar mi plan ahora',
            fullWidth: true,
            onPressed: () => context.goNamed(AppRoute.crisisMode),
          ),
        ),
      ],
    );
  }

  Future<void> _importContacts(BuildContext context, WidgetRef ref) async {
    final granted = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _ContactPermissionSheet(),
    );
    if (granted != true) return;
    final service = ref.read(contactsServiceProvider);
    final ok = await service.requestPermission();
    if (!ok) return;
    final contacts = await service.importContacts();
    for (final contact in contacts) {
      await _controller(ref).addContact(contact);
    }
  }

  Future<void> _confirmRemoveContact(
    BuildContext context,
    WidgetRef ref,
    int index,
  ) async {
    final contact = plan.contacts[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Quitar esta persona?'),
        content: Text(
          '${contact.name} ya no aparecerá en tu plan de apoyo. Puedes volver '
          'a agregarla cuando quieras.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _controller(ref).removeContact(index);
  }

  Future<void> _addActivity(BuildContext context, WidgetRef ref) async {
    final value = await _promptText(
      context,
      title: 'Agregar actividad',
      hint: 'Ej: Salir a caminar juntos',
    );
    if (value != null && value.trim().isNotEmpty) {
      await _controller(ref).addActivity(value);
    }
  }
}

Future<String?> _promptText(
  BuildContext context, {
  required String title,
  required String hint,
  String initial = '',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(controller.text),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

class _StepTile extends StatefulWidget {
  const _StepTile({
    required this.index,
    required this.title,
    required this.text,
    required this.onSave,
  });

  final int index;
  final String title;
  final String text;
  final ValueChanged<String> onSave;

  @override
  State<_StepTile> createState() => _StepTileState();
}

class _StepTileState extends State<_StepTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final filled = widget.text.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: ContigoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ContigoColors.notifMeetingBg),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _StepBadge(filled: filled, number: widget.index + 1),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.title, style: textTheme.titleSmall),
                  ),
                  Flexible(
                    child: Text(
                      filled ? 'Completo' : 'Falta por diligenciar',
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (textTheme.bodySmall ?? const TextStyle()).copyWith(
                        color: filled
                            ? ContigoColors.sage
                            : ContigoColors.notifClosenessAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: ContigoColors.inkMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filled
                        ? widget.text
                        : 'Este paso aún no tiene información guardada.',
                    style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                      color: filled
                          ? ContigoColors.ink
                          : ContigoColors.inkMuted,
                      fontStyle: filled ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ContigoButton(
                    label: 'Editar',
                    variant: ContigoButtonVariant.secondary,
                    small: true,
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final value = await _promptText(
                        context,
                        title: widget.title,
                        hint: 'Escribe aquí lo que quieras recordar...',
                        initial: widget.text,
                      );
                      if (value != null) widget.onSave(value);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.filled, required this.number});

  final bool filled;
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: filled
            ? ContigoColors.notifReminderBg
            : ContigoColors.notifClosenessBg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: filled
          ? const Icon(Icons.check, size: 16, color: ContigoColors.sage)
          : Text(
              '$number',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ContigoColors.notifClosenessAccent,
              ),
            ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact, required this.onRemove});

  final SafetyPlanContact contact;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                Text(contact.name, style: textTheme.titleSmall),
                Text(
                  '${contact.label} · ${contact.phone}',
                  style: (textTheme.bodySmall ?? const TextStyle())
                      .copyWith(color: ContigoColors.inkMuted),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onRemove, child: const Text('Quitar')),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, required this.onRemove});

  final String activity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: ContigoColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ContigoColors.notifMeetingBg),
      ),
      child: Row(
        children: [
          Expanded(child: Text(activity, style: textTheme.bodyMedium)),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Eliminar actividad $activity',
            color: ContigoColors.clay,
          ),
        ],
      ),
    );
  }
}

class _EnvironmentField extends StatefulWidget {
  const _EnvironmentField({required this.value, required this.onSave});

  final String value;
  final ValueChanged<String> onSave;

  @override
  State<_EnvironmentField> createState() => _EnvironmentFieldState();
}

class _EnvironmentFieldState extends State<_EnvironmentField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);
  late bool _saved = widget.value.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          minLines: 3,
          maxLines: 6,
          onChanged: (_) => setState(() => _saved = false),
          decoration: const InputDecoration(
            filled: true,
            fillColor: ContigoColors.surface,
            hintText: '[[Acciones por validar con el equipo clínico]]',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Solo tú puedes ver y editar esta información.',
          style: (textTheme.bodySmall ?? const TextStyle())
              .copyWith(color: ContigoColors.inkMuted),
        ),
        const SizedBox(height: 10),
        if (_saved)
          Row(
            children: const [
              Icon(Icons.check, size: 16, color: ContigoColors.sage),
              SizedBox(width: 6),
              Text(
                'Guardado',
                style: TextStyle(
                  color: ContigoColors.sage,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          )
        else
          ContigoButton(
            label: 'Guardar',
            variant: ContigoButtonVariant.secondary,
            small: true,
            onPressed: _controller.text.trim().isEmpty
                ? null
                : () {
                    widget.onSave(_controller.text);
                    setState(() => _saved = true);
                  },
          ),
      ],
    );
  }
}

/// Hoja de permiso de contactos (portada del `BottomSheet` del prototipo).
/// Devuelve `true` si el usuario permite el acceso simulado.
class _ContactPermissionSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Acceder a tus contactos', style: textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            'Para agregar personas de confianza a tu plan, necesitamos acceder '
            'a tus contactos del dispositivo. Solo verás la lista de contactos '
            'para elegir a quién agregar. No se comparte nada de forma '
            'automática.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Solo se usa para mostrarte los contactos. No se accede a mensajes '
            'ni datos adicionales.',
            style: (textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
          const SizedBox(height: 16),
          ContigoButton(
            label: 'Permitir acceso',
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 10),
          ContigoButton(
            label: 'No permitir',
            variant: ContigoButtonVariant.tertiary,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}