--[[
	OnlyBars · Locales/esMX.lua
	Spanish strings (default). A missing key falls back to the key itself.
	Textos en español (idioma base). Si falta una clave, se muestra la clave.
	© 2026 iAthVo_Kr
]]

local _, ns = ...

local L = setmetatable({}, { __index = function(_, key) return key end })
ns.L = L

L.PREFIX = "|cff4fc3f7OnlyBars|r"
L.LOADED = "v%s cargado. |cffffffff/ob|r abre el panel · |cffffffff/ob ayuda|r muestra los comandos."

-- Bars / Barras
L.BAR_NAME = "Barra %d"
L.BAR_CREATED = "%s creada."
L.BAR_COPIED = "%s copiada de %s."
L.BAR_COPIED_GENERAL = "%s copiada de %s. Es de otra clase: quedó General, con el contenido de su primera spec."
L.BAR_SENT = "%s copiada a %s: la verás cuando entres con ese personaje."
L.BAR_SENT_GENERAL = "%s copiada a %s, que es de otra clase: quedó General, con el contenido de su primera spec."
-- Copy between characters, both ways (D-67) / Copiar entre personajes, en los dos sentidos (D-67)
L.COPY_OPEN = "Copiar barras entre personajes"
L.COPY_CHOOSE = "Elige un personaje"
L.COPY_NONE = "No hay otros personajes con OnlyBars. Entra una vez con ellos para que aparezcan."
L.COPY_NO_BARS = "Este personaje no tiene barras."
L.COPY_TO = "Copiar a %s"
L.COPY_DIRECTION = "%s  >  %s"
L.COPY_SWAP = "Clic para invertir el sentido."
L.COPY_HINT = "Marca las barras y cópialas. Llegan sin teclas, en el centro de la pantalla. La barra original no cambia."
L.BAR_DELETED = "%s borrada."
L.BAR_LIMIT = "Llegaste al tope de %d barras."
L.BAR_NOT_FOUND = "No existe la barra %s. Usa el número, por ejemplo: /ob borrar 9"
L.BAR_UPDATED = "%s: %s = %s."
L.CONFIRM_DELETE = "¿Borrar la %s?\nSe pierde todo lo que tiene."
L.SHOWN = "visibles"
L.HIDDEN = "ocultos"
L.COPY_SUFFIX = "(copia)"

-- Situations (D-26) / Situaciones (D-26)
L.CAT_LOCATION = "Ubicación"
L.CAT_SPEC = "Especialización"
L.CAT_EQUIPSET = "Conjunto de equipo"
L.CAT_STATE = "Estado"
L.LOC_WORLD = "Mundo abierto"
L.LOC_REST = "Áreas de descanso"
L.LOC_DUNGEON = "Mazmorras"
L.LOC_RAID = "Bandas"
L.LOC_DELVE = "Profundidades y escenarios"
L.LOC_BATTLEGROUND = "Campos de batalla"
L.LOC_ARENA = "Arenas"
L.LOC_PVE = "PvE"
L.LOC_PVP = "PvP"
L.STATE_ANY = "siempre"
L.STATE_COMBAT_ALWAYS = "Siempre"
L.STATE_COMBAT_IN = "En combate"
L.STATE_COMBAT_OUT = "Fuera de combate"
L.STATE_MOUNTED = "Montura"
L.STATE_MOUNTED_YES = "solo montado"
L.STATE_MOUNTED_NO = "solo sin montar"
L.STATE_TARGET = "Objetivo"
L.STATE_TARGET_ANY = "no importa"
L.STATE_TARGET_EXISTS = "con objetivo"
L.STATE_TARGET_HARM = "enemigo"
L.STATE_TARGET_HELP = "aliado"
L.STATE_GROUP = "Solo en grupo o banda"
L.STATE_HIDE_VEHICLE = "Ocultar en vehículo y batalla de mascotas"
L.SET_MOUSEOVER = "Aparecer al pasar el mouse"
L.SET_FADE_ALPHA = "Opacidad sin el mouse"

