# OnlyBars — Changelog

Versión **X.Y.Z**: X = cambios grandes · Y = cambios estéticos o de configuración ·
Z = cambios menores.

## [0.11.0] — 2026-10-27 · build de prueba

**Y**: textos en inglés (D-70).

### Agregado
- **Inglés** (`Locales/enUS.lua`) como idioma base para cualquier cliente; **español**
  (`Locales/esMX.lua`) encima en clientes esMX y esES. Los términos siguen los del Modo Edición
  de Blizzard en cada idioma.
- **Comandos en inglés**, que funcionan junto a los de español en cualquier cliente: `help`,
  `keys`, `free`, `lock`, `new`, `delete`, `icons`, `rows`, `empty`, `scope`, `test`, `errors`.

## [0.10.2] — 2026-10-27 · build de prueba

**Z**: carpetas ordenadas por tema (D-69). Sin cambios de funcionamiento.

### Cambiado
- `Modules/` se divide en **`Bars/`** (Buttons, Bars, Visibility, Keybinds) y **`Layout/`**
  (Grid, EditMode, Modes). `Commands.lua` pasa de `Core/` a **`UI/`**. El orden de carga en
  `OnlyBars.toc` sigue esos grupos.

## [0.10.1] — 2026-10-27 · build de prueba

**Z**: copia en los dos sentidos y letra más nítida (D-67, D-68).

### Resultado de las pruebas de 0.9.0 a 0.10.1 (2026-10-27)
- ✅ Barra nueva en el centro · copiar entre personajes · letra más nítida · Montura y Objetivo
  con un solo control · «Mostrar solo si…».
- ⏳ Sin confirmar: «Montura: solo sin montar» le gana a «Mostrar solo si…».

### Cambiado
- **Copiar barras entre personajes** funciona en los dos sentidos: el botón de sentido
  (`OTRO  >  TU PERSONAJE`) se invierte con un clic. Hacia otro personaje se copian tus barras; las
  verá cuando entres con él. Si es de otra clase, la copia queda General.
- OnlyBars guarda la clase de cada personaje al entrar. Mientras un personaje no haya entrado
  con esta versión, su clase se deduce de las specs de sus barras.
- El menú de personajes también muestra a los que no tienen barras, para poder copiarles.
- **Letra más nítida**: las ventanas de OnlyBars usan fuentes propias, un punto más grandes y
  con sombra de 1 px, en lugar de las chicas de Blizzard.

## [0.10.0] — 2026-10-27 · build de prueba

**Y**: copiar barras de otro personaje (D-67).

### Agregado
- La lista de barras muestra arriba el **nombre de tu personaje**, con un botón **<** que abre
  a la izquierda el panel **«Copiar barras de otro personaje»**:
  - Arriba, el nombre del otro personaje y un botón **v** con el menú de tus personajes.
  - Sus barras con su etiqueta (General / Demo…) y una casilla para marcar cuáles copiar.
  - Abajo, **«Copiar a TU PERSONAJE»** copia las marcadas como barras nuevas.
- La copia llega sin teclas, sin anclar y en el centro de la pantalla. Si es de la misma
  clase, conserva sus specs; si es de otra clase, queda General con el contenido de su
  primera spec. La barra original no se toca.

### Corregido
- Una barra nueva aparecía cada vez más abajo; con muchas barras quedaba detrás de la barra 1
  de Blizzard. Ahora aparece en el **centro de la pantalla**, igual que «Restablecer posición».

## [0.9.0] — 2026-10-27 · build de prueba

**Y**: Mostrar sin duplicados (D-66). Esquema 14.

### Cambiado
- «Mostrar también si…» se llama **«Mostrar solo si…»**, que es lo que hace desde la 0.6.4.
- **Montura**, un solo control: siempre / solo montado / solo sin montar. Reemplaza a «Ocultar si
  estoy montado (siempre)».
- **Objetivo**, un solo control: no importa / con objetivo / enemigo / aliado. Reemplaza a «Solo
  con objetivo» y a las casillas «Objetivo enemigo / aliado».
- Montura, objetivo y vehículo son **filtros**: siempre se aplican, también con «Mostrar solo
  si…», y nunca se bloquean. El bloqueo queda solo entre combate/grupo y «Mostrar solo si…».
- Al actualizar se conserva lo que tenía cada barra. Ojo: si una barra combinaba «Objetivo
  enemigo/aliado» con otras casillas de «Mostrar…», antes bastaba una; ahora el objetivo
  siempre se tiene que cumplir.

## [0.8.0] — 2026-10-27 · build de prueba

**Y**: opacidad al pasar el mouse (D-65). Esquema 13.

### Resultado de las pruebas de 0.5.9 a 0.8.0 (2026-10-27)
- ✅ Todo funciona: desmarcar spec guarda el contenido · aviso de barra de otra spec · duplicar
  desde otra spec · conversión de General limitadas · tooltip de conjuntos sin error · Mundo
  abierto y Áreas de descanso separados · opacidad sin el mouse · «Mostrar también si…» solo
  cuando se cumple · sin condición personalizada · sin «Barra visible en» · teclas por spec ·
  aviso de asignar teclas dentro del panel. Ya no queda nada sin probar.

### Agregado
- **Opacidad sin el mouse** (0–100 %, inicia en 0 %): con «Aparecer al pasar el mouse» activo, la
  barra se queda en esa opacidad en vez de desaparecer, y vuelve a su transparencia normal al
  pasar el mouse. Solo cosmético: botones y teclas funcionan con cualquier opacidad.

### Cambiado
- «Aparecer al pasar el mouse» pasa de **Mostrar → Estado** a **Forma** (y a la ventanita del
  Modo Edición), junto a su opacidad. El deslizador solo se usa con la casilla marcada. Al
  actualizar se conserva lo que tenía cada barra.

## [0.7.4] — 2026-10-26 · build de prueba

**Z**: Mundo abierto y Áreas de descanso por separado (D-64).

### Cambiado
- **Mundo abierto** ya no incluye ciudades ni posadas: ahí cuenta solo **Áreas de descanso**.
  Una barra marcada solo con Mundo abierto ya no aparece en la ciudad; para que aparezca en los
  dos, marca ambas casillas.
- Por eso, una barra de Mundo abierto y otra de Áreas de descanso ya pueden compartir tecla.

## [0.7.3] — 2026-10-26 · build de prueba

