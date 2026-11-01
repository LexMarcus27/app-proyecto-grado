import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/ema/ema.dart';
import '../../domain/journey/journey.dart';
import '../widgets/widgets.dart';

/// Flujo en vivo del `JourneyState` para la pantalla del mapa de red.
///
/// Expone [JourneyRepository.watchJourney] como `StreamProvider` para que la UI
/// lo observe de forma reactiva (se recarga sola si el recorrido cambia, p. ej.
/// al alternar el escenario demo).
final networkJourneyProvider = StreamProvider.autoDispose<JourneyState>(
  (ref) => ref.watch(journeyRepositoryProvider).watchJourney(),
);

/// Referencia EMA actualmente guardada (solo identificadores), o `null`.
///
/// Se usa para mostrar cuál es la persona de referencia activa. Se expone como
/// `FutureProvider` que puede recargarse tras confirmar una nueva selección
/// (`ref.invalidate`).
final savedEmaReferenceProvider = FutureProvider.autoDispose<EmaReference?>(
  (ref) => ref.watch(emaReferenceStoreProvider).loadReference(),
);

/// Entrada mínima a "Tu mapa de red" para la Etapa 2 (tarea 2.15).
///
/// Su único cometido en esta etapa es permitir que el PCS confirme o cambie la
/// Referencia_EMA **con confirmación explícita** (Requirements 5.7 y 5.9). El
/// mapa completo, las métricas, los gráficos y el flujo de invitaciones llegan
/// en la Etapa 3 (tareas 3.11/3.12).
///
/// Lista las personas con vínculo activo ([validCaregivers]); al tocar una se
/// marca como candidata y se pide confirmación explícita en un diálogo. Solo al
/// confirmar se construye la [EmaReference] con [emaReferenceForPerson] y se
/// persiste mediante [EmaReferenceStore.saveReference]. Tocar sin confirmar no
/// persiste nada.
class NetworkMapScreen extends ConsumerWidget {
  const NetworkMapScreen({super.key});

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
            _Header(onBack: () => _handleBack(context)),
            Expanded(
              child: journeyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    _ErrorBody(onBack: () => _handleBack(context)),
                data: (journey) => _NetworkBody(
                  journey: journey,
                  savedReference: savedReference,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Vuelve a la pantalla anterior; si no hay nada que desapilar, va al inicio
  /// del PCS (destino natural desde donde se abre este mapa).
  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoute.pcsHome);
    }
  }
}

/// Cabecera con afordancia de volver, título y subtítulo (estilo del prototipo).
class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 18, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Volver',
            icon: const Icon(Icons.arrow_back),
            color: ContigoColors.terracotta,
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tu mapa de red',
                  style: (textTheme.headlineSmall ?? const TextStyle())
                      .copyWith(color: ContigoColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  'A tu propio ritmo',
                  style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                    color: ContigoColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cuerpo de la pantalla con la lista de personas vinculadas o el estado vacío.
class _NetworkBody extends ConsumerWidget {
  const _NetworkBody({required this.journey, required this.savedReference});

  final JourneyState journey;
  final EmaReference? savedReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = validCaregivers(journey);
    final textTheme = Theme.of(context).textTheme;

    if (people.isEmpty) {
      return const _EmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(
          'Elige la persona de referencia para tu registro diario.',
          style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
            color: ContigoColors.inkMuted,
          ),
        ),
        const SizedBox(height: 16),
        for (final person in people) ...[
          _PersonEntry(
            person: person,
            isCurrentReference:
                savedReference?.personId == person.id &&
                isEmaReferenceActive(journey, savedReference),
            onSelect: () => _confirmSelection(context, ref, journey, person),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  /// Pide confirmación explícita antes de persistir. Solo si el usuario
  /// confirma en el diálogo se construye y guarda la [EmaReference].
  Future<void> _confirmSelection(
    BuildContext context,
    WidgetRef ref,
    JourneyState journey,
    NetworkPerson candidate,
  ) async {
    final hasCurrent = savedReference != null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ConfirmReferenceDialog(
        candidate: candidate,
        currentReference: savedReference,
        journey: journey,
        hasCurrent: hasCurrent,
      ),
    );

    if (confirmed != true) return;

    final reference = emaReferenceForPerson(journey, candidate.id);
    if (reference == null) return;

    await ref.read(emaReferenceStoreProvider).saveReference(reference);
    // Refresca la referencia mostrada para que se vea la selección activa.
    ref.invalidate(savedEmaReferenceProvider);

    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    }
  }
}

/// Tarjeta de una persona con vínculo activo, con la acción de selección para
/// el registro EMA (confirmación explícita diferida al diálogo).
class _PersonEntry extends StatelessWidget {
  const _PersonEntry({
    required this.person,
    required this.isCurrentReference,
    required this.onSelect,
  });

  final NetworkPerson person;
  final bool isCurrentReference;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Prototipo: "Seleccionada para registro EMA" cuando ya es la referencia
    // activa; "Seleccionar para registro EMA" en otro caso.
    final buttonLabel = isCurrentReference
        ? 'Seleccionada para registro EMA'
        : 'Seleccionar para registro EMA';

    return ContigoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  person.name,
                  style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
                    color: ContigoColors.ink,
                  ),
                ),
              ),
              if (isCurrentReference) const _ReferenceBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Persona cercana vinculada',
            style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
              color: ContigoColors.inkMuted,
            ),
          ),
          const SizedBox(height: 14),
          ContigoButton(
            label: buttonLabel,
            fullWidth: true,
            small: true,
            variant: isCurrentReference
                ? ContigoButtonVariant.secondary
                : ContigoButtonVariant.primary,
            // Aun siendo la referencia actual, permitir reconfirmar: el gating
            // de cambio real vive en el diálogo (confirmación explícita).
            onPressed: onSelect,
          ),
        ],
      ),
    );
  }
}

