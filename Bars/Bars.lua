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

-- x, y of a corner (TOPLEFT…) of a rect / x, y de una esquina (TOPLEFT…) de un rectángulo
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
	-- Exact: a rounded centre moved a freed bar half a pixel (D-73).
	-- Exacto: un centro redondeado movía medio píxel una barra recién soltada (D-73).
	f.layout.x = cx * k - UIParent:GetWidth() / 2
	f.layout.y = cy * k - UIParent:GetHeight() / 2
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

-- Keeps f's anchor only while it still joins its bar: the same distance across
-- the side (old: the anchor it had before) and still side by side along it.
-- An anchor is never kept at a distance (D-73).
-- Conserva el anclaje de f solo si sigue unida a su barra: la misma distancia
-- a través del lado (old: el anclaje que tenía antes) y todavía lado a lado.
-- Un anclaje nunca se queda a distancia (D-73).
function Bars:KeepAnchor(f, old)
	local anchor = f.layout and f.layout.anchor
	if not anchor then return end
	local target = self:AnchorFrame(anchor.to)
	local mine, theirs = ns.Grid.Rect(f), target and ns.Grid.FrameRect(target)
	local across = anchor.side == "above" or anchor.side == "below"
	local joined = mine and theirs and true or false
	if joined and old then
		joined = math.abs(across and (anchor.dy - old.dy) or (anchor.dx - old.dx)) < 0.5
	end
	if joined then
		if across then
			joined = math.min(mine.right, theirs.right) - math.max(mine.left, theirs.left) > 0
		else
			joined = math.min(mine.top, theirs.top) - math.max(mine.bottom, theirs.bottom) > 0
		end
	end
	if not joined then self:Detach(f) end
end

-- Out of combat only / Solo fuera de combate
function Bars:Detach(f)
	if not (f.layout and f.layout.anchor) then return end
	self:SyncCenter(f)
	f.layout.anchor = nil
	self:Place(f)
end

-- Puts the bar where its layout says: on its anchor, or at x, y from the centre / Pone la barra donde dice su forma: en su anclaje, o en x, y desde el centro
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

-- Back to the screen centre, unanchored (out of combat) / De regreso al centro de la pantalla, sin anclar (fuera de combate)
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

---------------------------------------------------------------------------
-- Grid of buttons (D-72) / Cuadrícula de botones (D-72)
-- Horizontal fills rows left to right; vertical fills columns top to bottom,
-- extra columns to the right, like Blizzard's side bars.
-- Horizontal llena filas de izquierda a derecha; vertical llena columnas de
-- arriba hacia abajo, las columnas extra a la derecha, como las barras laterales de Blizzard.
---------------------------------------------------------------------------
-- lines: the "rows" setting (columns when vertical). Returns columns, rows and
-- buttons per line.
-- lines: el ajuste "filas" (columnas en vertical). Devuelve columnas, filas y
-- botones por línea.
function Bars.Shape(count, lines, vertical)
	lines = math.max(1, math.min(lines or 1, count))
	local perLine = math.ceil(count / lines)
	lines = math.ceil(count / perLine)
	if vertical then return lines, perLine, perLine end
	return perLine, lines, perLine
end

-- Column and row (from 0) of button i / Columna y fila (desde 0) del botón i
function Bars.Cell(i, perLine, vertical)
	local along, across = (i - 1) % perLine, math.floor((i - 1) / perLine)
	if vertical then return across, along end
	return along, across
end

-- Out of combat only / Solo fuera de combate
function Bars:Build(data)
	local f = self:Get(data.id)
	local set = ns.DB:ActiveSet(data)
	local layout = set.layout
	f.data = data
	f.layout = layout

	-- Blizzard's model (D-39): rows (columns when vertical, D-72), icon size as
	-- % of its 45 px button, margin.
	-- El modelo de Blizzard (D-39): filas (columnas en vertical, D-72), tamaño
	-- en % de su botón de 45 px, margen.
	local count = U.Clamp(layout.buttons, 1, ns.MAX_BUTTONS)
	local vertical = layout.orientation == "vertical"
	local columns, rows, perLine = Bars.Shape(count, layout.rows, vertical)
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
			local column, row = Bars.Cell(i, perLine, vertical)
			b:SetPoint("TOPLEFT", f, "TOPLEFT", column * (size + gap), -row * (size + gap))
			b:Show()
			b:ApplySlot(set.slots[i])
		elseif b then
			b:ApplySlot(nil)
			b:Hide()
		end
	end

	f:SetSize(columns * size + (columns - 1) * gap, rows * size + (rows - 1) * gap)
	f:SetScale(layout.iconSize)
	f:SetAlpha(layout.alpha)
	self:Place(f)
	ns.Visibility:Apply(f)
