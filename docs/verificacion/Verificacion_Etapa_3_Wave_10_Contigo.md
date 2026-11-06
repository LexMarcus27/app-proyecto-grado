# Contigo Flutter · Wave 10 · Revisión posterior de Android

Fecha: 5 de noviembre de 2026. Alcance: acceso normal desde Inicio PCS al relato, reproducción y detención del audio en los dos videos, ambas etiquetas finales en la página 7 y una edición ficticia en el editor. Sin cambios de implementación ni trabajo de Wave 11.

**Resultado: las comprobaciones pendientes solicitadas se completaron satisfactoriamente con Skia/OpenGL sobre SwiftShader, con Vulkan e Impeller desactivados.** Se entró desde Inicio PCS, ambos videos mostraron imagen y audio y dejaron de sonar al pausar o abandonar su página, ambas etiquetas finales quedaron completas y se guardó una modificación ficticia en el editor. No hubo nuevos cierres de QEMU en este recorrido. La ejecución partió de `lib/main.dart`, sin entrada directa de prueba. No se repitió la batería general.

## Configuración identificada

Al comenzar no había emulador ni dispositivo ADB activos. El AVD es `Medium_Phone_API_37.0`; su archivo de definición apunta a `C:\Users\Lex\.android\avd\Medium_Phone.avd`. La configuración leída declara Android 37.0 Google APIs Play Store x86_64, 2048 MB de RAM, 8 núcleos y `hw.gpu.mode=software`.

Para este intento se arrancó el emulador con `-gpu swiftshader -feature -Vulkan -no-snapshot-load -no-snapshot-save`. Flutter se ejecuta desde el proyecto con `-t lib/main.dart --no-enable-impeller --enable-software-rendering --no-resident`: Skia por software, con Impeller desactivado solo para este arranque. No se editan el AVD ni el manifiesto. La prueba no certifica estabilidad con la configuración habitual de Impeller.

**Incidencia del primer intento de esta revisión:** con Skia por software el usuario oyó el audio del primer video, pero la imagen quedó del color del fondo. QEMU y Contigo seguían activos (QEMU 1616, Contigo 3543); no hubo cierre en ese punto. Se conservaron los registros y se cambió solo Flutter a Skia/OpenGL, omitiendo `--enable-software-rendering` y manteniendo `--no-enable-impeller`, el mismo APK y el mismo proceso de emulador. Con el nuevo proceso de Contigo 3972, el usuario confirmó imagen en movimiento y audio. Esta comparación apunta al modo de renderizado de software de Flutter como causa de la imagen ausente en este entorno; no se considera un defecto reproducido del contenido ni una corrección de código. Las comprobaciones siguientes continúan con Skia/OpenGL sobre el GPU SwiftShader del emulador.

La lectura del código confirmó el nuevo botón «Ir a mi plan para desenredar» en Inicio PCS, las etiquetas flexibles en `ContigoButton` y el respaldo que ahora se marca antes de liberar el reproductor. La corrección de Kiro y sus 16 pruebas puntuales aprobadas son un antecedente comunicado por el usuario; no se presentan como ejecuciones nuevas. No se induce un fallo artificial de creación de video en esta revisión, cuyo alcance es lo pendiente en Android.

## Resultados de este recorrido

