import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/journey/journey.dart';
import '../caregiver_journeys/caregiver_journeys_controller.dart'
    show ConnectionResponseFormat;
import '../widgets/widgets.dart';
import 'pcs_connection_questions_controller.dart';

/// Preguntas para conectar del **PCS** (tarea 3.19 / E3-W13-01), portada de
/// ``MobileScreen14`` con ``role === "pcs"``. Seis preguntas conversacionales
/// compartidas con una persona cercana **vinculada activa**; respuesta en
/// texto/audio/foto (adjuntos simulados). El estado se **aísla por vínculo** y
/// solo vive en sesión. Es distinta de la evaluación de nueve preguntas.
///
/// Si una notificación con acción ``questions`` abre esta pantalla, se puede
/// pasar [initialQuestion] para posicionarse en esa pregunta, conservando la
/// persona interlocutora.
class PcsConnectionQuestionsScreen extends ConsumerWidget {
  const PcsConnectionQuestionsScreen({super.key, this.initialQuestion});

  final String? initialQuestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final journeyAsync = ref.watch(pcsConnectionJourneyProvider);

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
                    onPressed: () => context.goBack(AppRoute.pcsHome),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Volver',
                  ),
                  Expanded(
                    child: Text('Preguntas para conectar',
                        style: textTheme.titleLarge),
                  ),
                ],
              ),
            ),
            Expanded(
              child: journeyAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
                data: (journey) {
                  final partner = pcsConnectionPartner(journey);
                  if (partner == null) {
                    return _NoPartner(journey: journey);
                  }
                  return _PcsQuestionsBody(
                    journey: journey,
                    partner: partner,
                    initialQuestion: initialQuestion,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sin persona vinculada activa: explica la autorización y permite ir al mapa a
/// elegir/invitar (una invitación aceptada por sí sola no habilita esto).
class _NoPartner extends StatelessWidget {
  const _NoPartner({required this.journey});
  final JourneyState journey;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Necesitas un vínculo activo', style: textTheme.titleMedium),
          const SizedBox(height: 10),
          Text(
            'Las preguntas para conectar se comparten con una persona cercana '
            'vinculada con asociación activa. Una invitación aceptada por sí '
            'sola no habilita este recorrido.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ContigoButton(
            label: 'Ir a Tu mapa de red',
            fullWidth: true,
            onPressed: () => context.pushNamed(AppRoute.networkMap),
          ),
        ],
      ),
    );
  }
}

class _PcsQuestionsBody extends ConsumerStatefulWidget {
  const _PcsQuestionsBody({
    required this.journey,
    required this.partner,
    this.initialQuestion,
  });
  final JourneyState journey;
  final NetworkPerson partner;
  final String? initialQuestion;

  @override
  ConsumerState<_PcsQuestionsBody> createState() => _PcsQuestionsBodyState();
}

class _PcsQuestionsBodyState extends ConsumerState<_PcsQuestionsBody> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Posiciona el recorrido en la pregunta de la notificación (si aplica),
    // conservando esa pregunta y persona (acción `questions`).
    if (widget.initialQuestion != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final key = pcsLinkKey(widget.journey, widget.partner.id);
        ref
            .read(pcsConnectionQuestionsControllerProvider.notifier)
            .focusQuestion(key, widget.initialQuestion);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

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
    final key = pcsLinkKey(widget.journey, widget.partner.id);
    final controller =
        ref.read(pcsConnectionQuestionsControllerProvider.notifier);
    final all = ref.watch(pcsConnectionQuestionsControllerProvider);
    final s =
        (key == null ? null : all[key]) ?? const PcsConnectionQuestionsState();
    _syncText(s.text);
    final otherName = widget.partner.name;
    final questions = s.questions;
    final currentIndex = s.index < questions.length ? s.index : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Una conversación entre tú y $otherName',
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
                      onPressed: () => controller.reset(key, currentIndex + 1),
                      child: const Text('Ver otra'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(questions[currentIndex], style: textTheme.titleMedium),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('¿Cómo quieres responder?', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              _formatChip(s, controller, key,
                  ConnectionResponseFormat.text, '✍️', 'Texto'),
              const SizedBox(width: 8),
              _formatChip(s, controller, key,
                  ConnectionResponseFormat.audio, '🎙️', 'Audio'),
              const SizedBox(width: 8),
              _formatChip(s, controller, key,
                  ConnectionResponseFormat.photo, '🖼️', 'Foto'),
            ],
          ),
          const SizedBox(height: 12),
          if (s.format == ConnectionResponseFormat.text)
            TextField(
              controller: _textController,
              minLines: 3,
              maxLines: 6,
              onChanged: (v) => controller.setText(key, v),
              decoration: const InputDecoration(
                filled: true,
                fillColor: ContigoColors.surface,
                hintText: 'Escribe lo que quieras compartir...',
                border: OutlineInputBorder(),
              ),
            )
          else ...[
            SimulationIndicator.forFeature(
              const FeatureLayerInfo(
                featureId: 'pcs-connection-attachments',
                layer: FeatureLayer.simulada,
                label:
                    'Adjuntos simulados: la grabación de audio y la selección '
                    'de foto son de demostración; no se captura ni envía nada '
                    'real.',
              ),
            ),
            const SizedBox(height: 8),
            ContigoButton(
              label: s.format == ConnectionResponseFormat.audio
                  ? (s.attachment.isEmpty ? 'Grabar audio' : 'Volver a grabar')
                  : (s.attachment.isEmpty
                      ? 'Elegir fotografía'
                      : 'Cambiar fotografía'),
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => controller.setAttachment(
                key,
                s.format == ConnectionResponseFormat.audio
                    ? 'Audio de 0:18 listo'
                    : 'Fotografía seleccionada',
              ),
            ),
            if (s.attachment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(s.attachment,
                  style: (textTheme.bodySmall ?? const TextStyle())
                      .copyWith(color: ContigoColors.sage)),
            ],
          ],
          const SizedBox(height: 12),
          Text(
            'Tu respuesta permanecerá oculta hasta que $otherName también '
            'responda esta pregunta.',
            style: (textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted),
          ),
          const SizedBox(height: 16),
          if (s.shared)
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
              onPressed:
                  s.hasResponse ? () => controller.markShared(key) : null,
            ),
          const SizedBox(height: 10),
          ContigoButton(
            label: 'Omitir y ver otra pregunta',
            variant: ContigoButtonVariant.tertiary,
            fullWidth: true,
            onPressed: () => controller.reset(key, currentIndex + 1),
          ),
        ],
      ),
    );
  }

  Widget _formatChip(
    PcsConnectionQuestionsState s,
    PcsConnectionQuestionsController controller,
    String? key,
    ConnectionResponseFormat value,
    String icon,
    String label,
  ) {
    final selected = s.format == value;
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: InkWell(
        onTap: () => controller.setFormat(key, value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: selected
                ? ContigoColors.notifQuestionsBg
                : ContigoColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? ContigoColors.terracotta
                  : ContigoColors.notifMeetingBg,
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