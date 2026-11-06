import 'package:flutter/material.dart';

/// Acción de navegación opcional ofrecida como botón en [PlaceholderScreen].
///
/// Permite que una pantalla aún pendiente exponga un punto de entrada mínimo a
/// un recorrido ya construido (p. ej. el flujo EMA) sin tener que implementar
/// la pantalla real todavía.
class PlaceholderAction {
  const PlaceholderAction({required this.label, required this.onPressed});

  /// Texto del botón.
  final String label;

  /// Acción al pulsar.
  final VoidCallback onPressed;
}

/// Pantalla placeholder mínima para el cableado de rutas del app shell.
///
/// Las pantallas reales de cada recorrido llegan en tareas posteriores. Este
/// widget existe únicamente para que el router tenga un destino por ruta y para
/// poder verificar la navegación y las guardas por rol.
///
/// Admite [actions] opcionales: botones de entrada mínima a recorridos ya
/// construidos. El inicio del PCS (home real, tarea 3.4) aún es placeholder, por
/// lo que se usa [actions] para ofrecer un acceso temporal y documentado al
/// flujo EMA de extremo a extremo (tarea 2.17), suficiente para la prueba manual
/// en el emulador. Se retirará al implementar el home real del PCS.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.actions = const [],
  });

  final String title;

  /// Botones de entrada mínima (p. ej. "Ir a mi registro EMA").
  final List<PlaceholderAction> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$title\n(pantalla pendiente)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final action in actions) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: action.onPressed,
                  child: Text(action.label),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
