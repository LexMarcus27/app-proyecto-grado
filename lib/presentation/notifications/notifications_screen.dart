import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../authorization/gating.dart';
import '../widgets/widgets.dart';
import 'notification_card.dart';
import 'notification_dispatch.dart';
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
    final journey = ref.watch(gatingJourneyProvider).value;

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
                      for (final notification in state.inbox.reversed.where(
                        (n) => isNotificationAvailable(journey, n),
                      ))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: NotificationCard(
                            notification: notification,
                            onOpen: () =>
                                openDemoNotification(context, ref, notification),
                          ),
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

}