**Z**: corrección del tooltip de conjuntos de equipo.

### Corregido
- Error `C_TooltipInfo.GetEquipmentSet(setID) … outside of expected range` (×120) al pasar el
  mouse sobre un botón con conjunto de equipo: Midnight pide el ID del conjunto y se le pasaba el
  nombre. El `pcall` no lo evitaba porque Blizzard lo reporta desde su propio `securecallfunction`.
  Si el conjunto ya no existe, el tooltip muestra solo su nombre.

## [0.7.2] — 2026-10-26 · build de prueba

**Z**: sin «Barra visible en» en ningún lado (D-63).

### Quitado
- «Barra visible en» de la ventanita del Modo Edición. Al elegir Siempre / En combate / Fuera
  de combate borraba todas las situaciones de Mostrar. Ahora cuándo se ve una barra se cambia
  solo en el panel, pestaña **Mostrar**, y se oculta con la palomita de la lista.

## [0.7.1] — 2026-10-26 · build de prueba

**Z**: sin «Barra visible en» en el panel.

### Quitado
- «Barra visible en» de la pestaña **Forma** del panel: lo mismo está en **Mostrar** (combate,
  y ocultar con la palomita de la lista). Sigue en la ventanita del Modo Edición.

## [0.7.0] — 2026-10-26 · build de prueba

**Y**: sin condición personalizada (D-62). Esquema 12.

### Quitado
- El cuadro **Condición personalizada** de «Mostrar también si…». Al actualizar se borra la que
  tuviera cada barra, para que ninguna quede con una regla que ya no se puede ver ni quitar.

## [0.6.4] — 2026-10-26 · build de prueba

**Z**: corrección de «Mostrar también si…» (D-61).

### Resultado de la prueba de 0.6.3
- ✅ Combate en tres casillas, bloqueo entre Estado y «Mostrar también si…», etiquetas de la
  lista, recuadro de Especialización.
- ❌ Invocaciones (Sin mascota + Mascota muerta) se veía con la mascota viva.

### Corregido
- Sin nada en Estado, la barra se ve **solo** cuando se cumple alguna casilla de «Mostrar también
  si…» o la condición personalizada. Antes el controlador terminaba en «mostrar».
- Una barra que todavía usa Estado y «Mostrar también si…» a la vez conserva el «o» de antes.

## [0.6.3] — 2026-10-26 · build de prueba

**Z**: Estado sin choques con «Mostrar también si…» (D-61).

### Cambiado
- **Combate** pasa de botón de ciclo a tres casillas: **Siempre**, **En combate**, **Fuera de
  combate**. Se marca una o ninguna; ninguna = siempre.
- **Estado** (combate, montura, objetivo, grupo) y **«Mostrar también si…»** (casillas y condición
  personalizada) se bloquean entre sí: con algo marcado en uno, el otro se ve «(bloqueado)» y en
  gris, con un aviso debajo de Estado.
- No entran en el bloqueo: ocultar en vehículo, aparecer al pasar el mouse y «Ocultar si estoy
  montado (siempre)».
- Una barra que ya usaba los dos los deja usables, con un aviso para quitar uno.

## [0.6.2] — 2026-10-26 · build de prueba

**Z**: textos del recuadro de Especialización.

### Cambiado
- General: **General** · «Visible para todas las especializaciones».
- Una spec: su nombre de título · «Solo visible para esta especialización».
- Varias: «Visible solo para Demonología y Destrucción», sin título.
- El recuadro crece con el texto. El aviso de barra de otra spec también une con «y».

## [0.6.1] — 2026-10-26 · build de prueba

**Z**: dónde está guardada cada barra, en la lista.

### Agregado
- La lista del panel muestra en gris, antes de la palomita, dónde está guardada cada barra:
  **(General)** o sus specs con cuatro letras, por ejemplo **(Demo)** o **(Demo, Dest)**.
  Reemplaza el «(otra spec)»; las barras de otra spec siguen en gris.

## [0.6.0] — 2026-10-26 · build de prueba

**Y**: General / por spec se configura solo en **Especialización** (D-60). Esquema 11.

### Cambiado
- Se quita el menú **Alcance** del panel. En Mostrar → **Especialización**, **General** va arriba:
  - **General marcada:** la misma barra en todas las specs; las specs se ven marcadas y bloqueadas.
  - **General desmarcada:** se liberan las specs y queda marcada la spec actual; cada spec marcada
    guarda su propia barra.
  - Un recuadro junto a las casillas explica la opción elegida.
- **Desmarcar una spec** quita la barra de esa spec, pero su contenido queda guardado; al volver
  a marcarla regresa igual. La última spec no se puede desmarcar.
- **Cada spec se edita en su propia spec.** Una barra de otra spec se ve en el panel atenuada y
  bloqueada, con el aviso «Esta barra es de …»; solo sus specs se pueden marcar.
- **Duplicar** una barra de otra spec crea la copia en la spec actual, con el contenido de la
  original. Duplicar una barra General da otra General.
- La condición de spec sale de las situaciones. Al actualizar, una barra General limitada a
  algunas specs pasa a barra por spec de esas specs, con el mismo contenido en cada una.
- El reporte marca con «-» las specs desmarcadas.

## [0.5.9] — 2026-10-23 · build de prueba

**Z**: aviso de asignar teclas dentro del panel.

### Resultado de las pruebas de 0.5.x (2026-10-26)
- ✅ Subir/Bajar · barras por spec solo en su spec · «Ocultar si estoy montado» · asignar teclas
  (panel y modo de atajos de Blizzard) · «Mostrar teclas» y «Teclas activas aunque esté oculta» ·
  pregunta por tecla repetida · teclas compartidas · el modo libre cierra la asignación ·
  comandos `/ob teclas`, `ayuda`, `panel`, `libre`, `bloquear`, `nueva`, `borrar`, `iconos`,
  `vacios`, `alcance`.
- 🟡 «Mostrar también si…» funciona a medias: choca con «En combate / Fuera de combate / Siempre».
- ⏳ Sin probar: teclas por spec en barras por spec, aviso dentro del panel (0.5.9).

### Cambiado
- Con el panel `/ob` abierto, el aviso de asignar teclas (con **Listo**) aparece dentro del panel,
  abajo de la columna derecha, arriba de Modo libre. Con el panel cerrado sigue arriba de la
  pantalla, y se mueve solo si abres o cierras el panel mientras asignas.

