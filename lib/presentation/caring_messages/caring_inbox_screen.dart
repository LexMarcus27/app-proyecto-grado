import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/caring_messages/caring_message.dart';
import '../widgets/widgets.dart';
import 'caring_messages_controller.dart';

/// Bandeja de mensajes de cuidado recibidos del PCS (tarea 3.18), portada de
/// `CaringMessageInboxScreen` (`src/screens/caring-message-inbox.tsx`).
///
/// Es la contraparte **recibida**: muestra los mensajes de cuidado que los
/// vínculos activos han guardado para el PCS, para releerlos sin tener que
/// responder. Se abre **sin exigir** una Asociacion_Activa (Requirement 8.11);
/// solo lista los mensajes cuyo vínculo sigue vigente (Requirement 8.6). Es
/// distinta del recorrido para **tejer cercanía** (mensajes que el PCS compone
/// hacia otras personas), que vive en "Tejiendo vínculos".
class CaringInboxScreen extends ConsumerWidget {
  const CaringInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final messagesAsync = ref.watch(visibleCaringMessagesProvider);

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
                    child: Text('Mensajes de cuidado', style: textTheme.titleLarge),
                  ),
                ],
              ),
            ),
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('No se pudo cargar: $e')),
                data: (messages) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mensajes de tus vínculos activos que puedes volver a '
                        'leer cuando quieras. No tienes que responder.',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bandeja de prueba: estos mensajes son simulados y se '
                        'borran al recargar.',
                        style: (textTheme.bodySmall ?? const TextStyle())
                            .copyWith(color: ContigoColors.inkMuted),
                      ),
                      const SizedBox(height: 16),
                      if (messages.isEmpty)
                        Text(
                          'Aún no hay mensajes de cuidado de tus vínculos '
                          'activos en esta sesión.',
                          style: (textTheme.bodyMedium ?? const TextStyle())
                              .copyWith(color: ContigoColors.inkMuted),
                        )
                      else
                        for (final message in messages)
                          _CaringMessageCard(message: message),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaringMessageCard extends StatelessWidget {
  const _CaringMessageCard({required this.message});

  final SimulatedCaringMessage message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ContigoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.caregiverName, style: textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(
              'Para ${message.pcsName} · Envío simulado',
              style: (textTheme.bodySmall ?? const TextStyle())
                  .copyWith(color: ContigoColors.inkMuted),
            ),
            const SizedBox(height: 10),
            Text(message.text, style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}