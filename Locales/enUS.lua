--[[
	OnlyBars · Locales/enUS.lua
	English strings: the base for every client language. Locales/esMX.lua
	replaces them on Spanish clients. A missing key shows the key itself.
	Textos en inglés: la base para cualquier idioma del cliente.
	Locales/esMX.lua los reemplaza en clientes en español. Si falta una
	clave, se muestra la clave.
	© 2026 iAthVo_Kr
]]

local _, ns = ...

local L = setmetatable({}, { __index = function(_, key) return key end })
ns.L = L

L.PREFIX = "|cff4fc3f7OnlyBars|r"
L.LOADED = "v%s loaded. |cffffffff/ob|r opens the panel · |cffffffff/ob help|r lists the commands."

-- Bars
L.BAR_NAME = "Bar %d"
L.BAR_CREATED = "%s created."
L.BAR_COPIED = "%s copied from %s."
L.BAR_COPIED_GENERAL = "%s copied from %s. It is from another class: it became General, with the content of its first spec."
L.BAR_SENT = "%s copied to %s: you will see it when you log in with that character."
L.BAR_SENT_GENERAL = "%s copied to %s, which is another class: it became General, with the content of its first spec."
-- Copy between characters, both ways (D-67)
L.COPY_OPEN = "Copy bars between characters"
L.COPY_CHOOSE = "Choose a character"
L.COPY_NONE = "No other characters use OnlyBars yet. Log in with them once and they will show up."
L.COPY_NO_BARS = "This character has no bars."
L.COPY_TO = "Copy to %s"
L.COPY_DIRECTION = "%s  >  %s"
L.COPY_SWAP = "Click to swap the direction."
L.COPY_HINT = "Check the bars and copy them. They arrive without keys, in the middle of the screen. The original bar does not change."
L.BAR_DELETED = "%s deleted."
L.BAR_LIMIT = "You reached the limit of %d bars."
L.BAR_NOT_FOUND = "Bar %s does not exist. Use its number, for example: /ob delete 9"
L.BAR_UPDATED = "%s: %s = %s."
L.CONFIRM_DELETE = "Delete %s?\nEverything on it will be lost."
L.SHOWN = "shown"
L.HIDDEN = "hidden"
L.COPY_SUFFIX = "(copy)"

-- Situations (D-26)
L.CAT_LOCATION = "Location"
L.CAT_SPEC = "Specialization"
L.CAT_EQUIPSET = "Equipment set"
L.CAT_STATE = "State"
L.LOC_WORLD = "Open world"
L.LOC_REST = "Rest areas"
L.LOC_DUNGEON = "Dungeons"
L.LOC_RAID = "Raids"
L.LOC_DELVE = "Delves and scenarios"
L.LOC_BATTLEGROUND = "Battlegrounds"
L.LOC_ARENA = "Arenas"
L.LOC_PVE = "PvE"
L.LOC_PVP = "PvP"
L.STATE_ANY = "always"
L.STATE_COMBAT_ALWAYS = "Always"
L.STATE_COMBAT_IN = "In combat"
L.STATE_COMBAT_OUT = "Out of combat"
L.STATE_MOUNTED = "Mount"
L.STATE_MOUNTED_YES = "mounted only"
L.STATE_MOUNTED_NO = "unmounted only"
L.STATE_TARGET = "Target"
L.STATE_TARGET_ANY = "any"
L.STATE_TARGET_EXISTS = "has a target"
L.STATE_TARGET_HARM = "enemy"
L.STATE_TARGET_HELP = "friendly"
L.STATE_GROUP = "Only in a party or raid"
L.STATE_HIDE_VEHICLE = "Hide in vehicles and pet battles"
L.SET_MOUSEOVER = "Show on mouseover"
L.SET_FADE_ALPHA = "Opacity without the mouse"

-- Panel (UI/Panel.lua)
L.PANEL_TITLE = "OnlyBars"
L.PANEL_NAME = "Name"
L.PANEL_EYE = "Show or hide this bar"
L.PANEL_NEW = "+ New bar"
L.PANEL_DUPLICATE = "Duplicate"
L.PANEL_DELETE = "Delete"
L.PANEL_TAB_SHAPE = "Layout"
L.PANEL_TAB_SHOW = "Show"
L.PANEL_FREE = "Free mode"
L.PANEL_LOCK = "Lock bars"
L.GRID = "Grid"
L.GRID_PX = "%d px"
L.MAGNET = "Snapping"
L.PANEL_REPORT = "Report"
L.PANEL_EMPTY = "You have no bars. Create one with \"+ New bar\"."
L.PANEL_NO_SETS = "You have no sets in the Equipment Manager."
L.PANEL_SHAPE_HINT = "On a per-spec bar, these settings belong to the spec you are in."
L.PANEL_OTHER_SPEC_NOTE = "This bar belongs to %s. Check it under Specialization or use Duplicate."
L.SPEC_NOTE_GLOBAL = "Visible in every specialization"
L.SPEC_NOTE_ONE = "Visible only in this specialization"
L.SPEC_NOTE_SOME = "Visible only in %s"
L.AND = " and "
L.SPEC_LAST = "A per-spec bar needs at least one spec. To hide it, uncheck it in the list."
L.PANEL_SHOW_HINT = "Within a category one option is enough; across categories, all of them. Nothing checked = no limit."
L.OPTIONS_TEXT = "Bars are set up in the OnlyBars panel (/ob)."
L.OPTIONS_OPEN = "Open the OnlyBars panel"

