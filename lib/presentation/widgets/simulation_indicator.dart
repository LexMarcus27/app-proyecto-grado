import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../feature_layer.dart';

/// Indicador visual **persistente** de que una funcionalidad opera en la
/// Capa_Simulada (Requirement 3.4).
///
/// Punto clave de diseño: el indicador **no** es responsabilidad del
/// repositorio. Se deriva del metadato de capa por feature ([FeatureLayer] /
/// [FeatureLayerInfo]) que la UI consulta. Renderiza **solo** cuando la capa es
/// [FeatureLayer.simulada]; para [FeatureLayer.local] y [FeatureLayer.firebase]
/// no produce nada visible ([SizedBox.shrink]). Así, al promover una feature de
/// `Capa_Simulada` a `Capa_Firebase` el indicador desaparece **sin cambiar la
/// pantalla** (Requirement 3.6, design Property 2).
///
/// Es una barra/chip persistente, pensada para ubicarse de forma fija en la
/// pantalla de la feature (p. ej. bajo la [StatusBar] o como banner superior).
/// Toma todos los colores del tema ([ContigoColors]), sin literales.
class SimulationIndicator extends StatelessWidget {
  /// Construye el indicador a partir de una [FeatureLayer] directa.
  const SimulationIndicator({super.key, required this.layer, this.label});

  /// Construye el indicador a partir del metadato de capa de una feature.
  ///
  /// Si [FeatureLayerInfo.label] está definido, se usa como texto del indicador.
  SimulationIndicator.forFeature(FeatureLayerInfo info, {super.key})
    : layer = info.layer,
      label = info.label;

  /// Capa de madurez de la feature cuya pantalla muestra el indicador.
  final FeatureLayer layer;

  /// Texto opcional. Si es `null`, se usa el mensaje por defecto.
  final String? label;

  /// Texto por defecto del indicador cuando la feature no aporta uno propio.
  static const String defaultLabel =
      'Función simulada: el comportamiento es de demostración.';

  @override
  Widget build(BuildContext context) {
    // Property 2 / Req. 3.4 / 3.6: solo visible en Capa_Simulada.
    if (!layer.showsSimulationIndicator) {
      return const SizedBox.shrink();
    }

    final text = label ?? defaultLabel;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      liveRegion: false,
      label: 'Indicador de simulación. $text',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          // Par cálido "warm" del prototipo (fondo claro + acento oscuro),
          // con contraste holgado entre texto y fondo.
          color: ContigoColors.notifClosenessBg,
          border: Border(
            left: BorderSide(
              color: ContigoColors.notifClosenessAccent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            const ExcludeSemantics(
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: ContigoColors.notifClosenessAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                  color: ContigoColors.notifClosenessAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
