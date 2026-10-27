--[[
	OnlyBars · Core/Init.lua
	Namespace, constants, event dispatcher and start-up.
	Espacio de nombres, constantes, despachador de eventos y arranque.
	© 2026 iAthVo_Kr
]]

local ADDON, ns = ...

ns.VERSION = C_AddOns.GetAddOnMetadata(ADDON, "Version") or "?"

ns.FIRST_BAR = 9    -- Blizzard uses bars 1-8 / Blizzard usa las barras 1 a 8 (D-02)
ns.MAX_BARS = 20
ns.MAX_BUTTONS = 12

---------------------------------------------------------------------------
-- Events / Eventos
-- Several modules can listen to the same event. An event this client does
-- not know is recorded instead of raising an error.
-- Varios módulos pueden escuchar el mismo evento. Si el cliente no conoce un
-- evento, se anota en vez de dar error.
---------------------------------------------------------------------------
local frame = CreateFrame("Frame")
local handlers = {}
ns.missingEvents = {}

function ns:On(event, fn)
	if not handlers[event] then
		if not pcall(frame.RegisterEvent, frame, event) then
			ns.missingEvents[event] = true
			return false
		end
		handlers[event] = {}
	end
	table.insert(handlers[event], fn)
	return true
end

-- Each handler runs protected: an error goes to the OnlyBars log (Core/Log.lua).
-- Cada manejador corre protegido: un error va al registro de OnlyBars (Core/Log.lua).
frame:SetScript("OnEvent", function(_, event, ...)
	for _, fn in ipairs(handlers[event]) do
		ns.Log.Call(fn, event, ...)
	end
end)

---------------------------------------------------------------------------
-- Start-up / Arranque
---------------------------------------------------------------------------
ns:On("ADDON_LOADED", function(_, name)
	if name == ADDON then
		ns.DB:Init()
		ns.Log:Init()
	end
end)

ns:On("PLAYER_LOGIN", function()
	ns.DB:InitCharacter()
	-- A /reload in combat waits for the end of combat to build the bars.
	-- Un /reload en combate espera a que termine para construir las barras.
	ns.Combat:Run("login", function() ns.Bars:BuildAll() end)
	ns.Buttons:StartRangeTimer()
	ns.Visibility:StartFadeTimer()
	ns.U.Print(ns.L.LOADED, ns.VERSION)
end)
