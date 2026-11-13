import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/journey/journey.dart';
import '../widgets/widgets.dart';
import 'caregiver_home_controller.dart';
import 'caregiver_home_screen.dart';

/// Borde neutro del prototipo (`#DFD4C9`).
const Color caregiverBorder = Color(0xFFDFD4C9);

/// Título grande del inicio del cuidador (`.caregiver-hero h1`, Georgia 48;
/// Lora en Android, ajustado a 44 para el ancho móvil).
const TextStyle caregiverHeroTitleStyle = TextStyle(
  fontFamily: ContigoTheme.displayFontFamily,
  fontFamilyFallback: ContigoTheme.displayFontFallback,
  fontSize: 46,
  height: 1.1,
  fontWeight: FontWeight.w700,
  letterSpacing: -1.5,
  color: ContigoColors.ink,
);

/// Título de las vistas internas (`.caregiver-page-title`, Georgia 29).
const TextStyle caregiverPageTitleStyle = TextStyle(
  fontFamily: ContigoTheme.displayFontFamily,
  fontFamilyFallback: ContigoTheme.displayFontFallback,
  fontSize: 29,
  height: 34 / 29,
  fontWeight: FontWeight.w700,
  color: ContigoColors.ink,
);

/// Nota secundaria (`.caregiver-note`, `.caregiver-empty`).
const TextStyle caregiverNoteStyle = TextStyle(
  fontSize: 13,
  height: 20 / 13,
  color: ContigoColors.inkMuted,
);

/// Estructura común de las vistas del cuidador: lienzo cálido, botón flotante
/// «Proveer apoyo» (deshabilitado sin vínculo activo) y navegación inferior.
class CaregiverScaffold extends StatelessWidget {
  const CaregiverScaffold({
    super.key,
    required this.active,
    required this.supportEnabled,
    required this.child,
  });

  final CaregiverTab active;
  final bool supportEnabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Padding(
          // Reserva el espacio del botón flotante bajo el contenido.
          padding: const EdgeInsets.only(bottom: supportButtonHeight + 12),
          child: child,
        ),
      ),
      floatingActionButton: SupportButton.caregiver(
        context,
        enabled: supportEnabled,
      ),
      bottomNavigationBar: CaregiverBottomNav(active: active),
    );
  }
}

/// Cabecera de las vistas internas del cuidador: «← Inicio» y título serif.
class _CaregiverPageHeader extends StatelessWidget {
  const _CaregiverPageHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusBar(),
        Semantics(
          label: 'Volver al inicio del cuidador',
          button: true,
          excludeSemantics: true,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: ContigoColors.sage,
              padding: const EdgeInsets.symmetric(horizontal: 0),
              minimumSize: const Size(44, 44),
              textStyle: const TextStyle(fontFamily: ContigoTheme.bodyFontFamily, 
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => context.goNamed(AppRoute.caregiverHome),
            icon: const Icon(Icons.arrow_back, size: 22),
            label: const Text('Inicio'),
          ),
        ),
        const SizedBox(height: 20),
        Text(title, style: caregiverPageTitleStyle),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Mensaje común cuando no hay una asociación activa autorizada.
class _BlockedNotice extends StatelessWidget {
  const _BlockedNotice();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'No hay una asociación activa autorizada para esta cuenta. Una '
          'invitación aceptada por sí sola no habilita el plan, los mensajes ni '
          'los registros.',
          style: TextStyle(fontSize: 16, height: 24 / 16),
        ),
        const SizedBox(height: 16),
        ContigoButton(
          label: 'Explorar recursos para aprender',
          variant: ContigoButtonVariant.secondary,
          fullWidth: true,
          onPressed: () => context.goNamed(AppRoute.caregiverLearning),
        ),
      ],
    );
  }
}

