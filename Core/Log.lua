--[[
	OnlyBars · Core/Log.lua
	OnlyBars' own error log: Lua errors in its code, blocked actions and API
	warnings. Kept across reloads; shown in the Report window (/ob errores).
	Registro de errores propio: errores de Lua en su código, acciones bloqueadas
	y avisos de la API. Sobrevive a /reload; se ve en la ventana de Reporte.
	© 2026 iAthVo_Kr
]]

local ADDON, ns = ...
local L, U = ns.L, ns.U

local Log = { entries = {} }
ns.Log = Log

local MAX_ENTRIES = 50
local STACK_LINES = 8

-- Saved entries replace the in-memory list; anything logged before loading is kept.
-- Las entradas guardadas reemplazan la lista en memoria; lo registrado antes se conserva.
function Log:Init()
	local saved = OnlyBarsDB.log or {}
	for i = #self.entries, 1, -1 do
		table.insert(saved, 1, self.entries[i])
	end
	OnlyBarsDB.log = saved
	self.entries = saved
	self:Trim()
end

-- Keeps only the newest entries / Conserva solo las entradas más nuevas
function Log:Trim()
	for i = #self.entries, MAX_ENTRIES + 1, -1 do
		self.entries[i] = nil
	end
end

-- Logs an entry; a repeated one only counts up / Registra una entrada; una repetida solo suma
function Log:Add(kind, text, stack)
	local now = date("%Y-%m-%d %H:%M:%S")
	for _, entry in ipairs(self.entries) do
		if entry.text == text then
			entry.count = entry.count + 1
			entry.time = now
			self:Changed()
			return
		end
	end
	table.insert(self.entries, 1, {
		kind = kind,
		text = text,
		stack = stack,
		count = 1,
		time = now,
		version = ns.VERSION,
	})
	self:Trim()
	if not self.notified then
		self.notified = true
		U.Print(L.LOG_NEW)
	end
	self:Changed()
end

-- Empties the log (Report window button) / Vacía el registro (botón de la ventana de Reporte)
function Log:Clear()
	wipe(self.entries)
	self.notified = nil
	self:Changed()
end

-- Refreshes the Report window if it is open / Actualiza la ventana de Reporte si está abierta
function Log:Changed()
	if ns.Report then ns.Report:RefreshIfShown() end
end

