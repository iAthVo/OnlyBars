--[[
	OnlyBars · Bars/Bars.lua
	Bar frames: layout, position, create and delete. Shape and position come
	from the bar's active set, so Per-spec bars can differ per spec (D-20).
	Marcos de las barras: acomodo, posición, crear y borrar. La forma y la
	posición salen del conjunto activo, así las barras Por spec pueden ser
	distintas en cada spec (D-20).
	© 2026 iAthVo_Kr
]]

local _, ns = ...
local L, U = ns.L, ns.U

local Bars = { frames = {} }
ns.Bars = Bars

-- The name follows the scope like everything else (D-30): a Per-spec bar has
-- one name per spec. setKey as in SetLayout; nil means the active set.
-- El nombre sigue al alcance como todo lo demás (D-30): una barra por spec
-- tiene un nombre por spec. setKey como en SetLayout; nil es el conjunto activo.
function Bars:Name(data, setKey)
	return ns.DB:SetFor(data, setKey).name or L.BAR_NAME:format(data.id)
end

---------------------------------------------------------------------------
-- Position / Posición
-- Stored as an offset from the screen centre in UIParent units, so changing
-- the bar's scale does not move it.
-- Se guarda como distancia al centro de la pantalla en unidades de UIParent,
-- así cambiar la escala de la barra no la mueve.
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- Anchors (D-47) / Anclajes (D-47)
-- A bar joined to another one (OnlyBars or Blizzard) is anchored to it and
-- follows it when it moves or changes size. Only OnlyBars bars are ever
-- anchored: a Blizzard bar is never moved, so there is no taint.
-- layout.anchor = { to = "ob:<id>" | "bz:<frame name>", side, dx, dy }
-- side: where this bar is ("above", "below", "left", "right"); dx, dy in
-- UIParent units between this bar's point and the target's point.
-- Una barra unida a otra (OnlyBars o Blizzard) queda anclada y la sigue cuando
-- se mueve o cambia de tamaño. Solo se anclan barras de OnlyBars: una barra de
-- Blizzard nunca se mueve, así que no hay taint.
---------------------------------------------------------------------------
local ANCHOR_POINTS = {
	above = { "BOTTOMLEFT", "TOPLEFT" },
	below = { "TOPLEFT", "BOTTOMLEFT" },
	right = { "TOPLEFT", "TOPRIGHT" },
	left = { "TOPRIGHT", "TOPLEFT" },
}

local function PointOf(rect, point)
	local x = point:find("LEFT") and rect.left or rect.right
	local y = point:find("TOP") and rect.top or rect.bottom
	return x, y
end

-- The frame behind an anchor key, if it exists and has a position.
-- El marco detrás de una clave de anclaje, si existe y tiene posición.
function Bars:AnchorFrame(key)
	local kind, ref = key:match("^(%a+):(.+)$")
	local frame
	if kind == "ob" then
		frame = self.frames[tonumber(ref)]
		if frame and not frame.data then frame = nil end
	elseif kind == "bz" then
		frame = _G[ref]
	end
	return frame and frame.GetLeft and frame:GetLeft() and frame or nil
end

-- layout.x / y from where the bar really is (UIParent units, from the centre).
-- layout.x / y según dónde está de verdad la barra (unidades de UIParent, desde el centro).
function Bars:SyncCenter(f)
	local cx, cy = f:GetCenter()
	if not cx then return end
	local k = f:GetEffectiveScale() / UIParent:GetEffectiveScale()
	f.layout.x = U.Round(cx * k - UIParent:GetWidth() / 2)
	f.layout.y = U.Round(cy * k - UIParent:GetHeight() / 2)
end

-- Would anchoring f to key make a loop? / ¿Anclar f a key haría un ciclo?
local function MakesLoop(f, key)
	local seen = 0
	while key and key:match("^ob:") and seen < ns.MAX_BARS do
		local id = tonumber(key:match("%d+"))
		if id == f.id then return true end
		local data = ns.DB:Bars()[id]
		local anchor = data and ns.DB:Layout(data).anchor
		key = anchor and anchor.to
		seen = seen + 1
	end
	return false
end

-- Out of combat only / Solo fuera de combate
function Bars:Attach(f, target, key, side)
	if InCombatLockdown() or not ANCHOR_POINTS[side] or MakesLoop(f, key) then return end
	local mine, theirs = ns.Grid.Rect(f), ns.Grid.FrameRect(target)
	if not (mine and theirs) then return end
	local points = ANCHOR_POINTS[side]
	local mx, my = PointOf(mine, points[1])
	local tx, ty = PointOf(theirs, points[2])
	f.layout.anchor = { to = key, side = side, dx = mx - tx, dy = my - ty }
	self:Place(f)