| Comprobación | Resultado |
| --- | --- |
| Inicio PCS → relato, desde el arranque normal | El usuario activó con A3K9X2, entró en Inicio PCS y pulsó «Ir a mi plan para desenredar». Llegó a pantalla 1 de 7. Comprobado. |
| Video 1: reproduce y el audio se detiene al pausar | El usuario confirmó imagen en movimiento, audio y silencio al pausar con Skia/OpenGL. Comprobado. |
| Video 1: el audio se detiene al abandonar su página mientras reproduce | El usuario volvió a reproducir y pulsó «Siguiente» mientras sonaba; confirmó que se detuvo al llegar a página 2. Comprobado. |
| Video 2: reproduce y el audio se detiene al pausar | El usuario confirmó imagen, audio y detención al pausar en página 4 con Skia/OpenGL. Comprobado. |
| Video 2: el audio se detiene al abandonar su página mientras reproduce | El usuario volvió a reproducir y avanzó a página 5 mientras sonaba; confirmó que el audio se detuvo. Comprobado. |
| Página 7, plan vacío: «Construir mi plan para desenredar» completo | El usuario pulsó «Simular plan sin diligenciar» y confirmó la etiqueta completa dentro del botón. Comprobado. |
| Página 7, plan con información: «Ir a mi plan para desenredar» completo | El usuario pulsó «Simular plan con información» y confirmó la etiqueta completa dentro del botón. Observado también en captura Android: se distribuye en dos líneas, sin desbordamiento. Comprobado. |
| Entrada al editor y guardado de una modificación ficticia | Desde la página 7 se pulsó «Ir a mi plan para desenredar». El usuario editó y guardó el primer paso; confirmó «Completo» y que el emulador siguió abierto. La captura muestra el texto «prueba ficticia wave 10 corregida» y el estado «Completo». Comprobado. |

## Estado de los hallazgos y límites

| Hallazgo anterior | Estado tras esta revisión |
| --- | --- |
| E3-W10-01, acceso al relato | Corrección confirmada manualmente desde el inicio normal de la app. |
| E3-W10-02, etiqueta final desbordada | Corrección confirmada con plan vacío y con información en Android. La captura conservada corresponde al estado con información; el estado vacío fue confirmado por el usuario. |
| E3-W10-03, respaldo ante fallo de creación | Corrección comunicada por Kiro, coherente con el código inspeccionado; sus 16 pruebas puntuales son antecedente del usuario. No se volvió a forzar este error en Android ni se afirma una nueva prueba de respaldo en esta sesión. |
| E3-W10-04, cierres de QEMU | Sin reincidencia durante el recorrido actual. No se considera resuelta la causa de los dos cierres anteriores, ni se certifica la configuración con Impeller. |

El proceso final de Contigo permaneció en **3972** y QEMU en **1616**, el mismo emulador utilizado en ambos intentos gráficos de esta revisión. Se consultaron los eventos de Windows desde el inicio de la sesión y no se encontraron nuevos registros de cierre de QEMU/Contigo. En el registro Android del recorrido con Skia/OpenGL no aparecieron coincidencias con errores Flutter de nivel E, `FATAL EXCEPTION`, `RenderFlex overflowed` ni `Unhandled Exception`. Esta búsqueda acotada complementa las observaciones del usuario; no constituye una prueba exhaustiva de ausencia de errores.

No quedan interacciones pendientes de la lista solicitada para la configuración probada. **Sigue pendiente fuera de ese resultado** determinar la causa de los cierres anteriores y comprobar estabilidad con Impeller u otro dispositivo Android. La falta de imagen del intento con Skia por software queda registrada como incidencia dependiente del renderizador observado; el mismo APK sí reprodujo imagen y audio al omitir ese modo. No se evaluó de forma completa la calidad del sonido ni se reprodujeron íntegros los dos videos.

La app queda abierta en el editor con datos ficticios de sesión. Los parámetros gráficos son temporales: no se modificaron el manifiesto ni la configuración del AVD. No se modificó la fecha ni la sincronización automática. No se implementaron cambios ni se avanzó a Wave 11.

## Evidencia de esta revisión

