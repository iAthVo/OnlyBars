--[[
	OnlyBars · Locales/esMX.lua
	Spanish strings, over the English base (Locales/enUS.lua) on Spanish
	clients (esMX and esES). A key missing here keeps its English text.
	Textos en español, sobre la base en inglés (Locales/enUS.lua) en clientes
	en español (esMX y esES). Una clave que falte aquí conserva su texto en inglés.
	© 2026 iAthVo_Kr
]]

local _, ns = ...

local locale = GetLocale()
if locale ~= "esMX" and locale ~= "esES" then return end

local L = ns.L

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
L.SET_COLUMNS = "Número de columnas"
L.SET_ORIENTATION = "Orientación"
L.ORIENT_HORIZONTAL = "Horizontal"
L.ORIENT_VERTICAL = "Vertical"
L.SET_SHOW_KEYS = "Mostrar teclas"
L.SET_KEYS_ALWAYS = "Teclas activas aunque esté oculta"

-- Keys (Bars/Keybinds.lua) / Teclas
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

-- Lista de teclas (D-75)
L.PANEL_KEYLIST = "Lista de teclas"
L.KEYLIST_TITLE = "OnlyBars · Lista de teclas"
L.KEYLIST_SEARCH = "Buscar tecla…"
L.KEYLIST_HIDE_EMPTY = "Ocultar botones sin tecla"
L.KEYLIST_ALL_SPECS = "Todas las specs"
L.KEYLIST_ONLYBARS = "OnlyBars"
L.KEYLIST_BLIZZARD = "Blizzard"
L.KEYLIST_BAR = "Barra de acción %d"
L.KEYLIST_PET = "Barra de mascota"
L.KEYLIST_STANCE = "Barra de posturas"
L.KEYLIST_COUNT = "%d teclas"
L.KEYLIST_NONE = "—"
L.KEYLIST_EMPTY = "No hay nada que coincida."
L.KEYLIST_CLASH = "Choque: estas barras pueden verse al mismo tiempo."
L.KEYLIST_OVER_BLIZZARD = "También en una barra de Blizzard: OnlyBars la toma mientras su barra está activa."
L.KEYLIST_SHARED = "Compartida: estas barras nunca se ven juntas."
L.KEYLIST_ALSO = "También en:"
L.KEYLIST_LEGEND = "|cff%s!|r choque   |cff%s!|r también en Blizzard"

-- Importar / Exportar (D-76)
L.PANEL_TRANSFER = "Importar / Exportar"
L.TRANSFER_TITLE = "OnlyBars · Importar / Exportar"
L.TRANSFER_EXPORT = "Exportar"
L.TRANSFER_IMPORT = "Importar"
L.EXPORT_PICK = "Barras a exportar"
L.EXPORT_ALL = "Todas"
L.EXPORT_NONE = "Ninguna"
L.EXPORT_NAME = "Nombre en la lista (opcional)"
L.EXPORT_GO = "Exportar"
L.EXPORT_GO_COUNT = "Exportar (%d)"
L.EXPORT_HINT = "Ctrl+C copia el texto. También quedó guardado en la lista de la pestaña Importar, en todos tus personajes."
L.EXPORT_FAILED = "No se pudo exportar: revisa la ventana de Reporte."
L.EXPORT_MORE = " +%d"
L.EXPORT_SAVED = "Exportado y guardado en la lista: %s."
L.IMPORT_SAVED = "Guardadas en la lista"
L.IMPORT_SAVED_EMPTY = "Todavía no hay nada guardado. Exporta barras o pega un texto abajo."
L.IMPORT_RENAME = "Renombrar"
L.IMPORT_DELETE = "Borrar"
L.IMPORT_PASTE = "O pega aquí un texto (Ctrl+V):"
L.IMPORT_AS_NEW = "Nueva barra"
L.IMPORT_REPLACE = "Reemplaza: %s"
L.IMPORT_CONTENT = "Con iconos y hechizos"
L.IMPORT_CONTENT_TIP = "Sin marcar, las barras llegan vacías. En los dos casos conservan su forma, posición y situaciones. Las macros y mascotas que no existan aquí quedan como botón vacío."
L.IMPORT_KEYS_CHECK = "Con teclas"
L.IMPORT_KEYS_TIP = "Las teclas que ya use otra barra que puede verse al mismo tiempo no se ponen."
L.IMPORT_GO = "Importar"
L.IMPORT_GO_COUNT = "Importar (%d)"
L.IMPORT_BARS = "%d barras"
L.IMPORT_SUMMARY = "%d barras listas para importar · %s"
L.IMPORT_OTHER_CLASS = "|cffffa020(otra clase: las barras por spec llegan como General)|r"
L.IMPORT_NOTHING = "Elige una de la lista o pega un texto."
L.IMPORT_BAD_FORMAT = "Ese texto no es de OnlyBars."
L.IMPORT_BAD_VERSION = "Ese texto es de otra versión de OnlyBars: actualiza el addon."
L.IMPORT_DAMAGED = "El texto está incompleto o dañado: cópialo otra vez completo."
L.IMPORT_EMPTY = "El texto no trae barras."
L.IMPORT_CONFIRM_REPLACE = "Se van a reemplazar %d barras con las importadas.\n¿Seguir?"
L.IMPORT_RENAME_TEXT = "Nuevo nombre para «%s»:"
L.IMPORT_DELETE_TEXT = "¿Borrar «%s» de la lista?\nLas barras que ya importaste no cambian."
L.IMPORT_DONE = "Importación lista: %d nuevas, %d reemplazadas."
L.IMPORT_SKIPPED = "%d no cupieron (el límite es de %d barras)."
L.IMPORT_CONVERTED = "%d barras de otra clase pasaron a General."
L.IMPORT_SLOTS = "%d botones quedaron vacíos: macros o mascotas que no existen aquí."
L.IMPORT_KEYS = "%d teclas no se pusieron: ya las usa otra barra que puede verse al mismo tiempo."
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
L.LOG_HEALED = "Botón sin acción, reparado: %s (tenía %s, debía %s · a media pulsación: %s)"
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
L.REPORT_STATE = "Estado de los botones (/ob estado)"
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
	"  |cffffffff/ob listateclas|r — lista de teclas de OnlyBars y de Blizzard",
	"  |cffffffff/ob exportar|r · |cffffffff/ob importar|r — compartir barras con un texto, como los talentos",
	"  |cffffffff/ob prueba|r — resultado de la prueba de Midnight (en la ventana de Reporte)",
	"  |cffffffff/ob errores|r — ventana de Reporte para copiar errores",
	"  |cffffffff/ob estado|r — con el mouse sobre un botón que no responde: muestra qué le pasa",
	"Arrastra hechizos, objetos, juguetes, macros, monturas, mascotas y conjuntos de equipo a los botones.",
	"Saca o cambia lo que tiene un botón con Shift + arrastrar.",
	"En modo libre o en el Modo Edición: arrastra una barra para moverla y haz clic para ajustarla.",
}
