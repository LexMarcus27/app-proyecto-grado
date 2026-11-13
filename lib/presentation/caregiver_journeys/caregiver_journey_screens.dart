import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/journey/caregiver.dart';
import '../authorization/gating.dart';
import '../widgets/widgets.dart';
import 'caregiver_journeys_content.dart';
import 'caregiver_journeys_controller.dart';

/// Envoltura común de los recorridos del cuidador dependientes de asociación
/// (tarea 3.19). Aplica el **gating por Asociacion_Activa** (Requirement 8.1,
/// 8.2): si no hay vínculo vigente (tupla válida), bloquea el recorrido
/// conservando el estado y muestra un aviso, en vez de su contenido. Deriva el
/// nombre del PCS del contexto de cuidado.
class _CaregiverGatedScaffold extends ConsumerWidget {
  const _CaregiverGatedScaffold({
    required this.title,
    required this.builder,
    this.fromConnections = false,
  });

  final String title;

  /// `true` para los recursos que se abren desde «Tejiendo vínculos» (M23):
  /// la flecha vuelve a ese hub en lugar del inicio, como en el prototipo.
  final bool fromConnections;
  final Widget Function(BuildContext context, CaregiverContext careContext)
      builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final gatingAsync = ref.watch(careGatingProvider);

    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.goNamed(
                      fromConnections
                          ? AppRoute.caregiverConnections
                          : AppRoute.caregiverHome,
                    ),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: fromConnections
                        ? 'Volver a Tejiendo vínculos'
                        : 'Volver al inicio del cuidador',
                  ),
                  Expanded(child: Text(title, style: textTheme.titleLarge)),
                ],
              ),
            ),
            Expanded(
              child: gatingAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
                data: (gating) {
                  final careContext = gating.contextFor(DemoCaregiver.id);
                  if (careContext == null) {
                    return _BlockedByAssociation(textTheme: textTheme);
                  }
                  return builder(context, careContext);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aviso de bloqueo cuando no hay Asociacion_Activa válida. Conserva el estado:
/// no borra nada, solo impide la acción (Requirement 10.4, 10.5).
class _BlockedByAssociation extends StatelessWidget {
  const _BlockedByAssociation({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Necesitas un vínculo activo', style: textTheme.titleMedium),
          const SizedBox(height: 10),
          Text(
            'No hay una asociación activa autorizada para esta cuenta. Una '
            'invitación aceptada por sí sola no habilita el plan, los mensajes '
            'ni los registros.',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Indicador de adjunto simulado (audio/foto) reutilizable.
Widget _simulatedAttachmentNote(BuildContext context) {
  return SimulationIndicator.forFeature(
    const FeatureLayerInfo(
      featureId: 'caregiver-attachments',
      layer: FeatureLayer.simulada,
      label:
          'Adjuntos simulados: la grabación de audio y la selección de foto son '
          'de demostración; no se captura ni se envía nada real.',
    ),
  );
}

// ─── Plan de acompañamiento (MobileScreen11) ────────────────────────────────

/// Plan de acompañamiento del cuidador: plan de ejemplo de solo lectura con un
/// modo "acompañar paso a paso" (checklist) y una simulación de llamada de
/// emergencia. Gated por Asociacion_Activa.
class CaregiverSupportPlanScreen extends StatelessWidget {
  const CaregiverSupportPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _CaregiverGatedScaffold(
      title: 'Plan de acompañamiento',
      builder: (context, careContext) =>
          _SupportPlanBody(pcsName: careContext.pcsName),
    );
  }
}

class _SupportPlanBody extends StatefulWidget {
  const _SupportPlanBody({required this.pcsName});
  final String pcsName;

  @override
  State<_SupportPlanBody> createState() => _SupportPlanBodyState();
}

class _SupportPlanBodyState extends State<_SupportPlanBody> {
  bool _checklist = false;
  final Set<int> _checked = <int>{};

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan de acompañamiento de ${widget.pcsName} · Solo lectura',
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Plan de ejemplo para revisar la interfaz. El contenido '
                  'compartido y sus permisos serán definidos por el equipo '
                  'investigador.',
                  style: (textTheme.bodySmall ?? const TextStyle())
                      .copyWith(color: ContigoColors.inkMuted),
                ),
                const SizedBox(height: 16),
                Text('Qué puede ayudarle ahora', style: textTheme.titleSmall),
                Text(
                  'Habilidades que ella eligió',
                  style: (textTheme.bodySmall ?? const TextStyle())
                      .copyWith(color: ContigoColors.inkMuted),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < caregiverPlanSteps.length; i++)
                  _planStep(context, i),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Text(
                  'Cómo ayudar a mantener un entorno seguro',
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _mutedBox(
                  context,
                  '[Lista proporcionada por el equipo clínico responsable]',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ContigoColors.notifMeetingBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Si hay peligro inmediato',
                        style: (textTheme.titleSmall ?? const TextStyle())
                            .copyWith(color: ContigoColors.clay),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sigue el protocolo indicado por el equipo responsable.',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      ContigoButton(
                        label: 'Llamar a emergencias',
                        variant: ContigoButtonVariant.critical,
                        small: true,
                        fullWidth: true,
                        onPressed: () => _emergency(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: ContigoColors.surface,
            border: Border(top: BorderSide(color: ContigoColors.notifMeetingBg)),
          ),
          child: ContigoButton(
            label: _checklist ? 'Ver plan completo' : 'Acompañar paso a paso',
            fullWidth: true,
            onPressed: () => setState(() => _checklist = !_checklist),
          ),
        ),
      ],
    );
  }

  Widget _planStep(BuildContext context, int i) {
    final textTheme = Theme.of(context).textTheme;
    final step = caregiverPlanSteps[i];
    if (!_checklist) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ContigoColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ContigoColors.notifMeetingBg),
        ),
        child: Text('${i + 1}. $step', style: textTheme.bodyMedium),
      );
    }
    final checked = _checked.contains(i);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(
          () => checked ? _checked.remove(i) : _checked.add(i),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: checked
                ? ContigoColors.notifReminderBg
                : ContigoColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: checked ? ContigoColors.sage : ContigoColors.notifMeetingBg,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                checked ? Icons.check_box : Icons.check_box_outline_blank,
                color: checked ? ContigoColors.sage : ContigoColors.inkMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(step, style: textTheme.bodyMedium)),
            ],
          ),
        ),
      ),
    );
  }

  void _emergency(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Llamar a emergencias'),
        content: const Text(
          'Esta es una simulación del recorrido de llamada. No se realiza '
          'ninguna llamada desde este prototipo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar simulación'),
          ),
        ],
      ),
    );
  }
}

