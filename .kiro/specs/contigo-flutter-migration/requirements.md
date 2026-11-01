# Requirements Document

## Introduction

Este documento define los requisitos para migrar el prototipo "Contigo" (app de apoyo en salud mental para personas con conducta suicida y sus cuidadores) desde el prototipo web React/Vite hacia una app móvil Flutter respaldada por Firebase/Google Cloud. La fuente autoritativa del comportamiento actual es `docs/analisis-prototipo.md` (derivado del commit `267ef91`); este documento no repite ese análisis, lo referencia.

El alcance propuesto cubre **solo dos roles**: PCS (persona con conducta suicida) y Cuidador, y deja el panel de escritorio del investigador/admin **fuera de alcance** (herramienta aparte). Estas decisiones de alcance —los dos roles, la exclusión del panel del investigador y la estratificación local → simulación → Firebase— se registran como **propuestas pendientes de confirmación**, no como decisiones finales.

La app se construye en tres capas/etapas claramente separadas (ver Requirement 3):
- **Capa_Local**: funcionalidad real que opera por completo en el dispositivo, sin backend.
- **Capa_Simulada**: funcionalidades que se fingen localmente y luego serán reales.
- **Capa_Firebase**: etapa posterior de integración con autenticación real, persistencia y reglas de seguridad del lado servidor.

Principios rectores:
- Preservar textos, estilo visual y comportamientos del prototipo.
- Distinguir con claridad la Capa_Local, la Capa_Simulada y la Capa_Firebase: lo que el prototipo simula arranca como simulación en Flutter y luego se reemplaza por funciones reales en la etapa de integración con Firebase.
- La autorización por asociación activa es lógica real a portar; en la Capa_Local opera como control de interfaz del cliente y, en la Capa_Firebase, **debe respaldarse además en el backend** (reglas de seguridad de Firebase), no solo en el cliente.
- Los contenidos clínicos suministrados se preservan **literalmente** (carácter por carácter); el estado de validación se documenta **por tipo de contenido** (no como un descargo único en toda la interfaz).

## Glossary

- **App_Contigo**: la aplicación móvil Flutter objeto de esta migración.
- **PCS**: persona con conducta suicida; rol de usuario principal.
- **Cuidador**: usuario vinculado a un PCS mediante una asociación de cuidado.
- **Modulo_Autorizacion**: componente que decide si una acción de fortalecimiento/contacto está permitida según la asociación activa.
- **Asociacion_Activa**: estado en que existe una invitación `accepted` y una asociación `active` que coincide con la tupla exacta (pcsId, caregiverId, personId).
- **Backend_Firebase**: Firebase/Google Cloud previsto como sustrato de datos, autenticación y reglas de seguridad.
- **Reglas_Seguridad**: reglas de seguridad de Firebase que respaldan la autorización del lado servidor.
- **Modulo_EMA**: banco de ítems EMA, borrador, referencia, día, omisión y completitud (`EMA_VERSION = "daily-nine-v2"`).
- **Modulo_Metricas_Red**: motor `metricsFor` de puntuación POMP, anillos y clasificación de relaciones.
- **Modulo_Plan_Seguridad**: editor de `SafetyPlanDraft` (pasos, contactos, actividades, entorno).
- **Modulo_Mensajes_Cuidado**: contenido educativo, borradores y registro de mensajes de cuidado.
- **Contenido_Clinico**: textos suministrados (banco EMA, relato del plan de seguridad, guion/ejemplos de mensajes de cuidado) a preservar verbatim.
- **Funcion_Simulada**: comportamiento que el prototipo finge localmente y que la App_Contigo mantiene como simulación (Capa_Simulada) hasta ser reemplazado por una función real.
- **Funcion_Real**: función respaldada por Backend_Firebase (Capa_Firebase) que reemplaza a una Funcion_Simulada.
- **Capa_Local**: funcionalidad real que opera por completo en el dispositivo sin backend (p. ej. flujo EMA, cálculo `metricsFor`, editor del plan de seguridad, editor de mensajes de cuidado y el gating de autorización como lógica de interfaz del cliente).
- **Capa_Simulada**: conjunto de funcionalidades que se fingen localmente y serán reales más adelante.
- **Capa_Firebase**: etapa posterior de integración con autenticación real, persistencia y Reglas_Seguridad del lado servidor.
- **Estado_Validacion_Contenido**: estado de validación registrado por tipo de contenido a nivel de documentación/metadatos del proyecto, no como descargo en la interfaz.
- **Contenido_Validacion_Pendiente**: umbrales y cortes (evaluación de relación, métricas de red) cuya validación clínica está pendiente.
- **Referencia_EMA**: persona de referencia del EMA recordada entre registros, almacenada únicamente mediante identificadores de persona.

