import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/session_controller.dart';

/// Pantalla mostrada cuando la sesión tiene un rol no soportado por la app
/// móvil (Requirement 1.3).
///
/// La sesión se conserva (no se cierra) y no se cargan datos de otros roles; se
/// indica que el rol no está soportado y se ofrece cerrar sesión.
class UnsupportedRoleScreen extends ConsumerWidget {
  const UnsupportedRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rol no soportado')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Tu rol no está soportado en la app móvil.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () =>
                    ref.read(sessionControllerProvider.notifier).clear(),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