- [Arranque normal con Skia por software](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-revision-arranque.log).
- [Configuración del AVD leída](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-revision-config-avd.log).
- [Parámetros reales de los procesos del emulador](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-revision-procesos.json).
- [Registro de arranque del emulador](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-revision-emulador.log).
- [Sesión del primer renderizador](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-revision-sesion.json).
- [Registro Android del video sin imagen](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-revision-android.log).
- [Arranque del mismo APK con Skia/OpenGL](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-revision-skia-gl-arranque.log).
- [Sesión de Skia/OpenGL y opciones utilizadas](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-revision-skia-gl-sesion.json).
- [Registro Android del recorrido completado](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-revision-skia-gl-android.log).
- [Comprobación de que ambos intentos usaron el mismo APK](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-revision-comparacion-apk.json).
- [Etiqueta final con información, completa en dos líneas](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-revision-etiqueta-con-informacion.jpg).
- [Modificación ficticia guardada en el editor](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-revision-editor-guardado.jpg).
- [Consulta de nuevos eventos de Windows](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-revision-eventos-windows.json).
- [Procesos activos al terminar](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-revision-estado-final.json).
- [Verificación de fuentes sin cambios durante la sesión](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-revision-version.json).

Los resultados y fallos de la primera revisión que siguen se conservan como historial anterior a las correcciones; no describen automáticamente la versión instalada en esta segunda revisión.

---

# Historial de la primera revisión de Wave 10

# Verificación de Contigo Flutter · Etapa 3, Wave 10

Fecha: 5 de noviembre de 2026. Proyecto: `C:\Users\Lex\Documents\app-proyecto-grado`. Alcance: tareas 3.1, 3.8, 3.13 y 3.25. Datos de prueba ficticios. No se implementan correcciones ni tareas posteriores.

Entorno: Flutter 3.47.8, Dart 3.13.7; AVD `Medium_Phone_API_37.0`, Android x86_64. Se compararon hashes de los 86 archivos de `lib/` con la captura previa: ninguno cambió durante la verificación.

**Resultado: 3.1, 3.8 y 3.25 comprobados en su alcance actual; 3.13 no queda aprobado sin reservas.** El análisis y las 203 pruebas existentes pasan. La activación se confirmó manualmente para ambos roles. El editor se verificó en Android mediante entrada directa y Skia por software. Se encontraron dos defectos del plan, una limitación de acceso desde el inicio y dos cierres del emulador, que impiden aprobar la estabilidad del recorrido normal. No se implementaron correcciones.

## Resultados automatizados

| Comprobación | Resultado y alcance |
| --- | --- |
| `flutter analyze` | Sin problemas; ejecución nueva de esta revisión. |
| Suite del proyecto | 203/203 pasan; ejecución nueva. Incluye activación, métricas, plan, notificaciones y regresiones EMA. El recorrido de revocación B sigue emitiendo `REVIEW_B_ROUTE=/mapa-red`. |
| Compilación Android normal | Correcta; se instaló y arrancó con `video_player: 2.14.1`. No se ha compilado iOS. |
| Comparación independiente del relato | Las 7 páginas coinciden con el prototipo en orden, IDs, títulos, párrafos, listas, cierres y videos asociados. |
| Comparación independiente de notificaciones | Las 11 plantillas coinciden en todos los campos, no solo en cantidad/primer y último ID. |
| Aislamiento por escenario mediante controlador | Se editó A, se pasó a B vacío, se editó B y se volvió a ambos: cada borrador conservó sus propios campos. |
| Activación con retardo real simulado | Mayúsculas, «Verificando...», botón deshabilitado durante la espera y destino cuidador correctos. |
| Relato en vista amplia con fallo de decodificación simulado | Se observó respaldo, se recorrieron las 7 páginas y se llegó al editor con el router real y sesión PCS ficticia. |
| Diseño del relato a 412 px y fuentes reales Inter/Lora | Falla al llegar a la última pantalla: desbordamiento horizontal de 140 px en una acción. Véase E3-W10-02. |
| Fallo al crear el reproductor nativo | No aparece el respaldo tras 5 segundos de tiempo simulado; permanece la carga. Véase E3-W10-03. |
| Editor a 412 px y nueva sesión | Pasa: edición de paso, rechazo del permiso simulado sin agregar contactos, aceptación con Dra. Valentina Ríos ficticia, actividad, entorno y conservación de los demás campos. Al crear otro contenedor de sesión con las mismas preferencias, todos los campos del plan están vacíos. |

