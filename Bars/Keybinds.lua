--[[
	OnlyBars · Bars/Keybinds.lua
	Key assignment mode, like Blizzard's Quick Keybind Mode (D-48 to D-53).
	The bindings themselves are applied by Bars/Visibility.lua, so they follow
	the bar's visibility, also in combat (D-52).
	Modo de asignación de teclas, como el Modo de atajo rápido de Blizzard (D-48
	a D-53). Las teclas en sí las aplica Bars/Visibility.lua, así siguen la
	visibilidad de la barra, también en combate (D-52).
	© 2026 iAthVo_Kr
]]

local _, ns = ...
local L, U = ns.L, ns.U

local Keybinds = { overlays = {} }
ns.Keybinds = Keybinds

-- Modifier keys alone are never bound / Las teclas modificadoras solas nunca se asignan
local IGNORED = {
	LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true,
	LMETA = true, RMETA = true, UNKNOWN = true,
}

local MOUSE_KEYS = { MiddleButton = "BUTTON3", Button4 = "BUTTON4", Button5 = "BUTTON5" }

---------------------------------------------------------------------------
-- Key text / Texto de la tecla
---------------------------------------------------------------------------
-- Short, like Blizzard's buttons: s1 = Shift+1, c = Ctrl, a = Alt, M4, RU/RD.
-- Corto, como los botones de Blizzard: s1 = Shift+1, c = Ctrl, a = Alt, M4, RU/RD.
local SHORT = {
	{ "ALT%-", "a" }, { "CTRL%-", "c" }, { "SHIFT%-", "s" }, { "META%-", "m" },
	{ "MOUSEWHEELUP", "RU" }, { "MOUSEWHEELDOWN", "RD" }, { "BUTTON(%d+)", "M%1" },
	{ "NUMPADDECIMAL", "N." }, { "NUMPADPLUS", "N+" }, { "NUMPADMINUS", "N-" },
	{ "NUMPADMULTIPLY", "N*" }, { "NUMPADDIVIDE", "N/" }, { "NUMPAD", "N" },
	{ "PAGEUP", "PU" }, { "PAGEDOWN", "PD" }, { "SPACE", "Sp" }, { "INSERT", "Ins" },
	{ "HOME", "Hm" }, { "END", "End" }, { "BACKSPACE", "Bs" }, { "CAPSLOCK", "Cap" },
}

function Keybinds.Abbreviate(key)
	if not key then return "" end
	for _, pair in ipairs(SHORT) do
		key = key:gsub(pair[1], pair[2])
	end
	return key
end

-- Long, for messages: "Shift+1" / Largo, para mensajes: "Shift+1"
function Keybinds.Readable(key)
	return (key:gsub("ALT%-", "Alt+"):gsub("CTRL%-", "Ctrl+"):gsub("SHIFT%-", "Shift+"))
end

local function Compose(key)
	return (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "")
		.. (IsShiftKeyDown() and "SHIFT-" or "") .. key
end

---------------------------------------------------------------------------
-- Storing / Guardar
-- Keys live in the bar's active set: per spec on Per-spec bars (D-48).
-- Las teclas viven en el conjunto activo de la barra: por spec en barras por spec (D-48).
---------------------------------------------------------------------------
local function KeysOf(f)
	return ns.DB:ActiveSet(f.data).keys
end