## Requirements

### Requirement 1: Plataforma Flutter y alcance de roles

**User Story:** Como equipo de producto, quiero una app móvil Flutter que cubra solo los roles PCS y Cuidador, para reimplementar el prototipo con un alcance acotado.

#### Acceptance Criteria

1. THE App_Contigo SHALL implementarse como aplicación móvil desarrollada en Flutter, ejecutable en dispositivos móviles iOS y Android.
2. THE App_Contigo SHALL habilitar el acceso a sus funcionalidades únicamente para los roles PCS y Cuidador, conforme a la decisión de alcance propuesta y pendiente de confirmación.
3. IF un usuario tiene un rol distinto de PCS o Cuidador, THEN THE App_Contigo SHALL denegar el acceso a las funcionalidades de la app, conservar la sesión sin cargar datos de otros roles y presentar una indicación de que el rol no está soportado en la app móvil.
4. THE App_Contigo SHALL excluir el panel de escritorio del investigador/administrador, de modo que no exista ninguna ruta de navegación ni pantalla accesible para dicho panel dentro de la app móvil, conforme a la decisión de alcance propuesta y pendiente de confirmación.
5. WHERE opera la Capa_Local, THE App_Contigo SHALL ejecutar la activación/login y la persistencia de datos de forma local y simulada, sin requerir Backend_Firebase.
6. WHERE se habilita la Capa_Firebase, THE App_Contigo SHALL realizar la autenticación real y la persistencia de datos a través de Backend_Firebase, conforme a la estratificación propuesta y pendiente de confirmación.

### Requirement 2: Preservación de textos, estilo y comportamiento

**User Story:** Como equipo clínico, quiero que la app conserve los textos, el estilo visual y el comportamiento del prototipo, para mantener la coherencia de la experiencia del equipo.

#### Acceptance Criteria

1. THE App_Contigo SHALL preservar el Contenido_Clinico suministrado (banco EMA, relato del plan de seguridad, guion y ejemplos de mensajes de cuidado) con texto idéntico carácter por carácter, sin alterar, truncar, reordenar ni parafrasear.
2. IF se detecta una discrepancia entre el Contenido_Clinico mostrado y el texto suministrado, THEN THE App_Contigo SHALL conservar el texto original suministrado sin reemplazarlo.
3. WHEN la App_Contigo presenta una pantalla equivalente a una del prototipo, THE App_Contigo SHALL conservar su disposición, paleta, tipografía y comportamientos interactivos.
4. THE App_Contigo SHALL registrar el Estado_Validacion_Contenido por tipo de contenido a nivel de documentación/metadatos del proyecto, de modo que cada contenido tenga su propio estado en lugar de un único estado global.
5. THE App_Contigo SHALL registrar que el banco EMA (`daily-nine-v2`) fue suministrado tras revisión del evaluador, sin presentarlo como validación clínica formal, y SHALL registrar los textos narrativos suministrados (relato del plan de seguridad, guion y ejemplos de mensajes de cuidado) como contenido a preservar verbatim con su estado de validación propio.
6. THE App_Contigo SHALL marcar como Contenido_Validacion_Pendiente, a nivel de documentación, los umbrales y cortes no validados, sin presentar un descargo de "pendiente de validación clínica" en toda la interfaz cada vez que se muestra Contenido_Clinico.

