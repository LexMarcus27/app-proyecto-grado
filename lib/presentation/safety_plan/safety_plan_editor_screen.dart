import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/safety_plan/safety_plan_draft.dart';
import '../widgets/widgets.dart';
import 'safety_plan_controller.dart';

/// Editor del plan de seguridad ("Mi plan de seguridad"), portado de
/// `MobileScreen05` (`src/screens/mobile.tsx`) con la propuesta visual M5.
///
/// - Tarjeta de cabecera con planta y progreso de los cuatro pasos.
/// - Los **cuatro pasos** comparten un mismo formato: fila con estado
///   («Completo» / «Falta por diligenciar»), resumen y lápiz; cada uno se edita
///   en la misma hoja inferior («PASO n DE 4»).
/// - Personas de apoyo (importación simulada), actividades sociales y entorno
///   más seguro en tarjetas con ícono y título serif.
///
/// Edita el [SafetyPlanDraft] de sesión. La importación de contactos es una
/// Funcion_Simulada (permisos fingidos, sin agregar contactos reales) y lo
/// indica bajo el botón (Requirement 7.4, 3.4). El borrador no se persiste en
/// disco (Requirement 7.1, 7.5).
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
    final planAsync = ref.watch(safetyPlanControllerProvider);

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        child: planAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('No se pudo cargar el plan: $e')),
          data: (plan) => _EditorBody(plan: plan),
        ),
      ),
    );
  }
}

// Paleta de la propuesta M5.
const Color _canvas = Color(0xFFFAF7F3);
const Color _accent = ContigoColors.terracotta;
const Color _peach = Color(0xFFFCE9DC);
const Color _peachBorder = Color(0xFFE8C2AA);
const Color _border = Color(0xFFE8DFD5);
const Color _done = ContigoColors.sage;
const Color _doneSoft = Color(0xFFE3ECDF);
const Color _pending = Color(0xFF805C1D);
const Color _pendingSoft = Color(0xFFF8ECD4);

const TextStyle _muted = TextStyle(
  fontSize: 14,
  height: 20 / 14,
  color: ContigoColors.inkMuted,
);

class _EditorBody extends ConsumerWidget {
  const _EditorBody({required this.plan});

  final SafetyPlanDraft plan;

