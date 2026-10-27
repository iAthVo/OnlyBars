--[[
	OnlyBars · Modules/EditMode.lua
	Blizzard-style selection for OnlyBars bars, used both in Blizzard's Edit Mode
	and in /ob libre (D-18). Listens to Blizzard, never changes its state (D-11).
	Selección al estilo de Blizzard para las barras de OnlyBars, en el Modo
	Edición de Blizzard y en /ob libre (D-18). Escucha a Blizzard, nunca cambia
	su estado (D-11).
	© 2026 iAthVo_Kr
]]

local _, ns = ...
local L, U = ns.L, ns.U

local EditMode = { frames = {} }
ns.EditMode = EditMode

---------------------------------------------------------------------------
-- Selection overlay / Capa de selección
---------------------------------------------------------------------------
-- Used only if the client lacks Blizzard's template.
-- Solo se usa si el cliente no tiene la plantilla de Blizzard.
local function CreateFallbackSelection(f)
	local r, g, b = unpack(U.ACCENT)
	local sel = CreateFrame("Frame", nil, f)
	local fill = sel:CreateTexture(nil, "BACKGROUND")
	fill:SetAllPoints()
	fill:SetColorTexture(r, g, b, 0.2)
	U.Border(sel, 1, r, g, b, 0.9)
	local label = sel:CreateFontString(nil, "OVERLAY", "OnlyBarsFontHighlight")   -- UI/Style.lua (0.10.1)
	label:SetPoint("CENTER")

	function sel:ShowHighlighted()
		self.isSelected = false
		fill:SetAlpha(0.5)
		label:SetText(self.system:GetSystemName())
		self:Show()
	end
	function sel:ShowSelected()
		self.isSelected = true
		fill:SetAlpha(1)
		label:SetText(self.system:GetSystemName())
		self:Show()
	end
	return sel
end

local function OnMouseDown(sel)
	if InCombatLockdown() then return end
	EditMode:Select(sel.parent)
end

-- The drag is OnlyBars' own, so magnetism pulls live (D-34; Modules/Grid.lua).
-- El arrastre es propio de OnlyBars, así el magnetismo jala en vivo (D-34; Modules/Grid.lua).
local function OnDragStart(sel)
	if InCombatLockdown() then return end
	EditMode:Select(sel.parent)
	ns.Grid:BeginDrag(sel.parent)
end

local function OnDragStop()
	ns.Grid:EndDrag()
end

function EditMode:Attach(f)
	local ok, sel = pcall(CreateFrame, "Frame", nil, f, "EditModeSystemSelectionTemplate")
	if not ok or not sel.ShowHighlighted then
		self.fallback = true
		sel = CreateFallbackSelection(f)
	end
	sel:SetAllPoints()
	sel:SetFrameLevel(f:GetFrameLevel() + 20)
	sel.parent = f
	-- Since 11.2 the template asks its system for a name.
	-- Desde 11.2 la plantilla le pide un nombre a su sistema.
	sel.system = {
		GetSystemName = function() return f.data and ns.Bars:Name(f.data) or "" end,
	}
	sel:EnableMouse(true)
	sel:RegisterForDrag("LeftButton")
	sel:SetScript("OnMouseDown", ns.Log.Wrap(OnMouseDown))
	sel:SetScript("OnDragStart", ns.Log.Wrap(OnDragStart))
	sel:SetScript("OnDragStop", ns.Log.Wrap(OnDragStop))
	sel:Hide()
	f.selection = sel
	self.frames[f] = true
end

---------------------------------------------------------------------------
-- Selecting / Seleccionar
---------------------------------------------------------------------------
function EditMode:Select(f)
	self:ClearBlizzardSelection()
	self.selected = f
	for frame in pairs(self.frames) do
		local sel = frame.selection
		if sel:IsShown() then
			if frame == f then sel:ShowSelected(true) else sel:ShowHighlighted() end
		end
	end
	ns.BarDialog:Open(f)
end

function EditMode:Deselect()
	self.selected = nil
	for frame in pairs(self.frames) do
		if frame.selection:IsShown() then frame.selection:ShowHighlighted() end
	end
	ns.BarDialog:Close()
end

-- A deleted bar stops being selectable / Una barra borrada deja de poder seleccionarse
function EditMode:Forget(f)
	if self.selected == f then self:Deselect() end
	f.selection:Hide()
end

-- Shows or hides the selection on every active bar (called by Modes:Apply).
-- Muestra u oculta la selección en cada barra activa (lo llama Modes:Apply).
function EditMode:Show(active)
	for frame in pairs(self.frames) do
		local sel = frame.selection
		if active and frame.data then
			if frame == self.selected then sel:ShowSelected(true) else sel:ShowHighlighted() end
		else
			sel:Hide()
		end
	end
	if not active and self.selected then
		self:Deselect()
	end
end

---------------------------------------------------------------------------
-- Blizzard / Blizzard
-- Only one thing selected at a time, like between Blizzard's own systems:
-- • Blizzard selects → OnlyBars deselects (listening only).
-- • OnlyBars selects → Blizzard's selection is cleared. This is the one call
--   that may taint (D-24); a block would show up in /ob errores.
-- Solo una cosa seleccionada a la vez, como entre los sistemas de Blizzard:
-- • Blizzard selecciona → OnlyBars quita la suya (solo escuchando).
-- • OnlyBars selecciona → se quita la de Blizzard. Es la única llamada que
--   puede causar taint (D-24); un bloqueo aparecería en /ob errores.
---------------------------------------------------------------------------
local OnBlizzardSelection = ns.Log.Wrap(function()
	if EditMode.selected and not EditMode.clearing then EditMode:Deselect() end
end)

-- Blizzard's Edit Mode may load after OnlyBars, so the hooks go in when it is
-- first seen (login or entering Edit Mode), once.
-- El Modo Edición de Blizzard puede cargarse después de OnlyBars, así que los
-- hooks se ponen cuando aparece (al entrar o al abrir el Modo Edición), una vez.
function EditMode:HookBlizzard()
	if self.hooked or not EditModeManagerFrame then return end
	self.hooked = true
	if EditModeManagerFrame.SelectSystem then
		hooksecurefunc(EditModeManagerFrame, "SelectSystem", OnBlizzardSelection)
	end
	-- Blizzard's settings dialog opens or switches to another system.
	-- La ventana de ajustes de Blizzard se abre o cambia a otro sistema.
	local blizzardDialog = EditModeSystemSettingsDialog
	if blizzardDialog then
		blizzardDialog:HookScript("OnShow", OnBlizzardSelection)
		if blizzardDialog.AttachToSystem then
			hooksecurefunc(blizzardDialog, "AttachToSystem", OnBlizzardSelection)
		end
	end
end

function EditMode:ClearBlizzardSelection()
	if EditModeManagerFrame and EditModeManagerFrame.ClearSelectedSystem and EditModeManagerFrame:IsShown() then
		self.clearing = true
		pcall(EditModeManagerFrame.ClearSelectedSystem, EditModeManagerFrame)
		self.clearing = nil
	end
end

ns:On("PLAYER_LOGIN", function() EditMode:HookBlizzard() end)
EventRegistry:RegisterCallback("EditMode.Enter", ns.Log.Wrap(function() EditMode:HookBlizzard() end), EditMode)