### Requirement 3: Capas de funcionalidad (local, simulada e integración Firebase)

**User Story:** Como equipo de desarrollo, quiero que cada funcionalidad declare a qué capa pertenece (local, simulada o integración Firebase), para no tratar una simulación del prototipo como función terminada.

#### Acceptance Criteria

1. THE App_Contigo SHALL clasificar cada funcionalidad incorporada con exactamente una de tres capas mutuamente excluyentes: Capa_Local, Capa_Simulada o Capa_Firebase, conforme a la estratificación propuesta y pendiente de confirmación.
2. THE App_Contigo SHALL implementar en la Capa_Local, operando por completo en el dispositivo sin backend, el flujo del Modulo_EMA, el cálculo `metricsFor` del Modulo_Metricas_Red, el editor del Modulo_Plan_Seguridad, el editor del Modulo_Mensajes_Cuidado y el gating de autorización por Asociacion_Activa como lógica de interfaz del cliente.
3. THE App_Contigo SHALL implementar en la Capa_Simulada la activación/login demo, el envío de invitaciones, el envío de mensajes, las llamadas, las notificaciones, la bandeja de mensajes de cuidado, la importación de contactos del sistema operativo y los adjuntos de audio y foto.
4. WHERE una funcionalidad opera en la Capa_Simulada, THE App_Contigo SHALL mostrar un indicador visual persistente, ubicado en la pantalla de esa funcionalidad, que señale que el comportamiento es simulado.
5. THE App_Contigo SHALL reservar para la Capa_Firebase, como etapa posterior, la autenticación real, la persistencia respaldada por Backend_Firebase y las Reglas_Seguridad del lado servidor.
6. WHEN se libere la Capa_Firebase para una funcionalidad de la Capa_Simulada, THE App_Contigo SHALL cambiar su capa a Capa_Firebase y retirar el indicador de simulación.
7. IF una funcionalidad incorporada no tiene asignada ninguna de las tres capas, THEN THE App_Contigo SHALL tratarla como no disponible hasta que se le asigne una capa.

### Requirement 4: Autorización por asociación activa

**User Story:** Como PCS, quiero que las acciones de fortalecimiento y contacto exijan una asociación activa válida, para que solo cuidadores autorizados accedan a mis vínculos.

#### Acceptance Criteria

1. WHEN se solicita fortalecer una relación, THE Modulo_Autorizacion SHALL exigir una invitación `accepted` y una asociación `active` que coincidan con la tupla exacta (pcsId, caregiverId, personId).
2. IF la Asociacion_Activa no coincide con la tupla exacta, THEN THE Modulo_Autorizacion SHALL deshabilitar las acciones de mensaje, contacto y encuentro.
3. WHERE se habilita la Capa_Firebase, THE Reglas_Seguridad SHALL aplicar la autorización por Asociacion_Activa en el Backend_Firebase, con independencia del estado del cliente.
4. WHERE se habilita la Capa_Firebase, IF el Backend_Firebase recibe una operación de cuidado sin una Asociacion_Activa que coincida con la tupla exacta, THEN THE Reglas_Seguridad SHALL rechazar la operación.
5. WHEN una asociación es revocada, THE App_Contigo SHALL ocultar el contenido de cuidado asociado a esa tupla.

### Requirement 5: EMA diario

**User Story:** Como PCS, quiero completar el EMA diario con sus ítems y reglas, para registrar mi estado según el instrumento definido.

#### Acceptance Criteria

