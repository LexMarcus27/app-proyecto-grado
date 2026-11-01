# assets/media — Recursos multimedia del prototipo "Contigo"

Recursos multimedia del prototipo incorporados al bundle de Flutter y
preservados **verbatim** (sin alterar, recomprimir, recortar ni reordenar),
conforme a los Requirements 2.1, 2.3, 7.6 y 8.3 (tarea 1.7).

- **Origen:** prototipo React en `public/media/` (ver `docs/analisis-prototipo.md`).
- **Trazabilidad:** se conserva la estructura de subcarpetas y los nombres de
  archivo exactos del prototipo.
- **Declaración:** en `pubspec.yaml`, sección `flutter: assets:`.
- **Consumo:** las pantallas no referencian rutas literales; usan las constantes
  tipadas de `lib/content/app_media.dart` (`AppMedia`).

## Contenido

### `plan-desenredo/` — Relato del plan de seguridad "Las crisis también pasan"

| Archivo                | Uso en el relato                                     |
| ---------------------- | ---------------------------------------------------- |
| `plan-desenredo-1.mp4` | Página 1: "Conoce el plan para desenredar"           |
| `plan-desenredo-2.mp4` | Página 4: "Prepararnos para los momentos difíciles"  |

### `caring-messages/` — Guía de mensajes de cuidado y avatar del acompañante

| Archivo                  | Uso                                                      |
| ------------------------ | -------------------------------------------------------- |
| `metafora.mp4`           | Video de la guía de mensajes de cuidado                  |
| `avatar.png`             | Avatar del acompañante (CompanionNote) y guía            |
| `preparacion.png`        | Ilustración: el avatar respira y se prepara para conectar |
| `historia-bastogne.png`  | Ilustración de la historia "Bastogne"                    |
| `historia-cartas.jpeg`   | Ilustración de la historia "Cartas"                      |
| `historia-conexion.png`  | Ilustración de la historia "Conexión"                    |

## Reemplazo o actualización

Si estos binarios deben re-suministrarse, cópielos **verbatim** desde la fuente
original conservando exactamente estos nombres de archivo y subcarpetas. No los
recomprima ni los edite: el contenido debe ser idéntico byte a byte al
suministrado por el equipo investigador.