La suite externa final contiene **8 pruebas: 6 pasan y 2 fallan**. Las dos fallidas se conservan para reproducir los hallazgos. Los primeros intentos del arnés se ajustaron para cargar las fuentes reales y dejar terminar la cancelación asíncrona del video antes de evaluar la interfaz; los resultados de la tabla corresponden al arnés corregido.

Las fórmulas POMP, grupos de ítems, cercanía final, cortes, formas y colores se contrastaron con el código del prototipo. Los cortes siguen identificados como contenido pendiente de validación. Las reglas de elegibilidad y sustitución de persona de 3.25 se verificaron con las pruebas de dominio del proyecto; no se afirma que exista todavía una interfaz de notificaciones ni entrega real.

## Comprobación manual en Android

| Recorrido | Evidencia y estado |
| --- | --- |
| Código corto `abc` | El usuario confirmó `ABC`, mensaje «No pudimos validar el código. Revísalo o solicita ayuda.» y permanencia en Activación. Pasa. |
| PCS con `a3k9x2` | El usuario confirmó mayúsculas, «Verificando...» y llegada a Inicio PCS. Pasa. |
| Cuidador con `c1d2e3` | El usuario confirmó mayúsculas y llegada a Inicio Cuidador. Pasa. |
| Presentación inicial | Observados marca Contigo, encabezado, subtítulo, campo centrado y espaciado, placeholder, acción, ayuda, privacidad, pista demo e indicador de simulación. No se realizó comparación píxel a píxel. |
| Primer video | Reproduce según el usuario. Audio ocasionalmente entrecortado al usar otras aplicaciones. No se ha atribuido la causa. |
| Segundo video | El usuario confirmó reproducción y entrecortes ocasionales bajo uso simultáneo del equipo. La detención del audio al pausar no quedó confirmada expresamente; se conserva como pendiente. |
| Llegada a pantalla 7 | Tras recuperar el emulador, el usuario llegó sin reproducir videos y confirmó el texto del botón cortado. Captura Android conservada. Al pulsarlo se volvió a cerrar el emulador completo. |
| Edición del primer paso | En el editor abierto directamente con Skia por software, el usuario guardó «Ejemplo ficticio de prueba», observó el texto y «Completo», sin cierre del emulador. Pasa en esa configuración. |
| Contactos simulados | El usuario pulsó primero «Permitir acceso» y observó Dra. Valentina Ríos y el aviso de simulación. Al volver a abrir y pulsar «No permitir», la hoja cerró y siguió un solo contacto, sin agregar otro. Pasa con Skia por software. |
| Actividades y entorno | El usuario agregó «Actividad ficticia de prueba» y guardó «Entorno ficticio de prueba». Confirmó ambos resultados; la captura muestra la actividad, el texto del entorno y «Guardado». Pasa con Skia por software. |

La pantalla de Inicio Cuidador continúa siendo un placeholder: es coherente con que el inicio real 3.5 todavía está pendiente y no se cuenta como defecto de 3.1.

## Hallazgos para Kiro

### E3-W10-01 · Falta un acceso desde Inicio PCS al plan

**Estado:** confirmado por inspección del router. **Impacto:** impide iniciar la comprobación manual normal del módulo 3.13 desde la app instalada.

`lib/app/router.dart` registra `/plan-seguridad/relato` y `/plan-seguridad`, pero el placeholder PCS solo ofrece EMA y mapa. No hay otra entrada visible al relato/editor en el código de navegación revisado. El home completo 3.4 está pendiente; para verificar 3.13 antes de implementarlo basta un acceso temporal de desarrollo, como el utilizado para EMA.

Para continuar esta revisión se utilizó una entrada **externa de prueba**, sin editar `lib/`: inicializa una sesión PCS ficticia mediante el servicio real simulado y dirige el router real al relato o al editor. Por tanto, lo observado así verifica pantallas, plugin y flujo interno, pero **no demuestra acceso normal desde Inicio PCS**. Al finalizar se compiló, instaló y abrió nuevamente el APK con `lib/main.dart`; se observó «Activa tu cuenta», confirmando que se retiró el arranque directo de prueba del dispositivo.