-- Layout settings (Core/Settings.lua), named like Blizzard's Edit Mode
L.SET_BUTTONS = "# of Icons"
L.SET_SPACING = "Icon Padding"
L.SET_ROWS = "# of Rows"
L.SET_SHOW_KEYS = "Show keybinds"
L.SET_KEYS_ALWAYS = "Keybinds work while hidden"

-- Keys (Bars/Keybinds.lua)
L.PANEL_KEYS = "Set keybinds"
L.PANEL_SAVED = "(%s)"
L.PANEL_UP = "Up"
L.PANEL_DOWN = "Down"

-- "Show only if…" (D-55, D-61)
L.CAT_SHOW_IF = "Show only if…"
L.SHOWIF_NOPET = "No pet"
L.SHOWIF_PETDEAD = "Pet is dead"
L.SHOWIF_STEALTH = "Stealthed"
L.SHOWIF_FLYING = "Flying"
L.SHOWIF_SWIMMING = "Swimming"
L.SHOWIF_FOCUS = "Has a focus"
L.LOCKED = "%s (locked)"
L.STATE_SHOWIF_NOTE = "Combat and party are not used together with \"Show only if…\": clear one to use the other. Mount, target and vehicle always apply."
L.STATE_SHOWIF_BOTH = "Note: this bar uses combat or party and \"Show only if…\" at the same time. Clear one of them."
L.KEY_MODE_ON = "Keybind mode: hover a button and press a key."
L.KEY_MODE_OFF = "Keybind mode finished."
L.KEY_MODE_HINT = "Hover an OnlyBars button and press a key.\nRight-click or Delete clears · Esc exits."
L.KEY_MODE_DONE = "Done"
L.KEY_SET = "%s bound to %s, button %d."
L.KEY_CLEARED = "Keybind cleared from %s, button %d."
L.KEY_BLIZZARD = "%s is also \"%s\" in Blizzard's keybinds: OnlyBars uses it while its bar is active."
L.KEY_WHERE = "%s, button %d"
L.KEY_CONFIRM_MOVE = "%s is already on %s.\nMove it to this button?"
L.KEY_CONFIRM_SHARE = "%s is already on %s.\nThose bars are never active at the same time as this one: you can share it or move it."
L.KEY_SHARE = "Share"
L.KEY_MOVE = "Move"
L.KEY_NO_SHARE = "%s can't be shared: those bars can be active at the same time (check location, spec, combat, mount, \"Show only if…\" and \"Keybinds work while hidden\")."
L.KEY_SHARED = "%s shared with %s: each bar uses it while it is active."
L.KEY_SHARE_BROKEN = "Note: %s is on %s and on %s, and with these situations they can be active at the same time. Change their situations or remove the key from one."
L.SET_ICON_SIZE = "Icon Size"
L.SET_ALPHA = "Opacity"
L.SET_SHOW_EMPTY = "Show empty buttons"

-- Bar dialog (UI/BarDialog.lua)
L.DIALOG_SCOPE = "Scope: %s (click to change)"
L.DIALOG_RESET_POSITION = "Reset position"
L.DIALOG_MORE = "More options…"
L.DIALOG_HINT = "Arrows: move 1 px · Shift + arrows: 10 px"

-- Scope
L.SCOPE_GLOBAL = "General"
L.SCOPE_SPEC = "Per spec"
L.SCOPE_SET = "%s is now %s."

-- Modes
L.MODE_FREE = "Free mode: drag a bar to move it or click it to adjust it. |cffffffff/ob lock|r to finish."
L.MODE_LOCKED = "Bars locked."

-- Combat
L.COMBAT_QUEUED = "In combat: the change applies when combat ends."
L.COMBAT_BLOCKED = "That can't be done in combat."

-- Buttons
L.UNSUPPORTED = "That kind of action can't be placed on OnlyBars."