end

-- Out of combat only / Solo fuera de combate
function Bars:Detach(f)
	if not (f.layout and f.layout.anchor) then return end
	self:SyncCenter(f)
	f.layout.anchor = nil
	self:Place(f)
end

function Bars:Place(f)
	local layout = f.layout
	local scale = layout.iconSize
	f:ClearAllPoints()
	local anchor = layout.anchor
	local target = anchor and self:AnchorFrame(anchor.to)
	if target and ANCHOR_POINTS[anchor.side] then
		local points = ANCHOR_POINTS[anchor.side]
		f:SetPoint(points[1], target, points[2], anchor.dx / scale, anchor.dy / scale)
		self:SyncCenter(f)
		return
	end
	-- Offsets are in the bar's own (scaled) units / Las distancias van en las unidades (escaladas) de la barra
	f:SetPoint("CENTER", UIParent, "CENTER", layout.x / scale, layout.y / scale)
end

-- Arrow keys: an anchored bar moves its offset and stays anchored.
-- Flechas: una barra anclada mueve su distancia y sigue anclada.
function Bars:Nudge(f, dx, dy)
	if InCombatLockdown() then return end
	local anchor = f.layout.anchor
	if anchor then
		anchor.dx, anchor.dy = anchor.dx + dx, anchor.dy + dy
	else
		f.layout.x = f.layout.x + dx
		f.layout.y = f.layout.y + dy
	end
	self:Place(f)
end

function Bars:ResetPosition(f)
	if InCombatLockdown() then return end
	f.layout.anchor = nil
	f.layout.x = ns.DB.LAYOUT_DEFAULTS.x
	f.layout.y = ns.DB.LAYOUT_DEFAULTS.y
	self:Place(f)
end
---------------------------------------------------------------------------
-- Frames / Marcos
---------------------------------------------------------------------------
function Bars:Get(id)
	local f = self.frames[id]
	if f then return f end

	-- State template: ready for the visibility drivers (D-08).
	-- Plantilla de estados: lista para los controladores de visibilidad (D-08).
	f = CreateFrame("Frame", "OnlyBarsBar" .. id, UIParent, "SecureHandlerStateTemplate")
	f.id = id
	f.buttons = {}
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	if f.SetDontSavePosition then f:SetDontSavePosition(true) end
	ns.EditMode:Attach(f)
	f:HookScript("OnShow", function()
		for _, b in ipairs(f.buttons) do
			if b:IsShown() then b:Refresh() end
		end
	end)
	self.frames[id] = f
	return f
end

-- Out of combat only / Solo fuera de combate
function Bars:Build(data)
	local f = self:Get(data.id)
	local set = ns.DB:ActiveSet(data)
	local layout = set.layout
	f.data = data
	f.layout = layout

	-- Blizzard's model (D-39): rows, icon size as % of its 45 px button, margin.
	-- El modelo de Blizzard (D-39): filas, tamaño en % de su botón de 45 px, margen.
	local count = U.Clamp(layout.buttons, 1, ns.MAX_BUTTONS)
	local rows = U.Clamp(layout.rows, 1, count)
	local perRow = math.ceil(count / rows)
	-- Like Blizzard (D-43): built with 45 px buttons and the margin as is, then
	-- the whole bar is scaled by the icon size, so the margin scales too.
	-- Como Blizzard (D-43): se arma con botones de 45 px y el margen tal cual, y
	-- luego toda la barra se escala con el tamaño de iconos, así el margen también.
	local size = ns.Settings.BASE_SIZE
	local gap = layout.spacing

	-- Hidden buttons keep their content, so lowering and raising the count restores it.
	-- Los botones ocultos conservan su contenido: bajar y subir la cantidad lo recupera.
	for i = 1, ns.MAX_BUTTONS do
		local b = f.buttons[i]
		if i <= count then
			if not b then
				b = ns.Buttons:Get(f, i)
				f.buttons[i] = b
			end
			b:SetSize(size, size)
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", f, "TOPLEFT", ((i - 1) % perRow) * (size + gap), -math.floor((i - 1) / perRow) * (size + gap))
			b:Show()
			b:ApplySlot(set.slots[i])
		elseif b then
			b:ApplySlot(nil)
			b:Hide()
		end
	end

	rows = math.ceil(count / perRow)
	f:SetSize(perRow * size + (perRow - 1) * gap, rows * size + (rows - 1) * gap)
	f:SetScale(layout.iconSize)
	f:SetAlpha(layout.alpha)
	self:Place(f)
	ns.Visibility:Apply(f)
