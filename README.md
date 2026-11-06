# Contigo

**Avance de desarrollo: Wave 12 implementada; verificación pendiente.**

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

## Estado del desarrollo y verificación

Actualizado el 5 de noviembre de 2026.

**La última ola implementada, Wave 12 de la etapa 3, aún no está verificada.**
Se publica como avance de desarrollo pendiente de revisión independiente y de
comprobación manual en Android; no debe interpretarse como una versión aprobada.

| Bloque | Estado |
| --- | --- |
| Etapa 1: base y estilo | Implementada y revisada. |
| Etapa 2: recorrido EMA | Implementada y verificada en los recorridos documentados de Android. |
| Etapa 3, Wave 10: activación, métricas, plan y dominio de notificaciones | Comprobaciones funcionales realizadas; verificación Android con configuración gráfica temporal documentada. |
| Etapa 3, Wave 11: onboarding, cuidador, autorización, conexión, mensajes y crisis/respiración | Comprobación manual solicitada completada en Android, incluidos los pendientes de bienvenida, contactos simulados y animación. |
| Etapa 3, Wave 12: inicio PCS, construcción del mapa y mensajes/bandeja | Implementación reportada por Kiro; **revisión independiente y comprobación manual pendientes**. |
| Waves 13–14 y etapa 4 (Firebase) | Pendientes según la especificación. |

Kiro reportó análisis limpio y 275 pruebas aprobadas para Wave 12. Ese resultado
no se ha reproducido como parte de este envío ni sustituye su verificación manual.

Las revisiones manuales recientes utilizaron el emulador Android con SwiftShader,
Vulkan desactivado e Impeller desactivado temporalmente, sin
`--enable-software-rendering`. No se ha determinado la causa de los cierres
históricos de QEMU ni se certifica estabilidad con Impeller o en iOS.

Las funciones de envío, activación y comunicación conservan el carácter simulado
definido por la especificación. Los destinos de olas posteriores y Firebase aún
no están completos.

Informes: [Wave 10](docs/verificacion/Verificacion_Etapa_3_Wave_10_Contigo.md)
y [Wave 11](docs/verificacion/Verificacion_Etapa_3_Wave_11_Contigo.md).
El plan detallado está en `.kiro/specs/contigo-flutter-migration/tasks.md`.