  SafetyPlanController _controller(WidgetRef ref) =>
      ref.read(safetyPlanControllerProvider.notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = [
      for (final text in plan.stepTexts) text.trim().isNotEmpty,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StatusBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ResourceCircleButton(
                      icon: Icons.arrow_back,
                      tooltip: 'Volver a Necesito ayuda',
                      onPressed: () => context.goBack(AppRoute.helpHub),
                    ),
                    const SizedBox(width: 12),
                    const Flexible(
                      child: ResourceChip(
                        label: 'Necesito ayuda',
                        icon: Icons.support,
                        palette: ResourcePalette.plan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _HeroCard(
                  completed: completed,
                  hasInformation: safetyPlanHasInformation(plan),
                ),
                const SizedBox(height: 16),
                // Los cuatro pasos, con el mismo formato.
                _StepsCard(
                  plan: plan,
                  onEdit: (i) => _editStep(context, ref, i),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: Icons.people_outline,
                  title: 'Personas a quienes puedo pedir ayuda',
                  description:
                      'Estas personas aparecerán en tu plan cuando lo necesites.',
                  children: [
                    for (var i = 0; i < plan.contacts.length; i++) ...[
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF0E8E0)),
                      _ContactRow(
                        index: i,
                        contact: plan.contacts[i],
                        onRemove: () => _confirmRemoveContact(context, ref, i),
                      ),
                    ],
                    if (plan.contacts.isNotEmpty)
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF0E8E0)),
                    const SizedBox(height: 14),
                    _DashedAction(
                      icon: Icons.people_outline,
                      label: 'Agregar desde mis contactos',
                      onPressed: () => _importContacts(context, ref),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      SafetyPlanEditorScreen.contactsLayer.label ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 18 / 13,
                        color: ContigoColors.inkMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: Icons.favorite_border,
                  title: 'Actividades sociales que pueden ayudarme',
                  description:
                      'Agrega actividades sencillas que podrías hacer con otra '
                      'persona cuando necesites apoyo.',
                  children: [
                    if (plan.activities.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < plan.activities.length; i++)
                            _ActivityChip(
                              activity: plan.activities[i],
                              onRemove: () => _controller(ref).removeActivity(i),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                    _DashedAction(
                      icon: Icons.add,
                      label: 'Agregar actividad',
                      onPressed: () => _addActivity(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  icon: Icons.shield_outlined,
                  title: 'Cómo puedo hacer mi entorno más seguro',
                  description:
                      'Escribe acciones concretas que te ayuden a reducir '
                      'riesgos en tu entorno.',
                  children: [
                    _EnvironmentField(
                      value: plan.environment,
                      onSave: (value) => _controller(ref).setEnvironment(value),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Botón inferior fijo.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: _canvas,
            border: Border(top: BorderSide(color: Color(0xFFEDE5DC))),
          ),
          child: ResourcePillButton(
            label: 'Usar mi plan ahora',
            leadingIcon: Icons.support,
            color: _accent,
            onPressed: () => context.pushNamed(AppRoute.crisisMode),
          ),
        ),
      ],
    );
  }

  Future<void> _editStep(BuildContext context, WidgetRef ref, int index) async {
    final value = await showPlanTextSheet(
      context,
      overline: 'Paso ${index + 1} de ${safetyPlanStepTitles.length}',
      title: safetyPlanStepTitles[index],
      initial: plan.stepTexts[index],
      completed: plan.stepTexts[index].trim().isNotEmpty,
      step: index + 1,
      hint: 'Escribe aquí lo que quieras recordar...',
    );
    if (value != null) await _controller(ref).setStepText(index, value);
  }

  Future<void> _importContacts(BuildContext context, WidgetRef ref) async {
    final granted = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
        backgroundColor: Colors.white,
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
    final value = await showPlanTextSheet(
      context,
      overline: 'Actividad social',
      title: 'Agregar actividad',
      hint: 'Ej: Salir a caminar juntos',
      multiline: false,
    );
    if (value != null && value.trim().isNotEmpty) {
      await _controller(ref).addActivity(value);
    }
  }
}

/// Hoja inferior común para escribir en el plan (propuesta M5): estado del
/// paso, sobretítulo («PASO 1 DE 4»), título serif, campo de texto, nota de
/// privacidad y «Guardar» / «Cancelar». Devuelve el texto guardado o `null` si
/// se cancela.
Future<String?> showPlanTextSheet(
  BuildContext context, {
  required String overline,
  required String title,
  required String hint,
  String initial = '',
  bool completed = false,
  int? step,
  bool multiline = true,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => _PlanTextSheet(
      overline: overline,
      title: title,
      hint: hint,
      initial: initial,
      completed: completed,
      step: step,
      multiline: multiline,
    ),
  );
}

class _PlanTextSheet extends StatefulWidget {
  const _PlanTextSheet({
    required this.overline,
    required this.title,
    required this.hint,
    required this.initial,
    required this.completed,
    required this.step,
    required this.multiline,
  });

  final String overline;
  final String title;
  final String hint;
  final String initial;
  final bool completed;
  final int? step;
  final bool multiline;

  @override
  State<_PlanTextSheet> createState() => _PlanTextSheetState();
}

class _PlanTextSheetState extends State<_PlanTextSheet> {
  // El controlador vive en el estado de la hoja: se libera al desmontarla,
  // nunca mientras aún se anima al cerrarse.
  late final TextEditingController _text =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (widget.step != null) ...[
                _StepStatusIcon(completed: widget.completed, step: widget.step!),
                const SizedBox(width: 12),
              ],
              Text(
                widget.overline.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: _accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.title,
            style: resourceSerif.copyWith(fontSize: 25, height: 31 / 25),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            autofocus: true,
            minLines: widget.multiline ? 4 : 1,
            maxLines: widget.multiline ? 8 : 1,
            style: resourceBody,
            decoration: InputDecoration(
              hintText: widget.hint,
              filled: true,
              fillColor: _canvas,
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFD9CDC2), width: 1.3),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: _done, width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const _PrivacyLine(),
          const SizedBox(height: 18),
          ResourcePillButton(
            label: 'Guardar',
            color: _accent,
            onPressed: () => Navigator.of(context).pop(_text.text),
          ),
          const SizedBox(height: 10),
          ResourcePillButton(
            label: 'Cancelar',
            color: _accent,
            outlined: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// «Solo tú puedes ver y editar esta información» con candado.
class _PrivacyLine extends StatelessWidget {
  const _PrivacyLine();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.lock_outline, size: 16, color: ContigoColors.inkMuted),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Solo tú puedes ver y editar esta información.',
            style: TextStyle(fontSize: 13, height: 18 / 13, color: ContigoColors.inkMuted),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de cabecera: título serif, planta, progreso de los cuatro pasos y
/// estado de guardado.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.completed, required this.hasInformation});

  final List<bool> completed;
  final bool hasInformation;

  @override
  Widget build(BuildContext context) {
    final done = completed.where((c) => c).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            top: -14,
            right: -20,
            child: HomePlant(width: 96, height: 90),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 70),
                child: Text(
                  'Mi plan de seguridad',
                  style: resourceSerif.copyWith(fontSize: 32, height: 37 / 32),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Prepáralo cuando tengas calma. Podrás consultarlo incluso '
                'sin conexión.',
                style: TextStyle(
                  fontSize: 15,
                  height: 22 / 15,
                  color: ContigoColors.inkMuted,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: '$done de ${completed.length} pasos completos',
                excludeSemantics: true,
                child: SizedBox(
                  height: 24,
                  width: 170,
                  child: CustomPaint(painter: _StepsProgressPainter(completed)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                hasInformation
                    ? 'Información guardada en esta sesión'
                    : 'Aún no hay información en tu plan',
                style: _muted.copyWith(fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Progreso de los cuatro pasos: nodo relleno si el paso está completo, anillo
/// en el primer paso pendiente y nodos huecos en los demás.
class _StepsProgressPainter extends CustomPainter {
  _StepsProgressPainter(this.completed);

  final List<bool> completed;

  @override
  void paint(Canvas canvas, Size size) {
    final n = completed.length;
    if (n < 2) return;
    const inset = 8.0;
    final y = size.height / 2;
    final step = (size.width - inset * 2) / (n - 1);
    Offset node(int i) => Offset(inset + step * i, y);
    final current = completed.indexWhere((c) => !c);

    for (var i = 0; i < n - 1; i++) {
      final a = node(i);
      final b = node(i + 1);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo((a.dx + b.dx) / 2, y + (i.isEven ? -4 : 4), b.dx, b.dy);
      if (completed[i] && (completed[i + 1] || i + 1 == current)) {
        canvas.drawPath(
          path,
          Paint()
            ..color = _done
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
      } else {
        final dots = Paint()
          ..color = _peachBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        for (final metric in path.computeMetrics()) {
          for (var d = 6.0; d < metric.length - 6; d += 5) {
            canvas.drawPath(metric.extractPath(d, d + 0.1), dots);
          }
        }
      }
    }
    for (var i = 0; i < n; i++) {
      final c = node(i);
      if (completed[i]) {
        canvas.drawCircle(c, 5, Paint()..color = _done);
      } else if (i == current) {
        canvas.drawCircle(c, 8.5, Paint()..color = Colors.white);
        canvas.drawCircle(
          c,
          8.5,
          Paint()
            ..color = _done
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );
        canvas.drawCircle(c, 3.5, Paint()..color = _done);
      } else {
        canvas.drawCircle(c, 5, Paint()..color = Colors.white);
        canvas.drawCircle(
          c,
          5,
          Paint()
            ..color = _peachBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StepsProgressPainter old) => true;
}

/// Tarjeta con los cuatro pasos del plan, uno por fila.
class _StepsCard extends StatelessWidget {
  const _StepsCard({required this.plan, required this.onEdit});

  final SafetyPlanDraft plan;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: _border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < safetyPlanStepTitles.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF0E8E0)),
            _StepRow(
              step: i + 1,
              title: safetyPlanStepTitles[i],
              text: plan.stepTexts[i],
              onEdit: () => onEdit(i),
            ),
          ],
        ],
      ),
    );
  }
}

/// Fila de un paso: estado, título, etiqueta, resumen y lápiz. Toda la fila
/// abre la hoja de edición del paso.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.title,
    required this.text,
    required this.onEdit,
  });

  final int step;
  final String title;
  final String text;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final completed = text.trim().isNotEmpty;
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepStatusIcon(completed: completed, step: step),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 6),
                  _StatusChip(completed: completed),
                  if (completed) ...[
                    const SizedBox(height: 8),
                    Text(text, style: _muted),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar: $title',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20, color: _accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ícono de estado del paso: ✓ relleno si está completo; número en anillo si
/// falta.
class _StepStatusIcon extends StatelessWidget {
  const _StepStatusIcon({required this.completed, required this.step});

  final bool completed;
  final int step;

  @override
  Widget build(BuildContext context) {
    if (completed) {
      return Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(color: _done, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 18, color: Colors.white),
      );
    }
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _peachBorder, width: 1.8),
      ),
      child: Text(
        '$step',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: _pending,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: completed ? _doneSoft : _pendingSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        completed ? 'Completo' : 'Falta por diligenciar',
        style: TextStyle(
          fontSize: 12,
          height: 17 / 12,
          fontWeight: FontWeight.w700,
          color: completed ? _done : _pending,
        ),
      ),
    );
  }
}

/// Tarjeta de sección: ícono en círculo melocotón, título serif y descripción.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: _peach, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: _accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: resourceSerif.copyWith(fontSize: 21, height: 26 / 21),
                    ),
                    const SizedBox(height: 6),
                    Text(description, style: _muted),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.index,
    required this.contact,
    required this.onRemove,
  });

  final int index;
  final SafetyPlanContact contact;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          HomeAvatar(index: index == 0 ? 0 : 3, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ContigoColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text('${contact.label} · ${contact.phone}', style: _muted.copyWith(fontSize: 13)),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _accent,
              textStyle: const TextStyle(
                fontFamily: ContigoTheme.bodyFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: onRemove,
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
  }
}