1. THE Modulo_EMA SHALL presentar el banco de ítems de la versión `daily-nine-v2`, compuesto por 3 ítems binarios y 2 bloques de 3 ítems de rango cada uno, para un total de 9 ítems cuando se presenta el bloque de relación.
2. WHEN el PCS responde un ítem binario, THE Modulo_EMA SHALL registrar la respuesta como "Sí" o "No".
3. WHEN el Modulo_EMA presenta un ítem de rango, THE Modulo_EMA SHALL mostrarlo como una barra continua con etiquetas únicamente en los extremos ("Nada cierta" y "Completamente cierta"), sin números visibles y sin valor preseleccionado, de modo que la barra inicie en estado sin responder.
4. WHEN el PCS actúa sobre un ítem de rango mediante teclado, lector de pantalla o puntero, THE Modulo_EMA SHALL asignar un valor en el rango interno de 0 a 100 y exponer el valor actual a las tecnologías de asistencia mediante los mecanismos nativos de accesibilidad de Flutter (Semantics), sin mostrarlo como número visible.
5. WHEN el PCS abre el EMA por primera vez y existe vínculo activo, THE Modulo_EMA SHALL presentar la pantalla de selección de Referencia_EMA para elegir una única persona de referencia entre las personas con vínculo activo.
6. WHEN el PCS selecciona la Referencia_EMA, THE Modulo_EMA SHALL recordar esa referencia entre registros almacenando únicamente identificadores de persona, de modo que la pantalla de selección no vuelva a presentarse antes de registros posteriores.
7. WHEN el PCS solicita cambiar la Referencia_EMA, THE Modulo_EMA SHALL dirigir el cambio desde la pantalla "Tu mapa de red" y SHALL requerir confirmación explícita del usuario, sin cambiar la referencia de forma automática.
8. WHEN la Referencia_EMA guardada ya no corresponde a un vínculo activo y no existe ninguna persona con vínculo activo, THE Modulo_EMA SHALL presentar una pantalla de revisión que indique que no cambiará la selección de forma automática, ofreciendo "Ir a Tu mapa de red" como acción primaria y "Continuar con el registro de hoy" como enlace de texto secundario que omite el bloque de relación solo por ese día.
9. WHEN la Referencia_EMA guardada ya no corresponde a un vínculo activo y existe al menos otra persona con vínculo activo, THE Modulo_EMA SHALL dirigir al usuario a "Tu mapa de red" para confirmar una nueva Referencia_EMA, sin ofrecer la omisión del bloque de relación de los 6 ítems.
10. WHERE no existe un vínculo activo, THE Modulo_EMA SHALL permitir que el PCS elija explícitamente "Continuar con el registro de hoy", lo que omite el bloque de relación solo por ese día y presenta únicamente los 6 ítems restantes, sin alterar la preferencia de Referencia_EMA guardada.
11. THE Modulo_EMA SHALL distinguir la omisión del bloque de relación —en la que los 3 ítems de relación no se presentan— de una respuesta "No" en un ítem binario y de un valor 0 ("Nada cierta") en un ítem de rango, tratando "No" y 0 como respuestas válidas que cuentan como respondidas.
12. WHEN la fecha del dispositivo corresponde a un día distinto al del último EMA registrado, THE Modulo_EMA SHALL iniciar un nuevo borrador diario sin respuestas previas.
13. WHILE existen ítems presentados sin responder, THE Modulo_EMA SHALL marcar el EMA diario como incompleto e impedir su cierre como completado.
14. WHEN el PCS ha respondido todos los ítems presentados, THE Modulo_EMA SHALL marcar el EMA diario como completo.
15. THE Modulo_EMA SHALL registrar las respuestas sin calcular ni mostrar ninguna puntuación clínica ni selección automática derivada de dichas respuestas.

### Requirement 6: Persistencia (comportamiento demo vs política final, decisión abierta)

**User Story:** Como equipo clínico, quiero que la persistencia de las respuestas EMA, del plan de seguridad y de los mensajes de cuidado sea una decisión validada, para no heredar el comportamiento efímero del prototipo como política final.

#### Acceptance Criteria

1. THE App_Contigo SHALL documentar el comportamiento de persistencia del prototipo/demo: las respuestas EMA, el plan de seguridad y los mensajes de cuidado son solo de sesión (efímeros), y únicamente el mapa de red (journey) y la Referencia_EMA (solo identificadores) persisten.
2. THE App_Contigo SHALL mantener registrada, a nivel de documentación del proyecto, la política final de persistencia de las respuestas EMA, del plan de seguridad y de los mensajes de cuidado como una decisión abierta pendiente de validación con el equipo clínico.
3. THE App_Contigo SHALL documentar explícitamente que el comportamiento efímero del prototipo es el punto de partida y no la política final.
4. WHEN la App_Contigo persista la Referencia_EMA, THE App_Contigo SHALL almacenar únicamente identificadores de persona, sin incluir el contenido de las respuestas EMA.