---------------------------------------------------------------------------
-- Catching errors / Atrapar errores
-- OnlyBars' handlers run through Log.Call: the error is logged and then
-- passed on to the normal error handler, so other tools still see it.
-- Los manejadores de OnlyBars corren con Log.Call: el error se registra y
-- después sigue al manejador normal, así las demás herramientas lo ven.
---------------------------------------------------------------------------
local function ShortStack()
	local lines = {}
	for line in (debugstack(3) or ""):gmatch("[^\n]+") do
		lines[#lines + 1] = line
		if #lines >= STACK_LINES then break end
	end
	return table.concat(lines, "\n")
end

-- Logs the error, then passes it to the game's handler / Registra el error y luego lo pasa al manejador del juego
local function OnError(err)
	Log:Add(L.LOG_KIND_LUA, tostring(err), ShortStack())
	return geterrorhandler()(err)
end

-- Runs fn catching its errors / Corre fn atrapando sus errores
function Log.Call(fn, ...)
	return xpcall(fn, OnError, ...)
end

-- fn wrapped with Log.Call, for scripts and events / fn envuelta con Log.Call, para scripts y eventos
function Log.Wrap(fn)
	return function(...)
		Log.Call(fn, ...)
	end
end

-- Actions the game blocked for OnlyBars (taint) / Acciones que el juego le bloqueó (taint)
local function OnBlocked(_, addon, action)
	if addon == ADDON then
		Log:Add(L.LOG_KIND_BLOCKED, tostring(action))
	end
end
ns:On("ADDON_ACTION_BLOCKED", OnBlocked)
ns:On("ADDON_ACTION_FORBIDDEN", OnBlocked)

---------------------------------------------------------------------------
-- Report text / Texto del reporte
---------------------------------------------------------------------------
local DIAG_KEYS = { "cooldown", "charges", "itemcd", "usable", "range", "glow" }

-- Diagnostic lines for /ob prueba and the report / Líneas de diagnóstico para /ob prueba y el reporte
function Log:DiagLines()
	local lines = {}
	for _, key in ipairs(DIAG_KEYS) do
		local parts = {}
		for label, n in pairs(ns.Diag[key] or {}) do
			parts[#parts + 1] = ("%s ×%d"):format(label, n)
		end
		table.sort(parts)
		lines[#lines + 1] = ("%s: %s"):format(L["DIAG_" .. key:upper()], #parts > 0 and table.concat(parts, ", ") or L.DIAG_NONE)
	end
	for spellID, matched in pairs(ns.Diag.glowSpells or {}) do
		lines[#lines + 1] = L.DIAG_GLOW_SPELL:format(C_Spell.GetSpellName(spellID) or "?", spellID,
			matched and L.DIAG_GLOW_ON_BAR or L.DIAG_GLOW_NOT_ON_BAR)
	end
	for event in pairs(ns.missingEvents) do
		lines[#lines + 1] = L.DIAG_EVENT_MISSING:format(event)
	end
	-- Blizzard art and Edit Mode template (D-19, D-18) / Arte de Blizzard y plantilla del Modo Edición (D-19, D-18)
	local missing = ns.Buttons.missingArt
	if missing then
		lines[#lines + 1] = #missing == 0 and L.DIAG_ART_OK or L.DIAG_ART_MISSING:format(table.concat(missing, ", "))
	end
	lines[#lines + 1] = ns.EditMode.fallback and L.DIAG_SELECTION_FALLBACK or L.DIAG_SELECTION_OK
	-- Native gap measured on Blizzard's bars (D-36) / Espacio nativo medido en las barras de Blizzard (D-36)
	-- Icon mask size, to compare with Blizzard's 45 px button (0.3.12).
	-- Medida de la máscara del ícono, para comparar con el botón de 45 px de Blizzard (0.3.12).
	local maskInfo = C_Texture.GetAtlasInfo("UI-HUD-ActionBar-IconFrame-Mask")
	if maskInfo then
		lines[#lines + 1] = L.DIAG_MASK:format(maskInfo.width or 0, maskInfo.height or 0)
	end
	lines[#lines + 1] = L.DIAG_JOIN_GAP
	return lines
end

-- "Name (id)" of a spell, safe with secret values / "Nombre (id)" de un hechizo, seguro con valores secretos
local function SpellLabel(spellID)
	if U.IsSecret(spellID) then return L.DIAG_SECRET end
	if not spellID then return L.REPORT_NO_SPELL end
	return ("%s (%d)"):format(C_Spell.GetSpellName(spellID) or "?", spellID)
end

-- An item's details for the report / El detalle de un objeto para el reporte
local function ItemLabel(itemID)
	if not itemID then return "?" end
	return L.REPORT_ITEM_DETAIL:format(C_Item.GetItemNameByID(itemID) or itemID, itemID,
		C_Item.GetItemCount(itemID, false, true) or 0, ns.Buttons.QualityAtlas(itemID) or L.REPORT_NO_QUALITY)
end

-- What each bar holds right now, by kind / Qué tiene cada barra ahora, por tipo
function Log:ContentLines()
	local lines = {}
	local bars = ns.DB.char and ns.DB:Bars()
	if not bars then return lines end
	local ids = {}
	for id in pairs(bars) do ids[#ids + 1] = id end
	table.sort(ids)
	for _, id in ipairs(ids) do
		local data = bars[id]
		local counts, parts, macros = {}, {}, {}
		local set = ns.DB:ActiveSet(data)
		local slots = set.slots
		for i = 1, set.layout.buttons do
			local slot = slots[i]
			if slot then
				counts[slot.kind] = (counts[slot.kind] or 0) + 1
				if slot.kind == "macro" then
					-- What OnlyBars reads live (D-46) / Lo que OnlyBars lee en vivo (D-46)
					local kind, live = ns.Buttons.MacroTarget(slot.name)
					local target = kind == "item" and ItemLabel(C_Item.GetItemInfoInstant(live))
						or SpellLabel(kind == "spell" and live or nil)
					macros[#macros + 1] = L.REPORT_MACRO:format(slot.name, target)
					-- Live macros (D-46): what the client reports / Macros en vivo (D-46): lo que reporta el cliente
					local dynamic, icon = ns.Buttons.IsDynamicMacro(slot.name)
					macros[#macros + 1] = L.REPORT_MACRO_LIVE:format(tostring(icon),
						dynamic and L.REPORT_YES or L.REPORT_NO, IsShiftKeyDown() and L.REPORT_YES or L.REPORT_NO)
				elseif slot.kind == "item" then
					macros[#macros + 1] = L.REPORT_ITEM:format(ItemLabel(slot.id))
				end
			end
		end
		for kind, n in pairs(counts) do
			parts[#parts + 1] = ("%s ×%d"):format(L["KIND_" .. kind:upper()], n)
		end
		table.sort(parts)
		lines[#lines + 1] = ("%s (%s, %d botones): %s"):format(ns.Bars:Name(data),
			data.scope == "spec" and L.SCOPE_SPEC or L.SCOPE_GLOBAL, set.layout.buttons,
			#parts > 0 and table.concat(parts, ", ") or L.REPORT_EMPTY_BAR)
		-- Anchor (D-47) / Anclaje (D-47)
		local anchor = set.layout.anchor
		if anchor then
			local id = tonumber(anchor.to:match("^ob:(%d+)$") or "")
			local target = id and ns.DB:Bars()[id] and ns.Bars:Name(ns.DB:Bars()[id]) or anchor.to:gsub("^%a+:", "")
			lines[#lines + 1] = L.REPORT_ANCHOR:format(target, L["SIDE_" .. anchor.side:upper()])
		end
		-- Which specs have saved content; "-" = unchecked (D-60).
		-- Qué specs tienen contenido guardado; "-" = desmarcada (D-60).
		if data.scope == "spec" then
			local specs = {}
			for key in pairs(data.sets) do
				specs[#specs + 1] = (data.off[key] and "-" or "") .. tostring(key)
			end
			table.sort(specs)
			lines[#lines + 1] = L.REPORT_SPECS:format(tostring(ns.DB:SpecID()), table.concat(specs, ", "))
		end
		for _, line in ipairs(macros) do
			lines[#lines + 1] = line
		end
	end
	return lines
end

-- The whole report as copyable text / Todo el reporte como texto copiable
function Log:ReportText()
	local version, build = GetBuildInfo()
	local out = {
		("OnlyBars %s · WoW %s (%s) · %s"):format(ns.VERSION, version, build, date("%Y-%m-%d %H:%M")),
		"",
		"== " .. L.REPORT_CONTENT .. " ==",
	}
	for _, line in ipairs(self:ContentLines()) do
		out[#out + 1] = line
	end
	out[#out + 1] = ""
	out[#out + 1] = "== " .. L.REPORT_DIAG .. " =="
	for _, line in ipairs(self:DiagLines()) do
		out[#out + 1] = line
	end
	out[#out + 1] = ""
	out[#out + 1] = ("== %s (%d) =="):format(L.REPORT_ERRORS, #self.entries)
	if #self.entries == 0 then
		out[#out + 1] = L.REPORT_NO_ERRORS
	end
	for _, entry in ipairs(self.entries) do
		out[#out + 1] = ""
		out[#out + 1] = ("[%s] %s ×%d · v%s"):format(entry.time, entry.kind, entry.count, entry.version or "?")
		out[#out + 1] = entry.text
		if entry.stack and entry.stack ~= "" then
			out[#out + 1] = entry.stack
		end
	end
	return table.concat(out, "\n")
end