## [0.5.8] — 2026-10-23 · build de prueba

**Z**: teclas compartidas entre barras (D-59).

### Agregado
- La misma tecla puede ir en varias barras si **nunca están activas al mismo tiempo**. Al asignar
  una tecla que ya está en otra barra, la ventana ofrece **Compartir**, **Mover** o **Cancelar**.
- Separan a dos barras: ubicaciones que no se cruzan, specs distintas, en combate / fuera de
  combate, montado / sin montar. Combate y montura solo cuentan si la barra no tiene
  «Mostrar también si…» ni condición personalizada; «Ocultar si estoy montado» siempre cuenta.
- No se puede compartir si alguna tiene «Teclas activas aunque esté oculta», o si es la misma barra.
  El chat explica por qué.
- Si después cambias una situación y dos barras con tecla compartida ya pueden coincidir, el chat
  avisa.

## [0.5.7] — 2026-10-23 · build de prueba

**Z**: un modo a la vez (D-58).

### Cambiado
- Activar el **modo libre** (panel, `/ob libre` o Modo Edición) mientras se asignan teclas cierra
  la asignación de teclas.

## [0.5.6] — 2026-10-23 · build de prueba

**Z**: asignación de teclas.

### Resultado de la prueba de 0.5.0
- ❌ No se podían asignar teclas: el modo activaba el modo libre, cuyos recuadros de selección del
  Modo Edición tapaban los botones y se quedaban con el mouse.

### Corregido
- La asignación de teclas ya **no activa el modo libre**: muestra las barras de la spec (también
  ocultas) y los botones vacíos por su cuenta, sin recuadros de selección.
- Las zonas de asignación de cada botón van en una capa superior (`DIALOG`), por encima de todo.

## [0.5.5] — 2026-10-23 · build de prueba

**Z**: monturas.

### Corregido
- Los botones con una **montura** no la invocaban. Ahora la invocan por su nombre, como una macro
  `/cast <montura>`; si el nombre aún no está disponible, usan el hechizo como antes. Ícono,
  cooldown y tooltip no cambian.

### Resultado de la prueba de 0.5.5
- ✅ Los botones con montura ya la invocan.

## [0.5.4] — 2026-10-23 · build de prueba

**Z**: ocultar al montar, con prioridad (D-57).

### Agregado
- En **"Mostrar también si…"**: casilla **"Ocultar si estoy montado (siempre)"**. Montado, la
  barra se oculta aunque se cumpla otra casilla de la sección; sin montura, sigue sus reglas
  normales. Incluye el vuelo con montura.

### Cambiado
- El panel mide 728 px de alto para que quepa la casilla.

## [0.5.3] — 2026-10-23 · build de prueba

**Z**: ordenar la lista de barras (D-56).

### Agregado
- Panel: botones **Subir** y **Bajar** debajo de la lista para mover la barra seleccionada un
  lugar. El orden se guarda por personaje; las barras nuevas y duplicadas van al final. Solo
  cambia la lista: los números, nombres y posiciones en pantalla no se tocan.

## [0.5.2] — 2026-10-23 · build de prueba

**Z**: "Mostrar también si…" (D-55).

### Agregado
- Pestaña **Mostrar**, sección **"Mostrar también si…"**: casillas Sin mascota, Mascota muerta,
  En sigilo, Volando, Nadando, Objetivo enemigo, Objetivo aliado y Con foco. Si se cumple
  cualquiera, la barra aparece **aunque** "Combate", "Montura", "Con objetivo" o "En grupo" la
  oculten, también en combate.
- **Condición personalizada:** un campo para escribir condiciones de macro, por ejemplo
  `[nopet][@pet,dead]` o `[form:2,combat]`; se guarda con Enter solo si el juego la puede leer.
- Elegir Siempre / En combate / Fuera de combate en "Barra visible en" también limpia estas
  condiciones.

### Cambiado
- El panel mide 700 px de alto para que quepa la sección nueva.

## [0.5.1] — 2026-10-23 · build de prueba

**Z**: barras por spec solo en sus specs (D-54).

### Corregido
- Al cambiar de spec, las barras por spec de otras specs ya **no aparecen** (antes salían vacías).
  En cada spec se ven las barras **General** y las por spec **que pertenecen a esa spec**.
  Tampoco aparecen en modo libre ni ocupan espacio para el magnetismo.

### Cambiado
- **Agregar una barra a una spec:** elegir esa spec en el menú **Alcance** del panel. Una barra
  General pasa a ser de esa spec, con su contenido.
- En la lista del panel, las barras de otra spec salen **en gris** con "(otra spec)".
- **Datos (esquema 10):** se quitan los conjuntos vacíos que las barras por spec recibieron solo
  por visitar una spec.

## [0.5.0] — 2026-10-23 · build de prueba

**Y**: teclas (D-48 a D-53).

### Agregado
- **Modo de asignación** (`/ob teclas`, botón **Asignar teclas** en el panel, o **solo al abrir el
  Modo de atajo rápido de Blizzard**): mouse sobre un botón de OnlyBars y presionar una tecla.
  Acepta Shift/Ctrl/Alt, botones 3–5 del mouse y la rueda. Clic derecho o Supr borra; Esc sale.
  Muestra todas las barras mientras dura, también las ocultas.
- **Teclas por spec (D-48):** se guardan en el conjunto de la barra; en barras por spec cada spec
  tiene las suyas y la misma tecla puede repetirse entre specs.
- **Tecla de Blizzard (D-49):** OnlyBars la toma solo mientras su barra está activa y Blizzard la
  recupera después; tus atajos de Blizzard no se cambian. Un aviso dice qué hacía en Blizzard.
- **Tecla de otro botón de OnlyBars (D-50):** pregunta si moverla, diciendo en qué barra y botón está.
- **Teclas según la barra (D-52):** solo funcionan mientras la barra se ve, también en combate.
  Casilla **"Teclas activas aunque esté oculta"** para que funcionen siempre (pesca, interacción).
- **En el botón (D-53):** la tecla abreviada como Blizzard (`s1`, `c`, `a`, `M4`, `RU`/`RD`),
  roja fuera de alcance; casilla **"Mostrar teclas"**. El botón se ve presionado al usar su tecla.
- Las teclas actúan **al presionar** si la opción de Blizzard "lanzar al presionar la tecla" está
  activa; el clic del mouse sigue actuando al soltar.

### Cambiado
- Duplicar una barra crea la copia **sin teclas**, para que no choquen.

