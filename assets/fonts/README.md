# Fuentes tipográficas de Contigo

Fuentes empacadas con la app bajo la **SIL Open Font License 1.1 (OFL)**.
Declaradas en `pubspec.yaml` (sección `flutter: fonts:`) y usadas por
`lib/app/theme.dart`.

## Archivos

| Familia | Archivo                        | Rol        | Licencia            |
| ------- | ------------------------------ | ---------- | ------------------- |
| Inter   | `Inter-Variable.ttf`           | Cuerpo     | `Inter-OFL.txt`     |
| Lora    | `Lora-Variable.ttf`            | Títulos    | `Lora-OFL.txt`      |

Ambas son **fuentes variables** (eje de peso `wght`, rango aprox. 100–900).
Flutter aplica el `fontWeight` solicitado (400/500/600/700, usados por el
`TextTheme`) sobre el eje de peso de la fuente variable, por lo que un único
archivo por familia cubre todos los pesos requeridos.

## Decisión de sustitución de fuente (títulos)

El prototipo web usa **Inter** para el cuerpo y **Georgia** (serif) para los
títulos. Georgia es una fuente propietaria que **no se distribuye en Android**,
por lo que un build de Android caería a la serif por defecto del sistema y
perdería el carácter tipográfico del prototipo.

Sustitución aplicada: se empaca **Lora** (serif OFL, trazo cálido y legible,
cercana al carácter de Georgia) como familia de títulos. En iOS/web se mantiene
la cadena de respaldo `Georgia → Times New Roman → serif` (ver
`ContigoTheme.displayFontFallback`), de modo que en esas plataformas, donde
Georgia sí existe, se preserva la equivalencia visual original.

Inter se mantiene como fuente del cuerpo.

## Origen y atribución

- **Inter** — Rasmus Andersson. Fuente: proyecto Inter
  (<https://rsms.me/inter/>) / Google Fonts
  (<https://fonts.google.com/specimen/Inter>). Binario tomado del repositorio
  `google/fonts` (`ofl/inter/Inter[opsz,wght].ttf`). Licencia OFL en
  `Inter-OFL.txt`.
- **Lora** — Cyreal. Fuente: Google Fonts
  (<https://fonts.google.com/specimen/Lora>). Binario tomado del repositorio
  `google/fonts` (`ofl/lora/Lora[wght].ttf`). Licencia OFL en `Lora-OFL.txt`.

Los archivos `*-OFL.txt` contienen el texto completo de la licencia y los
avisos de copyright de cada fuente; deben conservarse junto a los binarios.