/// «Aprendiendo a tejer vínculos» (M22, vista `learning`). Disponible sin
/// vínculo activo; el contenido lo valida el equipo investigador.
class CaregiverLearningScreen extends ConsumerWidget {
  const CaregiverLearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careContext = ref.watch(caregiverContextProvider).value;
    final pcsName = careContext?.pcsName;
    return CaregiverScaffold(
      active: CaregiverTab.aprender,
      supportEnabled: careContext != null,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const _CaregiverPageHeader(title: 'Aprendiendo a tejer vínculos'),
          Text(
            pcsName != null
                ? 'Lo que puedo saber para cuidar mi relación con $pcsName'
                : 'Lo que puedo saber para cuidar a quienes quiero',
            style: const TextStyle(fontSize: 16, height: 24 / 16),
          ),
          const SizedBox(height: 24),
          for (final resource in const [
            'Validación',
            'Habilidades interpersonales',
          ]) ...[
            ContigoButton(
              label: resource,
              variant: ContigoButtonVariant.secondary,
              fullWidth: true,
              icon: const Icon(Icons.menu_book_outlined),
              onPressed: () => _openResource(context, resource),
            ),
            const SizedBox(height: 12),
          ],
          const Text(
            'Los recursos serán proporcionados y validados por el equipo '
            'investigador.',
            style: caregiverNoteStyle,
          ),
        ],
      ),
    );
  }

  /// Muestra el contenido (pendiente de validación) de un recurso, sin
  /// inventar material clínico.
  void _openResource(BuildContext context, String title) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: ContigoColors.surface,
      builder: (sheetContext) {
        final textTheme = Theme.of(sheetContext).textTheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                'Este contenido será proporcionado y validado por el equipo '
                'investigador.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ContigoButton(
                label: 'Volver a aprender',
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

/// «Tejiendo vínculos» del cuidador (M23, vista `connections`): cuatro
/// opciones paralelas — mensaje íntimo, mensaje de cuidado, preguntas para
/// conectar y registrar encuentro. Sin asociación activa muestra el bloqueo.
class CaregiverConnectionsScreen extends ConsumerWidget {
  const CaregiverConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careContext = ref.watch(caregiverContextProvider).value;
    final linked = careContext != null;
    return CaregiverScaffold(
      active: CaregiverTab.vinculos,
      supportEnabled: linked,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const _CaregiverPageHeader(title: 'Tejiendo vínculos'),
          if (careContext == null)
            const _BlockedNotice()
          else ...[
            Text(
              'Formas pequeñas de cuidar tu relación con ${careContext.pcsName}.',
              style: const TextStyle(fontSize: 16, height: 24 / 16),
            ),
            const SizedBox(height: 24),
            _option(
              context,
              'Escribir un mensaje íntimo',
              Icons.chat_bubble_outline,
              AppRoute.caregiverIntimateMessage,
            ),
            _option(
              context,
              'Escribir un mensaje de cuidado',
              Icons.favorite_border,
              AppRoute.caringCompose,
            ),
            _option(
              context,
              'Preguntas para conectar',
              Icons.people_outline,
              AppRoute.caregiverConnectionQuestions,
            ),
            _option(
              context,
              'Registrar encuentro',
              Icons.calendar_today_outlined,
              AppRoute.caregiverEncounter,
            ),
          ],
        ],
      ),
    );
  }

  Widget _option(
    BuildContext context,
    String label,
    IconData icon,
    String route,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ContigoButton(
        label: label,
        variant: ContigoButtonVariant.secondary,
        fullWidth: true,
        icon: Icon(icon),
        onPressed: () => context.goNamed(route),
      ),
    );
  }
}

/// Perfil del cuidador (M24, vista `profile`): nombre, estado del vínculo y
/// herramientas de demostración. No implementa gestión de cuenta real.
class CaregiverProfileScreen extends ConsumerWidget {
  const CaregiverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careContext = ref.watch(caregiverContextProvider).value;
    final pcsName = careContext?.pcsName;
    return CaregiverScaffold(
      active: CaregiverTab.perfil,
      supportEnabled: careContext != null,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const _CaregiverPageHeader(title: 'Perfil'),
          const Text(
            DemoCaregiver.name,
            style: TextStyle(
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pcsName != null ? 'Vínculo activo con $pcsName' : 'Sin vínculo activo',
            style: const TextStyle(fontSize: 16, height: 24 / 16),
          ),
          const SizedBox(height: 12),
          const Text(
            'Este prototipo utiliza una cuenta ficticia para revisar el '
            'recorrido del cuidador.',
            style: caregiverNoteStyle,
          ),
          const SizedBox(height: 20),
          const CaregiverDemoPanel(),
        ],
      ),
    );
  }
}
