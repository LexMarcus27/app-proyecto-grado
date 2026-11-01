import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/session_controller.dart';
import '../../domain/auth/session.dart';
import '../../domain/auth/user_role.dart';

/// Pantalla de activación mínima del app shell.
///
/// El flujo de activación real (código en mayúsculas, verificación simulada y
/// enrutamiento por rol, Requirement 11) se implementa en la tarea 3.1 sobre el
/// `AuthService`. Aquí solo se ofrecen atajos mínimos para establecer la sesión
/// y ejercitar las guardas por rol del router.
class ActivationScreen extends ConsumerWidget {
  const ActivationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(sessionControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Activación')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Activación (pantalla pendiente)'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => controller.setSession(
                const Session(userId: 'demo-pcs', role: UserRole.pcs),
              ),
              child: const Text('Entrar como PCS'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => controller.setSession(
                const Session(userId: 'demo-cuidador', role: UserRole.cuidador),
              ),
              child: const Text('Entrar como Cuidador'),
            ),
            const SizedBox(height: 24),
            // Acceso a la galería de componentes de desarrollo (Etapa 1).
            TextButton(
              onPressed: () => context.goNamed('ver-componentes'),
              child: const Text('Ver componentes'),
            ),
            // Acceso a los controles de demostración (alternar escenarios 2.10).
            TextButton(
              onPressed: () => context.goNamed(AppRoute.demoControls),
              child: const Text('Controles de demostración'),
            ),
          ],
        ),
      ),
    );
  }
}