Widget _mutedBox(BuildContext context, String text) {
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

// ─── Registro de vínculo / check-in diario (MobileScreen12) ─────────────────

/// Registro de vínculo del cuidador: formulario de prueba (contacto, calidad,
/// quién inició). El banco EMA del cuidador está pendiente de validación.
class CaregiverLinkCheckInScreen extends StatelessWidget {
  const CaregiverLinkCheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _CaregiverGatedScaffold(
      title: 'Registro de la relación',
      builder: (context, careContext) =>
          _LinkCheckInBody(pcsName: careContext.pcsName),
    );
  }
}

class _LinkCheckInBody extends ConsumerStatefulWidget {
  const _LinkCheckInBody({required this.pcsName});
  final String pcsName;

  @override
  ConsumerState<_LinkCheckInBody> createState() => _LinkCheckInBodyState();
}

class _LinkCheckInBodyState extends ConsumerState<_LinkCheckInBody> {
  /// Retorno automático al inicio tras guardar (`setTimeout(navigate(9),
  /// 2600)` del prototipo). Se cancela si la pantalla se desmonta antes.
  Timer? _returnTimer;

  @override
  void dispose() {
    _returnTimer?.cancel();
    super.dispose();
  }

  void _save(LinkCheckInController controller) {
    controller.markSaved();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Registro de prueba completado. No se ha enviado.'),
    ));
    _returnTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) context.goNamed(AppRoute.caregiverHome);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pcsName = widget.pcsName;
    final textTheme = Theme.of(context).textTheme;
    // El estado del registro se conserva por asociación (sobrevive a una
    // revocación y se recupera al reactivar la misma asociación); no vive en el
    // widget para que el bloqueo por gating no lo borre.
    final checkIn =
        ref.watch(currentLinkCheckInProvider) ?? const LinkCheckInState();
    final controller = ref.read(linkCheckInControllerProvider.notifier);

    if (checkIn.saved) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle,
                  color: ContigoColors.sage, size: 56),
              const SizedBox(height: 16),
              Text('Registro de prueba completado',
                  style: textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('No se ha enviado.',
                  style: (textTheme.bodyMedium ?? const TextStyle())
                      .copyWith(color: ContigoColors.inkMuted)),
              const SizedBox(height: 20),
              ContigoButton(
                label: 'Volver al inicio',
                variant: ContigoButtonVariant.secondary,
                onPressed: () => context.goNamed(AppRoute.caregiverHome),
              ),
            ],
          ),
        ),
      );
    }
    final hadYes = checkIn.hadContact == 'si';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cómo está el tejido con $pcsName ahora?',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Formulario de prueba. El banco EMA del cuidador está pendiente de '
            'validación por el equipo investigador.',
            style: (textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
          const SizedBox(height: 20),
          Text('¿Tuviste contacto con $pcsName hoy?',
              style: textTheme.titleSmall),
          const SizedBox(height: 10),
          _choiceRow(
            options: const ['si', 'no', 'prefiero'],
            labels: const ['Sí', 'No', 'Prefiero no responder'],
            selected: checkIn.hadContact,
            onSelect: controller.setHadContact,
          ),
          if (hadYes) ...[
            const SizedBox(height: 20),
            Text('¿Cómo calificarías la calidad de la interacción?',
                style: textTheme.titleSmall),
            const SizedBox(height: 10),
            _scaleRow(
              min: 'Difícil',
              max: 'Muy bien',
              count: 5,
              selected: checkIn.quality,
              onSelect: controller.setQuality,
            ),
            const SizedBox(height: 20),
            Text('¿Quién inició el contacto?', style: textTheme.titleSmall),
            const SizedBox(height: 10),
            _choiceRow(
              options: const ['yo', 'otro', 'ambos'],
              labels: ['Yo', pcsName, 'Ambos'],
              selected: checkIn.initiator,
              onSelect: controller.setInitiator,
            ),
          ],
          const SizedBox(height: 24),
          ContigoButton(
            label: 'Completar registro de prueba',
            fullWidth: true,
            onPressed: checkIn.hadContact == null
                ? null
                : () => _save(controller),
          ),
          const SizedBox(height: 10),
          ContigoButton(
            label: 'Completar después',
            variant: ContigoButtonVariant.tertiary,
            fullWidth: true,
            onPressed: () => context.goNamed(AppRoute.caregiverHome),
          ),
        ],
      ),
    );
  }
}
// ─── Evaluación de encuentros (MobileScreen09A) ─────────────────────────────