## [0.4.10] — 2026-10-22 · build de prueba

**Z**: arrastre fluido.

### Resultado de la prueba de 0.4.9
- ✅ Anclaje a barras de Blizzard: pegar, seguir al moverla, seguir al cambiar filas, soltar al
  arrastrar, flechas sin soltar y combate sin errores.
- ❌ Al mover una barra de OnlyBars con otra anclada encima, se trababa y parpadeaba.

### Corregido
- El magnetismo ya no toma como objetivo a las barras **ancladas a la que se mueve** (directas o en
  cadena): se movían con ella y la jalaban en cada cuadro, causando el parpadeo y el "freno".
- Las demás barras se miden **una vez** al empezar a arrastrar, no en cada cuadro.

### Resultado de la prueba de 0.4.10
- ✅ Arrastre fluido, también con barras de OnlyBars ancladas en cadena. Todo lo pendiente
  de la 0.4.x funciona.

## [0.4.9] — 2026-10-22 · build de prueba

**Z**: anclaje entre barras (D-47).

### Resultado de pruebas anteriores
- ✅ Shift + arrastrar la macro de `/reload` la mueve sin recargar.

### Agregado
- **Anclaje:** al soltar una barra de OnlyBars **pegada** al lado, encima o debajo de otra barra
  (de OnlyBars o de Blizzard), queda **anclada** a ella:
  - Si esa barra se **mueve** (también desde el Modo Edición de Blizzard), la tuya la sigue.
  - Si **crece o se achica**, la tuya se recorre.
  - **Arrastrar** tu barra la suelta; las **flechas** la mueven sin soltarla.
  - Solo alinear un borde no ancla.
- Solo se anclan barras de OnlyBars: **una barra de Blizzard nunca se mueve**, así no hay taint.
- Sin ciclos (A anclada a B anclada a A). Al borrar una barra, las ancladas a ella quedan libres
  donde estaban. Duplicar crea la copia libre.
- Reporte: a qué barra está anclada cada una y de qué lado.

## [0.4.8] — 2026-10-22 · build de prueba

**Z**: macros en vivo, tercera vuelta.

### Resultado de la prueba de 0.4.7
- ❌ El ícono se quedaba siempre en Invocación: `GetMacroSpell` no sigue modificadores como
  `[mod:shift]`.

### Corregido
- OnlyBars lee la macro **como Blizzard**: el argumento de `#showtooltip <x>` o su primera línea
  `/cast` / `/use` (con los comandos localizados del cliente), evaluada **en ese momento** con
  `SecureCmdOptionParse`. Entiende nombres `Hechizo(Subtexto)`, `!Hechizo` y números de ranura
  (`/use 13`). Si no se puede leer así, usa lo que reporta el cliente.
- El cooldown, las cargas, el alcance y la cantidad también siguen al hechizo u objeto en vivo.
- El reporte muestra lo que OnlyBars lee en vivo.

### Resultado de la prueba de 0.4.8
- ✅ La macro del Círculo demoníaco cambia de ícono con Shift, igual que en Blizzard.

## [0.4.7] — 2026-10-22 · build de prueba

**Z**: macros en vivo, segunda vuelta.

### Resultado de la prueba de 0.4.6
- ❌ El ícono de la macro del Círculo demoníaco no cambiaba con Shift (la macro sí funcionaba).

### Corregido
- Una macro se trata como "en vivo" si su ícono es el signo de interrogación **o** si su texto
  empieza con una línea `#showtooltip` / `#show` sola: el cliente puede no devolver el signo de
  interrogación en esas macros.

### Reporte
- Por cada macro: el ícono que devuelve el juego, si se trata como en vivo y si Shift estaba
  presionado. La ventana de Reporte se actualiza al presionar o soltar Shift/Ctrl/Alt.

## [0.4.6] — 2026-10-22 · build de prueba

**Z**: macros en vivo (D-46).

### Agregado
- Las macros con el ícono de **signo de interrogación** (`#showtooltip`) cambian de ícono según lo
  que lanzarían **en ese momento**, con cualquier condición: Shift/Ctrl/Alt, objetivo, combate,
  forma, montura, sigilo… Junto con el ícono se actualizan cooldown, cargas, alcance, calidad y
  tooltip. Una macro con ícono elegido lo conserva, como en Blizzard.
- Los modificadores cambian el ícono al instante; lo demás se revisa 5 veces por segundo, solo en
  botones con macro y solo se redibuja si cambia.

## [0.4.5] — 2026-10-22 · build de prueba

**Z**: macros con Shift y panel que bloquea al cerrarse.

### Resultado de las pruebas de 0.4.x
- ✅ `/ob filas` · "Barra visible en" · barra nueva del tamaño de Blizzard · ícono del mismo
  tamaño · jalón en vivo con líneas rojas · barras unidas de OnlyBars se empujan.
- ❌ Una macro `/cast [mod:shift] …` no respondía a Shift + clic.
- ⏳ Que también se empujen las barras de Blizzard: pendiente de decisión (mover barras de
  Blizzard desde un addon causa taint en las barras de acción).

### Corregido
- **Shift + clic (D-44):** los botones actúan al **soltar** el clic, como el libro de hechizos de
  Blizzard. Shift + clic lanza normal (macros `[mod:shift]`), y Shift + arrastrar sigue moviendo
  el botón sin lanzarlo, porque arrastrar cancela el clic.

### Agregado
- **Cerrar el panel `/ob` bloquea las barras (D-45)**, salvo que esté abierto el Modo Edición.

## [0.4.4] — 2026-10-22 · build de prueba

**Z**: mismo ancho que Blizzard (D-43).

### Corregido
- Con el mismo tamaño de iconos y margen, la barra de OnlyBars quedaba más ancha: Blizzard
  escala toda la barra (botones **y margen**) y OnlyBars solo los botones. Ahora la barra se arma
  con botones de 45 px y el margen tal cual, y se escala completa con el tamaño de iconos. Los
  números de los botones también se escalan, como en Blizzard.

### Resultado de la prueba de 0.4.4
- ✅ Las barras de OnlyBars y las de Blizzard miden lo mismo con el mismo tamaño y margen.

## [0.4.3] — 2026-10-22 · build de prueba

**Z**: sin escala (D-42).