/// Actividad en pastilla melocotón con ✕ para quitarla.
class _ActivityChip extends StatelessWidget {
  const _ActivityChip({required this.activity, required this.onRemove});

  final String activity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: _peach,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              activity,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ContigoColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Eliminar actividad $activity',
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const SizedBox(
                  width: 30,
                  height: 30,
                  child: Icon(Icons.close, size: 16, color: _accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Acción secundaria con borde punteado en pastilla.
class _DashedAction extends StatelessWidget {
  const _DashedAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      color: _peachBorder,
      radius: 999,
      child: Material(
        color: Colors.transparent,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: _accent),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          minLines: 4,
          maxLines: 8,
          style: resourceBody,
          onChanged: (_) => setState(() => _saved = false),
          decoration: InputDecoration(
            filled: true,
            fillColor: _canvas,
            hintText: '[[Acciones por validar con el equipo clínico]]',
            contentPadding: const EdgeInsets.all(16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFD9CDC2), width: 1.3),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: _done, width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(child: _PrivacyLine()),
            const SizedBox(width: 12),
            if (_saved)
              const Row(
                children: [
                  Icon(Icons.check, size: 16, color: _done),
                  SizedBox(width: 6),
                  Text(
                    'Guardado',
                    style: TextStyle(
                      color: _done,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            else
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  disabledBackgroundColor: _accent.withValues(alpha: 0.4),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  textStyle: const TextStyle(
                    fontFamily: ContigoTheme.bodyFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: _controller.text.trim().isEmpty
                    ? null
                    : () {
                        widget.onSave(_controller.text);
                        setState(() => _saved = true);
                      },
                child: const Text('Guardar'),
              ),
          ],
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
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: _peach, shape: BoxShape.circle),
                child: const Icon(Icons.people_outline, size: 20, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Acceder a tus contactos',
                  style: resourceSerif.copyWith(fontSize: 24, height: 30 / 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Para agregar personas de confianza a tu plan, necesitamos acceder '
            'a tus contactos del dispositivo. Solo verás la lista de contactos '
            'para elegir a quién agregar. No se comparte nada de forma '
            'automática.',
            style: resourceBody,
          ),
          const SizedBox(height: 12),
          const Text(
            'Solo se usa para mostrarte los contactos. No se accede a mensajes '
            'ni datos adicionales.',
            style: _muted,
          ),
          const SizedBox(height: 18),
          ResourcePillButton(
            label: 'Permitir acceso',
            color: _accent,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 10),
          ResourcePillButton(
            label: 'No permitir',
            color: _accent,
            outlined: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
