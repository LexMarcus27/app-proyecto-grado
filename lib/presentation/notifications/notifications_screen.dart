import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/notifications/notifications.dart';
import '../authorization/gating.dart';
import '../widgets/widgets.dart';
import 'notification_card.dart';
import 'notifications_controller.dart';

/// Pantalla de notificaciones simuladas (tarea 3.28), portada del flujo de
/// notificaciones del prototipo (`home.tsx`, `notification-card.tsx`).
///
/// "Simular notificación" genera un aviso in-app aleatorio (Funcion_Simulada,
/// sin envíos externos) y lo agrega a la bandeja. Las tarjetas usan los pares
/// de color del tema con contraste WCAG ≥ 4.5:1 (Requirement 12.5). Muestra el
/// indicador de simulación persistente.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const FeatureLayerInfo featureLayer = FeatureLayerInfo(
    featureId: 'notifications',
    layer: FeatureLayer.simulada,
    label:
        'Notificaciones simuladas: muestra avisos de demostración dentro de la '
        'app. No envía notificaciones reales ni analiza tus datos.',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);
    final withoutNetwork = ref.watch(notificationsWithoutActiveNetworkProvider);

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
                    onPressed: () => context.goNamed(AppRoute.pcsHome),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Volver al inicio',
                  ),
                  Expanded(
                    child: Text(
                      'Notificaciones simuladas',
                      style: textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            SimulationIndicator.forFeature(NotificationsScreen.featureLayer),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avisos ficticios de esta sesión. Toca uno para abrir su '
                      'herramienta; no se ha enviado ningún mensaje.',
                      style: (textTheme.bodySmall ?? const TextStyle())
                          .copyWith(color: ContigoColors.inkMuted),
                    ),
                    if (withoutNetwork) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Sin personas vinculadas, verás recordatorios generales.',
                        style: (textTheme.bodySmall ?? const TextStyle())
                            .copyWith(color: ContigoColors.inkMuted),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ContigoButton(
                      label: 'Simular notificación',
                      fullWidth: true,
                      icon: const Icon(Icons.notifications_none),
                      onPressed: controller.simulate,
                    ),
                    const SizedBox(height: 20),
                    if (state.inbox.isEmpty)
                      Text(
                        'Aún no has generado notificaciones. Usa "Simular '
                        'notificación".',
                        style: (textTheme.bodyMedium ?? const TextStyle())
                            .copyWith(color: ContigoColors.inkMuted),
                      )
                    else
                      for (final notification in state.inbox.reversed)
                        NotificationCard(
                          notification: notification,
                          onOpen: () => _openNotification(context, ref, notification),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Abre el destino de una notificación (portado del flujo del prototipo).
  ///
  /// Los recordatorios (acción `relationships`) abren "Tejiendo vínculos", cuyo
  /// destino ya existe. Las acciones dirigidas a una persona
  /// (mensaje/contacto/encuentro) y las preguntas se reevalúan contra la
  /// autorización vigente antes de abrir y, como sus pantallas destino llegan en
  /// Waves 12–13, muestran una explicación temporal en vez de un callback vacío.
  void _openNotification(
    BuildContext context,
    WidgetRef ref,
    DemoNotification notification,
  ) {
    if (notification.template.action == NotificationAction.relationships) {
      context.goNamed(AppRoute.connectionHub);
      return;
    }

    // Reevalúa la autorización exacta antes de abrir una acción dirigida.
    final gating = ref.read(careGatingProvider).value;
    final personId = notification.personId;
    final authorized =
        gating != null && personId != null && gating.canStrengthen(personId);
    if (!authorized) {
      _showPending(
        context,
        'Necesitas un vínculo activo',
        'Esta acción requiere una persona cercana vinculada con asociación '
            'activa.',
      );
      return;
    }

    // Acción `questions`: abre el recorrido conversacional del PCS conservando
    // la pregunta y la persona de la notificación (MobileScreen14).
    if (notification.template.action == NotificationAction.questions) {
      _openQuestions(context, ref, personId, notification.template.question);
      return;
    }

    _showPending(
      context,
      'Herramienta en preparación',
      'Esta herramienta de conexión se completa en las pantallas dirigidas a '
          'la persona, disponibles en una etapa posterior.',
    );
  }

  /// Fija la persona interlocutora (la de la notificación) y abre las preguntas
  /// para conectar del PCS posicionadas en [question].
  Future<void> _openQuestions(
    BuildContext context,
    WidgetRef ref,
    String personId,
    String? question,
  ) async {
    final repo = ref.read(journeyRepositoryProvider);
    final journey = await repo.loadJourney();
    if (journey.selectedPersonId != personId) {
      await repo.save(journey.copyWith(selectedPersonId: personId));
    }
    if (!context.mounted) return;
    context.goNamed(
      AppRoute.pcsConnectionQuestions,
      queryParameters: question == null ? const {} : {'q': question},
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