-- Diagnostics (/ob test)
L.DIAG_TITLE = "Midnight check (use the buttons in and out of combat before reading it):"
L.DIAG_NONE = "no data yet"
L.DIAG_EVENT_MISSING = "Event missing on this client: %s"
L.DIAG_COMBAT = "in combat"
L.DIAG_IDLE = "out of combat"
L.DIAG_OK = "normal"
L.DIAG_SECRET = "secret"
L.DIAG_ERROR = "error"
L.DIAG_EMPTY = "no answer"
L.DIAG_COOLDOWN = "Spell cooldowns"
L.DIAG_CHARGES = "Charges"
L.DIAG_ITEMCD = "Item cooldowns"
L.DIAG_USABLE = "Out of mana / usable"
L.DIAG_RANGE = "Range"
L.DIAG_GLOW = "Proc glow"

-- Log and Report window
L.LOG_NEW = "An error was logged. Type |cffffffff/ob errors|r to see and copy it."
L.LOG_KIND_LUA = "Lua error"
L.LOG_KIND_BLOCKED = "Action blocked"
L.LOG_KIND_WARNING = "API warning"
L.REPORT_TITLE = "OnlyBars · Report"
L.REPORT_HINT = "Ctrl+A selects all · Ctrl+C copies"
L.LOG_CURSOR = "Couldn't place it on a button. Cursor: %s"
L.LOG_TEMPLATE = "Blizzard template %s is missing; using the OnlyBars style."
L.DIAG_ART_OK = "Blizzard button art: complete"
L.DIAG_ART_MISSING = "Blizzard button art: %s missing (using the flat style)"
L.DIAG_MASK = "Blizzard icon mask: %d × %d (reference button: 45 × 45)"
L.DIAG_JOIN_GAP = "Gap between joined bars: same as the bar's icon padding"
L.DIAG_SELECTION_OK = "Edit Mode selection: Blizzard template"
L.DIAG_SELECTION_FALLBACK = "Edit Mode selection: Blizzard template missing, using the OnlyBars one"
L.REPORT_CONTENT = "Bar contents"
L.REPORT_EMPTY_BAR = "empty"
L.REPORT_MACRO = "  · macro \"%s\" → %s"
L.REPORT_NO_SPELL = "no spell"
L.REPORT_ANCHOR = "  · anchored to %s (%s)"
L.SIDE_ABOVE = "above"
L.SIDE_BELOW = "below"
L.SIDE_LEFT = "on the left"
L.SIDE_RIGHT = "on the right"
L.REPORT_MACRO_LIVE = "      game icon: %s · live: %s · Shift held while reading: %s"
L.REPORT_YES = "yes"
L.REPORT_NO = "no"
L.REPORT_ITEM = "  · %s"
L.REPORT_ITEM_DETAIL = "item \"%s\" (%d) · you have %d · quality: %s"
L.REPORT_NO_QUALITY = "none"
L.REPORT_SPECS = "  · current spec: %s · specs with content: %s"
L.DIAG_GLOW_SPELL = "  · %s (%d) glowed: %s"
L.DIAG_GLOW_ON_BAR = "it was on OnlyBars"
L.DIAG_GLOW_NOT_ON_BAR = "it was not on OnlyBars"
L.REPORT_DIAG = "Midnight check"
L.KIND_SPELL = "spell"
L.KIND_ITEM = "item"
L.KIND_TOY = "toy"
L.KIND_MACRO = "macro"
L.KIND_MOUNT = "mount"
L.KIND_PET = "pet"
L.KIND_EQUIPSET = "equipment set"
L.REPORT_ERRORS = "Errors"
L.REPORT_NO_ERRORS = "No errors logged."
L.REPORT_SELECT = "Select all"
L.REPORT_CLEAR = "Clear errors"
L.REPORT_CLOSE = "Close"

L.HELP = {
	"Commands:",
	"  |cffffffff/ob|r — open or close the panel",
	"  |cffffffff/ob free|r · |cffffffff/ob lock|r — move and adjust the bars (also from Edit Mode)",
	"  |cffffffff/ob new|r — create a bar",
	"  |cffffffff/ob delete 9|r — delete Bar 9",
	"  |cffffffff/ob icons 9 6|r — Bar 9 with 6 icons (1-12)",
	"  |cffffffff/ob rows 9 2|r — Bar 9 in 2 rows",
	"  |cffffffff/ob empty 9|r — show or hide empty buttons",
	"  |cffffffff/ob scope 9|r — switch between General and Per spec",
	"  |cffffffff/ob keys|r — keybind mode (also with Blizzard's Quick Keybind Mode)",
	"  |cffffffff/ob test|r — Midnight check (in the Report window)",
	"  |cffffffff/ob errors|r — Report window to copy errors",
	"Drag spells, items, toys, macros, mounts, pets and equipment sets onto the buttons.",
	"Take out or swap what a button holds with Shift + drag.",
	"In free mode or Edit Mode: drag a bar to move it and click it to adjust it.",
}