### Cambiado
- Se quita la escala fija de 85%: las barras van al 100% y el tamaño lo da solo **Tamaño de los
  iconos**, de 50% a 200% como en Blizzard. Tus barras vuelven al tamaño que tenían en la 0.4.1.

## [0.4.2] — 2026-10-22 · build de prueba

**Z**: escala fija (D-41).

### Cambiado
- Se quitan "Usar escala" y "Escala": el tamaño se ajusta solo con **Tamaño de los iconos**.
- Todas las barras usan una **escala fija de 85%** en el código (`Core/Settings.lua`, `Settings.SCALE`).
- Una barra nueva compensa ese 85% para verse del mismo tamaño que tu barra 1 de Blizzard.
- **Datos (esquema 9):** se borra la escala guardada en cada barra.

## [0.4.1] — 2026-10-22 · build de prueba

**Z**: escala opcional y barras nuevas del tamaño de Blizzard (D-40).

### Cambiado
- Regresa la casilla **"Usar escala"**, apagada por defecto: apagada, la barra va al 100% y el
  deslizador de Escala queda en gris.
- **Barra nueva:** empieza con el tamaño de iconos y el margen de tu barra de acción 1 de
  Blizzard, así coincide aunque tus barras de Blizzard no estén al 100%.
- **Datos (esquema 8):** las barras con escala distinta de 100% quedan con "Usar escala" encendida.

## [0.4.0] — 2026-10-22 · build de prueba

**Y**: los mismos ajustes que las barras de Blizzard (D-39). Las teclas pasan a la 0.5.0.

### Cambiado
- La lista de ajustes de la ventana del Modo Edición y de la pestaña Forma es la de Blizzard:
  **Número de filas**, **Número de iconos**, **Tamaño de los iconos** (50–200%, 100% = botón de
  Blizzard de 45 px), **Margen de iconos** (2–10), **Escala**, **Transparencia**, **Mostrar
  botones vacíos** y **Barra visible en**.
- **Barra visible en** (menú): Siempre, En combate, Fuera de combate u Oculta. Siempre/En
  combate/Fuera de combate limpian las situaciones finas del panel. Si hay situaciones finas,
  dice "Personalizado (panel)" y al elegirlo abre la pestaña Mostrar.
- Se quitan las casillas "Igual que Blizzard" y "Usar escala", y la medición de la barra 1.
- **Datos (esquema 7):** "por fila" pasa a número de filas; todas las barras quedan al 100% de
  tamaño; la escala de las barras con "usar escala" apagado vuelve a 100%.
- Comandos: `/ob iconos 9 6` y `/ob filas 9 2` (los viejos `botones` y `fila` siguen
  funcionando; `fila` ahora es filas).

## [0.3.14] — 2026-10-22 · build de prueba

**Z**: "Igual que Blizzard" por defecto, sin saltos.

### Cambiado
- "Igual que Blizzard (tamaño y relleno)" sigue **activado por defecto** en toda barra nueva.
- Al **apagarlo**, la barra empieza con el tamaño y el relleno actuales de Blizzard (no salta a
  los valores viejos); los deslizadores se recargan con esos valores.
- El tamaño propio de reserva pasa de 36 a **45 px** (el de Blizzard).

## [0.3.13] — 2026-10-22 · build de prueba

**Z**: espacio entre barras unidas.

### Corregido
- Entre barras de OnlyBars unidas quedaba una franja extra: se usaba el doble del margen de las
  barras de Blizzard. Ahora el espacio es **el mismo relleno que hay entre los botones** (D-38),
  como las barras de Blizzard apiladas.

## [0.3.12] — 2026-10-22 · build de prueba

**Z**: ícono del mismo tamaño que en Blizzard.

### Resultado de la prueba de 0.3.11
- ✅ Los botones ya miden lo mismo que los de Blizzard.
- ❌ El ícono se veía más chico dentro del marco que en Blizzard.

### Corregido
- La máscara de esquinas redondeadas se estiraba al tamaño del botón y, como trae un margen
  transparente, recortaba de más el ícono. Ahora va **centrada y a su tamaño propio**
  (proporcional a un botón de 45 px), como en Blizzard.
- Reporte: medida de la máscara del ícono.

## [0.3.11] — 2026-10-22 · build de prueba

**Z**: el mismo tamaño que Blizzard (D-37).

### Resultado de la prueba de 0.3.10
- ❌ Los botones de OnlyBars (36 px fijos) se veían más chicos que los de Blizzard (45 px).
- ✅ El espacio entre barras unidas se ve parejo.

### Agregado
- **"Igual que Blizzard (tamaño y relleno)"**, activado por defecto: los botones toman el tamaño
  y el relleno de tu barra de acción 1 de Blizzard, medidos en el juego. Si cambias el tamaño de
  los íconos en el Modo Edición de Blizzard, OnlyBars se ajusta al cerrarlo. Tamaño y Relleno
  quedan en gris mientras está activado.
- Reporte: tamaño y relleno medidos del botón de Blizzard.

### Cambiado
- **Datos (esquema 6):** todas las barras pasan a "Igual que Blizzard". Quitando la casilla
  vuelven sus valores propios.

## [0.3.10] — 2026-10-22 · build de prueba

**Z**: que se sienta nativo (D-36).

### Agregado
- **"Usar escala"** en la pestaña Forma y en la ventana del Modo Edición: apagada, la barra va
  al 100% y el deslizador de escala queda en gris.
- **Espacio nativo al unir barras:** OnlyBars mide el margen de tus barras de Blizzard y, al
  pegar una barra a otra, deja el mismo espacio que queda entre dos barras de Blizzard unidas
  por su magnetismo. El reporte muestra cuánto midió.

### Cambiado
- "Separación" se llama **"Relleno"**, con el rango de Blizzard: **2 a 10 px**, 2 por defecto.
- **Datos (esquema 5):** las barras con escala distinta de 100% conservan "Usar escala"
  activado; el relleno fuera de rango se ajusta al más cercano.

## [0.3.9] — 2026-10-22 · build de prueba

**Z**: magnetismo con los botones, no con los márgenes.

### Corregido
- **Barras de Blizzard:** el magnetismo usaba el marco completo de la barra, que tiene márgenes
  vacíos alrededor de los botones; ahora usa el área de sus **botones visibles**.
- **Barras encimadas:** al unir dos barras lado a lado (o arriba/abajo) se deja la misma
  **separación** que hay entre los botones de la barra que se mueve, así parecen una sola
  barra. Alinear bordes (izquierdo con izquierdo, etc.) no lleva separación.