### Requirement 7: Plan de seguridad

**User Story:** Como PCS, quiero editar mi plan de seguridad, para tener a mano pasos, contactos y actividades de apoyo.

#### Acceptance Criteria

1. WHEN el PCS edita el `SafetyPlanDraft`, THE Modulo_Plan_Seguridad SHALL permitir modificar los títulos de pasos, los contactos, las actividades y el entorno, y reflejar cada cambio en el borrador en edición.
2. WHERE la App_Contigo opera en modo demostración, THE Modulo_Plan_Seguridad SHALL mantener el `SafetyPlanDraft` como borrador de sesión, perdiéndose su contenido al recargar, conforme al comportamiento del prototipo; la persistencia final del plan de seguridad queda como decisión abierta pendiente de validación (ver Requirement 6).
3. WHEN el PCS modifica un campo de un escenario de demostración, THE Modulo_Plan_Seguridad SHALL mantener sin alteración todos los campos de los demás escenarios de demostración.
4. THE App_Contigo SHALL implementar la importación de contactos del sistema operativo del plan de seguridad como Funcion_Simulada inicial.
5. WHERE la importación de contactos del sistema operativo opera como Funcion_Simulada, THE App_Contigo SHALL indicar en la interfaz que el flujo de permisos es simulado y SHALL no agregar contactos reales del dispositivo al `SafetyPlanDraft`.
6. THE App_Contigo SHALL presentar el relato narrativo del plan de seguridad conservando su contenido verbatim, sin alterar ni reordenar el texto de sus páginas.

### Requirement 8: Recorridos de cuidado y conexión

**User Story:** Como Cuidador quiero acceder a mis recorridos de acompañamiento y como PCS quiero acceder a mis recorridos de conexión y mensajes recibidos, para participar en el tejido de vínculos según mi rol.

#### Acceptance Criteria

1. THE App_Contigo SHALL incluir los seis recorridos del cuidador: plan de acompañamiento, registro de vínculo, evaluación de encuentros, mensajes de cuidado, mensajes íntimos y preguntas de conexión.
2. WHILE no exista Asociacion_Activa válida que coincida con la tupla exacta (pcsId, caregiverId, personId), THE App_Contigo SHALL deshabilitar los recorridos del cuidador que dependen de la asociación: plan de acompañamiento, registro de vínculo, evaluación de encuentros, mensajes de cuidado, mensajes íntimos y preguntas de conexión.
3. THE Modulo_Mensajes_Cuidado SHALL presentar la guía educativa, el seguimiento de lectura y las preguntas de reflexión conservando el contenido verbatim, sin alterar ni truncar el Contenido_Clinico suministrado.
4. WHEN el Cuidador inserta un ejemplo en el borrador, THE Modulo_Mensajes_Cuidado SHALL añadir el contenido del ejemplo al borrador existente conservando íntegro el texto previo, sin sobrescribirlo ni reemplazarlo.
5. WHEN se genera o guarda el registro del mensaje de cuidado, THE Modulo_Mensajes_Cuidado SHALL excluir del registro las notas privadas y las preguntas de reflexión seleccionadas, conservando los identificadores necesarios para la visibilidad y el aislamiento (id, caregiverId, caregiverName, pcsId, pcsName, personId, associationId), el texto del mensaje y el estado de entrega.
6. WHEN el Cuidador envía un mensaje de cuidado o un mensaje íntimo, THE App_Contigo SHALL ejecutar el envío como Funcion_Simulada inicial (Capa_Simulada), indicando en la interfaz que el comportamiento es simulado y sin entregar el mensaje a un destinatario real.
7. THE App_Contigo SHALL incluir para el PCS el recorrido "Tejiendo vínculos" (connection hub) con los pasos de conexión: mensaje, recibido, contacto, encuentro y habilidades.
8. THE App_Contigo SHALL incluir para el PCS la bandeja de mensajes recibidos (caring-message inbox) que presenta la vista de mensajes recibidos.
9. WHEN el PCS solicita "Otro paso" o "Un paso para hoy", THE App_Contigo SHALL rotar entre los pasos propuestos mediante `nextConnectionStep`, avanzando de forma cíclica y reiniciando al llegar al final, sin exigir que el PCS complete la propuesta actual antes de rotar.
10. WHILE no exista Asociacion_Activa válida que coincida con la tupla exacta (pcsId, caregiverId, personId), THE App_Contigo SHALL deshabilitar las acciones de conexión del PCS dirigidas a una persona que dependen de la asociación: mensaje, contacto y encuentro.
11. THE App_Contigo SHALL mantener la bandeja de mensajes recibidos del PCS y la rotación de "Otro paso" disponibles sin aplicarles el gating de Asociacion_Activa de las acciones dirigidas a una persona.

