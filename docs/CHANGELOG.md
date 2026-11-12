# OnlyBars — Changelog

## 1.0.0 — 2026-11-12

### 🇲🇽 Español
- **Orientación horizontal / vertical** por barra, como en el Modo Edición de Blizzard. En vertical,
  «Número de filas» pasa a «Número de columnas».
- **Cambiar el tamaño ya no desacomoda nada.** Al cambiar orientación, filas, iconos, tamaño o margen
  solo se mueve esa barra; las vecinas se recorren en línea recta, nunca en diagonal. Si no cabe en
  la pantalla, crece hacia el otro lado, y regresar al tamaño anterior deja todo donde estaba.
- **Lista de teclas** (`/ob listateclas`): todas las teclas de OnlyBars y de las barras de acción de
  Blizzard, barra por barra. Marca las repetidas, busca por tecla, oculta botones sin tecla y puede
  mostrar todas las specs.
- **Importar / Exportar** (`/ob exportar`, `/ob importar`): comparte una o varias barras con un texto,
  como los talentos. También se guardan en una lista que ves en todos tus personajes. Al importar
  eliges si llegan con iconos y hechizos, con teclas, y si cada barra entra como nueva o reemplaza a
  una tuya; siempre conservan su forma, posición y situaciones.
- En el panel, «Duplicar» y «Borrar» quedan lado a lado. La ventanita del Modo Edición ya no tiene el
  botón «Alcance»: General o por spec se elige en el panel, pestaña Mostrar → Especialización.

### 🇺🇸 English
- **Horizontal / vertical orientation** per bar, like Blizzard's Edit Mode. When vertical,
  "# of Rows" becomes "# of Columns".
- **Resizing no longer messes up your layout.** Changing orientation, rows, icons, size or padding
  moves only that bar; neighbouring bars shift in a straight line, never diagonally. If it does not
  fit on screen it grows the other way, and going back to the previous size puts everything back.
- **Key list** (`/ob keylist`): every OnlyBars key and every Blizzard action bar key, bar by bar. It
  marks repeated keys, searches by key, hides buttons without a key and can show every spec.
- **Import / Export** (`/ob export`, `/ob import`): share one bar or several as a text, like talents.
  They are also saved in a list you see on all your characters. When importing you choose whether
  they come with icons and spells, with keys, and whether each bar is added as new or replaces one of
  yours; they always keep their shape, position and situations.
- In the panel, "Duplicate" and "Delete" now sit side by side. The Edit Mode dialog no longer has the
  "Scope" button: General or per spec is chosen in the panel, Show tab → Specialization.

## 0.11.3 — 2026-11-02

- 🇲🇽 Nuevo `/ob estado`: con el mouse sobre un botón que no responde, muestra en la ventana de
  Reporte qué le pasa (para reportar fallas).
- 🇺🇸 New `/ob state`: with the mouse over a button that does not respond, shows in the Report
  window what is wrong with it (to report bugs).

## 0.11.2 — 2026-11-02

- 🇲🇽 Corregido: los botones podían quedarse sin responder (ni clic ni tecla) hasta relogear,
  después de hacer clic con algo en el cursor. Además, si un botón pierde su acción por cualquier
  motivo, se repara solo al salir de combate.
- 🇺🇸 Fixed: buttons could stop responding (neither click nor key) until relogging, after clicking
  with something on the cursor. Also, if a button loses its action for any reason, it repairs
  itself out of combat.

## 0.11.1 — 2026-10-27

- 🇲🇽 Descarga más ligera: el paquete ya no incluye capturas de pantalla.
- 🇺🇸 Smaller download: the package no longer includes screenshots.

## 0.11.0 — 2026-10-27

**Primera versión pública.** · **First public release.**

### 🇲🇽 Español
- Hasta 20 barras de acción extra por personaje, iguales a las de Blizzard en arte, tamaño y
  ajustes del Modo Edición.
- Hechizos, objetos, juguetes, macros con ícono en vivo, monturas, mascotas y conjuntos de equipo.
- Barras generales o con contenido distinto en cada especialización.
- Cuándo se ve cada barra: ubicación, conjunto de equipo, combate, montura, objetivo, grupo,
  vehículo y «Mostrar solo si…» (sin mascota, mascota muerta, sigilo, volando, nadando, foco).
- Desvanecer al pasar el mouse, con la opacidad que elijas.
- Teclas por barra y por spec, también desde el Modo de atajo rápido de Blizzard; barras que nunca
  se ven juntas pueden compartir tecla.
- Modo libre, Modo Edición, rejilla, magnetismo y anclaje entre barras.
- Copiar barras entre personajes, en los dos sentidos.
- Interfaz en español e inglés.

### 🇺🇸 English
- Up to 20 extra action bars per character, matching Blizzard's in art, size and Edit Mode
  settings.
- Spells, items, toys, macros with live icons, mounts, pets and equipment sets.
- General bars or different content in each specialization.
- When each bar shows: location, equipment set, combat, mount, target, group, vehicle and
  "Show only if…" (no pet, pet dead, stealthed, flying, swimming, focus).
- Fade on mouseover, to the opacity you choose.
- Keybinds per bar and per spec, also from Blizzard's Quick Keybind Mode; bars that never show
  together can share a key.
- Free mode, Edit Mode, grid, snapping and anchoring between bars.
- Copy bars between characters, both ways.
- Interface in English and Spanish.