end

-- Empties and hides the frame of a bar that no longer exists / Vacía y oculta el marco de una barra que ya no existe
function Bars:Release(f)
	for _, b in ipairs(f.buttons) do
		b:ApplySlot(nil)
		b:Hide()
	end
	ns.Visibility:Release(f)
	f:Hide()
	f.data, f.layout = nil, nil
end

-- Builds every bar of this character and frees the unused frames / Construye todas las barras del personaje y libera los marcos que sobran
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

-- Deletes a bar and frees the bars anchored to it / Borra una barra y suelta las que estaban ancladas a ella
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

-- A copy with its own number; from another spec it lands in this one (D-60) / Una copia con su propio número; de otra spec llega a esta (D-60)
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

-- The list's check: shows or hides the bar / La palomita de la lista: muestra u oculta la barra
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

---------------------------------------------------------------------------
-- Changing size (D-73) / Cambiar de tamaño (D-73)
-- Only the bar being changed moves:
-- • its left edge stays and it grows to the right;
-- • with a bar joined below it, its bottom edge stays and it grows up;
--   otherwise its top edge stays and it grows down.
-- The bars on its right move right and, when it grows up, the bars above it
-- move up: straight lines, never diagonal. Bars on its left and below never
-- move. Anchors are kept, its own and the ones of the bars anchored to it.
-- Solo se mueve la barra que cambia:
-- • su orilla izquierda se queda y crece hacia la derecha;
-- • con una barra unida debajo, su orilla de abajo se queda y crece hacia
--   arriba; si no, su orilla de arriba se queda y crece hacia abajo.
-- Las barras a su derecha se recorren a la derecha y, cuando crece hacia
-- arriba, las de arriba suben: en línea recta, nunca en diagonal. Las de su
-- izquierda y las de abajo nunca se mueven. Se conservan los anclajes, el suyo
-- y los de las barras ancladas a ella.
-- No room (D-73): it grows that way up to the screen edge and the rest the
-- other way, moving the bars on that side in a straight line. Anchors that no
-- longer join are freed. Going back to the size it had, with nothing moved in
-- between, puts every bar back exactly where it was.
-- Sin espacio (D-73): crece hacia ese lado hasta el borde de la pantalla y el
-- resto hacia el otro, recorriendo en línea recta las barras de ese lado. Los
-- anclajes que ya no se unen se sueltan. Regresar al tamaño que tenía, sin mover
-- nada entre medio, deja cada barra exactamente donde estaba.
---------------------------------------------------------------------------
local function Size(f)
	return f:GetWidth() * f:GetScale(), f:GetHeight() * f:GetScale()
end

local function Near(a, b) return math.abs(a - b) < 0.5 end

-- Where every bar is, to undo a change / Dónde está cada barra, para deshacer un cambio
function Bars:Positions()
	local list = {}
	for id, g in pairs(self.frames) do
		if g.data and g.layout then
			list[id] = { x = g.layout.x, y = g.layout.y, anchor = g.layout.anchor and CopyTable(g.layout.anchor) }
		end
	end
	return list
end

-- Nothing moved since `b`? Anchored bars compare their anchor.
-- ¿No se movió nada desde `b`? Las ancladas comparan su anclaje.
local function SamePositions(a, b)
	for id, p in pairs(a) do
		local q = b[id]
		if not q or (p.anchor == nil) ~= (q.anchor == nil) then return false end
		if p.anchor then
			local m, n = p.anchor, q.anchor
			if m.to ~= n.to or m.side ~= n.side or not Near(m.dx, n.dx) or not Near(m.dy, n.dy) then return false end
		elseif not (Near(p.x, q.x) and Near(p.y, q.y)) then
			return false
		end
	end
	for id in pairs(b) do
		if not a[id] then return false end
	end
	return true
end

function Bars:Restore(list)
	for id, p in pairs(list) do
		local g = self.frames[id]
		g.layout.x, g.layout.y = p.x, p.y
		g.layout.anchor = p.anchor and CopyTable(p.anchor)
	end
	for id in pairs(list) do self:Place(self.frames[id]) end
	-- Again: a bar anchored to one placed after it / Otra vez: una anclada a otra que se puso después
	for id, p in pairs(list) do
		if p.anchor then self:Place(self.frames[id]) end
	end
end

-- The farthest edge on `side` of rect plus the bars stacked on that side.
-- La orilla más lejana por `side` del rectángulo más las barras pegadas de ese lado.
local function Extent(f, rect, side)
	local edge = rect[side]
	for _, r in ipairs(ns.Grid.Chain(rect, side, { [f] = true })) do
		edge = (side == "bottom" or side == "left") and math.min(edge, r[side]) or math.max(edge, r[side])
	end
	return edge