end

function Bars:Release(f)
	for _, b in ipairs(f.buttons) do
		b:ApplySlot(nil)
		b:Hide()
	end
	ns.Visibility:Release(f)
	f:Hide()
	f.data, f.layout = nil, nil
end

function Bars:BuildAll()
	local bars = ns.DB:Bars()
	for id, f in pairs(self.frames) do
		if not bars[id] then self:Release(f) end
	end
	for _, data in pairs(bars) do
		self:Build(data)
	end
	-- Second pass: a bar anchored to one built after it can now find it (D-47).
	-- Segunda pasada: una barra anclada a otra construida después ya la encuentra (D-47).
	for _, f in pairs(self.frames) do
		if f.data and f.layout.anchor then self:Place(f) end
	end
	ns.Modes:Apply()
end

---------------------------------------------------------------------------
-- Actions / Acciones
-- Everything goes through the combat queue.
-- Todo pasa por la cola de combate.
---------------------------------------------------------------------------
function Bars:Create()
	ns.Combat:Run("create", function()
		local data = ns.DB:CreateBar()
		if not data then
			U.Print(L.BAR_LIMIT, ns.MAX_BARS)
			return
		end
		-- A new bar starts with the icon size and margin of Blizzard's bar 1 (D-40).
		-- Una barra nueva empieza con el tamaño y el margen de la barra 1 de Blizzard (D-40).
		local iconSize, margin = ns.Grid:BlizzardBar()
		local layout = ns.DB:Layout(data)
		if iconSize then layout.iconSize = ns.Settings.Normalize("iconSize", iconSize) end
		-- The measured margin is on screen; unscale it like Blizzard's (D-43).
		-- El margen medido está en pantalla; se quita la escala como en Blizzard (D-43).
		if margin then layout.spacing = ns.Settings.Normalize("spacing", margin / layout.iconSize) end
		self:Build(data)
		ns.Modes:Apply()
		U.Print(L.BAR_CREATED, self:Name(data))
		self:Changed()
	end)
end

function Bars:Delete(id)
	ns.Combat:Run("delete" .. id, function()
		local data = ns.DB:Bars()[id]
		if not data then return end
		local name = self:Name(data)
		-- Bars anchored to this one stay where they are, free (D-47).
		-- Las barras ancladas a esta se quedan donde están, libres (D-47).
		for _, f in pairs(self.frames) do
			if f.data and f.layout.anchor and f.layout.anchor.to == "ob:" .. id then self:Detach(f) end
		end
		ns.DB:DeleteBar(id)
		if self.frames[id] then
			ns.EditMode:Forget(self.frames[id])
			self:Release(self.frames[id])
		end
		U.Print(L.BAR_DELETED, name)
		self:Changed()
	end)
end

function Bars:Duplicate(data)
	ns.Combat:Run("duplicate" .. data.id, function()
		local copy = ns.DB:DuplicateBar(data)
		if not copy then
			U.Print(L.BAR_LIMIT, ns.MAX_BARS)
			return
		end
		self:Build(copy)
		ns.Modes:Apply()
		U.Print(L.BAR_CREATED, self:Name(copy))
		self:Changed()
	end)
end

-- Copies bars between characters, both ways (D-67). sources: { bar, ... }.
-- targetKey: nil copies into this character (frames are built); a "Name-Realm"
-- copies into that one (saved only, it shows when that character logs in).
-- other: the other character's name, for the message. onDone(lastCopy) after copying.
-- Copia barras entre personajes, en los dos sentidos (D-67). sources: { barra, ... }.
-- targetKey: nil copia a este personaje (se construyen los marcos); un
-- "Nombre-Reino" copia a ese (solo se guarda, se ve cuando ese personaje entra).
-- other: el nombre del otro personaje, para el mensaje. onDone(últimaCopia) al terminar.
function Bars:CopyBars(sources, targetKey, other, onDone)
	ns.Combat:Run("copy", function()
		local last
		for _, source in ipairs(sources) do
			local copy, converted = ns.DB:CopyBarFrom(source, targetKey)
			if not copy then
				U.Print(L.BAR_LIMIT, ns.MAX_BARS)
				break
			end
			if targetKey then
				U.Print(converted and L.BAR_SENT_GENERAL or L.BAR_SENT, self:Name(source), other)
			else
				self:Build(copy)
				U.Print(converted and L.BAR_COPIED_GENERAL or L.BAR_COPIED, self:Name(copy), other)
			end
			last = copy
		end
		if not targetKey then
			ns.Modes:Apply()
			self:Changed()
		end
		if onDone then onDone(last) end
	end)