### Requirement 9: Mapa de red y métricas

**User Story:** Como PCS, quiero ver mi mapa de red con sus métricas, para entender la cercanía y calidad de mis vínculos.

#### Acceptance Criteria

1. WHEN el PCS abre el mapa de red, THE Modulo_Metricas_Red SHALL calcular mediante `metricsFor` la puntuación POMP de cada vínculo en una escala interna de 0 a 1, usando `pomp(questions) = clamp((sum(answers) - n) / (5*n), 0, 1)` donde `n` es el número de preguntas del conjunto.
2. THE Modulo_Metricas_Red SHALL derivar `closeness` como POMP de los ítems [4,5,6,13,14], `positivity` como POMP de los ítems [10,11,15], `negativity` como POMP de los ítems [7,9,12,16,17,18] e `importance` como `clamp((answer(2)-1)/5, 0, 1)`.
3. THE Modulo_Metricas_Red SHALL calcular `finalCloseness = max(0, closeness - 0.4 * negativity)`.
4. WHEN `metricsFor` termina el cálculo de un vínculo, THE Modulo_Metricas_Red SHALL asignar exactamente un anillo según `finalCloseness`: `>= 0.7` → Íntimo; `>= 0.35` → Personal; en otro caso → Ocasional.
5. WHEN `metricsFor` termina el cálculo de un vínculo, THE Modulo_Metricas_Red SHALL asignar exactamente una clasificación comparando `positivity` y `negativity` con 0.5: `positivity>=0.5 & negativity<0.5` → "Mayormente positiva"; `positivity>=0.5 & negativity>=0.5` → "Ambivalente"; `positivity<0.5 & negativity>=0.5` → "Mayormente negativa"; en otro caso → "Baja intensidad".
6. THE Modulo_Metricas_Red SHALL marcar los cortes numéricos de anillo y las reglas de clasificación como Contenido_Validacion_Pendiente, sin convertirlos en lógica clínica definitiva.
7. IF un vínculo carece de datos suficientes para completar los 18 ítems, THEN THE Modulo_Metricas_Red SHALL excluir ese vínculo del cálculo de puntuación sin interrumpir el cálculo de los demás vínculos.
8. WHEN el PCS abre el mapa de red, THE App_Contigo SHALL representar un gráfico de cercanía y un gráfico de calidad construidos a partir de los valores devueltos por `metricsFor`.
9. WHILE el mapa de red muestra el flujo de invitaciones, THE App_Contigo SHALL operarlo como Funcion_Simulada inicial (Capa_Simulada), representando los estados pending, accepted y declined únicamente como datos locales sin envío real.
10. IF el PCS solicita una invitación de la red en modo Funcion_Simulada, THEN THE App_Contigo SHALL indicar en la interfaz que el envío es simulado y no se transmite a la otra persona.

### Requirement 10: Evaluación de relación y preguntas para conectar