### E3-W10-02 · Acción final del relato no cabe al ancho de teléfono

**Estado:** reproducido en prueba de widgets a 412 × 900, con las fuentes Inter y Lora del proyecto; confirmado por el usuario y observado en captura de Android. **Impacto:** el texto de la acción final se sale de su espacio.

La navegación inferior de `lib/presentation/safety_plan/safety_plan_story_screen.dart` divide el ancho entre «Anterior» y la acción principal. En la página 7, «Construir mi plan para desenredar» tiene mucho más texto que «Siguiente». `ContigoButton` coloca su etiqueta en un `Text` sin flexibilidad dentro de un `Row`; el arnés registra un `RenderFlex` desbordado 140 px. El emulador configurado tiene 1080 × 2400 físicos y densidad 420, aproximadamente 411 px lógicos de ancho.

**Reproducción:** entrar al relato como PCS y avanzar hasta página 7 con el plan vacío. **Esperado:** etiquetas completas y accionables dentro del ancho disponible. Se confirmó visualmente el caso «Construir mi plan para desenredar»; conviene verificar también «Ir a mi plan para desenredar» al corregir la distribución.

### E3-W10-03 · El respaldo no se muestra si falla la creación del reproductor

**Estado:** reproducido con fallo nativo controlado; no se provocó este fallo en Android. **Impacto:** permanece el indicador de carga en lugar del mensaje de respaldo.

En `lib/presentation/safety_plan/widgets/story_video.dart`, el `catch` de `_initialize` espera `controller.dispose()` antes de marcar `_failed=true`. En `video_player` 2.14.1, `dispose()` espera el completador de creación. Si `createWithOptions` falla antes de entregar un ID, ese completador queda pendiente; la UI no alcanza el estado de respaldo.

**Reproducción externa:** una implementación de `VideoPlayerPlatform` que falla en `createWithOptions`; montar el `StoryVideo` original y avanzar 5 segundos de tiempo de prueba. No aparece «No pudimos cargar el video.». Un error de decodificación emitido **después** de crear el reproductor sí muestra el respaldo en la prueba de navegación. No se generaliza este hallazgo a todos los errores de video.

### E3-W10-04 · Se cerró el proceso del emulador durante el relato

**Estado:** reportado por el usuario y corroborado en Windows. **Clasificación:** incidencia del entorno; causa raíz sin determinar.

El usuario indicó que desapareció toda la ventana al pulsar «Siguiente», probablemente después de la página 6 de 7. ADB dejó de mostrar dispositivos y el proceso QEMU no estaba activo. El registro de aplicación de Windows, a las **14:51:57 (America/Bogota)**, identifica `qemu-system-x86_64.exe` con excepción `0xc0000005`, módulo desconocido. Esto confirma el fallo del emulador, pero no prueba que la app lo causara ni que faltara RAM. Después del fallo había 18,3 GB disponibles de 31,12 GB; esa medición no refleja necesariamente el instante del cierre.

Se reinició para continuar con `-gpu swiftshader -no-snapshot-load -no-snapshot-save`, solo como parámetros de esta sesión; no se editó la configuración persistente del AVD. En el segundo intento el usuario llegó hasta la página 7 sin reproducir videos. Al pulsar «Construir mi plan...» volvió a desaparecer toda la ventana. Windows registró otro fallo de QEMU con el mismo código a las **14:58:29**. Por tanto, SwiftShader por sí solo no resolvió la incidencia.

Se preparó un tercer intento distinto para aislar el editor: entrada directa a su ruta original, `-feature -Vulkan` en el emulador y `--no-enable-impeller --enable-software-rendering` en Flutter (Skia por software). El editor arrancó y el usuario pudo editar el paso, importar el contacto ficticio, rechazar otro permiso, agregar la actividad y guardar el entorno sin otro cierre durante esas interacciones. Son opciones temporales de arranque, no correcciones de la implementación. Este resultado no equivale a aprobar la estabilidad del recorrido normal con Impeller ni identifica cuál de los cambios de arranque evitó el cierre.

