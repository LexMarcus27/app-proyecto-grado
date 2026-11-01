# Contigo

App móvil Flutter de apoyo en salud mental para personas con conducta suicida
(PCS) y sus cuidadores, migrada desde el prototipo web "Contigo" (React/Vite).
Cubre los roles PCS y Cuidador y respeta los textos, el estilo visual y los
comportamientos del prototipo. El backend Firebase/Google Cloud (autenticación
real, persistencia y reglas de seguridad) se reserva para una etapa posterior;
por ahora la activación, el envío de mensajes y las notificaciones operan como
funciones simuladas locales.

## Cómo ejecutar

```bash
flutter pub get
# Si faltan las carpetas de plataforma (android/ ios/), regenéralas:
flutter create .
flutter run      # ejecuta la app en un dispositivo/emulador
flutter test     # corre la suite de pruebas
flutter analyze  # análisis estático
```

## Tipografía

- **Cuerpo: Inter** — empacada en `assets/fonts/Inter-Variable.ttf` (OFL). El
  prototipo la usa para el body; se empaca para no depender de que el sistema la
  provea (en Android no está disponible y caería a un fallback silencioso).
- **Títulos: Lora (sustitución)** — empacada en `assets/fonts/Lora-Variable.ttf`
  (OFL). El prototipo usa **Georgia** para los títulos, que no se distribuye en
  Android. Se sustituye por **Lora**, una serif OFL de trazo cálido cercana al
  carácter de Georgia. En iOS/web se conserva la cadena de respaldo
  `Georgia → Times New Roman → serif`, de modo que allí donde Georgia existe se
  mantiene la equivalencia visual original.

Ambas son fuentes variables; Flutter aplica el peso solicitado (400/500/600/700)
sobre su eje de peso. Las licencias y la atribución de origen están en
`assets/fonts/README.md` y los archivos `assets/fonts/*-OFL.txt`. No queda
ningún paso manual de fuentes pendiente: los binarios ya están incluidos en el
repositorio.

## Estado: Etapa 1 completa

La Etapa 1 (base del proyecto y estilo visual) está completa. Funciona:

- Proyecto Flutter con la estructura de capas `domain / data / presentation /
  app / content` y dependencias base (Riverpod, go_router, equatable,
  shared_preferences).
- App shell con `ProviderScope` y `go_router`: rutas nombradas y guardas por rol
  (PCS/Cuidador), negando acceso a roles no soportados.
- Tema portado del prototipo (`ContigoTheme.light()`) cableado en la app:
  paleta, tipografía (Inter + Lora) y contraste WCAG ≥ 4.5:1 de las tarjetas de
  notificación.
- Componentes de UI reutilizables (StatusBar, botones, tarjetas, CompanionNote,
  indicador de simulación). CompanionNote recorta el sprite correcto del avatar
  con un `CustomPainter` reproduciendo el recorte CSS del prototipo.
- Scaffold de carga de Contenido_Clínico verbatim con metadatos de estado de
  validación por tipo de contenido.
- Recursos multimedia del prototipo incorporados al bundle y expuestos por rutas
  tipadas (`AppMedia`).

Pendiente (placeholder hasta etapas siguientes):

- **Etapa 2** — recorrido EMA completo de extremo a extremo con sus
  dependencias mínimas (aún no implementado).
- **Etapa 3** — demás módulos (activación, mapa de red y métricas, plan de
  seguridad, mensajes de cuidado, conexión, notificaciones y modo crisis).
- **Etapa 4** — integración con Firebase (autenticación real, persistencia y
  reglas de seguridad del lado servidor).

Las pantallas de destino de las rutas son, en su mayoría, placeholders a la
espera de las Etapas 2–3.
