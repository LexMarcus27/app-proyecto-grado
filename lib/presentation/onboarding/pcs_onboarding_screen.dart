import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../widgets/widgets.dart';
import 'onboarding_controller.dart';

/// Bienvenida del onboarding del PCS (tarea 3.3), portada del `BottomSheet`
/// "Antes de empezar, reconoce tu red" de `src/screens/home.tsx`.
///
/// Si el onboarding ya no está en estado `not-started`, no hay bienvenida que
/// mostrar y se redirige al inicio del PCS. "Construir mi mapa" marca el
/// onboarding en progreso y abre el mapa; "Hacerlo después" lo aplaza y vuelve
/// al inicio. El estado se persiste en el `JourneyState` (Requirement 8.7).
class PcsOnboardingScreen extends ConsumerStatefulWidget {
  const PcsOnboardingScreen({super.key});

  @override
  ConsumerState<PcsOnboardingScreen> createState() =>
      _PcsOnboardingScreenState();
}

class _PcsOnboardingScreenState extends ConsumerState<PcsOnboardingScreen> {
  // Evita re-disparar el redirect tras iniciar/aplazar el onboarding: una vez
  // que el usuario pulsa una acción, esta pantalla navega por su cuenta y no
  // debe competir con un redirect reactivo al cambiar el estado.
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shouldShow = ref.watch(shouldShowOnboardingWelcomeProvider);
    final controller = ref.read(onboardingControllerProvider);

    // Si al ENTRAR el onboarding ya no está en "not-started" (y el usuario no
    // acaba de accionar), no hay bienvenida que mostrar: vuelve al inicio.
    if (shouldShow == false && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.goNamed(AppRoute.pcsHome);
      });
    }

    return Scaffold(
      backgroundColor: ContigoColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Antes de empezar, reconoce tu red',
                      style: textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Construye tu mapa de red y, al terminar, invita a las '
                      'personas cercanas con quienes quieras compartir la '
                      'aplicación o fortalecer tu relación.',
                      style: (textTheme.bodyLarge ?? const TextStyle())
                          .copyWith(color: ContigoColors.ink),
                    ),
                    const SizedBox(height: 24),
                    ContigoButton(
                      label: 'Construir mi mapa',
                      fullWidth: true,
                      onPressed: () async {
                        _navigated = true;
                        await controller.start();
                        if (!context.mounted) return;
                        context.goNamed(AppRoute.networkBuilder);
                      },
                    ),
                    const SizedBox(height: 9),
                    ContigoButton(
                      label: 'Hacerlo después',
                      variant: ContigoButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: () async {
                        _navigated = true;
                        await controller.defer();
                        if (!context.mounted) return;
                        context.goNamed(AppRoute.pcsHome);
                      },
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