**User Story:** Como Cuidador, quiero usar las preguntas para conectar y la evaluación de encuentros, para fortalecer el vínculo con el PCS.

#### Acceptance Criteria

1. WHEN el Cuidador recorre los pasos de conexión, THE App_Contigo SHALL preservar el orden de los pasos del prototipo y avanzar únicamente cuando el paso actual esté completado.
2. WHILE se presentan resultados de la evaluación de relación, THE App_Contigo SHALL mostrar un indicador de Contenido_Validacion_Pendiente y SHALL no presentar los umbrales como resultado clínico definitivo.
3. WHEN el Cuidador adjunta audio o foto, THE App_Contigo SHALL ejecutar el adjunto como Funcion_Simulada inicial, indicando que es simulado y sin generar, almacenar ni enviar un archivo real.
4. WHILE no exista Asociacion_Activa válida, THE App_Contigo SHALL deshabilitar las acciones de conexión que dependen de la asociación: mensaje, contacto y evaluación de encuentro, presentándolas en un estado no accionable.
5. IF el Cuidador intenta una acción de conexión dependiente de la asociación sin una Asociacion_Activa válida, THEN THE App_Contigo SHALL bloquear la acción, indicar que se requiere una asociación activa y conservar el estado actual.

### Requirement 11: Autenticación y activación

**User Story:** Como usuario, quiero activar mi cuenta e iniciar sesión, para acceder a la app según mi rol.

#### Acceptance Criteria

1. THE App_Contigo SHALL implementar la activación como Funcion_Simulada inicial (Capa_Simulada) mediante un código de activación ingresado por el usuario, sin validarlo contra Backend_Firebase.
2. WHEN el usuario ingresa un código de activación, THE App_Contigo SHALL convertir el texto a mayúsculas y ejecutar una verificación simulada breve antes de enrutar.
3. WHEN el código de activación tiene 4 caracteres o más y comienza con "C", THE App_Contigo SHALL enrutar al inicio del Cuidador.
4. WHEN el código de activación tiene 4 caracteres o más y no comienza con "C", THE App_Contigo SHALL enrutar al inicio del PCS.
5. IF el código de activación tiene menos de 4 caracteres, THEN THE App_Contigo SHALL rechazar el acceso, permanecer en la pantalla de activación y mostrar el mensaje de error existente.
6. WHERE se habilita la Capa_Firebase, THE App_Contigo SHALL reemplazar la activación simulada por autenticación real sobre Backend_Firebase que determine el rol del usuario, conforme a la estratificación propuesta y pendiente de confirmación.
7. THE App_Contigo SHALL tratar el modelo de identidad, los códigos de activación y la vinculación de roles como decisiones a definir junto con el Backend_Firebase.

### Requirement 12: Notificaciones y modo crisis

**User Story:** Como PCS, quiero recibir notificaciones elegibles y acceder al modo crisis, para contar con apoyo oportuno.

#### Acceptance Criteria

1. THE App_Contigo SHALL implementar las notificaciones como Funcion_Simulada en el estado inicial (Capa_Simulada), sin realizar envíos a servicios externos de notificación.
2. WHILE no existe ninguna persona vinculada en estado activo (`validCaregivers(journey).length === 0`), THE App_Contigo SHALL generar únicamente notificaciones de tipo recordatorio de relaciones y suprimir cualquier otro tipo de notificación.
3. WHEN la App_Contigo genera una notificación que contiene el marcador de persona, THE App_Contigo SHALL sustituir dicho marcador por el nombre de una persona vinculada en estado activo.
4. IF la notificación contiene el marcador de persona y no existe ninguna persona vinculada en estado activo, THEN THE App_Contigo SHALL omitir la generación de esa notificación.
5. THE App_Contigo SHALL mostrar las tarjetas de notificación con una relación de contraste de color conforme a WCAG de al menos 4.5:1 entre el texto y su fondo.
6. WHEN el usuario accede a las pantallas de modo crisis y de respiración, THE App_Contigo SHALL presentar el contenido textual conservándolo de forma idéntica al definido en el prototipo, sin alteraciones.
