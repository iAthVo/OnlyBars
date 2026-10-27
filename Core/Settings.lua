--[[
	OnlyBars · Core/Settings.lua
	The single settings model (D-18): every bar setting is defined once here and
	drawn by the Edit Mode dialog, the /ob panel and the commands.
	El modelo único de ajustes (D-18): cada ajuste de barra se define una vez
	aquí, y lo dibujan la ventana del Modo Edición, el panel /ob y los comandos.
	© 2026 iAthVo_Kr
]]

local _, ns = ...
local L = ns.L

local Settings = {}
ns.Settings = Settings

local function Percent(value)
	return ("%d%%"):format(math.floor(value * 100 + 0.5))
end

local function Plain(value)
	return tostring(math.floor(value + 0.5))
end

-- Blizzard's button at 100% icon size. Size comes only from "Tamaño de los
-- iconos" (50-200%, like Blizzard); bars have no scale (D-42).
-- El botón de Blizzard al 100% de tamaño de iconos. El tamaño sale solo de
-- "Tamaño de los iconos" (50-200%, como Blizzard); las barras no tienen escala (D-42).
Settings.BASE_SIZE = 45

-- The same list as Blizzard's action bar settings in Edit Mode, in its order (D-39).
-- kind: "slider" | "check" · key: field of set.layout (DB.lua)
-- La misma lista que los ajustes de barra de Blizzard en el Modo Edición, en su orden (D-39).
-- kind: "slider" | "check" · key: campo de set.layout (DB.lua)
Settings.LAYOUT = {
	{ kind = "slider", key = "rows", label = L.SET_ROWS, min = 1, max = 12, step = 1, format = Plain },
	{ kind = "slider", key = "buttons", label = L.SET_BUTTONS, min = 1, max = 12, step = 1, format = Plain },
	{ kind = "slider", key = "iconSize", label = L.SET_ICON_SIZE, min = 0.5, max = 2, step = 0.1, format = Percent },
	{ kind = "slider", key = "spacing", label = L.SET_SPACING, min = 2, max = 10, step = 1, format = Plain },
	{ kind = "slider", key = "alpha", label = L.SET_ALPHA, min = 0, max = 1, step = 0.05, format = Percent },
	-- Mouseover fade, cosmetic only (D-65): without the mouse the bar stays at
	-- fadeAlpha; with it, it goes back to its transparency. needs: usable only
	-- while that setting is on.
	-- Desvanecer con el mouse, solo cosmético (D-65): sin el mouse la barra se
	-- queda en fadeAlpha; con él, regresa a su transparencia. needs: usable solo
	-- mientras ese ajuste está activo.
	{ kind = "check", key = "mouseover", label = L.SET_MOUSEOVER },
	{ kind = "slider", key = "fadeAlpha", label = L.SET_FADE_ALPHA, min = 0, max = 1, step = 0.05,
		format = Percent, needs = "mouseover" },
	{ kind = "check", key = "showEmpty", label = L.SET_SHOW_EMPTY },
	-- Keys (D-52, D-53) / Teclas (D-52, D-53)
	{ kind = "check", key = "showKeys", label = L.SET_SHOW_KEYS },
	{ kind = "check", key = "keysAlways", label = L.SET_KEYS_ALWAYS },
	-- "Barra visible en" is gone: the Show tab has it all (D-63).
	-- "Barra visible en" ya no está: la pestaña Mostrar lo tiene todo (D-63).
}

-- Situations (D-26) / Situaciones (D-26)
Settings.LOCATIONS = {
	{ key = "world", label = L.LOC_WORLD },
	{ key = "rest", label = L.LOC_REST },
	{ key = "dungeon", label = L.LOC_DUNGEON },
	{ key = "raid", label = L.LOC_RAID },
	{ key = "delve", label = L.LOC_DELVE },
	{ key = "battleground", label = L.LOC_BATTLEGROUND },
	{ key = "arena", label = L.LOC_ARENA },
}

-- Shortcuts that mark several locations / Atajos que marcan varias ubicaciones
Settings.LOCATION_SHORTCUTS = {
	{ label = L.LOC_PVE, keys = { "dungeon", "raid", "delve" } },
	{ label = L.LOC_PVP, keys = { "battleground", "arena" } },
}

-- kind "cycle": click to go through the options / clic para pasar por las opciones
-- kind "choice": one check per option, one or none marked; none is "any" (0.6.3).
-- "always" works like "any", it only shows the check marked.
-- kind "choice": una casilla por opción, una o ninguna marcada; ninguna es "any" (0.6.3).
-- "always" funciona como "any", solo muestra la casilla marcada.
-- filter = true: always applied, also with "Mostrar solo si…", so the panel
-- never locks it (D-66).
-- filter = true: siempre se aplica, también con "Mostrar solo si…", así el
-- panel nunca lo bloquea (D-66).
Settings.STATES = {
	{ kind = "choice", key = "combat", none = "any",
		options = { { "always", L.STATE_COMBAT_ALWAYS }, { "in", L.STATE_COMBAT_IN }, { "out", L.STATE_COMBAT_OUT } } },
	{ kind = "cycle", key = "mounted", label = L.STATE_MOUNTED, filter = true,
		options = { { "any", L.STATE_ANY }, { "yes", L.STATE_MOUNTED_YES }, { "no", L.STATE_MOUNTED_NO } } },
	{ kind = "cycle", key = "target", label = L.STATE_TARGET, filter = true,
		options = { { "any", L.STATE_TARGET_ANY }, { "exists", L.STATE_TARGET_EXISTS },
			{ "harm", L.STATE_TARGET_HARM }, { "help", L.STATE_TARGET_HELP } } },
	{ kind = "check", key = "group", label = L.STATE_GROUP },
	{ kind = "check", key = "hideVehicle", label = L.STATE_HIDE_VEHICLE, filter = true },
}

-- "Mostrar solo si…" (D-55, D-61): macro conditions that work in combat.
-- "Mostrar solo si…" (D-55, D-61): condiciones de macro que funcionan en combate.
Settings.SHOW_IF = {
	{ key = "nopet", label = L.SHOWIF_NOPET, condition = "[nopet]" },
	{ key = "petdead", label = L.SHOWIF_PETDEAD, condition = "[@pet,dead]" },
	{ key = "stealth", label = L.SHOWIF_STEALTH, condition = "[stealth]" },
	{ key = "flying", label = L.SHOWIF_FLYING, condition = "[flying]" },
	{ key = "swimming", label = L.SHOWIF_SWIMMING, condition = "[swimming]" },
	{ key = "focus", label = L.SHOWIF_FOCUS, condition = "[@focus,exists]" },
}

Settings.byKey = {}
for _, def in ipairs(Settings.LAYOUT) do
	Settings.byKey[def.key] = def
end

-- Clamps and rounds a value to its definition / Ajusta y redondea un valor a su definición
function Settings.Normalize(key, value)
	local def = Settings.byKey[key]
	if not def or def.kind ~= "slider" then return value end
	value = math.max(def.min, math.min(def.max, value))
	return math.floor(value / def.step + 0.5) * def.step
end