end

-- Splits a growth `grow` between the preferred way and the other one, by the room left.
-- Reparte un crecimiento `grow` entre el lado preferido y el otro, según el espacio que queda.
local function Split(grow, room)
	if grow <= 0 then return grow, 0 end
	local first = math.max(0, math.min(grow, room))
	return first, grow - first
end

-- Hierarchy (D-74): a bar on f's right (or above it) sits against the farthest
-- edge of the bars it has on that side. If f grows past the others, it takes
-- the bar with it; if f was the farthest and shrinks, the bar goes back to the
-- next farthest; if f stays shorter, the bar does not move. Then the bars
-- behind it move with it, straight.
-- Jerarquía (D-74): una barra a la derecha de f (o encima) se queda contra la
-- orilla más lejana de las barras que tiene de ese lado. Si f crece más que las
-- otras, se la lleva; si f era la más lejana y se achica, la barra regresa a la
-- siguiente más lejana; si f sigue más corta, la barra no se mueve. Luego las
-- barras detrás de ella se mueven con ella, en línea recta.
local function Flush(self, f, before, side, moved)
	local after = ns.Grid.Rect(f)
	if not after then return end
	local right = side == "right"
	local function Far(r) return right and r.right or r.top end
	local function Close(r) return right and r.left or r.bottom end
	local function Across(a, b)
		if right then return math.min(a.top, b.top) - math.max(a.bottom, b.bottom) > 0 end
		return math.min(a.right, b.right) - math.max(a.left, b.left) > 0
	end
	local rects = {}
	for _, g in pairs(self.frames) do
		if g ~= f and g.data and g.layout and g:IsVisible() then rects[#rects + 1] = ns.Grid.Rect(g) end
	end

	-- First measure every move, then move: nothing moves while measuring.
	-- Primero se mide cada movimiento, luego se mueve: nada se mueve mientras se mide.
	local moves, set = {}, {}
	for _, gr in ipairs(rects) do
		local g = gr.frame
		local reach = ns.Grid.TOUCH + ns.Grid:JoinGap(g)
		if not moved[g] and (Across(before, gr) or Across(after, gr)) and Close(gr) >= Far(before) - ns.Grid.TOUCH then
			-- Its other neighbours on that side (not crossing it) / Sus otras vecinas de ese lado (sin cruzarla)
			local others = -math.huge
			for _, hr in ipairs(rects) do
				if hr ~= gr and Across(hr, gr) and Close(hr) < Close(gr) and Far(hr) <= Close(gr) + ns.Grid.TOUCH then
					others = math.max(others, Far(hr))
				end
			end
			local oldMax, newMax = math.max(Far(before), others), math.max(Far(after), others)
			local flush = Close(gr) - oldMax <= reach
			local shift
			if flush then
				shift = newMax + (Close(gr) - oldMax) - Close(gr)
			elseif Far(after) + ns.Grid:JoinGap(g) > Close(gr) then
				shift = Far(after) + ns.Grid:JoinGap(g) - Close(gr)
			end
			if shift and math.abs(shift) > 0.001 then
				moves[#moves + 1] = { rect = gr, shift = shift }
				set[g] = true
			end
		end
	end
	for _, m in ipairs(moves) do
		local g = m.rect.frame
		moved[g] = true
		local dx, dy = right and m.shift or 0, right and 0 or m.shift
		if not ns.Grid.FollowsAny(g, set) then ns.Grid.MoveBar(g, dx, dy) end
		ns.Grid.Shift(m.rect, side, dx, dy, moved)
	end
end

-- build: rebuilds the bar with its new layout. Out of combat only.
-- build: reconstruye la barra con su forma nueva. Solo fuera de combate.
function Bars:Resize(f, build)
	local undo = self.undo
	self.undo = nil
	local before = f:IsVisible() and ns.Grid.Rect(f)
	if not before then
		-- Hidden: keep the top-left corner, nobody else moves.
		-- Oculta: conservar la esquina superior izquierda, nadie más se mueve.
		local width, height = Size(f)
		build()
		if not f.layout.anchor then
			local newWidth, newHeight = Size(f)
			f.layout.x = U.Round(f.layout.x - width / 2 + newWidth / 2)
			f.layout.y = U.Round(f.layout.y + height / 2 - newHeight / 2)
			self:Place(f)
		end
		return
	end

	local positions = self:Positions()

	-- Free the bars anchored to it, see whether a bar is joined below it.
	-- Soltar las barras ancladas a ella, ver si hay una barra unida debajo.
	local key = "ob:" .. f.id
	local ownAnchor = f.layout.anchor and CopyTable(f.layout.anchor)
	local children = {}
	local joinedBelow = ownAnchor and ownAnchor.side == "above" or false
	for _, g in pairs(self.frames) do
		if g ~= f and g.data and g.layout and g:IsVisible() then
			local anchor = g.layout.anchor
			if anchor and anchor.to == key then
				children[#children + 1] = { frame = g, anchor = CopyTable(anchor) }
				if anchor.side == "below" then joinedBelow = true end
				self:Detach(g)
			end
			local rect = ns.Grid.Rect(g)
			if rect and ns.Grid.TouchingSide(before, rect) == "bottom" then joinedBelow = true end
		end
	end
	-- A Blizzard bar on its right never moves: then it grows to the left.
	-- Una barra de Blizzard a su derecha nunca se mueve: entonces crece a la izquierda.
	local wallRight = ownAnchor and ownAnchor.side == "left" and ownAnchor.to:match("^bz:") ~= nil
	self:Detach(f)

	build()
	local width, height = Size(f)

	-- Back to the size it had, nothing moved in between: everything goes back.
	-- De regreso al tamaño que tenía, sin mover nada entre medio: todo regresa.
	if undo and undo.id == f.id and Near(width, undo.width) and Near(height, undo.height)
		and SamePositions(positions, undo.after) then
		self:Restore(undo.before)
		return
	end

	-- How much it grows each way: right first (up first with a bar joined below,
	-- otherwise down); what does not fit on the screen goes the other way.
	-- Cuánto crece hacia cada lado: primero a la derecha (primero hacia arriba con
	-- una barra unida debajo, si no hacia abajo); lo que no cabe en la pantalla va al otro lado.
	local halfW, halfH = UIParent:GetWidth() / 2, UIParent:GetHeight() / 2
	local growW = width - (before.right - before.left)
	local growH = height - (before.top - before.bottom)
	local right, left = Split(growW, wallRight and 0 or halfW - Extent(f, before, "right"))
	local up, down
	if joinedBelow then
		up, down = Split(growH, halfH - Extent(f, before, "top"))
	else
		down, up = Split(growH, Extent(f, before, "bottom") + halfH)
	end

	-- Exact, not rounded: rounding a centre at .5 shifted the edges half a pixel.
	-- Exacto, sin redondear: redondear un centro en .5 corría las orillas medio píxel.
	f.layout.x = before.left - left + width / 2
	f.layout.y = before.top + up - height / 2
	self:Place(f)

	-- Straight moves only, each side by what it grew that way.
	-- Solo movimientos rectos, cada lado lo que creció hacia allá.
	-- Right and above follow the hierarchy (D-74); left and below only move when it did not fit.
	-- Derecha y arriba siguen la jerarquía (D-74); izquierda y abajo solo se mueven si no cupo.
	local moved = { [f] = true }
	if left > 0 then ns.Grid.Shift(before, "left", -left, 0, moved) end
	if down > 0 then ns.Grid.Shift(before, "bottom", 0, -down, moved) end
	Flush(self, f, before, "right", moved)
	Flush(self, f, before, "top", moved)

	-- Anchors come back, only where the bars still join.
	-- Los anclajes regresan, solo donde las barras siguen unidas.
	if ownAnchor then
		local target = self:AnchorFrame(ownAnchor.to)
		if target then
			self:Attach(f, target, ownAnchor.to, ownAnchor.side)
			self:KeepAnchor(f, ownAnchor)
		end
	end
	for _, child in ipairs(children) do
		self:Attach(child.frame, f, key, child.anchor.side)
		self:KeepAnchor(child.frame, child.anchor)
	end

	self.undo = { id = f.id, width = before.right - before.left, height = before.top - before.bottom,
		before = positions, after = self:Positions() }
end

-- One layout setting (Core/Settings.lua), always of the active set: each spec
-- is edited in its own spec (D-60).
-- Un ajuste de forma (Core/Settings.lua), siempre del conjunto activo: cada
-- spec se edita en su propia spec (D-60).
function Bars:SetLayout(data, key, value, source)
	local layout = ns.DB:ActiveSet(data).layout
	layout[key] = ns.Settings.Normalize(key, value)
	ns.Combat:Run("build" .. data.id, function()
		local f = self.frames[data.id]
		if f and f.data then
			self:Resize(f, function() self:Build(data) end)
		else
			self:Build(data)
		end
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

-- General <-> Per spec, nothing is lost (D-27, D-60) / General <-> Por spec, sin perder nada (D-27, D-60)
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
