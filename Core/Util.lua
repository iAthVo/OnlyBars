--[[
	OnlyBars · Core/Util.lua
	Shared helpers: chat output, secret values (D-12), drawing and diagnostics.
	Utilidades: mensajes, valores secretos (D-12), dibujo y diagnóstico.
	© 2026 iAthVo_Kr
]]

local _, ns = ...
local L = ns.L

local U = {}
ns.U = U

U.ACCENT = { 0.31, 0.76, 0.97 }

-- Prints to chat with the OnlyBars prefix / Escribe en el chat con el prefijo de OnlyBars
function U.Print(msg, ...)
	if select("#", ...) > 0 then
		msg = msg:format(...)
	end
	DEFAULT_CHAT_FRAME:AddMessage(L.PREFIX .. " " .. msg)
end

-- value kept between low and high / value dentro de low y high
function U.Clamp(value, low, high)
	return math.max(low, math.min(high, value))
end

-- Nearest whole number / Entero más cercano
function U.Round(value)
	return math.floor(value + 0.5)
end

-- Entries of a table with any keys / Elementos de una tabla con cualquier clave
function U.Count(t)
	local n = 0
	for _ in pairs(t) do n = n + 1 end
	return n
end

---------------------------------------------------------------------------
-- Secret values / Valores secretos (D-12)
-- In combat Midnight may hand out values an addon can show but never compare.
-- Everything that might be secret goes through here before an "if".
-- En combate Midnight puede entregar valores que se pueden mostrar pero no
-- comparar. Todo lo que pueda ser secreto pasa por aquí antes de un "if".
---------------------------------------------------------------------------
local issecretvalue = issecretvalue

-- Is this a Midnight secret value? / ¿Es un valor secreto de Midnight?
function U.IsSecret(value)
	return issecretvalue ~= nil and issecretvalue(value) or false
end

-- Does the character know the spell (or its override)? / ¿El personaje conoce el hechizo (o su reemplazo)?
function U.IsSpellKnown(spellID)
	if IsPlayerSpell and IsPlayerSpell(spellID) then return true end
	if IsSpellKnownOrOverridesKnown and IsSpellKnownOrOverridesKnown(spellID) then return true end
	return false
end

---------------------------------------------------------------------------
-- Drawing / Dibujo
---------------------------------------------------------------------------
-- A frame with four edges of the given thickness, drawn outside its parent.
-- Un marco con cuatro bordes del grosor indicado, por fuera de su padre.
function U.Border(parent, size, r, g, b, a)
	local f = CreateFrame("Frame", nil, parent)
	f:SetPoint("TOPLEFT", -size, size)
	f:SetPoint("BOTTOMRIGHT", size, -size)

	-- One edge texture / Una textura de borde
	local function Edge(from, to, isVertical)
		local t = f:CreateTexture(nil, "OVERLAY")
		t:SetColorTexture(r, g, b, a)
		t:SetPoint(from)
		t:SetPoint(to)
		if isVertical then t:SetWidth(size) else t:SetHeight(size) end
	end
	Edge("TOPLEFT", "TOPRIGHT")
	Edge("BOTTOMLEFT", "BOTTOMRIGHT")
	Edge("TOPLEFT", "BOTTOMLEFT", true)
	Edge("TOPRIGHT", "BOTTOMRIGHT", true)
	return f
end

---------------------------------------------------------------------------
-- Diagnostics (test build) / Diagnóstico (build de prueba)
-- Records whether each Midnight API answered normally, secretly or failed,
-- in and out of combat. Read with /ob prueba.
-- Anota si cada función de Midnight respondió normal, en secreto o con error,
-- dentro y fuera de combate. Se consulta con /ob prueba.
---------------------------------------------------------------------------
ns.Diag = {}

-- err: nil when the call worked, otherwise its error message (also logged).
-- err: nil si la llamada funcionó; si no, su mensaje de error (también se registra).
function U.Note(key, value, err)
	if err then
		ns.Log:Add(L.LOG_KIND_WARNING, ("%s: %s"):format(L["DIAG_" .. key:upper()], tostring(err)))
	end
	local state = err and L.DIAG_ERROR or (U.IsSecret(value) and L.DIAG_SECRET or L.DIAG_OK)
	U.NoteState(key, state)
end

-- Which spells lit up, and whether an OnlyBars button had them.
-- Qué hechizos se iluminaron y si algún botón de OnlyBars los tenía.
function U.NoteGlowSpell(spellID, matched)
	ns.Diag.glowSpells = ns.Diag.glowSpells or {}
	ns.Diag.glowSpells[spellID] = ns.Diag.glowSpells[spellID] or matched
end

-- The API answered nothing (nil) / La API no devolvió nada (nil)
function U.NoteEmpty(key)
	U.NoteState(key, L.DIAG_EMPTY)
end

-- Counts an answer, split by in or out of combat / Cuenta una respuesta, separada por dentro o fuera de combate
function U.NoteState(key, state)
	local context = InCombatLockdown() and L.DIAG_COMBAT or L.DIAG_IDLE
	local entry = ns.Diag[key] or {}
	ns.Diag[key] = entry
	local label = context .. " · " .. state
	entry[label] = (entry[label] or 0) + 1
end
