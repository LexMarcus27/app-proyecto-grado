import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/relation_evaluation/relation_evaluation.dart';
import '../widgets/widgets.dart';

/// Etapas del recorrido de evaluación de relación (orden del prototipo).
enum _EvalStage { person, questions, result, invite, sent }

/// Evaluación de relación y preguntas para conectar (tarea 3.23), portada de
/// `MobileScreen13` (`src/screens/social.tsx`).
///
/// Recorre los pasos **en orden**, avanzando **solo cuando el paso actual está
/// completo** (avance monótono, Property 19). El resultado es **orientación
/// demostrativa**: los umbrales y la puntuación final están **pendientes de
/// validación** (Requirement 10.2), lo que se señala en pantalla. La invitación
/// es una Funcion_Simulada (no envía nada real) y queda bloqueada sin una
/// Asociacion_Activa, conservando el estado del recorrido.
class RelationEvaluationScreen extends ConsumerStatefulWidget {
  const RelationEvaluationScreen({super.key});

  @override
  ConsumerState<RelationEvaluationScreen> createState() =>
      _RelationEvaluationScreenState();
}

class _RelationEvaluationScreenState
    extends ConsumerState<RelationEvaluationScreen> {
  _EvalStage _stage = _EvalStage.person;
  String _personName = '';
  final TextEditingController _contactController = TextEditingController();
  String _contact = '';
  int _questionIndex = 0;
  late List<int?> _answers =
      List<int?>.filled(relationEvaluationQuestions.length, null);
  int? _selected;

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  /// "Pensar en otra persona": reinicia el recorrido completo (portado de
  /// `restart` en `MobileScreen13`). Vuelve al paso de persona y descarta el
  /// nombre, el contacto y todas las respuestas.
  void _restart() {
    setState(() {
      _stage = _EvalStage.person;
      _personName = '';
      _contactController.clear();
      _contact = '';
      _questionIndex = 0;
      _answers = List<int?>.filled(relationEvaluationQuestions.length, null);
      _selected = null;
    });
  }

  /// Hoja de recurso sobre relaciones (Funcion_Simulada). El contenido narrativo
  /// está pendiente de entrega y validación por el equipo investigador.
  void _showRelationshipResource() {
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
              Text('Relaciones y conexión social',
                  style: textTheme.titleLarge),
              const SizedBox(height: 14),
              Text(
                '[[Contenido narrativo pendiente de entrega y validación por el '
                'equipo investigador]]',
                style: (textTheme.bodyMedium ?? const TextStyle())
                    .copyWith(color: ContigoColors.inkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ContigoButton(
                label: 'Volver a mi decisión',
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                    onPressed: _back,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Volver',
                  ),
                  Expanded(
                    child: Text('Elegir una relación', style: textTheme.titleLarge),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: _buildStage(textTheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _back() {
    switch (_stage) {
      case _EvalStage.questions:
        if (_questionIndex > 0) {
          setState(() {
            _questionIndex -= 1;
            _selected = _answers[_questionIndex];
          });
        } else {
          setState(() => _stage = _EvalStage.person);
        }
      case _EvalStage.result:
        setState(() {
          _questionIndex = relationEvaluationQuestions.length - 1;
          _selected = _answers[_questionIndex];
          _stage = _EvalStage.questions;
        });
      case _EvalStage.invite:
        setState(() => _stage = _EvalStage.result);
      case _EvalStage.person:
      case _EvalStage.sent:
        context.goNamed(AppRoute.pcsHome);
    }
  }

  Widget _buildStage(TextTheme textTheme) {
    switch (_stage) {
      case _EvalStage.person:
        return _personStage(textTheme);
      case _EvalStage.questions:
        return _questionsStage(textTheme);
      case _EvalStage.result:
        return _resultStage(textTheme);
      case _EvalStage.invite:
        return _inviteStage(textTheme);
      case _EvalStage.sent:
        return _sentStage(textTheme);
    }
  }

  Widget _personStage(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ContigoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Piensa en alguien cercano', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Estas preguntas pueden ayudarte a pensar si quieres invitar a '
                'esa persona a acompañarte en Contigo. La decisión siempre será '
                'tuya.',
                style: (textTheme.bodyMedium ?? const TextStyle())
                    .copyWith(color: ContigoColors.inkMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Nombre o apodo de la persona', style: textTheme.titleSmall),
        const SizedBox(height: 6),
        TextField(
          onChanged: (v) => setState(() => _personName = v),
          decoration: const InputDecoration(
            filled: true,
            fillColor: ContigoColors.surface,
            hintText: 'Ej: Mamá, Jorge',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tus respuestas se guardarán de forma privada y no se compartirán con '
          'la persona evaluada.',
          style: (textTheme.bodySmall ?? const TextStyle())
              .copyWith(color: ContigoColors.inkMuted),
        ),
        const SizedBox(height: 20),
        ContigoButton(
          label: 'Comenzar preguntas',
          fullWidth: true,
          onPressed: _personName.trim().isEmpty
              ? null
              : () => setState(() => _stage = _EvalStage.questions),
        ),
      ],
    );
  }

  Widget _questionsStage(TextTheme textTheme) {
    final total = relationEvaluationQuestions.length;
    final question = relationEvaluationQuestions[_questionIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pregunta ${_questionIndex + 1} de $total · Pensando en $_personName',
          style: (textTheme.bodySmall ?? const TextStyle())
              .copyWith(color: ContigoColors.inkMuted),
        ),
        const SizedBox(height: 12),
        ContigoCard(child: Text(question.text, style: textTheme.titleMedium)),
        const SizedBox(height: 12),
        Text('Selecciona la opción que más se acerque:',
            style: (textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: ContigoColors.inkMuted)),
        const SizedBox(height: 8),
        for (var i = 0; i < relationEvaluationScale.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ScaleOption(
              value: i + 1,
              label: relationEvaluationScale[i],
              selected: _selected == i + 1,
              onTap: () => setState(() => _selected = i + 1),
            ),
          ),
        const SizedBox(height: 12),
        ContigoButton(
          label: _questionIndex < total - 1 ? 'Siguiente' : 'Ver orientación',
          fullWidth: true,
          // Avance monótono: solo avanza con el paso actual respondido.
          onPressed: _selected == null ? null : _saveAnswerAndAdvance,
        ),
      ],
    );
  }

  void _saveAnswerAndAdvance() {
    _answers[_questionIndex] = _selected;
    if (!canAdvanceEvaluationStep(_answers, _questionIndex)) return;
    final total = relationEvaluationQuestions.length;
    setState(() {
      if (_questionIndex < total - 1) {
        _questionIndex += 1;
        _selected = _answers[_questionIndex];
      } else {
        _stage = _EvalStage.result;
      }
    });
  }

  Widget _resultStage(TextTheme textTheme) {
    final supportive = relationSeemsSupportive(_answers);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          supportive
              ? '$_personName puede ser una opción de apoyo'
              : 'Esta relación parece importante y también compleja',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Text(
          supportive
              ? 'Si te sientes cómodo/a, puedes continuar y enviarle una '
                  'invitación para acompañarte desde Contigo.'
              : 'Algunas respuestas sugieren momentos de tensión o estrés. '
                  'Puedes invitar a esta persona, considerar a alguien más o '
                  'revisar un recurso antes de decidir.',
          style: (textTheme.bodyMedium ?? const TextStyle())
              .copyWith(color: ContigoColors.inkMuted),
        ),
        const SizedBox(height: 12),
        _mutedBox(
          context,
          'La elección es tuya. Esta orientación nunca bloquea una invitación '
          'ni decide por ti.',
        ),
        const SizedBox(height: 16),
        ContigoButton(
          label: 'Continuar con la invitación',
          fullWidth: true,
          onPressed: () => setState(() => _stage = _EvalStage.invite),
        ),
        if (!supportive) ...[
          const SizedBox(height: 10),
          ContigoButton(
            label: 'Ver recurso sobre relaciones',
            variant: ContigoButtonVariant.secondary,
            fullWidth: true,
            onPressed: _showRelationshipResource,
          ),
        ],
        const SizedBox(height: 10),
        ContigoButton(
          label: 'Pensar en otra persona',
          variant: ContigoButtonVariant.tertiary,
          fullWidth: true,
          onPressed: _restart,
        ),
        const SizedBox(height: 12),
        // Marcador de Contenido_Validacion_Pendiente.
        Text(
          'Orientación demostrativa. Los umbrales y la puntuación final están '
          'pendientes de validación por el equipo investigador.',
          style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
            color: ContigoColors.inkMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _inviteStage(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invitar a $_personName', style: textTheme.titleMedium),
        const SizedBox(height: 10),
        SimulationIndicator.forFeature(
          const FeatureLayerInfo(
            featureId: 'relation-invite',
            layer: FeatureLayer.simulada,
            label:
                'Invitación simulada: no se envía nada hasta confirmar y, en '
                'esta demostración, no se contacta a ninguna persona real.',
          ),
        ),
        const SizedBox(height: 16),
        Text('Número o correo', style: textTheme.titleSmall),
        const SizedBox(height: 6),
        TextField(
          controller: _contactController,
          onChanged: (v) => setState(() => _contact = v),
          decoration: const InputDecoration(
            filled: true,
            fillColor: ContigoColors.surface,
            hintText: 'Ej: 300 123 4567',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'La invitación no se enviará hasta que confirmes. La persona solo '
          'podrá consultar la información que autorices compartir con ella.',
          style: (textTheme.bodySmall ?? const TextStyle())
              .copyWith(color: ContigoColors.inkMuted),
        ),
        const SizedBox(height: 16),
        ContigoButton(
          label: 'Enviar invitación',
          fullWidth: true,
          // El prototipo exige un contacto antes de confirmar la invitación
          // simulada: sin "Número o correo" el botón queda deshabilitado.
          onPressed: _contact.trim().isEmpty
              ? null
              : () => setState(() => _stage = _EvalStage.sent),
        ),
        const SizedBox(height: 10),
        ContigoButton(
          label: 'Volver a la orientación',
          variant: ContigoButtonVariant.tertiary,
          fullWidth: true,
          onPressed: () => setState(() => _stage = _EvalStage.result),
        ),
      ],
    );
  }

  Widget _sentStage(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.check_circle, color: ContigoColors.sage, size: 56),
        const SizedBox(height: 16),
        Text('Invitación preparada',
            style: textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Enviamos a $_personName la información para reclamar su cuenta de '
          'cuidador/a y vincularse contigo. (Envío simulado.)',
          style: (textTheme.bodyMedium ?? const TextStyle())
              .copyWith(color: ContigoColors.inkMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ContigoButton(
          label: 'Volver al inicio',
          fullWidth: true,
          onPressed: () => context.goNamed(AppRoute.pcsHome),
        ),
      ],
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
    child: Text(text, style: textTheme.bodyMedium),
  );
}

class _ScaleOption extends StatelessWidget {
  const _ScaleOption({
    required this.value,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final int value;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? ContigoColors.notifQuestionsBg : ContigoColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? ContigoColors.terracotta : ContigoColors.notifMeetingBg,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor:
                  selected ? ContigoColors.terracotta : ContigoColors.notifReminderBg,
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? ContigoColors.surface : ContigoColors.inkMuted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}