-- Panel (UI/Panel.lua)
L.PANEL_TITLE = "OnlyBars"
L.PANEL_NAME = "Nombre"
L.PANEL_EYE = "Mostrar u ocultar esta barra"
L.PANEL_NEW = "+ Nueva barra"
L.PANEL_DUPLICATE = "Duplicar"
L.PANEL_DELETE = "Borrar"
L.PANEL_TAB_SHAPE = "Forma"
L.PANEL_TAB_SHOW = "Mostrar"
L.PANEL_FREE = "Modo libre"
L.PANEL_LOCK = "Bloquear barras"
L.GRID = "Rejilla"
L.GRID_PX = "%d px"
L.MAGNET = "Magnetismo"
L.PANEL_REPORT = "Reporte"
L.PANEL_EMPTY = "No tienes barras. Crea una con \"+ Nueva barra\"."
L.PANEL_NO_SETS = "No tienes conjuntos en el gestor de equipo."
L.PANEL_SHAPE_HINT = "En una barra por spec, estos ajustes son de la spec en la que estás."
L.PANEL_OTHER_SPEC_NOTE = "Esta barra es de %s. Márcala en Especialización o usa Duplicar."
L.SPEC_NOTE_GLOBAL = "Visible para todas las especializaciones"
L.SPEC_NOTE_ONE = "Solo visible para esta especialización"
L.SPEC_NOTE_SOME = "Visible solo para %s"
L.AND = " y "
L.SPEC_LAST = "Una barra por spec necesita al menos una spec. Para esconderla, quítale la palomita en la lista."
L.PANEL_SHOW_HINT = "Dentro de una categoría basta una opción; entre categorías, todas. Sin marcar = sin límite."
L.OPTIONS_TEXT = "Las barras se configuran en el panel de OnlyBars (/ob)."
L.OPTIONS_OPEN = "Abrir el panel de OnlyBars"

-- Layout settings (Core/Settings.lua) / Ajustes de forma
L.SET_BUTTONS = "Número de iconos"
L.SET_SPACING = "Margen de iconos"
L.SET_ROWS = "Número de filas"
L.SET_SHOW_KEYS = "Mostrar teclas"
L.SET_KEYS_ALWAYS = "Teclas activas aunque esté oculta"

-- Keys (Modules/Keybinds.lua) / Teclas
L.PANEL_KEYS = "Asignar teclas"
L.PANEL_SAVED = "(%s)"
L.PANEL_UP = "Subir"
L.PANEL_DOWN = "Bajar"

-- "Mostrar solo si…" (D-55, D-61)
L.CAT_SHOW_IF = "Mostrar solo si…"
L.SHOWIF_NOPET = "Sin mascota"
L.SHOWIF_PETDEAD = "Mascota muerta"
L.SHOWIF_STEALTH = "En sigilo"
L.SHOWIF_FLYING = "Volando"
L.SHOWIF_SWIMMING = "Nadando"
L.SHOWIF_FOCUS = "Con foco"
L.LOCKED = "%s (bloqueado)"
L.STATE_SHOWIF_NOTE = "Combate y grupo no se usan junto con «Mostrar solo si…»: quita lo marcado en uno para usar el otro. Montura, objetivo y vehículo siempre se aplican."
L.STATE_SHOWIF_BOTH = "Ojo: esta barra usa combate o grupo y «Mostrar solo si…» a la vez. Quita lo marcado en uno de los dos."
L.KEY_MODE_ON = "Asignación de teclas: pasa el mouse sobre un botón y presiona una tecla."
L.KEY_MODE_OFF = "Asignación de teclas terminada."
L.KEY_MODE_HINT = "Pasa el mouse sobre un botón de OnlyBars y presiona una tecla.\nClic derecho o Supr borra · Esc sale."
L.KEY_MODE_DONE = "Listo"
L.KEY_SET = "%s asignada a %s, botón %d."
L.KEY_CLEARED = "Tecla borrada de %s, botón %d."
L.KEY_BLIZZARD = "%s también es «%s» en Blizzard: OnlyBars la usa mientras su barra esté activa."
L.KEY_WHERE = "%s, botón %d"
L.KEY_CONFIRM_MOVE = "%s ya está en %s.\n¿Moverla a este botón?"
L.KEY_CONFIRM_SHARE = "%s ya está en %s.\nEsas barras nunca están activas al mismo tiempo que esta: puedes compartirla o moverla."
L.KEY_SHARE = "Compartir"
L.KEY_MOVE = "Mover"
L.KEY_NO_SHARE = "%s no se puede compartir: esas barras pueden estar activas al mismo tiempo (revisa ubicación, spec, combate, montura, «Mostrar solo si…» y «Teclas activas aunque esté oculta»)."
L.KEY_SHARED ="%s compartida con %s: cada barra la usa cuando está activa."
L.KEY_SHARE_BROKEN = "Ojo: %s está en %s y en %s, y con estas situaciones pueden estar activas al mismo tiempo. Cambia sus situaciones o quítale la tecla a una."
L.SET_ICON_SIZE = "Tamaño de los iconos"
L.SET_ALPHA = "Transparencia"
L.SET_SHOW_EMPTY = "Mostrar botones vacíos"