-- The OnlyBars buttons that already have this key in the current spec; it can
-- be several when bars share it (D-59).
-- Los botones de OnlyBars que ya tienen esta tecla en la spec actual; pueden
-- ser varios cuando las barras la comparten (D-59).
function Keybinds:Owners(key, except)
	local owners = {}
	for _, f in pairs(ns.Bars.frames) do
		if f.data then
			local keys, count = KeysOf(f), f.layout.buttons
			for i = 1, count do
				local b = f.buttons[i]
				if keys[i] == key and b ~= except then owners[#owners + 1] = { bar = f, index = i } end
			end
		end
	end
	return owners
end

-- Can the key be shared: every owner on another bar that is never active at
-- the same time as this one (D-59).
-- Se puede compartir la tecla: cada dueño en otra barra que nunca está activa
-- al mismo tiempo que esta (D-59).
local function Shareable(f, owners)
	for _, owner in ipairs(owners) do
		if owner.bar == f or ns.Visibility:CanOverlap(f.data, owner.bar.data) then return false end
	end
	return true
end

local function Where(owners)
	local list = {}
	for _, owner in ipairs(owners) do
		list[#list + 1] = L.KEY_WHERE:format(ns.Bars:Name(owner.bar.data), owner.index)
	end
	return table.concat(list, ", ")
end

local function BarNames(owners)
	local list = {}
	for _, owner in ipairs(owners) do
		list[#list + 1] = ns.Bars:Name(owner.bar.data)
	end
	return table.concat(list, ", ")
end

local function Refresh(f)
	ns.Combat:Run("visibility", function() ns.Visibility:Apply(f) end, true)
	for _, b in ipairs(f.buttons) do b:UpdateHotkey() end
end

function Keybinds:Set(b, key)
	KeysOf(b.bar)[b.index] = key
	Refresh(b.bar)
	U.Print(L.KEY_SET, self.Readable(key), ns.Bars:Name(b.bar.data), b.index)
	-- Blizzard keeps its own binding; OnlyBars only takes it while the bar is active (D-49).
	-- Blizzard conserva su atajo; OnlyBars solo lo toma mientras la barra está activa (D-49).
	local action = GetBindingAction(key)
	if action and action ~= "" then
		U.Print(L.KEY_BLIZZARD, self.Readable(key), GetBindingName(action) or action)
	end
end

function Keybinds:Clear(b)
	local keys = KeysOf(b.bar)
	if not keys[b.index] then return end
	keys[b.index] = nil
	Refresh(b.bar)
	U.Print(L.KEY_CLEARED, ns.Bars:Name(b.bar.data), b.index)
end

-- Another OnlyBars button has it: ask, saying where (D-50). If the bars are
-- never active at the same time, it can also be shared (D-59).
-- Otro botón de OnlyBars la tiene: preguntar, diciendo dónde (D-50). Si las
-- barras nunca están activas al mismo tiempo, también se puede compartir (D-59).
function Keybinds:Assign(b, key)
	if InCombatLockdown() then
		U.Print(L.COMBAT_BLOCKED)
		return
	end
	local owners = self:Owners(key, b)
	if #owners == 0 then
		self:Set(b, key)
		return
	end
	local move = { key = key, button = b, owners = owners }
	if Shareable(b.bar, owners) then
		StaticPopup_Show("ONLYBARS_KEY_SHARE", self.Readable(key), Where(owners), move)
	else
		for _, owner in ipairs(owners) do
			if owner.bar ~= b.bar then
				U.Print(L.KEY_NO_SHARE, self.Readable(key))
				break
			end
		end
		StaticPopup_Show("ONLYBARS_KEY_MOVE", self.Readable(key), Where(owners), move)
	end
end

local function Move(_, move)
	for _, owner in ipairs(move.owners) do
		KeysOf(owner.bar)[owner.index] = nil
		Refresh(owner.bar)
	end
	Keybinds:Set(move.button, move.key)
end

local function Share(_, move)
	Keybinds:Set(move.button, move.key)
	U.Print(L.KEY_SHARED, Keybinds.Readable(move.key), BarNames(move.owners))
end

StaticPopupDialogs["ONLYBARS_KEY_MOVE"] = {
	text = L.KEY_CONFIRM_MOVE,
	button1 = YES,
	button2 = NO,
	OnAccept = ns.Log.Wrap(Move),
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["ONLYBARS_KEY_SHARE"] = {
	text = L.KEY_CONFIRM_SHARE,
	button1 = L.KEY_SHARE,
	button2 = CANCEL,
	button3 = L.KEY_MOVE,
	OnAccept = ns.Log.Wrap(Share),
	OnAlt = ns.Log.Wrap(Move),
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

-- After a situation changes, warn about shared keys whose bars can now be
-- active at the same time (D-59): then whichever bar applied last gets the key.
-- Después de cambiar una situación, avisar de teclas compartidas cuyas barras
-- ahora pueden estar activas al mismo tiempo (D-59): ahí la tecla queda en la
-- barra que se aplicó al último.
function Keybinds:CheckShared(data)
	local f = ns.Bars.frames[data.id]
	if not f or not f.data then return end
	local keys = KeysOf(f)
	for i = 1, f.layout.buttons do
		local key = keys[i]
		if key then
			for _, owner in ipairs(self:Owners(key, f.buttons[i])) do
				if owner.bar ~= f and ns.Visibility:CanOverlap(data, owner.bar.data) then
					U.Print(L.KEY_SHARE_BROKEN, self.Readable(key), ns.Bars:Name(data), ns.Bars:Name(owner.bar.data))
				end
			end
		end
	end
end

---------------------------------------------------------------------------
-- Assignment mode / Modo de asignación
---------------------------------------------------------------------------
local function Overlay(b)
	local overlay = Keybinds.overlays[b]
	if overlay then return overlay end
	overlay = CreateFrame("Button", nil, b)
	overlay:SetAllPoints()
	-- Above everything, also the Edit Mode selection (0.5.6) / Encima de todo, también la selección del Modo Edición (0.5.6)
	overlay:SetFrameStrata("DIALOG")
	overlay:SetFrameLevel(b:GetFrameLevel() + 40)
	overlay:EnableMouseWheel(true)
	local fill = overlay:CreateTexture(nil, "OVERLAY")
	fill:SetAllPoints()
	fill:SetColorTexture(0.2, 0.6, 1, 0.25)
	overlay.fill = fill
	overlay:SetScript("OnEnter", function(self)
		Keybinds.hovered = b
		self.fill:SetColorTexture(0.2, 0.8, 1, 0.5)
	end)
	overlay:SetScript("OnLeave", function(self)
		if Keybinds.hovered == b then Keybinds.hovered = nil end
		self.fill:SetColorTexture(0.2, 0.6, 1, 0.25)
	end)
	overlay:SetScript("OnMouseDown", ns.Log.Wrap(function(_, button)
		if button == "RightButton" then
			Keybinds:Clear(b)
		elseif MOUSE_KEYS[button] then
			Keybinds:Assign(b, Compose(MOUSE_KEYS[button]))
		end
	end))
	overlay:SetScript("OnMouseWheel", ns.Log.Wrap(function(_, delta)
		Keybinds:Assign(b, Compose(delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN"))
	end))
	Keybinds.overlays[b] = overlay
	return overlay
end

-- Takes the keyboard while the mouse is over an OnlyBars button.
-- Toma el teclado mientras el mouse está sobre un botón de OnlyBars.
local function OnKeyDown(self, key)
	if key == "ESCAPE" then
		-- Coming from Blizzard's mode, Esc also closes it / Si viene del modo de Blizzard, Esc también lo cierra
		self:SetPropagateKeyboardInput(Keybinds.fromBlizzard and true or false)
		Keybinds:Stop()
		return
	end
	local b = Keybinds.hovered
	if not b then
		self:SetPropagateKeyboardInput(true)
		return
	end
	self:SetPropagateKeyboardInput(false)
	if IGNORED[key] then return end
	if key == "DELETE" then
		Keybinds:Clear(b)
	else
		Keybinds:Assign(b, Compose(key))
	end
end

-- Inside the /ob panel when it is open (UI/Panel.lua), otherwise at the top of the screen (0.5.9).
-- Dentro del panel /ob si está abierto (UI/Panel.lua), si no arriba de la pantalla (0.5.9).
function Keybinds:PlaceBanner()
	local banner = self.banner
	if not banner then return end
	banner:ClearAllPoints()
	if not ns.Panel:PlaceKeyBanner(banner) then
		banner:SetParent(UIParent)
		banner:SetFrameStrata("TOOLTIP")
		banner:SetSize(560, 64)
		banner:SetPoint("TOP", 0, -120)
	end
	banner.text:SetWidth(banner:GetWidth() - 20)
end

local function CreateBanner()
	local banner = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	ns.Style.Flat(banner)
	local text = banner:CreateFontString(nil, "OVERLAY", "OnlyBarsFontHighlight")   -- UI/Style.lua (0.10.1)
	text:SetPoint("TOP", 0, -10)
	text:SetText(L.KEY_MODE_HINT)
	banner.text = text
	local done = ns.Widgets.FlatButton(banner, L.KEY_MODE_DONE, 120, function() Keybinds:Stop() end)
	done:SetPoint("BOTTOM", 0, 8)

	local catcher = CreateFrame("Frame", nil, UIParent)
	catcher:SetAllPoints()
	catcher:SetFrameStrata("TOOLTIP")
	catcher:EnableMouse(false)
	catcher:EnableKeyboard(true)
	catcher:SetScript("OnKeyDown", ns.Log.Wrap(OnKeyDown))
	catcher:Hide()
	banner.catcher = catcher
	banner:Hide()
	return banner
end

function Keybinds:IsActive()
	return self.active == true
end

-- Shows every bar of this spec (also hidden and empty buttons) without free
-- mode: its selection boxes covered the buttons and took the mouse (0.5.6).
-- Muestra todas las barras de esta spec (también ocultas y botones vacíos) sin
-- modo libre: sus recuadros de selección tapaban los botones y se quedaban con el mouse (0.5.6).
local function ShowAll()
	ns.Visibility:ApplyAll()
	for _, b in pairs(ns.Buttons.pool) do
		if b:IsShown() then b:UpdateEmpty() end
	end
end

function Keybinds:Start(fromBlizzard)
	if self.active then return end
	if InCombatLockdown() then
		U.Print(L.COMBAT_BLOCKED)
		return
	end
	self.active, self.fromBlizzard = true, fromBlizzard
	ShowAll()
	self.banner = self.banner or CreateBanner()
	self:PlaceBanner()
	self.banner:Show()
	self.banner.catcher:Show()
	for _, f in pairs(ns.Bars.frames) do
		if f.data then
			for i = 1, f.layout.buttons do
				local b = f.buttons[i]
				if b then Overlay(b):Show() end
			end
		end
	end
	U.Print(L.KEY_MODE_ON)
end

function Keybinds:Stop()
	if not self.active then return end
	self.active, self.hovered = false, nil
	for _, overlay in pairs(self.overlays) do overlay:Hide() end
	if self.banner then
		self.banner:Hide()
		self.banner.catcher:Hide()
	end
	if not InCombatLockdown() then ShowAll() end
	self.fromBlizzard = nil
	U.Print(L.KEY_MODE_OFF)
end

function Keybinds:Toggle()
	if self.active then self:Stop() else self:Start() end
end

-- Combat ends the mode / El combate termina el modo
ns:On("PLAYER_REGEN_DISABLED", function() Keybinds:Stop() end)

---------------------------------------------------------------------------
-- Blizzard's Quick Keybind Mode opens ours too (D-51), listening only.
-- El Modo de atajo rápido de Blizzard abre también el nuestro (D-51), solo escuchando.
---------------------------------------------------------------------------
function Keybinds:HookBlizzard()
	if self.hooked or not QuickKeybindFrame then return end
	self.hooked = true
	QuickKeybindFrame:HookScript("OnShow", ns.Log.Wrap(function() Keybinds:Start(true) end))
	QuickKeybindFrame:HookScript("OnHide", ns.Log.Wrap(function() Keybinds:Stop() end))
end

ns:On("PLAYER_LOGIN", function() Keybinds:HookBlizzard() end)
ns:On("ADDON_LOADED", function() Keybinds:HookBlizzard() end)
