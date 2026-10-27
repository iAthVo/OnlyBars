--[[
	OnlyBars · UI/Commands.lua
	/ob and /onlybars: alone it opens the panel; the rest are shortcuts.
	/ob y /onlybars: solo abre el panel; lo demás son atajos.
	© 2026 iAthVo_Kr
]]

local _, ns = ...
local L, U = ns.L, ns.U

---------------------------------------------------------------------------
-- Confirmations / Confirmaciones
---------------------------------------------------------------------------
StaticPopupDialogs["ONLYBARS_DELETE_BAR"] = {
	text = L.CONFIRM_DELETE,
	button1 = YES,
	button2 = NO,
	OnAccept = ns.Log.Wrap(function(_, id) ns.Bars:Delete(id) end),
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

---------------------------------------------------------------------------
-- Commands / Comandos
---------------------------------------------------------------------------
local function BarArg(arg)
	local id = tonumber(arg)
	local data = id and ns.DB:Bars()[id]
	if not data then U.Print(L.BAR_NOT_FOUND, arg or "?") end
	return data
end

local commands = {}

-- /ob ayuda · help: lists the commands / lista los comandos
function commands.ayuda()
	for _, line in ipairs(L.HELP) do U.Print(line) end
end

-- /ob panel
function commands.panel() ns.Panel:Show() end
-- /ob teclas · keys: key assignment mode / modo de asignar teclas
function commands.teclas() ns.Keybinds:Toggle() end

-- /ob libre · free  —  /ob bloquear · lock
function commands.libre() ns.Modes:SetFree(true) end
function commands.bloquear() ns.Modes:SetFree(false) end
-- /ob nueva · new
function commands.nueva() ns.Bars:Create() end

-- /ob borrar · delete <n>: asks before deleting / pregunta antes de borrar
function commands.borrar(arg)
	local data = BarArg(arg)
	if data then
		StaticPopup_Show("ONLYBARS_DELETE_BAR", ns.Bars:Name(data), nil, data.id)
	end
end

-- Layout commands go through the shared settings model (Core/Settings.lua).
-- Los comandos de forma pasan por el modelo único de ajustes (Core/Settings.lua).
local function SetLayoutCommand(key, arg, value)
	local data = BarArg(arg)
	local n = tonumber(value)
	if data and n then
		ns.Bars:SetLayout(data, key, n)
		U.Print(L.BAR_UPDATED, ns.Bars:Name(data), ns.Settings.byKey[key].label, ns.DB:Layout(data)[key])
	end
end

-- /ob iconos · icons <n> <count>  —  /ob filas · rows <n> <rows>
function commands.iconos(arg, value) SetLayoutCommand("buttons", arg, value) end
function commands.filas(arg, value) SetLayoutCommand("rows", arg, value) end
-- Old names still work / Los nombres viejos siguen funcionando
commands.botones = commands.iconos
commands.fila = commands.filas

-- /ob vacios · empty <n>: toggles empty buttons / alterna los botones vacíos
function commands.vacios(arg)
	local data = BarArg(arg)
	if data then
		local show = not ns.DB:Layout(data).showEmpty
		ns.Bars:SetLayout(data, "showEmpty", show)
		U.Print(L.BAR_UPDATED, ns.Bars:Name(data), L.SET_SHOW_EMPTY, show and L.SHOWN or L.HIDDEN)
	end
end

-- /ob alcance · scope <n>: General <-> Per spec / General <-> Por spec
function commands.alcance(arg)
	local data = BarArg(arg)
	if data then ns.Bars:ToggleScope(data) end
end

-- Chat summary plus the Report window, where it can be copied.
-- Resumen en el chat y la ventana de Reporte, donde se puede copiar.
function commands.prueba()
	U.Print(L.DIAG_TITLE)
	for _, line in ipairs(ns.Log:DiagLines()) do
		U.Print("  " .. line)
	end
	ns.Report:Show()
end

-- /ob errores · errors: Report window / ventana de Reporte
function commands.errores() ns.Report:Toggle() end
commands.reporte = commands.errores

-- English names (0.11.0): both languages work on every client.
-- Nombres en inglés (0.11.0): los dos idiomas funcionan en cualquier cliente.
local ENGLISH = {
	help = "ayuda", keys = "teclas", free = "libre", lock = "bloquear", new = "nueva",
	delete = "borrar", icons = "iconos", rows = "filas", empty = "vacios", scope = "alcance",
	test = "prueba", errors = "errores", report = "errores",
}
for english, spanish in pairs(ENGLISH) do
	commands[english] = commands[spanish]
end

SLASH_ONLYBARS1 = "/ob"
SLASH_ONLYBARS2 = "/onlybars"
SlashCmdList.ONLYBARS = ns.Log.Wrap(function(msg)
	local args = {}
	for word in (msg or ""):gmatch("%S+") do
		args[#args + 1] = word:lower()
	end
	-- /ob alone opens the panel / /ob solo abre el panel
	if not args[1] then
		ns.Panel:Toggle()
		return
	end
	local command = commands[args[1]] or commands.ayuda
	command(args[2], args[3])
end)