-- Bar dialog (UI/BarDialog.lua) / Ventana de la barra
L.DIALOG_SCOPE = "Alcance: %s (clic para cambiar)"
L.DIALOG_RESET_POSITION = "Restablecer posición"
L.DIALOG_MORE = "Más opciones…"
L.DIALOG_HINT = "Flechas: mover 1 px · Shift + flechas: 10 px"

-- Scope / Alcance
L.SCOPE_GLOBAL = "General"
L.SCOPE_SPEC = "Por spec"
L.SCOPE_SET = "%s ahora es %s."

-- Modes / Modos
L.MODE_FREE = "Modo libre: arrastra una barra para moverla o haz clic para ajustarla. |cffffffff/ob bloquear|r para terminar."
L.MODE_LOCKED = "Modo bloqueado."

-- Combat / Combate
L.COMBAT_QUEUED = "En combate: el cambio se aplica al salir."
L.COMBAT_BLOCKED = "No se puede hacer en combate."

-- Buttons / Botones
L.UNSUPPORTED = "Ese tipo de acción no se puede poner en OnlyBars."

-- Test build diagnostics / Diagnóstico de la build de prueba
L.DIAG_TITLE = "Prueba de Midnight (usa los botones dentro y fuera de combate antes de verla):"
L.DIAG_NONE = "sin datos todavía"
L.DIAG_EVENT_MISSING = "Evento que no existe en este cliente: %s"
L.DIAG_COMBAT = "en combate"
L.DIAG_IDLE = "fuera de combate"
L.DIAG_OK = "normal"
L.DIAG_SECRET = "secreto"
L.DIAG_ERROR = "error"
L.DIAG_EMPTY = "sin respuesta"
L.DIAG_COOLDOWN = "Cooldown de hechizos"
L.DIAG_CHARGES = "Cargas"
L.DIAG_ITEMCD = "Cooldown de objetos"
L.DIAG_USABLE = "Falta de maná / usable"
L.DIAG_RANGE = "Alcance"
L.DIAG_GLOW = "Brillo de proc"