/// Evaluación de un encuentro con el PCS: puntuación 1–7 y tres enunciados
/// adicionales; la escala y las etiquetas están pendientes de validación.
class CaregiverEncounterScreen extends StatelessWidget {
  const CaregiverEncounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _CaregiverGatedScaffold(
      title: 'Registrar encuentro',
      fromConnections: true,
      builder: (context, careContext) =>
          _EncounterBody(pcsName: careContext.pcsName),
    );
  }
}

class _EncounterBody extends ConsumerWidget {
  const _EncounterBody({required this.pcsName});
  final String pcsName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    // El estado se conserva por contexto completo (sobrevive a una revocación y
    // se recupera al reactivar la misma asociación); no vive en el widget.
    final encounter =
        ref.watch(currentEncounterProvider) ?? EncounterState();
    final controller = ref.read(encounterControllerProvider.notifier);

    if (encounter.saved) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle,
                  color: ContigoColors.sage, size: 56),
              const SizedBox(height: 16),
              Text('Registro de prueba completado',
                  style: textTheme.titleMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Encuentro con $pcsName', style: textTheme.titleMedium),
          const SizedBox(height: 16),
          Text(
            '¿Puedes puntuar la interacción que tuviste con $pcsName?',
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Escala y etiquetas por validar con el equipo investigador',
            style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
              color: ContigoColors.inkMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          _scaleRow(
            min: '[[Mín.]]',
            max: '[[Máx.]]',
            count: 7,
            selected: encounter.rating,
            onSelect: controller.setRating,
          ),
          const SizedBox(height: 24),
          Text('Valoración adicional', style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Opciones de respuesta por validar con el equipo investigador',
            style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
              color: ContigoColors.inkMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          for (var qi = 0; qi < encounterStatements.length; qi++) ...[
            Text(encounterStatements[qi], style: textTheme.bodyMedium),
            const SizedBox(height: 8),
            _scaleRow(
              min: '',
              max: '',
              count: 5,
              selected: encounter.additional[qi],
              onSelect: (n) => controller.setAdditional(qi, n),
            ),
            const SizedBox(height: 18),
          ],
          ContigoButton(
            label: 'Guardar registro',
            fullWidth: true,
            onPressed: encounter.allAnswered ? controller.markSaved : null,
          ),
        ],
      ),
    );
  }
}
// ─── Preguntas para conectar (MobileScreen14) ───────────────────────────────