end

-- An empty name goes back to "Barra N" / Un nombre vacío regresa a "Barra N"
function Bars:Rename(data, name)
	name = name and strtrim(name) or ""
	ns.DB:ActiveSet(data).name = name ~= "" and name or nil
	self:Changed()
end

function Bars:SetHidden(data, hidden)
	data.hidden = hidden
	ns.Combat:Run("visibility", function() ns.Visibility:ApplyAll() end)
	ns.Keybinds:CheckShared(data)
	self:Changed()
end

-- Tells the open windows that the bars changed, except the one that made the change.
-- Avisa a las ventanas abiertas que las barras cambiaron, menos a la que hizo el cambio.
function Bars:Changed(source)
	if source ~= "panel" and ns.Panel then ns.Panel:RefreshIfOpen() end
	if source ~= "dialog" and ns.BarDialog then ns.BarDialog:RefreshIfOpen() end
end

-- One layout setting (Core/Settings.lua), always of the active set: each spec
-- is edited in its own spec (D-60).
-- Un ajuste de forma (Core/Settings.lua), siempre del conjunto activo: cada
-- spec se edita en su propia spec (D-60).
function Bars:SetLayout(data, key, value, source)
	-- Where the bar was, so joined bars can be pushed (D-33).
	-- Dónde estaba la barra, para empujar las barras unidas (D-33).
	local f = self.frames[data.id]
	local before = f and f:IsVisible() and not InCombatLockdown() and ns.Grid.Rect(f) or nil

	local layout = ns.DB:ActiveSet(data).layout
	layout[key] = ns.Settings.Normalize(key, value)
	ns.Combat:Run("build" .. data.id, function()
		self:Build(data)
		if before then ns.Grid:Push(f, before) end
		ns.Modes:Apply()
	end)
	if key == "keysAlways" then ns.Keybinds:CheckShared(data) end
	self:Changed(source)
end

-- One visibility setting (D-26), of the active set like SetLayout.
-- Un ajuste de visibilidad (D-26), del conjunto activo como SetLayout.
function Bars:SetVisibility(data, key, value, option)
	local vis = ns.DB:ActiveSet(data).visibility
	if option ~= nil then
		vis[key][option] = value or nil   -- multi-choice categories / categorías de varias opciones
	else
		vis[key] = value
	end
	ns.Combat:Run("visibility", function() ns.Visibility:ApplyAll() end)
	ns.Keybinds:CheckShared(data)
end

-- Nothing is lost either way (D-27), so no confirmation is needed.
-- No se pierde nada en ningún sentido (D-27), así que no hace falta confirmar.
function Bars:ToggleScope(data)
	self:SetScope(data, data.scope == "global" and "spec" or "global")
end

function Bars:SetScope(data, scope)
	ns.Combat:Run("scope" .. data.id, function()
		ns.DB:SetScope(data, scope)
		self:Build(data)
		ns.Modes:Apply()
		self:Changed()
		U.Print(L.SCOPE_SET, self:Name(data), scope == "spec" and L.SCOPE_SPEC or L.SCOPE_GLOBAL)
	end)
end

-- Checks or unchecks one spec of a Per-spec bar (D-60).
-- Marca o desmarca una spec de una barra por spec (D-60).
function Bars:SetSpec(data, specID, on)
	ns.Combat:Run("scope" .. data.id, function()
		if not ns.DB:SetSpec(data, specID, on) then
			U.Print(L.SPEC_LAST)
		else
			self:Build(data)
			ns.Modes:Apply()
		end
		self:Changed()
	end)
end

-- Per-spec bars reload on a spec change (D-04, D-20).
-- Las barras Por spec se recargan al cambiar de spec (D-04, D-20).
-- Two events for safety; the shared queue key makes them rebuild once.
-- Dos eventos por seguridad; la misma clave de la cola hace que se reconstruya una vez.
local function OnSpecChanged(_, unit)
	if unit and unit ~= "player" then return end
	ns.Combat:Run("specs", function()
		Bars:BuildAll()
		Bars:Changed()
	end)
end
ns:On("PLAYER_SPECIALIZATION_CHANGED", OnSpecChanged)
ns:On("ACTIVE_PLAYER_SPECIALIZATION_CHANGED", OnSpecChanged)