### Observación de audio

El usuario describe entrecortes leves, casi imperceptibles, en ambos videos, más notorios al hacer otras tareas en el computador. Los dos MP4 del bundle tienen el mismo SHA-256 que los originales del prototipo. Esto descarta una diferencia de archivos en esta copia, pero no valida la calidad de audio original ni identifica el origen de los entrecortes. Pendiente comprobar en un dispositivo Android real o reproducir los originales bajo condiciones comparables.

## Evidencia

- [Suite de 203 pruebas](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-pruebas.log).
- [Análisis](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-analisis.log).
- [Compilación y arranque normales](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-arranque.log).
- [Pruebas externas y resultados](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-pruebas-adicionales.log).
- [Referencia de contenido extraída del prototipo](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-prototipo.json).
- [Código de las pruebas externas](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/stage3_wave10_extra_verification_test.dart).
- [Entrada externa para el plan](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/stage3_wave10_plan_emulator.dart).
- [Compilación y arranque directo del plan](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-plan-arranque.log).
- [Activación observada](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-activacion.jpg).
- [Inicio del relato y primer video](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-relato-inicio.jpg).
- [Botón final desbordado en Android](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-relato-ultima-pantalla.jpg).
- [Actividad y entorno guardados en Android](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-editor-guardado.jpg).
- [Hashes de los videos](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-videos.json).
- [Registro de Windows del cierre](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-cierre-emulador.json).
- [Reinicio del emulador](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-emulador-reinicio.log).
- [Hashes de los 86 archivos de implementación](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-version.json).
- [Arranque directo del editor con Skia por software](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-editor-arranque.log).
- [Compilación del arranque habitual para restauración](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-restauracion-build.log).
- [Restauración del APK habitual](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-restauracion.log).
- [Activación habitual restaurada](C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/etapa3-wave10-arranque-habitual-restaurado.jpg).

## Pendientes concretos

1. Exponer una entrada al plan mientras el home completo sigue pendiente, para poder verificar su acceso normal sin un arnés externo.
2. Corregir el desbordamiento del botón final y verificar las dos etiquetas según el estado del plan.
3. Hacer que el respaldo aparezca también cuando falla la creación nativa del reproductor.
4. Investigar los dos cierres de QEMU y volver a comprobar el recorrido relato → editor con reproducción, incluyendo pausa y detención de audio, en un entorno Android estable. El editor aislado con Skia pasó; el recorrido normal no se da por aprobado.
5. Comprobar el audio fuera de esta sesión de emulador si continúan los entrecortes.

No se repitió la batería manual EMA de la etapa 2. No se implementaron onboarding, homes completos, UI del mapa, UI de notificaciones, modo crisis ni otras tareas de olas posteriores. La fecha y la sincronización automática no se modificaron en esta revisión.

**Estado al terminar:** la app normal quedó abierta en Activación. En esta sesión siguen activos los parámetros gráficos temporales del emulador y Skia por software para la ejecución actual de Flutter; no se incorporaron al manifiesto ni a la configuración del AVD. Al restaurar la app se reinició la sesión, por lo que el borrador ficticio del plan dejó de existir, conforme a su diseño de sesión. Las capturas conservan la evidencia previa.

Para reproducir las pruebas externas en esta misma máquina, desde el proyecto:

```powershell
& 'C:\Users\Lex\develop\flutter\bin\flutter.bat' test 'C:\Users\Lex\Documents\Codex\2026-10-27\ay\outputs\stage3_wave10_extra_verification_test.dart' --reporter expanded
```

Estas pruebas usan `etapa3-wave10-prototipo.json` en la misma carpeta de evidencias; no se añadieron a `test/` ni se cambiaron las pruebas de Kiro.
