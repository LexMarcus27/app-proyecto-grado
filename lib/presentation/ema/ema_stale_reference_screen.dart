import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/ema/ema.dart';
import '../../domain/journey/journey.dart';
import '../network/network_map_screen.dart';
import '../widgets/widgets.dart';
import 'ema_stale_reference.dart';

/// Pantalla de revisión de una Referencia_EMA obsoleta (tarea 2.12).
///
/// Portado de la rama del prototipo (`src/screens/ema.tsx`) que se presenta
/// cuando `!activeReference && !omittedRelationship`: la persona guardada ya no
/// tiene un vínculo activo y la elección **no** se cambia automáticamente
/// (Requirements 5.7, 5.8, 5.9, 5.10). El texto clínico se preserva verbatim.
///
/// El modo concreto lo decide la función pura [emaStaleReferenceMode] a partir
/// de la referencia guardada y el recorrido vigente:
/// - [EmaReferenceReviewMode.reviewNoActivePeople] (Caso A, sin personas con
///   vínculo activo): además de "Ir a Tu mapa de red" (primaria) ofrece el
///   enlace secundario "Continuar con el registro de hoy", que omite el bloque
///   de relación **solo ese día** sin alterar la referencia guardada.
/// - [EmaReferenceReviewMode.reviewOtherActivePeople] (Caso B, con otras
///   personas con vínculo activo): solo dirige a "Tu mapa de red" para confirmar
///   otra persona; **no** ofrece "Continuar con el registro de hoy".
///
/// Qué hace y qué NO hace en esta etapa:
/// - La acción primaria navega a la ruta [AppRoute.networkMap] para revisar el
///   vínculo o confirmar otra persona.
/// - La omisión del Caso A se cablea de forma **mínima**: toma el borrador de la
///   sesión ([EmaDraftStore.loadTodayDraft], o uno nuevo con [createEmaDraft]),
///   le aplica [omitEmaRelationship] (marca `relationshipOmission ==
///   "no-active-link"` y deja 6 ítems presentados), lo guarda en la sesión
///   ([EmaDraftStore.saveDraft]) y **vuelve con ese borrador como resultado**
///   (`context.pop(draft)`). No construye el flujo EMA de extremo a extremo
///   (tarea 2.17): esa tarea empujará esta pantalla con `await` y continuará el
///   registro a partir del borrador devuelto. La **referencia guardada no se
///   toca** (solo se escribe el borrador de sesión).
/// - Si no hay a dónde volver (p. ej. se alcanzó por ruta directa), tras aplicar
///   la omisión navega al inicio del PCS.
class EmaStaleReferenceScreen extends ConsumerWidget {
  const EmaStaleReferenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyAsync = ref.watch(networkJourneyProvider);
    final savedReference = ref.watch(savedEmaReferenceProvider).value;

    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusBar(),
            const _Banner(),
            Expanded(
              child: journeyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const _ErrorBody(),
                data: (journey) => _ReviewBody(
                  mode: emaStaleReferenceMode(savedReference, journey),
                  onOpenNetwork: () => context.goNamed(AppRoute.networkMap),
                  onContinueToday: () => _continueToday(context, ref, journey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Aplica la omisión del bloque de relación **solo para hoy** (Caso A) y
  /// continúa el flujo.
  ///
  /// Toma el borrador de sesión (o crea uno), le aplica [omitEmaRelationship]
  /// —que solo surte efecto cuando no hay personas con vínculo activo—, lo
  /// persiste en la sesión y vuelve con él como resultado para que 2.17 continúe
  /// el registro. No altera la [EmaReference] guardada.
  Future<void> _continueToday(
    BuildContext context,
    WidgetRef ref,
    JourneyState journey,
  ) async {
    final store = ref.read(emaDraftStoreProvider);
    final current = await store.loadTodayDraft() ?? createEmaDraft();
    final omitted = omitEmaRelationship(current, journey);
    await store.saveDraft(omitted);

    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop(omitted);
    } else {
      context.goNamed(AppRoute.pcsHome);
    }
  }
}

/// Banner superior del prototipo (igual que la selección de referencia).
class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '¿Cómo estoy hoy?',
            style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
              color: ContigoColors.inkMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tu tejido de hoy',
            style: (textTheme.headlineSmall ?? const TextStyle()).copyWith(
              color: ContigoColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cuerpo de la revisión: copia verbatim + acciones según el [mode].
class _ReviewBody extends StatelessWidget {
  const _ReviewBody({
    required this.mode,
    required this.onOpenNetwork,
    required this.onContinueToday,
  });

  final EmaReferenceReviewMode mode;
  final VoidCallback onOpenNetwork;
  final VoidCallback onContinueToday;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final noActivePeople = mode == EmaReferenceReviewMode.reviewNoActivePeople;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        // Encabezado y copia del prototipo (verbatim).
        Text(
          'Revisa la persona de tu registro',
          style: (textTheme.titleLarge ?? const TextStyle()).copyWith(
            color: ContigoColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tu persona de referencia ya no tiene un vínculo activo contigo. No '
          'cambiaremos tu elección automáticamente.',
          style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
            color: ContigoColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        // Ayuda del prototipo (verbatim).
        Text(
          'En Tu mapa de red puedes revisar el vínculo o confirmar otra persona '
          'para el registro EMA.',
          style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
            color: ContigoColors.inkMuted,
          ),
        ),
        if (noActivePeople) ...[
          const SizedBox(height: 10),
          // Línea extra del prototipo, solo cuando no hay personas activas.
          Text(
            'También puedes continuar hoy con seis preguntas, sin el bloque '
            'sobre una persona cercana.',
            style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
              color: ContigoColors.ink,
            ),
          ),
        ],
        const SizedBox(height: 20),
        // Acción primaria: ir a "Tu mapa de red".
        ContigoButton(
          label: 'Ir a Tu mapa de red',
          fullWidth: true,
          onPressed: onOpenNetwork,
        ),
        if (noActivePeople) ...[
          const SizedBox(height: 12),
          // Enlace secundario (solo Caso A): continuar hoy con 6 preguntas.
          ContigoButton(
            label: 'Continuar con el registro de hoy',
            fullWidth: true,
            variant: ContigoButtonVariant.tertiary,
            onPressed: onContinueToday,
          ),
        ],
      ],
    );
  }
}

/// Cuerpo de error: el almacenamiento del recorrido no se pudo leer.
class _ErrorBody extends StatelessWidget {
  const _ErrorBody();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No pudimos cargar tu red en este momento.',
          textAlign: TextAlign.center,
          style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
            color: ContigoColors.ink,
          ),
        ),
      ),
    );
  }
}