- El empuje entre barras unidas (D-33) reconoce esa separación.

## [0.3.8] — 2026-10-22 · build de prueba

**Z**: jalón en vivo y líneas rojas.

### Agregado
- **Arrastre en vivo (D-34):** al arrastrar una barra, el magnetismo y la rejilla la **jalan
  mientras la mueves**, no solo al soltarla, como en el Modo Edición de Blizzard.
- **Líneas rojas guía:** mientras la barra está pegada aparece una línea roja vertical
  (alineación a lo ancho) u horizontal (a lo alto). Desaparecen al soltar.

### Cambiado
- El arrastre ya no usa `StartMoving` del juego: lo calcula OnlyBars. Si entra el combate o se
  suelta el botón del mouse, el arrastre termina donde está.

## [0.3.7] — 2026-10-21 · build de prueba

**Z**: barras unidas y magnetismo más fuerte.

### Agregado
- **Barras unidas se empujan (D-33):** si dos o más barras están pegadas y una cambia de tamaño
  (botones, por fila, tamaño, separación o escala), las que tocan sus lados se recorren para
  seguir pegadas sin encimarse, en cadena. Si se achica, regresan.

### Cambiado
- **Magnetismo 35% más fuerte:** atrapa desde 13.5 px (antes 10).

## [0.3.6] — 2026-10-21 · build de prueba

**Z**: rejilla solo en modo libre.

### Cambiado
- La casilla **Rejilla** y su **tamaño** están en gris fuera del modo libre y del Modo Edición,
  donde no se ve la rejilla. Se habilitan al entrar a cualquiera de los dos (desde el panel,
  `/ob libre` o el Modo Edición) y vuelven a gris al salir. El magnetismo sigue disponible.

## [0.3.5] — 2026-10-21 · build de prueba

**Z**: magnetismo.

### Agregado
- **Magnetismo (D-32):** al soltar una barra, si un borde o su centro queda a 10 px o menos de
  otra barra de OnlyBars, de una barra de acción de Blizzard, de los bordes o del centro de la
  pantalla, se pega. A lo ancho y a lo alto por separado: bordes alineados, una pegada a la otra
  y centros. Tiene prioridad sobre la rejilla; el eje que no se pega va a la rejilla.
- Casilla **Magnetismo** en el pie del panel, activada por defecto.

## [0.3.4] — 2026-10-21 · build de prueba

**Z**: rejilla propia.

### Resultado de las pruebas de 0.3.2 / 0.3.3
- ✅ Menú de alcance y editar otra spec · barras por personaje · conjuntos de equipo en botones
  · mostrar/ocultar vacíos · vacíos al arrastrar · **brillo de proc** · las cinco categorías de
  situaciones · ventana chica · una sola selección · flechas · "Más opciones…".

### Agregado
- **Rejilla de OnlyBars (D-31)** (`Modules/Grid.lua`): en el pie del panel, casilla **Rejilla** y
  tamaño de **20 a 300 px**. Se dibuja desde el centro de la pantalla (líneas del centro en azul)
  en modo libre y en el Modo Edición. Al soltar una barra, su esquina superior izquierda se
  ajusta a la línea más cercana; las flechas siguen moviendo de 1 en 1 px.

### Cambiado
- Panel: **Reporte** pasa debajo de la lista de barras; se quita el botón gris de teclas (vuelve
  en la 0.4.0).

## [0.3.3] — 2026-10-21 · build de prueba

**Z**: nombre por spec.

### Cambiado
- **El nombre sigue al alcance (D-30):** en una barra por spec, cada spec tiene su propio
  nombre. Una spec sin nombre muestra "Barra 9". El panel renombra la spec elegida en Alcance.
- **Datos (esquema 4):** migración automática. El nombre se queda en la versión General y en
  las de spec que tienen algo; las versiones vacías de otras specs regresan a "Barra N".
- Duplicar copia el nombre de cada spec con "(copia)".

### Resultado de la prueba de 0.3.3
- ✅ La misma barra se renombra por separado en cada spec.

## [0.3.2] — 2026-10-21 · build de prueba

**Z**: menú de alcance.

### Resultado de la prueba de 0.3.1
- ✅ Shift + clic ya no lanza la acción.

### Cambiado
- **Alcance con menú desplegable (D-29):** "General" o una de las specs del personaje (la
  actual dice "(actual)"). Elegir una spec hace la barra por spec y el panel edita esa spec
  aunque no sea la actual; un aviso lo indica.
- "Global" se llama ahora **General**.

## [0.3.1] — 2026-10-21 · build de prueba

**Z**: correcciones tras probar el panel.

### Resultado de la prueba de 0.3.0
- ✅ Panel: abrir/cerrar, lista, mostrar/ocultar, nueva, duplicar, borrar, renombrar, forma,
  restablecer posición, botones del pie y página en *Opciones → AddOns*.
- ❌ Cambiar el alcance estando en otra spec borraba el contenido y la barra no volvía a aparecer.
- ❌ Shift + clic para mover un botón lanzaba la acción (una macro de `/reload` no se podía mover).

### Corregido
- **Alcance (D-27):** cambiarlo nunca borra nada. Cada spec y la versión Global quedan
  guardadas, y al regresar vuelve lo que había. Ya no pide confirmación.
- Una spec nueva ya no copia la condición de **especialización** de la anterior, que la
  dejaba oculta.
- **Shift + clic (D-28):** fuera de combate, Shift + clic del mouse ya no lanza la acción;
  solo sirve para recoger el botón. En combate funciona como siempre.

## [0.3.0] — 2026-10-20 · build de prueba

**Y**: panel `/ob`, barras por personaje y situaciones.

### Agregado
- **Panel `/ob`** (`UI/Panel.lua`):
  - Izquierda: las barras de este personaje, con casilla para mostrar u ocultar cada una;
    botones **+ Nueva barra**, **Duplicar** y **Borrar**.
  - Derecha: **nombre** editable (Enter para guardar) y **alcance** Global / Por spec.
  - Pestaña **Forma**: botones, por fila, tamaño, separación, escala, transparencia, botones
    vacíos y restablecer posición (los mismos ajustes que la ventana del Modo Edición).
  - Pestaña **Mostrar**: las situaciones (D-26).
  - Abajo: modo libre / bloquear, asignar teclas (gris hasta la 0.4.0) y Reporte.
  - También en *Opciones → AddOns → OnlyBars*.