/// Recorrido de "Preguntas para conectar": una pregunta sugerida con respuesta
/// de texto, audio o foto (adjuntos simulados). "Ver otra" rota las preguntas.
class CaregiverConnectionQuestionsScreen extends StatelessWidget {
  const CaregiverConnectionQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _CaregiverGatedScaffold(
      title: 'Preguntas para conectar',
      fromConnections: true,
      builder: (context, careContext) =>
          _ConnectionQuestionsBody(otherName: careContext.pcsName),
    );
  }
}

class _ConnectionQuestionsBody extends ConsumerStatefulWidget {
  const _ConnectionQuestionsBody({required this.otherName});
  final String otherName;

  @override
  ConsumerState<_ConnectionQuestionsBody> createState() =>
      _ConnectionQuestionsBodyState();
}

class _ConnectionQuestionsBodyState
    extends ConsumerState<_ConnectionQuestionsBody> {
  // El controlador del campo refleja el texto del estado de sesión; el estado
  // vive en el provider (aislado por contexto completo), no en el widget, para
  // que el bloqueo por revocación no lo borre y se recupere al reactivar.
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Sincroniza el texto visible con el del estado (recupera al reactivar,
  /// limpia al cambiar de pregunta) sin romper el cursor mientras se escribe.
  void _syncText(String text) {
    if (_textController.text != text) {
      _textController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final questions =
        ref.watch(currentConnectionQuestionsProvider) ??
            const ConnectionQuestionsState();
    final controller =
        ref.read(connectionQuestionsControllerProvider.notifier);
    final total = connectionQuestions.length;
    _syncText(questions.text);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Una conversación entre tú y ${widget.otherName}',
            style: (textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
          const SizedBox(height: 12),
          ContigoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pregunta sugerida', style: textTheme.labelMedium),
                    TextButton(
                      onPressed: () =>
                          controller.reset(questions.index + 1, total),
                      child: const Text('Ver otra'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(connectionQuestions[questions.index],
                    style: textTheme.titleMedium),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('¿Cómo quieres responder?', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              _formatChip(questions, controller, ConnectionResponseFormat.text,
                  '✍️', 'Texto'),
              const SizedBox(width: 8),
              _formatChip(questions, controller,
                  ConnectionResponseFormat.audio, '🎙️', 'Audio'),
              const SizedBox(width: 8),
              _formatChip(questions, controller,
                  ConnectionResponseFormat.photo, '🖼️', 'Foto'),
            ],
          ),
          const SizedBox(height: 12),
          if (questions.format == ConnectionResponseFormat.text)
            TextField(
              controller: _textController,
              minLines: 3,
              maxLines: 6,
              onChanged: controller.setText,
              decoration: const InputDecoration(
                filled: true,
                fillColor: ContigoColors.surface,
                hintText: 'Escribe lo que quieras compartir...',
                border: OutlineInputBorder(),
              ),
            )
          else ...[
            _simulatedAttachmentNote(context),
            const SizedBox(height: 8),
            ContigoButton(
              label: questions.format == ConnectionResponseFormat.audio
                  ? (questions.attachment.isEmpty
                      ? 'Grabar audio'
                      : 'Volver a grabar')
                  : (questions.attachment.isEmpty
                      ? 'Elegir fotografía'
                      : 'Cambiar fotografía'),
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => controller.setAttachment(
                  questions.format == ConnectionResponseFormat.audio
                      ? 'Audio de 0:18 listo'
                      : 'Fotografía seleccionada'),
            ),
            if (questions.attachment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(questions.attachment,
                  style: (textTheme.bodySmall ?? const TextStyle())
                      .copyWith(color: ContigoColors.sage)),
            ],
          ],
          const SizedBox(height: 12),
          Text(
            'Tu respuesta permanecerá oculta hasta que ${widget.otherName} '
            'también responda esta pregunta.',
            style: (textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
          const SizedBox(height: 16),
          if (questions.shared)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ContigoColors.notifReminderBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Respuesta compartida (simulada). Se revelará cuando la otra '
                'persona responda.',
                style: textTheme.bodyMedium,
              ),
            )
          else
            ContigoButton(
              label: 'Compartir respuesta',
              fullWidth: true,
              onPressed: questions.hasResponse ? controller.markShared : null,
            ),
          const SizedBox(height: 10),
          ContigoButton(
            label: 'Omitir y ver otra pregunta',
            variant: ContigoButtonVariant.tertiary,
            fullWidth: true,
            onPressed: () => controller.reset(questions.index + 1, total),
          ),
        ],
      ),
    );
  }

  Widget _formatChip(
    ConnectionQuestionsState questions,
    ConnectionQuestionsController controller,
    ConnectionResponseFormat value,
    String icon,
    String label,
  ) {
    final selected = questions.format == value;
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: InkWell(
        onTap: () => controller.setFormat(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: selected ? ContigoColors.notifQuestionsBg : ContigoColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? ContigoColors.terracotta : ContigoColors.notifMeetingBg,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(label,
                  style: (textTheme.labelMedium ?? const TextStyle()).copyWith(
                    color: selected
                        ? ContigoColors.terracotta
                        : ContigoColors.inkMuted,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
// ─── Mensaje íntimo (MobileScreen10, messageKind "intimate") ────────────────

/// Mensaje íntimo del cuidador para el PCS (tarea 3.19), portado de
/// `MobileScreen10` con `messageKind == "intimate"`. Es **distinto** del mensaje
/// de cuidado: aquí el cuidador escribe algo cercano y personal. El borrador es
/// una Funcion_Simulada de sesión (no se envía a nadie real) y el recorrido está
/// gated por Asociacion_Activa. Las orientaciones de "antes de guardar" están
/// pendientes de validación final por el equipo investigador.
class CaregiverIntimateMessageScreen extends StatelessWidget {
  const CaregiverIntimateMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _CaregiverGatedScaffold(
      title: 'Mensaje íntimo',
      fromConnections: true,
      builder: (context, careContext) =>
          _IntimateMessageBody(pcsName: careContext.pcsName),
    );
  }
}

class _IntimateMessageBody extends ConsumerStatefulWidget {
  const _IntimateMessageBody({required this.pcsName});
  final String pcsName;

  @override
  ConsumerState<_IntimateMessageBody> createState() =>
      _IntimateMessageBodyState();
}

class _IntimateMessageBodyState extends ConsumerState<_IntimateMessageBody> {
  // El texto vive en el provider (aislado por contexto completo); el controlador
  // solo refleja ese texto, de modo que al revocar no se borra y al reactivar la
  // misma asociación se recupera.
  final TextEditingController _controller = TextEditingController();

  static const List<String> _chips = [
    'Recordarle que estás',
    'Compartir un recuerdo',
    'Ofrecer compañía',
  ];

  static const List<String> _reminders = [
    'Trata de evitar dar consejos que la persona no ha pedido.',
    'Evita juzgar o cuestionar lo que siente.',
    'No exijas una respuesta inmediata.',
    'Evita minimizar lo que está viviendo.',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncText(String text) {
    if (_controller.text != text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final message =
        ref.watch(currentIntimateMessageProvider) ??
            const IntimateMessageState();
    final controller = ref.read(intimateMessageControllerProvider.notifier);
    _syncText(message.text);

    if (message.saved) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle,
                  color: ContigoColors.sage, size: 56),
              const SizedBox(height: 16),
              Text('Borrador de prueba preparado',
                  style: textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('No se ha enviado.',
                  style: (textTheme.bodyMedium ?? const TextStyle())
                      .copyWith(color: ContigoColors.inkMuted),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mensaje íntimo para ${widget.pcsName}',
              style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Escribe algo cercano, breve y sin exigir una respuesta.',
            style: (textTheme.bodyMedium ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in _chips)
                ActionChip(
                  label: Text(chip),
                  backgroundColor: ContigoColors.notifReminderBg,
                  onPressed: () => controller.setText('${chip.toLowerCase()}...'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Tu mensaje', style: textTheme.titleSmall),
          const SizedBox(height: 6),
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 10,
            onChanged: controller.setText,
            decoration: const InputDecoration(
              filled: true,
              fillColor: ContigoColors.surface,
              hintText:
                  'Por ejemplo: Pensé en ti y quería recordarte que estoy aquí. '
                  'No tienes que responder ahora.',
              border: OutlineInputBorder(),
            ),
          ),
          if (message.text.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Vista previa para ${widget.pcsName}',
                style: (textTheme.bodySmall ?? const TextStyle())
                    .copyWith(color: ContigoColors.inkMuted)),
            const SizedBox(height: 8),
            ContigoCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: ContigoColors.notifReminderBg,
                    child: Text('🌿', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DemoCaregiver.name, style: textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(message.text, style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ContigoColors.notifMeetingBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Antes de guardar, recuerda',
                    style: (textTheme.titleSmall ?? const TextStyle())
                        .copyWith(color: ContigoColors.clay)),
                const SizedBox(height: 8),
                for (final item in _reminders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $item', style: textTheme.bodyMedium),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Orientaciones pendientes de validación final por el equipo '
                  'investigador',
                  style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                    color: ContigoColors.inkMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Borrador de prueba para ${widget.pcsName}. Permanece en esta sesión '
            'y se borra al recargar. No se envía a nadie.',
            style: (textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
          const SizedBox(height: 16),
          ContigoButton(
            label: 'Preparar borrador',
            fullWidth: true,
            onPressed:
                message.text.trim().isEmpty ? null : controller.markSaved,
          ),
        ],
      ),
    );
  }
}
// ─── Helpers de selección compartidos ───────────────────────────────────────

Widget _choiceRow({
  required List<String> options,
  required List<String> labels,
  required String? selected,
  required ValueChanged<String> onSelect,
}) {
  return Row(
    children: [
      for (var i = 0; i < options.length; i++) ...[
        Expanded(
          child: _SelectButton(
            label: labels[i],
            selected: selected == options[i],
            onTap: () => onSelect(options[i]),
          ),
        ),
        if (i < options.length - 1) const SizedBox(width: 8),
      ],
    ],
  );
}

Widget _scaleRow({
  required String min,
  required String max,
  required int count,
  required int? selected,
  required ValueChanged<int> onSelect,
}) {
  return Row(
    children: [
      if (min.isNotEmpty) ...[
        _ScaleEdge(text: min),
        const SizedBox(width: 6),
      ],
      for (var n = 1; n <= count; n++) ...[
        Expanded(
          child: _SelectButton(
            label: '$n',
            selected: selected != null && n <= selected,
            onTap: () => onSelect(n),
          ),
        ),
        if (n < count) const SizedBox(width: 6),
      ],
      if (max.isNotEmpty) ...[
        const SizedBox(width: 6),
        _ScaleEdge(text: max),
      ],
    ],
  );
}

class _ScaleEdge extends StatelessWidget {
  const _ScaleEdge({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text(
      text,
      style: (textTheme.labelSmall ?? const TextStyle())
          .copyWith(color: ContigoColors.inkMuted),
    );
  }
}

class _SelectButton extends StatelessWidget {
  const _SelectButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? ContigoColors.notifQuestionsBg : ContigoColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? ContigoColors.terracotta : ContigoColors.notifMeetingBg,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: (textTheme.labelMedium ?? const TextStyle()).copyWith(
            color: selected ? ContigoColors.terracotta : ContigoColors.inkMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}