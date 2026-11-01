import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../widgets/widgets.dart';

/// Vista del **primer registro sin persona vinculada** (tarea 2.16).
///
/// Portado de la rama vacía de `choosing` del prototipo (`src/screens/ema.tsx`,
/// `<div className="ema-reference-empty">`), que se presenta cuando aún no hay
/// una persona de referencia recordada y no existe ninguna persona con vínculo
/// activo (`!referencePreference && people.length === 0`). Reemplaza al estado
/// mínimo que la selección de 2.11 mostraba cuando no hay vínculo activo, para
/// que el camino sin vínculo del primer registro sea fiel al prototipo.
///
/// Es un widget **presentacional puro**: no lee providers ni navega por sí
/// mismo; recibe las dos acciones como callbacks para poder reusarse tanto desde
/// la selección de referencia (2.11, su caso sin personas activas) como desde el
/// flujo EMA de extremo a extremo (2.17). Así la lógica de omisión del bloque de
/// relación y la navegación viven en el llamador (que reutiliza el dominio
/// [omitEmaRelationship] y refleja el cableado de la revisión obsoleta de 2.12).
///
/// Presenta, verbatim respecto al prototipo:
/// - La copia "Aún no tienes personas cercanas vinculadas. Puedes continuar hoy
///   con seis preguntas, sin el bloque sobre una persona cercana."
/// - La acción PRIMARIA "Ir a Tu mapa de red" ([onOpenNetwork]). El prototipo la
///   rotula "Ir a Conoce tu red"; se usa "Ir a Tu mapa de red" para mantener la
///   coherencia con el resto de la app (la revisión obsoleta de 2.12 y el mapa
///   mínimo de 2.15 ya usan ese rótulo, y la ruta destino es "Tu mapa de red").
/// - El enlace SECUNDARIO "Continuar con el registro de hoy"
///   ([onContinueToday]), que en el llamador omite el bloque de relación solo
///   ese día sin alterar la referencia guardada.
class EmaNoLinkFirstRunView extends StatelessWidget {
  const EmaNoLinkFirstRunView({
    super.key,
    required this.onOpenNetwork,
    required this.onContinueToday,
  });

  /// Acción PRIMARIA: ir a "Tu mapa de red".
  final VoidCallback onOpenNetwork;

  /// Acción SECUNDARIA (enlace de texto): continuar hoy con seis preguntas,
  /// omitiendo el bloque de relación solo ese día.
  final VoidCallback onContinueToday;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        // Copia verbatim del prototipo (rama vacía de `choosing`).
        Text(
          'Aún no tienes personas cercanas vinculadas. Puedes continuar hoy con '
          'seis preguntas, sin el bloque sobre una persona cercana.',
          style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
            color: ContigoColors.ink,
          ),
        ),
        const SizedBox(height: 20),
        // Acción primaria: ir a "Tu mapa de red".
        ContigoButton(
          label: 'Ir a Tu mapa de red',
          fullWidth: true,
          onPressed: onOpenNetwork,
        ),
        const SizedBox(height: 12),
        // Enlace secundario: continuar hoy con los 6 ítems (omite relación).
        ContigoButton(
          label: 'Continuar con el registro de hoy',
          fullWidth: true,
          variant: ContigoButtonVariant.tertiary,
          onPressed: onContinueToday,
        ),
      ],
    );
  }
}