- **Situaciones** (`Modules/Visibility.lua`, D-26), como la transfiguración de Blizzard:
  - **Ubicación:** mundo abierto, **áreas de descanso**, mazmorras, bandas, profundidades y
    escenarios, campos de batalla, arenas; atajos PvE y PvP.
  - **Especialización:** las specs del personaje.
  - **Conjunto de equipo:** los conjuntos del gestor de equipo.
  - **Estado:** combate, montura, con objetivo, en grupo, ocultar en vehículo, aparecer al
    pasar el mouse.
  - Dentro de una categoría basta cualquiera; entre categorías, todas; sin marcar, sin límite.
  - Ubicación, spec y conjunto se aplican fuera de combate; el estado cambia también en combate.
  - En modo libre y en el Modo Edición todas las barras se ven, para poder acomodarlas.
- Ventana del Modo Edición: botón **Más opciones…** que abre el panel en esa barra.
- `UI/Widgets.lua`: controles compartidos por la ventana y el panel.

### Cambiado
- **Barras por personaje (D-25, esquema 3):** cada personaje tiene sus propias barras.
  Migración automática: cada personaje que ya había entrado conserva una copia de lo que veía.
- `/ob` solo abre el panel; `/ob ayuda` muestra los comandos.

## [0.2.2] — 2026-10-20 · build de prueba

**Z**: una sola selección a la vez y conjuntos de equipo.

### Resultado de la prueba de 0.2.1
- ✅ Arte de botones de Blizzard completo; la selección usa la plantilla de Blizzard.
- ✅ Calidad de profesión: Midnight usa `Professions-Icon-Quality-12-Tier%d-Inv`.
- ❌ Seguían seleccionadas dos cosas a la vez (OnlyBars y Blizzard).
- 🔍 Las "macros" que no entraban eran **conjuntos de equipo** (cursor `equipmentset`).

### Corregido
- **Hooks del Modo Edición:** se instalaban al cargar OnlyBars, pero el Modo Edición de
  Blizzard puede cargarse después y quedaban sin conectar. Ahora se conectan al entrar al
  juego o al abrir el Modo Edición.
- **Una sola selección (D-24):** al seleccionar una barra de OnlyBars se quita la selección de
  Blizzard (`ClearSelectedSystem`, puede causar taint; vigilar `/ob errores`).

### Agregado
- **Conjuntos de equipo** del gestor de equipo: se ponen en un botón y se equipan con el
  comando `/equipset` del juego; muestran ícono, nombre y tooltip.

## [0.2.1] — 2026-10-20 · build de prueba

**Z**: selección cruzada con el Modo Edición.

### Corregido
- Al seleccionar un elemento de Blizzard, la barra de OnlyBars seguía seleccionada. Ahora
  también se escucha la ventana de ajustes de Blizzard (`OnShow` y `AttachToSystem`), solo
  escuchando (D-11).

### Abierto
- Al seleccionar una barra de OnlyBars, el elemento de Blizzard sigue seleccionado. Quitarle
  la selección pide `EditModeManagerFrame:ClearSelectedSystem()`, que causa taint. Pendiente
  de decisión del usuario.

## [0.2.0] — 2026-10-19 · build de prueba

**Y**: sistema híbrido con el Modo Edición de Blizzard (D-18) y arte de Blizzard en los botones (D-19).

### Agregado
- **Modo Edición de Blizzard:** las barras de OnlyBars aparecen con la **misma selección azul**
  que las de Blizzard (`EditModeSystemSelectionTemplate`). Se arrastran para moverlas y con
  un clic se abre una **ventana chica con el estilo de Blizzard**:
  - Botones, por fila, tamaño, separación, escala, transparencia y botones vacíos, con
    deslizadores que cambian la barra en vivo.
  - Alcance Global / Por spec (clic para cambiar).
  - Restablecer posición.
  - Flechas: mover 1 px; Shift + flechas: 10 px. Esc cierra la ventana.
- `/ob libre` usa la misma selección y la misma ventana, sin abrir todo el Modo Edición.
- **Botones con el arte de Blizzard:** marco, esquinas redondeadas (máscara del ícono),
  marco presionado y resaltado. El brillo de proc usa el mismo marco en dorado.
- **Modelo único de ajustes** (`Core/Settings.lua`): la ventana, los comandos y el futuro
  panel usan las mismas definiciones.
- Reporte: si el cliente tiene el arte y la plantilla de Blizzard, o si se usa el respaldo.

### Cambiado
- **Datos (esquema 2, D-20):** la posición y la forma se guardan en cada conjunto (Global o
  cada spec), así una barra Por spec puede tener posición y forma distintas en cada spec.
  Migración automática: las barras existentes no pierden nada.
- Una spec nueva copia la posición y la forma de la spec anterior, con los botones vacíos (D-16).
- Sacar el contenido de un botón pide **Shift + arrastrar en cualquier modo** (D-23). En modo
  libre y en el Modo Edición la selección cubre la barra.
- D-11 revisada: escuchar a Blizzard sí, modificar su estado no. Seleccionar una barra de
  Blizzard cierra la ventana de OnlyBars; al revés no, para no causar taint.

### Quitado
- La pestaña azul de arrastre del modo libre (la reemplaza la selección de Blizzard).

### Pendiente
- Ajuste a la rejilla del Modo Edición: Blizzard no expone su rejilla para addons; por ahora
  se usan las flechas.

## [0.1.5] — 2026-10-17 · build de prueba

**Z**: objetos dentro de macros.

### Resultado de la prueba de 0.1.4
- ❌ Seguía sin verse la cantidad de un objeto. Sospecha: el objeto está dentro de una macro
  (`/use …`), que OnlyBars no leía.
- ✅ StatsMythic: no volvió a pasar.

### Agregado
- **Macros `/use <objeto>`:** muestran la cantidad, la calidad y el cooldown del objeto, como
  en las barras de Blizzard (`GetMacroItem`).
- Reporte: cada macro dice qué hechizo u objeto usa; cada objeto, su ID, cuántos tienes y su
  calidad.

### Resultado de la prueba de 0.1.5
- ✅ La cantidad de objetos ya aparece.
- ✅ Calidad de profesión: se ven los rombos.
- ✅ Macro con cargas: muestra el número.
- ✅ Barra Por spec: queda en blanco al cambiar de spec y conserva lo de cada spec (D-17).
- ⏳ Brillo de proc: se prueba en la 0.2.0, con teclas asignadas.
- ✅ Crear y borrar barras, cantidad de botones, botones por fila, ícono gris, tooltip, modo
  bloqueado, bloqueo en combate y Modo Edición.
