# Verificación manual — Etapa 3, Wave 11 — Contigo Flutter

Fecha de actualización: 2026-11-05.
Proyecto: `C:\Users\Lex\Documents\app-proyecto-grado`.

## Alcance y entorno

**Estado final: comprobación manual solicitada de Wave 11 completada y aprobada, sin pendientes abiertos dentro del alcance revisado.**

Verificación en Android, con datos ficticios. Emulador `Medium_Phone_API_37.0`, SwiftShader, Vulkan desactivado y sin cargar/guardar instantáneas. Flutter con Impeller desactivado, sin `--enable-software-rendering`. Ajustes temporales. No se modificó la implementación ni se avanzó a Wave 12.

Kiro reportó inicialmente analyze limpio y 255 pruebas aprobadas y, tras las últimas correcciones, una revisión posterior con 10 pruebas puntuales aprobadas. Son antecedentes comunicados por el usuario; no se repitió la batería automatizada en esta verificación.

La evidencia manual consiste en las confirmaciones del usuario sobre los recorridos de las guías. En el cierre confirmó expresamente los pasos 1 a 13 como esperados y ausencia de cierres. No se dispone de capturas o grabaciones individuales de cada paso.

## Resultados confirmados por el usuario

- **Cuidador: recursos y bloqueo en vivo — aprobado.** El usuario confirmó que toda esa sección se comportó tal como indicaba la guía: recursos de aprendizaje, vínculo activo, aceptación sin asociación, revocación y actualización del bloqueo al cambiar el estado en vivo. Evidencia: confirmación conjunta del usuario; no se dispone de capturas individuales de cada estado.
- **Tejiendo vínculos, con persona vinculada — aprobado.** El usuario confirmó que toda la sección se comportó tal como indicaba la guía, incluido el ciclo de «Otro paso», las acciones destacadas y «Otros pasos». Evidencia: confirmación conjunta del usuario, sin capturas individuales.
- **Notificaciones con vínculo — aprobado.** El usuario confirmó que toda la sección se comportó tal como indicaba la guía, incluida la simulación y las explicaciones temporales de destinos pendientes. Evidencia: confirmación conjunta del usuario, sin capturas individuales.
- **Tejiendo vínculos sin persona vinculada — aprobado.** El usuario confirmó el comportamiento esperado del recorrido y el bloqueo de acciones dirigidas.
- **Notificaciones sin vínculo — aprobado.** El usuario confirmó el comportamiento esperado de los recordatorios y la navegación.
- **Modo crisis y respiración — aprobado tras las correcciones.** El usuario había confirmado límite de pasos, confirmación de salida, opciones de contacto simuladas y navegación. La última comprobación aprobó también «Línea ayuda», «Contactar a alguien» desde respiración, movimiento visible del centro y del halo, detención y reanudación.
- **Bienvenida PCS nueva — aprobada.** Acceso desde el nuevo escenario, navegación al mapa mínimo con «Construir mi mapa», aplazamiento con «Hacerlo después» y conservación visible de ambas decisiones tras reiniciar sin reaplicar el escenario.
- **Estabilidad durante la comprobación manual — sin cierres observados.** El usuario confirmó que en ningún momento se cerraron Contigo ni el emulador. Este resultado corresponde a esta sesión y no prueba resuelta la causa de los cierres históricos de QEMU.

## Última comprobación manual: resultados de los 13 pasos

| Paso | Comprobación | Resultado confirmado por el usuario |
| --- | --- | --- |
| 1 | Aplicar «PCS nueva (onboarding no iniciado)» sin sesión, pasar por Activación, activar como PCS y abrir la bienvenida | Aprobado |
| 2 | «Construir mi mapa» abre «Tu mapa de red», en su estado mínimo vacío | Aprobado |
| 3 | Volver a Inicio PCS e intentar abrir la bienvenida no vuelve a ofrecer la decisión | Aprobado |
| 4 | Reiniciar sin reaplicar escenario conserva la decisión de comenzar; el mapa mínimo sigue accesible | Aprobado |
| 5 | Reaplicar deliberadamente el escenario PCS nueva permite volver a la bienvenida | Aprobado |
| 6 | «Hacerlo después» lleva a Inicio PCS y no vuelve a ofrecer la bienvenida | Aprobado |
| 7 | Reiniciar sin reaplicar escenario conserva el aplazamiento visible | Aprobado |
| 8 | «Línea ayuda» abre «Línea de ayuda», explica que la demostración no llama y se cierra con «Entendido» | Aprobado |
| 9 | «Contactar a alguien» desde respiración abre las tres opciones; «Ahora no» cierra la hoja | Aprobado |
| 10 | «Enviar un mensaje» y «Llamar» cierran las opciones sin envíos, llamadas ni apertura de aplicaciones externas | Aprobado |
| 11 | Centro naranja y halo celeste cambian de tamaño durante al menos dos ciclos completos | Aprobado |
| 12 | «Reducir movimiento» detiene ambos círculos y cambia el botón a «Activar animación» | Aprobado |
| 13 | «Activar animación» reanuda el movimiento de ambos círculos durante los ciclos observados | Aprobado |

La conservación del onboarding se verificó por el comportamiento visible después del reinicio, sin inspección directa del valor interno persistido. La interfaz no muestra una etiqueta que distinga «En progreso» de «Aplazado».

## Cierre de hallazgos y limitaciones anteriores

- **E3-W11-01 — movimiento de respiración: cerrado tras corrección y confirmación visual.** La observación inicial fue que no se percibía movimiento. Kiro amplió la animación para incluir también el círculo central. En el código revisado, centro y halo cambian de tamaño con 4 segundos por sentido, aproximadamente 8 segundos por ciclo. El usuario aprobó dos ciclos completos, detención y reanudación en Android. No se determina una causa de ejecución o del emulador para la observación histórica.
- **«Línea ayuda»: pendiente anterior cerrado.** Ya abre su explicación simulada y permite cerrarla; el usuario confirmó que no realiza una llamada.
- **«Contactar a alguien» desde respiración: pendiente anterior cerrado.** Ya abre las opciones simuladas; el usuario confirmó su cierre sin llamadas ni envíos.
- **Preparación de bienvenida PCS: limitación anterior resuelta.** Antes solo había dos escenarios con onboarding completado. El nuevo escenario «PCS nueva (onboarding no iniciado)» prepara el recorrido vacío. La guarda puede llevar a Activación si se aplica sin sesión; después se activa la sesión PCS y se abre «Ver bienvenida de onboarding». Este orden fue comprobado por el usuario.

## Límites del cierre

- No quedan comprobaciones manuales pendientes de las guías de Wave 11 ejecutadas por el usuario.
- La construcción completa del mapa, la bandeja y otros destinos previstos para Waves 12–13 permanecen fuera del alcance. Sus explicaciones temporales no se registran como fallos ni equivalen a funciones finales verificadas.
- Los contactos y llamadas se verificaron como simulación; no se validaron comunicaciones reales ni contenido clínico.
- No hubo cierres de Contigo ni del emulador durante la última comprobación, según confirmación expresa del usuario. Esto no demuestra resuelta la causa de los cierres históricos de QEMU.