/// Distintivo que marca a la persona que es la Referencia_EMA activa.
class _ReferenceBadge extends StatelessWidget {
  const _ReferenceBadge();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ContigoColors.notifReminderBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Referencia actual',
        style: (textTheme.labelSmall ?? const TextStyle()).copyWith(
          color: ContigoColors.notifReminderAccent,
        ),
      ),
    );
  }
}

/// Diálogo de confirmación explícita de la Referencia_EMA (Req. 5.7/5.9).
///
/// Nunca persiste por sí mismo: devuelve `true` solo si el usuario pulsa el
/// botón de confirmar; el llamador es quien guarda la referencia.
class _ConfirmReferenceDialog extends StatelessWidget {
  const _ConfirmReferenceDialog({
    required this.candidate,
    required this.currentReference,
    required this.journey,
    required this.hasCurrent,
  });

  final NetworkPerson candidate;
  final EmaReference? currentReference;
  final JourneyState journey;
  final bool hasCurrent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = hasCurrent
        ? 'Cambiar persona para el registro EMA'
        : 'Seleccionar persona para el registro EMA';
    final confirmLabel = hasCurrent
        ? 'Confirmar cambio para EMA'
        : 'Confirmar selección para EMA';

    String? currentName;
    if (currentReference != null) {
      for (final person in journey.people) {
        if (person.id == currentReference!.personId) {
          currentName = person.name;
          break;
        }
      }
    }

    return AlertDialog(
      backgroundColor: ContigoColors.surface,
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: 'Persona elegida: ',
              style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                color: ContigoColors.ink,
              ),
              children: [
                TextSpan(
                  text: candidate.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (currentReference != null) ...[
            const SizedBox(height: 8),
            Text(
              'Tu selección actual es '
              '${currentName ?? 'una persona que ya no aparece en tu red'}.',
              style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                color: ContigoColors.inkMuted,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Esta será tu persona de referencia para las preguntas sobre tu '
            'relación con alguien cercano.',
            style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
              color: ContigoColors.inkMuted,
            ),
          ),
        ],
      ),
      actions: [
        ContigoButton(
          label: 'Cancelar',
          small: true,
          variant: ContigoButtonVariant.tertiary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ContigoButton(
          label: confirmLabel,
          small: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

/// Estado vacío: no hay ninguna persona con vínculo activo.
///
/// Mínimo a propósito (tarea 2.15): no incluye generador de nombres, evaluación
/// ni `generateResults`; esos llegan en la Etapa 3.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.group_outlined,
              size: 56,
              color: ContigoColors.sageSoft,
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes personas cercanas vinculadas',
              textAlign: TextAlign.center,
              style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
                color: ContigoColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando una persona cercana acepte tu invitación, aparecerá aquí '
              'para que puedas elegirla como referencia de tu registro diario.',
              textAlign: TextAlign.center,
              style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                color: ContigoColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cuerpo de error: el almacenamiento del recorrido no se pudo leer.
class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No pudimos cargar tu mapa de red en este momento.',
              textAlign: TextAlign.center,
              style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
                color: ContigoColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            ContigoButton(label: 'Volver', small: true, onPressed: onBack),
          ],
        ),
      ),
    );
  }
}
