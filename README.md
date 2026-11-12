# Contigo

**Avance de desarrollo: Waves 10–13 implementadas; verificaciones de los recorridos documentados en Android cerradas. Etapa 4 (Firebase) pendiente por decisión del usuario.**

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

Actualizado el 12 de noviembre de 2026.

**Las Waves 10–13 están implementadas y sus verificaciones acordadas están cerradas en el alcance de los informes.** El cierre de Wave 13 no constituye una auditoría global de todas las tareas de la Etapa 3.
La siguiente etapa (Firebase/Etapa 4) queda pendiente por decisión del equipo.
Las funciones de envío, activación, invitaciones y notificaciones conservan su
carácter simulado local definido por la especificación.

| Bloque | Estado |
| --- | --- |
| Etapa 1: base y estilo | Implementada y revisada. |
| Etapa 2: recorrido EMA | Implementada y verificada en los recorridos documentados de Android. |
| Etapa 3, Wave 10: activación, métricas, plan y dominio de notificaciones | Comprobaciones funcionales realizadas; verificación Android con configuración gráfica temporal documentada. |
| Etapa 3, Wave 11: onboarding, cuidador, autorización, conexión, mensajes y crisis/respiración | Comprobación manual solicitada completada en Android, incluidos los pendientes de bienvenida, contactos simulados y animación. |
| Etapa 3, Wave 12: inicio PCS, construcción del mapa y mensajes/bandeja | Implementada y verificada manualmente en Android. |
| Etapa 3, Wave 13: mapa completo (3.12), recorridos del cuidador (3.19) y evaluación de relación (3.23) | Implementada y verificada manualmente en Android, incluidas las correcciones de la revisión. |
| Tareas opcionales de la Etapa 3 (propiedades PBT y port de pruebas del prototipo) | No ejecutadas, según el plan. |
| Etapa 4 (Firebase/Google Cloud) | Pendiente por decisión del equipo; no iniciada. |

El análisis estático (`flutter analyze`) está limpio y la suite de pruebas
(`flutter test`) pasa con 358 pruebas en el último estado registrado de la
Etapa 3. La verificación funcional de los recorridos documentados se confirmó en
Android según los informes del equipo. En Wave 13, el aislamiento ante una asociación nueva con la misma persona se acredita mediante pruebas automatizadas; no se reprodujo manualmente. Al reentrar al constructor, el generador vuelve a 1/10, conservando las personas y sus respuestas.

Las revisiones manuales recientes utilizaron el emulador Android con SwiftShader,
Vulkan desactivado e Impeller desactivado temporalmente, sin
`--enable-software-rendering`. No se ha determinado la causa de los cierres
históricos de QEMU ni se certifica estabilidad con Impeller o en iOS.

Las funciones de envío, activación, invitaciones y comunicación conservan el
carácter simulado local definido por la especificación. La Etapa 4 (Firebase:
autenticación real, persistencia en la nube y reglas de seguridad) no está
implementada y queda pendiente por decisión del equipo; está diseñada para
enchufarse sobreescribiendo los providers de Riverpod sin modificar las
pantallas.

Informes de verificación incluidos en el repositorio:
[Wave 10](docs/verificacion/Verificacion_Etapa_3_Wave_10_Contigo.md) y
[Wave 11](docs/verificacion/Verificacion_Etapa_3_Wave_11_Contigo.md). El cierre
de las verificaciones manuales de las Waves 12 y 13 (y de sus correcciones) está
registrado en el plan detallado, `.kiro/specs/contigo-flutter-migration/tasks.md`.
