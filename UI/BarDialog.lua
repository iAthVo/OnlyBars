--[[
	OnlyBars · UI/BarDialog.lua
	The small settings dialog of a selected bar, styled like Blizzard's Edit
	Mode dialog. Draws the shared settings model (Core/Settings.lua, D-18).
	La ventana chica de ajustes de la barra seleccionada, con el estilo de la
	del Modo Edición de Blizzard. Dibuja el modelo único de ajustes
	(Core/Settings.lua, D-18).
	© 2026 iAthVo_Kr
]]

local _, ns = ...
local L, W = ns.L, ns.Widgets

local Dialog = {}
ns.BarDialog = Dialog

local WIDTH = 380
local PAD = 20
local LABEL_WIDTH = 110

local MOVES = {
	LEFT = { -1, 0 },
	RIGHT = { 1, 0 },
	UP = { 0, 1 },
	DOWN = { 0, -1 },
}

-- Keyboard: arrows move the selected bar / Teclado: las flechas mueven la barra seleccionada
local function OnKeyDown(d, key)
	if InCombatLockdown() then return end
	local move = MOVES[key]
	if move and Dialog.bar then
		d:SetPropagateKeyboardInput(false)
		local step = IsShiftKeyDown() and 10 or 1
		ns.Bars:Nudge(Dialog.bar, move[1] * step, move[2] * step)
	elseif key == "ESCAPE" then
		d:SetPropagateKeyboardInput(false)
		ns.EditMode:Deselect()
	else
		d:SetPropagateKeyboardInput(true)
	end
end

-- Scope button: General <-> Per spec / Botón de alcance: General <-> Por spec
local function OnScopeClick()
	local data = Dialog.bar and Dialog.bar.data
	if data then ns.Bars:ToggleScope(data) end
end

-- Builds the dialog from the shared settings model / Arma la ventana desde el modelo único de ajustes
local function Create()
	local d = CreateFrame("Frame", "OnlyBarsBarDialog", UIParent)
	d:SetWidth(WIDTH)
	d:SetFrameStrata("DIALOG")
	d:SetFrameLevel(200)
	d:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -250, 250)
	d:EnableMouse(true)
	d:SetMovable(true)
	d:SetClampedToScreen(true)
	if d.SetDontSavePosition then d:SetDontSavePosition(true) end
	d:RegisterForDrag("LeftButton")
	d:SetScript("OnDragStart", d.StartMoving)
	d:SetScript("OnDragStop", d.StopMovingOrSizing)

	-- Blizzard's translucent dialog border, or the OnlyBars flat look.
	-- El borde translúcido de los diálogos de Blizzard, o el estilo plano de OnlyBars.
	if not W.TryCreate("Frame", d, "DialogBorderTranslucentTemplate") then
		local bg = CreateFrame("Frame", nil, d, "BackdropTemplate")
		bg:SetAllPoints()
		bg:SetFrameLevel(d:GetFrameLevel())
		ns.Style.Flat(bg)
	end

	d.title = d:CreateFontString(nil, "OVERLAY", "OnlyBarsFontHighlightLarge")
	d.title:SetPoint("TOP", 0, -15)

	local close = W.TryCreate("Button", d, "UIPanelCloseButton") or ns.Style.Button(d, "×", 24)
	close:SetPoint("TOPRIGHT", -2, -2)
	close:SetScript("OnClick", ns.Log.Wrap(function() ns.EditMode:Deselect() end))

	local inner = WIDTH - PAD * 2
	local y = -46
	d.rows = {}
	for _, def in ipairs(ns.Settings.LAYOUT) do
		-- Each row saves through Dialog:Set / Cada fila guarda con Dialog:Set
		local function OnChange(value) Dialog:Set(def.key, value) end
		local row
		if def.kind == "slider" then
			row = W.SliderRow(d, def, inner, LABEL_WIDTH, OnChange)
		else
			row = W.Check(d, def.label, inner, OnChange)
		end
		if row then
			row.def = def
			row:SetPoint("TOPLEFT", PAD, y)
			y = y - W.ROW - 2
			d.rows[#d.rows + 1] = row
		end
	end

	y = y - 10
	d.scope = W.BlizzardButton(d, "", inner, OnScopeClick)
	d.scope:SetPoint("TOPLEFT", PAD, y)
	y = y - 28

	local reset = W.BlizzardButton(d, L.DIALOG_RESET_POSITION, inner, function()
		if Dialog.bar then ns.Bars:ResetPosition(Dialog.bar) end
	end)
	reset:SetPoint("TOPLEFT", PAD, y)
	y = y - 28

	-- Everything else lives in the /ob panel / Todo lo demás está en el panel /ob
	local more = W.BlizzardButton(d, L.DIALOG_MORE, inner, function()
		if Dialog.bar and Dialog.bar.data then ns.Panel:Show(Dialog.bar.data.id) end
	end)
	more:SetPoint("TOPLEFT", PAD, y)
	y = y - 34

	local hint = d:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	hint:SetPoint("TOP", 0, y)
	hint:SetText(L.DIALOG_HINT)
	y = y - 26

	d:SetHeight(-y)
	d:EnableKeyboard(true)
	d:SetScript("OnKeyDown", ns.Log.Wrap(OnKeyDown))
	d:Hide()
	return d
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------
function Dialog:Open(f)
	self.frame = self.frame or Create()
	self.bar = f
	self:Refresh()
	self.frame:Show()
end

-- Hides the dialog / Oculta la ventana
function Dialog:Close()
	self.bar = nil
	if self.frame then self.frame:Hide() end
end

-- Reloads every row from the bar's active set / Recarga cada fila desde el conjunto activo de la barra
function Dialog:Refresh()
	local f = self.bar
	if not (self.frame and f and f.data and f.layout) then return end
	self.frame.title:SetText(ns.Bars:Name(f.data))
	for _, row in ipairs(self.frame.rows) do
		row:Load(f.layout[row.def.key])
		-- Usable only while the setting it needs is on (D-65) / Usable solo con su ajuste activo (D-65)
		if row.def.needs then row:SetEnabled(f.layout[row.def.needs] and true or false) end
	end
	local scope = f.data.scope == "spec" and L.SCOPE_SPEC or L.SCOPE_GLOBAL
	self.frame.scope:SetText(L.DIALOG_SCOPE:format(scope))
end

-- Reloads it only if it is open / La recarga solo si está abierta
function Dialog:RefreshIfOpen()
	if self.frame and self.frame:IsShown() then self:Refresh() end
end

-- Saves one setting of the selected bar / Guarda un ajuste de la barra seleccionada
function Dialog:Set(key, value)
	local f = self.bar
	if not (f and f.data) or InCombatLockdown() then return end
	ns.Bars:SetLayout(f.data, key, value, "dialog")
	if ns.Settings.byKey[key].kind == "check" then self:Refresh() end
end