- ❌ Shift + arrastrar en modo bloqueado: no le funcionó al usuario. Corregido sin publicar:
  Shift funciona siempre, además del modificador de Blizzard.
- ❓ Algunas macros no se pueden poner (otras, como una de invocación, sí). Pendiente de ver el
  registro del cursor en `/ob errores`.

## [0.1.4] — 2026-10-17 · build de prueba

**Z**: cantidad y calidad de los objetos.

### Corregido
- **Cantidad de objetos:** no aparecía si los datos del objeto no estaban cargados al entrar.
  Ahora se muestra siempre que tengas más de uno, y el botón se actualiza al llegar los datos
  (`GET_ITEM_INFO_RECEIVED`).

### Agregado
- **Calidad de profesión** (rombos de pociones, frascos, etc.) arriba a la izquierda, como en
  las barras de Blizzard. Prueba las dos formas conocidas de la API y solo usa un atlas que el
  cliente tenga.
- Reporte: cada objeto con cuántos tienes y qué calidad detectó.

### Investigado
- StatsMythic dejó de mostrar sus barras. OnlyBars no toca sus marcos, nombres ni eventos.
  Sospechas: la Barra 9 encima de su panel (los dos cerca del centro), o el modo "solo en
  combate" de StatsMythic, que revisa `InCombatLockdown()` en `PLAYER_REGEN_DISABLED`, cuando
  todavía devuelve falso.

## [0.1.3] — 2026-10-17 · build de prueba

**Z**: correcciones tras la segunda prueba en el juego.

### Resultado de la segunda prueba
- ✅ Cooldown de hechizos, alcance y falta de maná: normales en combate, sin secretos.
- ✅ Mascotas: aparecen. ✅ Poción sacada de la barra: sin aviso de destruir.
- ❌ Macro con cargas: no mostraba nada. ❌ Brillo de proc: no se vio. ❌ Por spec: no quedaba en blanco.

### Corregido
- **Por spec (D-17):** al pasar una barra de Global a Por spec, solo la spec actual conserva el
  contenido; las demás empiezan en blanco. Antes se copiaba a todas.
- **Macros con cargas:** muestran el número de cargas del hechizo que lanzan.
- El hechizo de un botón nunca se usa si llega como valor secreto (D-12).
- Cambio de spec: también escucha `ACTIVE_PLAYER_SPECIALIZATION_CHANGED`.

### Reporte
- Qué hechizo lanza cada macro.
- En barras Por spec: la spec actual y qué specs tienen contenido.
- Qué hechizos se iluminaron y si estaban en un botón de OnlyBars.

## [0.1.2] — 2026-10-16 · build de prueba

**Z**: reporte más claro, tras la primera prueba en el juego.

### Resultado de la primera prueba (WoW 12.1.5)
- **Cooldown de objetos: funciona en combate** (sin secretos ni errores). Sube de 🟠 a ✅.
- **Evento de brillo de proc: llega en combate con el hechizo legible.** Falta ver el brillo en un botón.
- Hechizos: sin datos (no había hechizos en las barras, o no se quedaron al soltarlos).

### Cambiado
- El reporte muestra **qué tiene cada barra** (hechizos, objetos, monturas…).
- Si algo no se puede soltar en un botón, se registra lo que traía el cursor.
- "Sin respuesta" cuando la API no devuelve nada, distinto de "normal".

## [0.1.1] — 2026-10-16 · build de prueba

**Z**: ventana de Reporte para poder copiar errores (el chat del juego no deja copiar).

### Agregado
- **Ventana "OnlyBars · Reporte"** (`/ob errores`): diagnóstico y errores como texto copiable
  (Ctrl+A, Ctrl+C). Botones: seleccionar todo, limpiar errores y cerrar. Se cierra con Esc.
- **Registro de errores propio** (`Core/Log.lua`), sin dependencias (D-14):
  - Errores de Lua dentro de OnlyBars, con las primeras líneas de su detalle técnico. También
    siguen al manejador normal de errores.
  - Acciones que el juego bloqueó a OnlyBars (`ADDON_ACTION_BLOCKED` / `FORBIDDEN`).
  - Avisos cuando una función de Midnight falla, con su mensaje.
  - Últimos 50 registros, se guardan entre `/reload` y los repetidos se cuentan.
  - Una sola línea de aviso en el chat por sesión.
- `/ob prueba` abre también la ventana de Reporte.
- `UI/Style.lua`: estilo común (plano, oscuro, minimalista) para las ventanas de OnlyBars.

## [0.1.0] — 2026-10-16 · build de prueba

**X**: primera build. Sirve para probar en el juego qué permite Midnight (`DISENO.md` 10.4).

### Agregado
- Barras propias desde la Barra 9, con hasta 12 botones y cuántos van por fila.
- Botones seguros propios: hechizos, objetos, juguetes, macros, monturas y mascotas.
- Arrastrar y soltar, intercambio entre botones y clic con algo en el cursor para colocarlo.
- Cooldown, recarga de cargas, número de cargas, cantidad de objetos, alcance, falta de maná,
  ícono gris si la spec no tiene el hechizo y brillo de proc.
- Modo libre (pestaña para arrastrar) y bloqueado (el modificador de Blizzard, Shift por defecto).
  Se bloquea al entrar en combate y se libera con el Modo Edición de Blizzard.
- Alcance Global / Por spec por barra, con lienzo en blanco en specs nuevas.
- Cola de combate para los cambios protegidos.
- Comandos `/ob`, `/onlybars` y diagnóstico `/ob prueba`.

### Pendiente para siguientes builds
- Teclas, visibilidad por situación, panel, perfiles, cuadrícula y flechas, tamaño/escala/transparencia
  desde el panel.

## [Sin publicar]

### Diseño
- 2026-10-16 — Idea y alcance de la 1.0.0 definidos en `docs/DISENO.md` (decisiones D-01 a D-10).
- 2026-10-16 — Revisión de la API de Midnight (`DISENO.md` 10.4), decisiones D-11 a D-13.
- 2026-10-16 — D-04 revisada (alcance Global/Por spec por barra), D-14 a D-16. Sin pendientes.