-- Log and Report window / Registro y ventana de Reporte
L.LOG_NEW = "Se registró un error. Escribe |cffffffff/ob errores|r para verlo y copiarlo."
L.LOG_KIND_LUA = "Error de Lua"
L.LOG_KIND_BLOCKED = "Acción bloqueada"
L.LOG_KIND_WARNING = "Aviso de la API"
L.REPORT_TITLE = "OnlyBars · Reporte"
L.REPORT_HINT = "Ctrl+A selecciona todo · Ctrl+C copia"
L.LOG_CURSOR = "No se pudo poner en un botón. Cursor: %s"
L.LOG_TEMPLATE = "Falta la plantilla de Blizzard %s; se usa el estilo de OnlyBars."
L.DIAG_ART_OK = "Arte de botones de Blizzard: completo"
L.DIAG_ART_MISSING = "Arte de botones de Blizzard: faltan %s (se usa estilo plano)"
L.DIAG_MASK = "Máscara del ícono de Blizzard: %d × %d (botón de referencia: 45 × 45)"
L.DIAG_JOIN_GAP = "Espacio entre barras unidas: igual al margen de iconos de la barra"
L.DIAG_SELECTION_OK ="Selección del Modo Edición: plantilla de Blizzard"
L.DIAG_SELECTION_FALLBACK = "Selección del Modo Edición: falta la plantilla de Blizzard, se usa la de OnlyBars"
L.REPORT_CONTENT = "Contenido de las barras"
L.REPORT_EMPTY_BAR = "vacía"
L.REPORT_MACRO = "  · macro \"%s\" → %s"
L.REPORT_NO_SPELL = "sin hechizo"
L.REPORT_ANCHOR = "  · anclada a %s (%s)"
L.SIDE_ABOVE = "encima"
L.SIDE_BELOW = "debajo"
L.SIDE_LEFT = "a la izquierda"
L.SIDE_RIGHT = "a la derecha"
L.REPORT_MACRO_LIVE = "      ícono del juego: %s · en vivo: %s · Shift presionado al leer: %s"
L.REPORT_YES = "sí"
L.REPORT_NO = "no"
L.REPORT_ITEM = "  · %s"
L.REPORT_ITEM_DETAIL = "objeto \"%s\" (%d) · tienes %d · calidad: %s"
L.REPORT_NO_QUALITY = "ninguna"
L.REPORT_SPECS = "  · spec actual: %s · specs con contenido: %s"
L.DIAG_GLOW_SPELL = "  · se iluminó %s (%d): %s"
L.DIAG_GLOW_ON_BAR = "estaba en OnlyBars"
L.DIAG_GLOW_NOT_ON_BAR = "no estaba en OnlyBars"
L.REPORT_DIAG = "Prueba de Midnight"
L.KIND_SPELL = "hechizo"
L.KIND_ITEM = "objeto"
L.KIND_TOY = "juguete"
L.KIND_MACRO = "macro"
L.KIND_MOUNT = "montura"
L.KIND_PET = "mascota"
L.KIND_EQUIPSET = "conjunto de equipo"
L.REPORT_ERRORS = "Errores"
L.REPORT_NO_ERRORS = "Sin errores registrados."
L.REPORT_SELECT = "Seleccionar todo"
L.REPORT_CLEAR = "Limpiar errores"
L.REPORT_CLOSE = "Cerrar"

L.HELP = {
	"Comandos (build de prueba):",
	"  |cffffffff/ob|r — abre o cierra el panel",
	"  |cffffffff/ob libre|r · |cffffffff/ob bloquear|r — mover y ajustar las barras (también desde el Modo Edición)",
	"  |cffffffff/ob nueva|r — crear una barra",
	"  |cffffffff/ob borrar 9|r — borrar la Barra 9",
	"  |cffffffff/ob iconos 9 6|r — la Barra 9 con 6 iconos (1-12)",
	"  |cffffffff/ob filas 9 2|r — la Barra 9 en 2 filas",
	"  |cffffffff/ob vacios 9|r — mostrar u ocultar los botones vacíos",
	"  |cffffffff/ob alcance 9|r — cambiar entre General y Por spec",
	"  |cffffffff/ob teclas|r — modo de asignación de teclas (también con el Modo de atajo rápido de Blizzard)",
	"  |cffffffff/ob prueba|r — resultado de la prueba de Midnight (en la ventana de Reporte)",
	"  |cffffffff/ob errores|r — ventana de Reporte para copiar errores",
	"Arrastra hechizos, objetos, juguetes, macros, monturas, mascotas y conjuntos de equipo a los botones.",
	"Saca o cambia lo que tiene un botón con Shift + arrastrar.",
	"En modo libre o en el Modo Edición: arrastra una barra para moverla y haz clic para ajustarla.",
}
