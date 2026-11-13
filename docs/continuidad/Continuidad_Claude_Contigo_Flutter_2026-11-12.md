# Contigo Flutter: continuidad del desarrollo y diferencias frente al prototipo

**Fecha:** 12 de noviembre de 2026.  
**Destinatarios:** Lex y la siguiente sesión de desarrollo con Claude.  
**Objetivo:** acercar la aplicación Flutter a la navegación, presentación e interacciones del prototipo activo, conservando las reglas y correcciones ya verificadas. **Firebase permanece pendiente por decisión de Lex.**

## 1. Conclusión principal

Flutter tiene una base funcional considerable: EMA, construcción y gráficos del mapa, referencia EMA, mensajes de cuidado, recorridos del cuidador y recursos narrativos. Sin embargo, **el cierre de las verificaciones de Waves 10–13 no acredita equivalencia completa con el prototipo**. Esta comparación encontró conexiones todavía provisionales y diferencias visuales importantes.

La prioridad es completar el recorrido PCS de conexión con una persona, las acciones posteriores al EMA, el centro de ayuda y la navegación del cuidador. Después conviene recuperar los componentes visuales por pantalla. Estos cambios pueden desarrollarse con los repositorios locales y las simulaciones actuales, sin Firebase ni servicios de IA reales.

Este documento es un diagnóstico y una propuesta de continuidad. Durante su elaboración no se modificó la aplicación ni se implementaron las diferencias encontradas.

## 2. Versiones, fuentes y alcance de la comparación

| Elemento | Referencia |
| --- | --- |
| Flutter | https://github.com/LexMarcus27/app-proyecto-grado |
| Commit base Flutter | `1419eb2a30a6cc42ec645d7b0f72199c25e8edf5` — «Cierra Waves 12-13 y documenta Firebase pendiente» |
| Rama | `main`; checkout limpio al comenzar esta revisión |
| Prototipo publicado | https://proto-snout-38000733.figma.site/?demo=1 |
| Código React de referencia | https://github.com/LexMarcus27/contigo-prototype |
| Commit React consultado | `267ef91fe1a2b9f7c1c8dd7ced526a46b5837937`; coincidía con `main` remoto al consultar |
| Checkout Flutter local | `C:/Users/Lex/Documents/app-proyecto-grado` |
| Copia React consultada | `C:/Users/Lex/Documents/contigo-prototype-main/Contigo` |
| Especificación de migración | `.kiro/specs/contigo-flutter-migration/{requirements.md,design.md,tasks.md}` dentro de Flutter |

Se revisó directamente el sitio publicado: inicios PCS/cuidador, centro de ayuda, resultado del EMA, plan y su botón «Usar mi plan ahora», crisis, entrada al mapa, vínculos/perfil del cuidador y conexión PCS con Marta, incluido el borrador simulado de mensaje. Se contrastaron esas observaciones con rutas, componentes, estilos y estado de ambas bases de código.

La copia local de `src/` React se comparó con el checkout del repositorio de referencia: no se encontraron diferencias textuales, normalizando finales de línea. **El sitio publicado no expone aquí un identificador de commit verificable:** la correspondencia con React se comprobó en los recorridos observados, sin afirmar que todos sus archivos desplegados sean idénticos byte a byte a ese commit.

En esta revisión **no se volvió a ejecutar Flutter en Android ni se realizó una comparación visual píxel a píxel**. Las diferencias de Flutter indicadas como confirmadas se sustentan en su implementación actual; la evidencia Android previa se identifica por separado. Los detalles de espaciado, teclado, escalado y composición necesitan contraste posterior en dispositivo.

**Cómo interpretar los hallazgos:**

- **F:** diferencia funcional o de navegación confirmada por código, contrastada con la navegación activa del prototipo.
- **V:** diferencia de estructura o estilo confirmada en los componentes; su acabado necesita revisión visual Android.
- **A:** adaptación o decisión previamente acordada que debe conservarse.
- **P1/P2/P3:** orden de trabajo propuesto para fidelidad, no una clasificación de gravedad clínica.

Los enlaces de código de referencia pueden construirse a partir de estos árboles fijados:

- [Flutter, commit base](https://github.com/LexMarcus27/app-proyecto-grado/tree/1419eb2a30a6cc42ec645d7b0f72199c25e8edf5).
- [React, commit de referencia](https://github.com/LexMarcus27/contigo-prototype/tree/267ef91fe1a2b9f7c1c8dd7ced526a46b5837937/Contigo).

Las rutas cortas de archivos utilizadas en este documento se interpretan respecto de esas dos raíces; **React** significa la carpeta `Contigo/` del repositorio del prototipo.

## 3. Qué se ha trabajado y qué debe conservar Claude

### 3.1 Base técnica y estilo

Proyecto Flutter con Riverpod, `go_router`, modelos de dominio Dart, interfaces de repositorio y adaptadores locales/en memoria. Incluye tema, botones, tarjetas, notas con avatar, metadatos de simulación y recursos multimedia.

- `lib/app/`: aplicación, tema, rutas, sesión e inyección de dependencias.
- `lib/domain/`: journey, autorización, EMA, métricas, red, mensajes, conexión y notificaciones.
- `lib/data/`: persistencia del journey y referencia EMA; borradores y mensajes de sesión.
- `lib/presentation/`: pantallas y controladores por módulo.
- `lib/content/`: texto portado y estado de validación del contenido.
- `assets/`: Inter, Lora, licencias, vídeos e ilustraciones del prototipo.
- `test/`: pruebas de dominio, navegación, widgets y regresiones aportadas en las revisiones.

Inter está empacada para el cuerpo. Lora es la sustitución acordada de Georgia para títulos en Android. La existencia de una fuente serif en el tema no significa que todas las pantallas estén usándola con el tamaño o jerarquía del prototipo.

### 3.2 Etapa 2: EMA

Se implementó el recorrido diario oficial de **nueve ítems**, con selección inicial de persona vinculada, cambio explícito de referencia desde el mapa y controles visuales acordes con el prototipo: tres respuestas binarias iniciales y barras continuas sin valores numéricos visibles donde corresponda.

- Sin vínculo activo, se puede continuar con **seis preguntas**, omitiendo el bloque sobre la persona cercana.
- La recomendación principal sigue siendo construir/revisar el mapa; «Continuar con el registro de hoy» es la alternativa secundaria.
- La referencia EMA persiste mediante identificadores; las respuestas EMA permanecen en memoria de sesión.
- Se corrigieron referencia obsoleta, revocación en vivo, navegación hacia el mapa y reconciliación al cambiar de referencia.
- Se corrigió cambio de día al entrar, antes de avanzar y al recibir `AppLifecycleState.resumed`, con observador registrado y retirado correctamente.
- Las pruebas de reanudación mantienen la misma pantalla montada; no se limitan a desmontarla y volverla a abrir.

**No restaurar el banco histórico de 13 ítems** ni su pantalla de listado. El recorrido oficial más reciente es de nueve/seis según vínculo.

### 3.3 Etapa 3, Waves 10–13

| Bloque | Trabajo realizado |
| --- | --- |
| Wave 10 | Activación demo y rol, métricas de red, relato y editor del plan, dominio de notificaciones; correcciones de accesos, botones y respaldo de vídeo. |
| Wave 11 | Onboarding, inicio del cuidador, autorización compartida, hub PCS, notificaciones, crisis y respiración; contactos simulados y animación perceptible. |
| Wave 12 | Inicio PCS, construcción de red y mensajes de cuidado/bandeja; aislamiento de borradores, revocación, cambio de rol demo, guía, orígenes y tres expresiones del avatar. |
| Wave 13 | Mapa completo con gráficos y nodos pulsables, invitaciones simuladas, recorridos del cuidador, evaluación independiente de nueve preguntas, conversación PCS de seis preguntas y constructor guiado. |

Correcciones que no se deben perder:

- Una invitación aceptada **no basta** para habilitar acciones que exigen asociación activa.
- El mapa generado se puede consultar sin vínculos activos; eso es distinto de no tener mapa generado.
- Cambiar la referencia EMA exige confirmación; cancelar no guarda ni anuncia éxito.
- Los borradores de cuidado se aíslan por contexto completo del vínculo. No existe respaldo compartido `drafts['_']` para escrituras sin vínculo.
- Cambiar de vínculo invalida editor/vista previa/revisión; el envío compara con el contexto revisado.
- Revocar oculta y bloquea; reactivar la misma asociación recupera el estado de sesión donde ya fue implementado. Una asociación distinta no debe heredarlo.
- La bandeja PCS abre sin asociación activa, pero oculta mensajes de asociaciones revocadas.
- «Consultar ejemplos» permite volver al mensaje y conserva el texto más las ideas añadidas; los ejemplos se insertan de forma aditiva.
- Las notas privadas y preguntas de reflexión no se incluyen en el registro del mensaje enviado.
- El avatar tiene `welcome`, `thoughtful` y `affection`; se corrigió el recorte y la composición de la imagen.
- El constructor guarda un nombre al pulsar «Continuar» o «Revisar mi lista», sin exigir «+».
- Las preguntas PCS aceptan una pregunta inicial de notificación ajena al banco, anteponiéndola a la lista.
- El estado de preguntas PCS distingue PCS, persona y asociación activa.
- «Emergencias» se lee completo. Lex aprobó mantener el fondo beige en las franjas superior e inferior de crisis y apilar sus acciones inferiores.

### 3.4 Estado de verificación

La última ejecución independiente en este chat dio **`flutter analyze` limpio y 358 pruebas aprobadas**, antes de los últimos ajustes documentales. No se repitió la suite para elaborar este informe.

El informe actualizado de Wave 13, cerrado el 12 de noviembre, aprueba los 26 pasos originales y las correcciones acordadas. Registra expresamente:

- El caso de asociación nueva con la misma persona está cubierto por automatización; no se reprodujo manualmente con los controles UI disponibles.
- Al reentrar al constructor, el generador vuelve a 1/10; se conservan las personas, sus categorías y las respuestas guardadas. No se acredita conservar la posición de esa pantalla.
- No se volvió a comprobar el plan PCS en esa última ronda.
- El cierre de Wave 13 no es una auditoría global de toda la Etapa 3 ni una validación clínica.

Los informes originales de Waves 12 y 13 están en `C:/Users/Lex/Documents/Codex/2026-10-27/ay/outputs/`; los de Waves 10 y 11 también están copiados en `docs/verificacion/` del repositorio. No se debe dar por hecho que todos los informes y capturas externos estén disponibles al clonar GitHub.

## 4. Correspondencia de las pantallas activas

La fuente de verdad para saber qué está conectado es **`src/App.tsx`**, además de las acciones de cada pantalla. Un componente existente pero no conectado no demuestra un recorrido activo.

| Prototipo activo | Referencia React | Flutter actual | Diagnóstico |
| --- | --- | --- | --- |
| M1 Activación | `mobile.tsx`, `MobileScreen01` | `/`, `ActivationScreen` | Flujo demo presente; presentación simplificada. |
| M2 Inicio PCS | `home.tsx`, `MobileHomeScreen` | `/pcs` | Funciones accesibles, composición y navegación distintas. |
| M3 EMA | `ema.tsx`, `EmaScreen` | `/ema` | Base verificada; conservar reglas y contenido. |
| M4 Resultado EMA | `EmaScreen`, `view="result"` | `_ResultView` dentro de `/ema` | Faltan las acciones posteriores; F02. |
| M5 Plan | `mobile.tsx`, `MobileScreen05` | `/plan-seguridad` | Editor presente; destinos incorrectos y detalles visuales pendientes. |
| M6 Crisis | `MobileScreen06` | `/necesito-ayuda` | Recorrido simulado presente; adaptaciones aprobadas. |
| M7 Respiración | `MobileScreen07` | `/respiracion` | Animación y contactos simulados presentes. |
| M8 Conexión con persona | `MobileScreen08` | Sin ruta PCS equivalente | Faltan asistente, contacto y preparación de encuentro; F01. |
| M9 Inicio cuidador | `caregiver-home.tsx` | `/cuidador` | Tarjeta sin acción, grid ausente y navegación simplificada. |
| M10 Mensaje íntimo | `MobileScreen10` con `messageKind="intimate"` | `/cuidador/mensaje-intimo` | Recorrido implementado, con estado de sesión. |
| M11 Plan cuidador | `MobileScreen11` | `/cuidador/plan-acompanamiento` | Implementado y verificado en el alcance acordado. |
| M12 Registro cuidador | `MobileScreen12` | `/cuidador/registro-vinculo` | Formulario presente; cierre y retorno difieren. |
| M9A Encuentro | `MobileScreen09A` | `/cuidador/encuentro` | Evaluación de cuatro respuestas; no sustituye planear un encuentro PCS. |
| M17 Red | `network.tsx`, `SocialNetworkScreen` | `/mapa-red` y `/mapa-red/construir` | Construcción y gráficos presentes; falta parte de entrada/gestión. |
| M20 Necesito ayuda | `help-hub.tsx`, `HelpHubScreen` | Sin equivalente | `/necesito-ayuda` contiene crisis directamente; F03. |
| M21 Tejiendo vínculos PCS | `connection-hub.tsx` + `connection-person.tsx` | `/tejiendo-vinculos` | Rota el paso, pero acciones dirigidas siguen provisionales. |
| M22 Aprender cuidador | Vista `learning` de `caregiver-home.tsx` | Hoja modal de aprendizaje | Contenido pendiente coincidente; estructura distinta. |
| M23 Vínculos cuidador | Vista `connections` | Sin hub propio | Se abre directamente la redacción; F06. |
| M24 Perfil cuidador | Vista `profile` | Sin pantalla equivalente | Parte de la navegación inferior pendiente. |
| M25 Relato del plan | `safety-plan-story.tsx` | `/plan-seguridad/relato` | Siete páginas, vídeos y simulación de plan presentes. |
| M26 Mensajes de cuidado | `caring-message.tsx` | `/mensajes-de-cuidado/redactar` | Flujo principal presente; estado de lectura y formato difieren. |
| M27 Recibidos PCS | `caring-message-inbox.tsx` | `/mensajes-de-cuidado` | Bandeja presente; retorno y botón de apoyo difieren. |
| M14 Preguntas PCS/cuidador | `social.tsx`, `MobileScreen14`; casos 18/19 | `/preguntas-conectar` y `/cuidador/preguntas-conectar` | Seis preguntas implementadas para ambos roles. |
| D13/D14/D15 | `desktop.tsx` | Excluidos de la app móvil | Fuera del alcance acordado. |

**Evaluación de nueve preguntas:** `MobileScreen13` existe en `social.tsx`, pero no está conectado en la navegación activa del prototipo revisado. Flutter lo conserva como `/evaluar-relacion`, con tile propio «Evaluar una relación», por acuerdo previo. No confundirlo con las seis preguntas conversacionales ni añadirlo después de los 18 ítems del mapa.

## 5. Diferencias funcionales confirmadas

### F01 · P1 · Falta el recorrido PCS completo de conexión con una persona

**Prototipo:** M21 permite elegir una persona desde un pequeño mapa/lista (`ConnectionPersonScreen`), y abrir M8 «Conexión con {persona}». M8 incluye recibidos, preguntas compartidas, llamada/audio simulados, borrador de mensaje para tejer cercanía, actividades propias y preparación/revisión de una invitación a un encuentro.

**Flutter:** `connection_hub_screen.dart:161–201` termina mensaje/contacto/encuentro en `_showPending`. El router no tiene una pantalla PCS equivalente a M8. Mostrar una explicación no reproduce esos recorridos. Además, el destacado toma `people.first`, sin preferir la selección vigente como React.

**Trabajo propuesto:** implementar selector/contexto PCS y acciones dirigidas, conservando persona e intención. El asistente debe seguir siendo simulado: generar borrador de ejemplo, editar, regenerar, copiar y marcar como preparado. Contacto debe poder representar llamada/audio y preparar saludo; encuentro debe permitir elegir/agregar actividad, editar invitación y revisarla. No abrir servicios ni comunicaciones reales.

**Referencias:** Flutter `connection/connection_hub_screen.dart`, `app/router.dart`; React `screens/connection-hub.tsx`, `screens/connection-person.tsx`, `screens/mobile.tsx:968–1367`, `App.tsx:178–207`.

**Aceptación:** desde los tres pasos se alcanza una interacción útil para la persona elegida; volver conserva el contexto razonable, revocar bloquea, y otra asociación no hereda borradores. La evaluación de un encuentro del cuidador no se reutiliza como preparación de encuentro PCS.

### F02 · P1 · El resultado del EMA conserva una versión provisional de Etapa 2

**Prototipo:** tarjetas «Pequeño · 1 min aprox.» para recibidos, «Mediano · 5 min aprox.» para contacto/mensaje y «Más grande · esta semana» para encuentro. Incluye habilidades, «Ahora no», resumen desplegable y acceso al plan.

**Flutter:** `ema_flow_screen.dart:1036–1135` muestra resumen, «Pronto podrás elegir un paso…» y volver al inicio. No enlaza esas herramientas.

**Trabajo propuesto:** completar esta vista después de F01; respetar tamaños narrativos, persona e intención. Los tiempos son orientación para la PCS, **no reglas de temporización, elegibilidad ni recomendaciones derivadas de respuestas EMA**.

**Aceptación:** los accesos llevan a recibidos, selección/contacto/mensaje, encuentro, habilidades y plan; el cuestionario y sus reglas permanecen intactos. Referencia React: `screens/ema.tsx:89–100`.

### F03 · P1 · Falta el centro «¿Qué necesitas ahora?»

**Prototipo:** Inicio PCS → «Necesito ayuda» → M20 con «Ver plan de seguridad», «Necesito ayuda ahora» y «Afrontar una crisis»; destinos M5, M6 y M25.

**Flutter:** el tile del inicio abre directamente `crisisMode` (`pcs_home_screen.dart:171`); no existe `HelpHubScreen` equivalente.

**Trabajo propuesto:** crear el centro y separar su ruta de la de crisis. El botón flotante de apoyo puede seguir abriendo crisis directamente, como en React; no debe confundirse con el tile del centro de ayuda.

**Aceptación:** las tres alternativas y sus retornos son accesibles. React: `screens/help-hub.tsx`; Flutter: `app/router.dart`, `pcs_home/pcs_home_screen.dart`.

### F04 · P1 · «Usar mi plan ahora» lleva al destino incorrecto

**Confirmado:** en el sitio publicado abre M6. En Flutter, `safety_plan_editor_screen.dart:202–204` ejecuta `goNamed(AppRoute.pcsHome)`. La flecha superior también vuelve al inicio, mientras React vuelve a M20.

**Trabajo propuesto:** botón principal → crisis; flecha → centro de ayuda cuando exista F03. Mantener el editor de sesión y los estados vacío/diligenciado ya aprobados.

**Aceptación:** usar el plan no devuelve al home; consultar/editar y volver conserva una navegación coherente con M20. React: `screens/mobile.tsx`, `MobileScreen05`.

### F05 · P1 · La tarjeta «Mi vínculo con…» del cuidador no es pulsable

**Prototipo y decisión expresa de Lex:** la tarjeta superior abre el registro de relación M12. «Proveer apoyo» abre el plan de acompañamiento M11.

**Flutter:** `_LinkCard`, `caregiver_home_screen.dart:228–277`, construye una tarjeta sin `onTap`. Su flecha sugiere una acción que no existe.

**Trabajo propuesto:** registrar `onTap` hacia `caregiverLinkCheckIn` cuando el vínculo esté autorizado. Conservar bloqueo sin asociación activa. Añadir «Proveer apoyo» según V03 hacia `caregiverSupportPlan`.

### F06 · P1 · Falta el hub «Tejiendo vínculos» del cuidador

**Prototipo:** M23 presenta cuatro opciones paralelas: mensaje íntimo, mensaje de cuidado, preguntas para conectar y registrar encuentro.

**Flutter:** el tile «Tejiendo vínculos» del home abre `caringCompose` directamente (`caregiver_home_screen.dart:88–95`). Los otros recorridos se alcanzan desde la bienvenida de redacción, una jerarquía diferente. Las salidas del recurso retornan al home, aunque alguna etiqueta dice volver a Tejiendo vínculos.

**Trabajo propuesto:** crear el hub M23, enlazar las cuatro pantallas existentes y devolver sus recursos al hub cuando corresponda. Conservar los enlaces ya útiles hasta terminar la transición.

**Aceptación:** no es necesario entrar al recurso de mensajes de cuidado para descubrir preguntas, encuentros o mensaje íntimo. React: `screens/caregiver-home.tsx`, vista `connections`; Flutter: `caregiver_home_screen.dart`, `caring_compose_screen.dart`, `app/router.dart`.

### F07 · P1 · Las notificaciones aún tienen destinos y estado incompletos

Las notificaciones de preguntas fueron corregidas y deben conservarse. Persisten otras diferencias:

- `notifications_screen.dart:155–159` muestra «Herramienta en preparación» para mensaje/contacto/encuentro; React abre M8 con persona e intención.
- El banner de Inicio PCS abre la bandeja (`pcs_home_screen.dart:78`), en lugar de ejecutar la acción de esa notificación.
- Cerrar el banner llama `clear()` y **vacía toda la bandeja** (`notifications_controller.dart:48`); React separa `visibleNotification` de `notifications` y oculta solo el aviso.
- El home Flutter toma la última notificación sin filtrar su persona por autorización vigente para mostrar el banner. React filtra el aviso cuando el vínculo ya no está autorizado. El bloqueo al abrir no equivale a ocultar la tarjeta obsoleta.

**Trabajo propuesto:** unificar el despacho por acción/persona con F01, separar visibilidad del banner e historial, y aplicar autorización al contenido mostrado. El límite de 12 avisos y el orden de la bandeja React son detalles secundarios de paridad.

**Aceptación:** cerrar un aviso no borra el historial; pulsarlo abre la herramienta correcta; una revocación deja de mostrar su contenido dirigido. React: `App.tsx:173–190`, `screens/home.tsx`.

### F08 · P2 · La red pierde parte de la entrada y la revisión posterior

**Prototipo:** entrada explicativa «Conoce tu red», «¿Por qué te preguntamos esto?», construir/aplazar; acceso al avance de la red y presentación introductoria por persona. Desde resultados existen «Editar respuestas» y acciones para fortalecer/consultar el vínculo.

**Flutter:** el constructor empieza en `_BuildStage.names`; desde Inicio, si no hay mapa generado, entra directamente allí. El detalle de resultados ofrece referencia EMA, invitación y cerrar, pero no «Editar respuestas» ni fortalecer el vínculo. La edición no está enlazada directamente desde ese detalle.

**Trabajo propuesto:** recuperar la introducción y el acceso al resumen/edición sin obligar a pasar de nuevo las diez preguntas. Conectar «Fortalecer este vínculo» al recorrido PCS de F01 cuando esté autorizado. Mantener gráficos, fórmulas, semántica de nodos, invitaciones y confirmación EMA.

**Aceptación:** una red en progreso puede retomarse de forma comprensible; desde una persona en resultados se revisan sus respuestas y se regresa al mapa. **Conservar la posición exacta 1/10 tras reiniciar es una mejora por acordar**, no una propiedad certificada previamente ni una diferencia demostrada en toda la persistencia del prototipo.

**Referencias:** React `screens/network.tsx`, vistas `intro`, `summary`, `person-intro` y detalle final (`Editar respuestas` alrededor de línea 2638); Flutter `network_builder_screen.dart:16–46`, `network_map_screen.dart:735–866`.

### F09 · P2 · Caracterizar una relación avanza al tocar la opción

React permite seleccionar y luego pulsar el botón de avance en los 18 ítems. Flutter guarda y avanza desde `_answerItem`, directamente al tocar la respuesta. La categoría avanza al tocarla en ambos proyectos; esa parte no es una diferencia.

**Trabajo propuesto:** reproducir selección y confirmación explícita según cada paso del prototipo, manteniendo una sola captura del tipo y los 18 ítems existentes. No añadir preguntas para compensar el cambio de interacción.

**Aceptación:** se puede reconsiderar una opción antes de avanzar. React: `network.tsx`, `saveAssessmentAnswer` y botón alrededor de 1858; Flutter: `network_builder_screen.dart:449–515`.

React también ofrece «Guardar y continuar después» durante la caracterización. Flutter permite salir mediante la navegación y conserva respuestas ya guardadas, pero no muestra esa acción explícita; recuperarla ayuda a reproducir el recorrido sin cambiar la política de persistencia.

### F10 · P2 · La lectura de la guía de mensajes no vive en la sesión del vínculo

React conserva `caringGuidesReviewed[caringKey]` en `App.tsx`, fuera de la pantalla. Flutter mantiene `_visitedGuidePages` dentro del `State` de `CaringComposeScreen`; al desmontar y volver a entrar se pierde ese seguimiento, aunque el borrador siga en su provider.

**Trabajo propuesto:** conservar el estado «guía revisada» en memoria de sesión por contexto del vínculo. No persistir datos adicionales en disco ni habilitar orígenes antes de recorrer las seis partes.

**Aceptación:** después de completar la guía y salir/volver durante la misma sesión, «Cómo empezó todo» sigue disponible para ese vínculo; otra asociación no hereda la lectura sin una decisión explícita. Referencias: React `App.tsx:120,298` y `caring-message.tsx`; Flutter `caring_compose_screen.dart:57–61`.

### F11 · P2 · «Cómo empezó todo» no retorna al punto de origen

React guarda `originReturnView` para volver a la guía, editor o bienvenida. Flutter siempre ofrece «Volver al recurso» y retorna a `welcome` (`caring_compose_screen.dart:691–700`). Tampoco ofrece el acceso a orígenes desde el editor como React.

**Trabajo propuesto:** conservar el origen del acceso; añadir el acceso desde el editor únicamente cuando la guía ya fue revisada. El texto del borrador debe conservarse.

### F12 · P3 · El registro del cuidador termina de otra manera

React M12 ofrece «Completar después» y, al guardar, comunica que es de prueba y vuelve al inicio después de la confirmación temporal. Flutter muestra una pantalla de éxito sin ese retorno automático y no incluye el botón secundario «Completar después» dentro del formulario.

**Trabajo propuesto:** recuperar las acciones y cierre del recorrido; conservar las respuestas por vínculo y el bloqueo ante revocación. No reemplazar este formulario de prueba por un banco clínico inventado.

**Referencias:** React `screens/mobile.tsx:1684–1790`; Flutter `caregiver_journeys/caregiver_journey_screens.dart:340–443`.

## 6. Diferencias de composición y estilo

### V01 · P2 · Los dos inicios no reproducen su diseño principal

En React, ambos inicios tienen tarjetas en **dos columnas**, títulos serif grandes, ilustración de planta y avatares de colores. Flutter usa una columna de tarjetas blancas, títulos «Inicio PCS»/«Inicio Cuidador» a 24 px y carece de esa planta.

Para Inicio PCS, React tiene cuatro tarjetas principales en este orden: red, conexión, ayuda y EMA. Flutter añade varios accesos principales para facilitar la revisión: preguntas, evaluación de nueve, recibidos y relato. Su existencia es útil, pero cambia la jerarquía visual. **No eliminarlos sin resolver primero su ubicación**; la evaluación de nueve fue conservada expresamente y necesita un lugar acordado.

Referencias: React `home.tsx`, `caregiver-home.tsx`, `index.css` (`home-hero`, `home-tile-grid`, `caregiver-grid`); Flutter `pcs_home_screen.dart`, `caregiver_home_screen.dart`.

### V02 · P2 · Falta la navegación inferior de ambos roles

No hay navegación inferior equivalente en el router/pantallas Flutter revisados.

- PCS: Inicio, Vínculos, Mi día y Perfil. En React, Perfil abre una hoja sencilla y Vínculos lleva a Tejiendo vínculos.
- Cuidador: Inicio, Aprender, Vínculos y Perfil. React tiene vistas dedicadas; Flutter muestra aprendizaje en una hoja y no tiene perfil equivalente.

El perfil del prototipo es sencillo: replicarlo no requiere construir gestión de cuenta real ni Firebase. Conviene crear una estructura común por rol, respetando las guardas y la disposición móvil.

### V03 · P1 · Faltan los botones flotantes persistentes de apoyo

El prototipo utiliza «Necesito apoyo» en numerosos recorridos PCS y «Proveer apoyo» en los del cuidador. Los componentes Flutter revisados no contienen un equivalente persistente: tener un tile en el home no reproduce ese acceso durante otros recorridos.

Crear un componente reutilizable con su espacio reservado y destino por rol: PCS → crisis; cuidador → plan de acompañamiento, deshabilitado sin autorización. Recuperar la forma de pastilla roja, icono y ubicación, con la separación compacta que pidió Lex. Evitar tapar contenido, teclado, pies y navegación inferior. No introducir el botón dentro del propio modo crisis si el prototipo no lo utiliza allí.

Referencias: React `ui.tsx`, `FloatingSupportBtn` y `supportContentPadding`; Flutter `presentation/widgets/` y pantallas de EMA, plan, relato, conexión, mensajes y home.

### V04 · P2 · El color de un botón depende del módulo, no de un único primario

| Uso | Prototipo | Flutter actual / acción necesaria |
| --- | --- | --- |
| `Btn` general, activación y varios formularios | `C.brand = #A85550` | `ContigoButton.primary` usa `#AA461D`; crear la variante adecuada. |
| Botón crítico general | `C.critical = #A3474A` | Variante critical usa `clay = #8D4541`; distinguir funciones de estos tokens. |
| Pantallas internas PCS con `.pcs-primary` | Terracota `#AA461D` | Mantener donde corresponda; no reemplazar globalmente por rosa. |
| Acción del EMA | Azul `#3174A1` | Ya tiene estilo específico; conservarlo. |
| Borde neutro habitual | `#DFD4C9` | Varias tarjetas/botones Flutter usan `notifMeetingBg = #F2E3E0` como borde; contrastar por componente. |
| Cuidado / salvia / lila | Usos diferenciados por pantalla | No utilizar la paleta de notificaciones como sustituto universal de fondos. |

Esto no exige reescribir todo el tema. Hace falta mapear correctamente los tokens y las variantes existentes. Referencias: React `ui.tsx`, `index.css`; Flutter `app/theme.dart`, `widgets/contigo_button.dart`, `widgets/contigo_card.dart`.

### V05 · P2 · Los recursos de mensajes volvieron a un formato más plano

React utiliza secciones narrativas con borde lateral, fondo suave y esquinas asimétricas; la variante `.caring-section--sage` del código actual usa **lila** (`#EEE6F2`, borde `#9B84A8`), pese al nombre histórico de la clase. Hay títulos fuertes, listas ordenadas/no ordenadas y cajas para ejemplos/preguntas.

Flutter `_GuideSection` es un `Padding` con una columna de títulos/párrafos. Se pierden cajas, variante lila y presentación de listas; los encabezados de recurso usan `titleLarge` sans serif frente a los títulos Georgia de React. La definición también debe evitar repetir «¿Qué son?» al inicio del primer párrafo, como ya hace React con `replace`.

Recuperar estos componentes sin reescribir el contenido. Mantener las tres expresiones del avatar y comprobar que su fondo no reaparece blanco al desplazar. Referencias: React `index.css:489,516–532`, `caring-message.tsx`; Flutter `caring_compose_screen.dart:339–466,855–880`.

### V06 · P2 · Cabeceras, jerarquía y tarjetas internas están demasiado generalizadas

Ejemplos comprobables: el destacado del hub usa una tarjeta común; «Otros pasos» se apila como filas y no como la rejilla del prototipo; los títulos de relato/recurso y vínculo usan estilos genéricos que no replican los tamaños, serif y espaciados de cada módulo. El logo de activación se aproxima con texto «Contigo» y no reproduce el componente gráfico `ContigoLogo`.

Portar las composiciones particulares, conservando Lora como sustitución acordada. Revisar cada módulo a 390 y 412 px lógicos, además de texto ampliado. No resolver etiquetas largas reduciendo indiscriminadamente la fuente: ya se corrigió `ContigoButton` para permitir crecer en alto.

### V07 · P3 · Varias hojas se sustituyeron por diálogos o pantallas

El editor del plan usa diálogos para edición y altas que React presenta mediante `BottomSheet` o entrada integrada. El onboarding aparece como tarjeta más pantalla independiente en Flutter, mientras React abre la bienvenida como hoja sobre el home. Recibidos vuelve al inicio en Flutter y a Tejiendo vínculos en React.

Revisar los retornos como parte de la navegación y después acercar formato, transición y altura al diseño. No abrir permisos reales de contactos: el prototipo también agrega un contacto ficticio tras un permiso simulado.

## 7. Adaptaciones y límites que deben conservarse

| ID | Decisión / alcance |
| --- | --- |
| A01 | Firebase/Google Cloud está aplazado. No añadir Auth, Firestore, sincronización, push ni reglas de servidor en esta ronda de fidelidad. |
| A02 | Envíos, activación, llamadas, audio, fotos e invitaciones siguen simulados. Completar una interacción simulada sí es necesario; contratar un servicio real no lo es. |
| A03 | Journey y referencia EMA persisten localmente según el diseño. Respuestas EMA, mensajes y otros borradores clínicos de demo permanecen en sesión. No cambiar esa política para «arreglar» una pantalla. |
| A04 | Guardas por rol y autorización por la tupla exacta PCS/cuidador/persona/asociación se conservan. No habilitar por tener una invitación `accepted` sin asociación activa. |
| A05 | Lora sustituye a Georgia en Android; Inter está empacada. El ajuste de fidelidad afecta aplicación/tamaños/jerarquía, no obliga a distribuir Georgia. |
| A06 | Fondo continuo beige y acciones inferiores de crisis legibles/apiladas son ajustes aprobados por Lex; no revertirlos por una copia literal del prototipo. |
| A07 | Las nueve preguntas de evaluación siguen separadas de conversación PCS/cuidador y de los 18 ítems del mapa. Su acceso extra requiere acordar ubicación si se reorganiza el home. |
| A08 | Gráficos/umbrales/orientaciones y marcadores `[[...]]` pendientes no se convierten en contenido clínicamente validado por estar portados. No inventar textos o reglas JITAI. |
| A09 | El escritorio de investigador/administrador no forma parte de esta app móvil. No copiar D13–D15 como supuesta funcionalidad faltante. |
| A10 | El botón «Necesito ayuda con mi código» tampoco tiene acción implementada en React; su no-op no demuestra por sí solo una regresión del portado. El contenido pendiente de habilidades también es compartido por ambos. |
| A11 | Modo crisis contiene ejemplos estáticos también en React. Su falta de integración con el plan editable es una limitación compartida; no presentarla como diferencia exclusiva de Flutter ni inventar un flujo clínico nuevo. |
| A12 | El asistente PCS de React genera un ejemplo local con temporizador. Su texto sobre IA no acredita un modelo real ni exige integrar uno para reproducirlo. |

## 8. Orden de trabajo recomendado para Claude

Trabajar por bloques pequeños, con una entrega y revisión por bloque. No reemplazar la arquitectura ni reiniciar la migración.

| Bloque | Alcance concreto | Resultado revisable |
| --- | --- | --- |
| 1. Ayuda y accesos | F03, F04, F05; base reutilizable de V03 | Centro de ayuda, botón del plan correcto, tarjeta de vínculo funcional y apoyo por rol. |
| 2. Conexión PCS | F01, conservando contexto y autorización | Selector de persona y M8 con mensaje/contacto/encuentro simulados completos. |
| 3. EMA y notificaciones | F02 y F07 sobre el bloque 2 | Post-EMA completo; avisos con destino correcto e historial independiente del banner. |
| 4. Navegación y homes | F06, V01 y V02 | Hub cuidador, pestañas por rol y grid/plantas/jerarquía; ubicación acordada de accesos extra. |
| 5. Red y guía | F08–F11, V05 | Revisión de respuestas desde resultados, entrada al mapa y lectura/orígenes conservados por contexto. |
| 6. Acabado | V04, V06, V07 y F12 | Variantes de color, títulos, hojas, retornos y cierre de formularios. |

Los controles de desarrollo deben seguir disponibles para probar, pero pueden agruparse y plegarse como en el prototipo, en lugar de dominar las pantallas de uso. No ocultar las advertencias necesarias para distinguir las simulaciones.

Para ahorrar uso de Claude: pedir un solo bloque, leer los archivos implicados y sus pruebas, implementar, ejecutar verificaciones pertinentes y resumir cambios. Evitar encargar otra vez toda la migración, auditorías repetidas de cada etapa o una reescritura global.

## 9. Criterios de aceptación y regresión

1. **Navegación activa:** cada tarjeta, botón y notificación del bloque abre la vista que corresponde, con persona/intención correctas. No reemplazar una acción del prototipo por «próximamente».
2. **Estados:** comprobar vacío, en progreso, completo, sin vínculo, aceptación sin asociación, revocación y nueva asociación donde el cambio los afecte.
3. **EMA protegido:** conservar nueve/seis preguntas, referencia confirmada, omisión, cambio de día y respuestas en memoria; las acciones posteriores no dependen de reglas clínicas nuevas.
4. **Mensajes protegidos:** inserción aditiva, notas privadas excluidas, revisión de contexto, borradores sin respaldo compartido, revocación y aislamiento por asociación.
5. **Mapa protegido:** mismas 10 preguntas de nombres, categoría +18 ítems, escalas y fórmulas; generar con al menos una relación completa; consultar gráficos sin vínculos activos; nodos pulsables; referencia EMA con confirmación/cancelación correctas.
6. **Diseño:** misma estructura y jerarquía, colores por módulo, tres expresiones del avatar, serif donde corresponda, botones de apoyo sin cubrir contenido y etiquetas completas.
7. **Pruebas:** mantener las expectativas de las regresiones externas en `test/stage2/` y `test/stage3/`. Si cambia legítimamente una etiqueta temporal como «Inicio PCS», actualizar solo la expectativa afectada; las pruebas no deben obligar a conservar un texto ajeno al diseño final.

Verificación técnica habitual desde la raíz Flutter:

```powershell
& 'C:/Users/Lex/develop/flutter/bin/flutter.bat' analyze
& 'C:/Users/Lex/develop/flutter/bin/flutter.bat' test
```

Ejecutar pruebas puntuales durante un bloque y la suite al cerrar cambios integrados. La última cifra de 358 es una línea base, no un objetivo fijo ni una garantía de fidelidad de pantallas aún no contrastadas.

Para revisión Android, utilizar un dispositivo estable o la configuración temporal ya documentada: emulador SwiftShader, Vulkan desactivado y Flutter con Impeller desactivado. No usar `--enable-software-rendering` para verificar vídeo: previamente produjo vídeo negro con audio. No incorporar estos cambios gráficos de forma permanente al proyecto/AVD sin una decisión específica. La causa de cierres históricos de QEMU sigue sin determinarse.

## 10. Documentación que necesita reconciliarse

- `tasks.md` conserva al principio un aviso del **5 de noviembre** que dice Wave 12 no verificada, aunque las notas finales registran su cierre y el de Wave 13. Debe marcarse como aviso histórico o reemplazarse por un estado actual claramente fechado.
- El padre «3. Demás módulos» sigue sin marcar, mientras las tareas obligatorias y las notas de cierre afirman implementación. Las opcionales continúan sin ejecutar. Conviene aclarar el criterio de cierre, sin marcar pruebas opcionales como realizadas ni convertir el cierre manual en una auditoría total.
- Varios comentarios de pantallas dicen que funciones «llegan en Etapa 3» o «Waves 12–13»; algunos describen comportamientos que siguen provisionales. Resolver el código antes de borrar esas advertencias como si ya estuviera terminado.
- En `caring_compose_screen.dart` algunos comentarios llaman a la redacción del cuidador «mensaje para tejer cercanía». Distinguir cuidado cuidador→PCS, íntimo cuidador→PCS y cercanía PCS→persona; sus formatos y permisos no son intercambiables.
- El README registra cierres en el alcance documentado. Mantener ese límite y el estado Firebase pendiente; este informe añade un backlog de fidelidad, sin invalidar las pruebas manuales que sí se completaron.

## 11. Pendientes de contraste visual posterior

Esta comparación no certifica posiciones exactas de nodos, equivalencia de todos los iconos, altura de cada cabecera, saltos de página narrativos, comportamiento con teclado ni todos los estados de orientación/escala de texto. Revisarlos por módulo al implementar su bloque, usando iguales datos y ancho lógico.

En particular, revisar los dos gráficos y sus leyendas frente al SVG React, la guía completa con sus ilustraciones, el control nativo de vídeo y sus estados de error/pausa/salida, el círculo de respiración y las opciones de accesibilidad. No se afirma una diferencia concreta en estos detalles sin comprobarla.

Los resultados de verificación anteriores corresponden a escenarios acordados; una nueva comparación de fidelidad puede encontrar diferencias fuera de esos escenarios. Una prueba automatizada verde no sustituye revisar el flujo activo ni su diseño.

## 12. Mensaje breve para comenzar la siguiente sesión

> Continúa Contigo Flutter desde el commit `1419eb2`. Lee este informe y revisa los archivos del primer bloque antes de editar. El objetivo actual es fidelidad al prototipo activo, conservando las reglas, textos y simulaciones ya acordadas. Firebase queda pendiente. Empieza solo por el bloque 1: centro de ayuda, destinos del plan, tarjeta de vínculo y base del botón de apoyo por rol. Mantén las regresiones existentes, valida los cambios pertinentes y detente para revisión antes del bloque 2.

Claude necesitará acceso al checkout Flutter y al código React de referencia para aplicar el trabajo; este documento transmite contexto y evidencia, pero no contiene ambos repositorios completos.
