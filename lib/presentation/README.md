# presentation

Capa de presentación (Flutter).

Contiene pantallas/widgets, controllers/notifiers (estado de UI), `CustomPainter`
(mapa de red) y la navegación. Depende de las interfaces del dominio, nunca de
implementaciones concretas.

## Componentes de UI reutilizables (tarea 1.5)

`widgets/` reúne los componentes portados del prototipo (`src/ui.tsx` y
`src/components/companion-note.tsx`). Todos consumen tokens del tema
(`lib/app/theme.dart`) y los recursos de `lib/content/app_media.dart`; ninguno
codifica colores ni rutas de asset a mano (Requirement 2.3). El barril
`widgets/widgets.dart` los exporta juntos.

- `StatusBar` — barra de estado móvil (hora + glifos de señal/batería).
- `ContigoButton` — botón con variantes `primary / secondary / tertiary /
  critical / ghost`, ícono opcional, ancho completo y modo compacto.
- `ContigoCard` / `ContigoActionCard` — tarjeta de contenido y tarjeta-botón
  con etiqueta de accesibilidad.
- `CompanionNote` — nota del acompañante; pinta `AppMedia.companionAvatar`.
- `SimulationIndicator` — indicador de simulación persistente (Requirement 3.4).

## Indicador de simulación y metadato de capa (`feature_layer.dart`)

El indicador **no** es responsabilidad del repositorio. Se deriva del metadato
de capa de madurez por feature que la UI consulta:

- `FeatureLayer` — enum con `local` (`Capa_Local`), `simulada`
  (`Capa_Simulada`) y `firebase` (`Capa_Firebase`).
- `FeatureLayerInfo` — asocia un `featureId` a su `FeatureLayer` (Property 2;
  una feature sin capa se trata como no disponible, Req 3.7).

`SimulationIndicator` renderiza **solo** para `FeatureLayer.simulada`
(Requirement 3.4) y es un `SizedBox.shrink()` para `local` y `firebase`. Por eso
promover una feature a `Capa_Firebase` **retira el indicador sin cambiar la
pantalla** (Requirement 3.6): basta con cambiar el metadato de capa que alimenta
al widget. Uso típico:

```dart
// En la pantalla de una feature simulada (p. ej. envío de mensajes):
const feature = FeatureLayerInfo(
  featureId: 'caring-messages',
  layer: FeatureLayer.simulada,
);
// ...
SimulationIndicator.forFeature(feature) // visible mientras sea Capa_Simulada
```
