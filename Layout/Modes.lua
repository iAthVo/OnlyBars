--[[
	OnlyBars · Layout/Modes.lua
	Free and locked modes, combat lock and Blizzard's Edit Mode (D-10, D-11, D-18).
	Free mode shows the Blizzard-style selection (Layout/EditMode.lua).
	Modo libre y bloqueado, bloqueo en combate y Modo Edición de Blizzard (D-10,
	D-11, D-18). El modo libre muestra la selección al estilo de Blizzard
	(Layout/EditMode.lua).
	© 2026 iAthVo_Kr
]]

local _, ns = ...
local L, U = ns.L, ns.U

local Modes = {}
ns.Modes = Modes

-- Are the bars in free mode? / ¿Las barras están en modo libre?
function Modes:IsFree()
	return ns.DB.db ~= nil and not ns.DB.db.settings.locked
end

-- Free or locked mode; free mode closes key assignment (D-58) / Modo libre o bloqueado; el libre cierra la asignación de teclas (D-58)
function Modes:SetFree(free, silent)
	if free and InCombatLockdown() then
		U.Print(L.COMBAT_BLOCKED)
		return
	end
	-- Free mode ends key assignment: one mode at a time (D-58).
	-- El modo libre termina la asignación de teclas: un modo a la vez (D-58).
	if free and ns.Keybinds:IsActive() then ns.Keybinds:Stop() end
	ns.DB.db.settings.locked = not free
	self:Apply()
	ns.Panel:RefreshFooter()
	if not silent then
		U.Print(free and L.MODE_FREE or L.MODE_LOCKED)
	end
end

-- Selection, grid and bars as the current mode says / Selección, rejilla y barras según el modo actual
function Modes:Apply()
	ns.EditMode:Show(self:IsFree())
	ns.Grid:Show(self:IsFree())
	-- Free mode shows every bar, whatever its situations (D-26).
	-- El modo libre muestra todas las barras, sin importar sus situaciones (D-26).
	if not InCombatLockdown() then ns.Visibility:ApplyAll() end
	for _, b in pairs(ns.Buttons.pool) do
		if b:IsShown() then b:UpdateEmpty() end
	end
end

-- Entering combat locks the bars / Entrar en combate bloquea las barras
ns:On("PLAYER_REGEN_DISABLED", function()
	if Modes:IsFree() then
		Modes.fromEditMode = nil
		Modes:SetFree(false)
	end
end)

-- Blizzard's Edit Mode: listening only, to avoid taint (D-11).
-- Modo Edición de Blizzard: solo escuchar, para evitar taint (D-11).
EventRegistry:RegisterCallback("EditMode.Enter", ns.Log.Wrap(function()
	if not Modes:IsFree() and not InCombatLockdown() then
		Modes.fromEditMode = true
		Modes:SetFree(true, true)
	end
end), Modes)

EventRegistry:RegisterCallback("EditMode.Exit", ns.Log.Wrap(function()
	if Modes.fromEditMode then
		Modes.fromEditMode = nil
		Modes:SetFree(false, true)
	end
end), Modes)
