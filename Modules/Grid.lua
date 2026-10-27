--[[
	OnlyBars · Modules/Grid.lua
	Where a dropped bar lands:
	• Magnetism (D-32): an edge or centre within 10 px of another bar (OnlyBars
	  or Blizzard), the screen edges or the screen centre sticks to it.
	• Grid (D-31): drawn from the screen centre in free mode or Edit Mode; an
	  axis that did not stick snaps its top-left corner to it.
	Dónde queda una barra al soltarla:
	• Magnetismo (D-32): un borde o centro a 10 px o menos de otra barra
	  (OnlyBars o Blizzard), de los bordes o del centro de la pantalla se pega.
	• Rejilla (D-31): se dibuja desde el centro en modo libre o Modo Edición; un
	  eje que no se pegó ajusta su esquina superior izquierda a ella.
	© 2026 iAthVo_Kr
]]

local _, ns = ...
local U = ns.U

local Grid = { lines = {} }
ns.Grid = Grid

Grid.MIN, Grid.MAX, Grid.STEP = 20, 300, 5
local DEFAULT_SIZE = 40

-- Account-wide: a screen preference, not a bar setting.
-- De cuenta: es una preferencia de pantalla, no un ajuste de barra.
function Grid:Settings()
	local settings = ns.DB.db.settings
	settings.grid = settings.grid or { enabled = false, size = DEFAULT_SIZE }
	-- Magnetism starts on, like Blizzard's / El magnetismo empieza activado, como el de Blizzard
	if settings.grid.magnet == nil then settings.grid.magnet = true end
	return settings.grid
end

function Grid:SetMagnet(enabled)
	self:Settings().magnet = enabled and true or false
end

function Grid:SetEnabled(enabled)
	self:Settings().enabled = enabled and true or false
	self:Show(ns.Modes:IsFree())
end

function Grid:SetSize(size)
	size = math.floor(size / self.STEP + 0.5) * self.STEP
	self:Settings().size = U.Clamp(size, self.MIN, self.MAX)
	self.drawnSize = nil
	self:Show(ns.Modes:IsFree())
end

---------------------------------------------------------------------------
-- Drawing / Dibujo
---------------------------------------------------------------------------
local function Line(index)
	local line = Grid.lines[index]
	if not line then
		line = Grid.frame:CreateTexture(nil, "BACKGROUND")
		Grid.lines[index] = line
	end
	line:ClearAllPoints()
	line:Show()
	return line
end

function Grid:Draw()
	local f = self.frame
	local size = self:Settings().size
	local width, height = UIParent:GetSize()
	-- One physical pixel in UIParent units / Un pixel real en unidades de UIParent
	local pixel = 1 / UIParent:GetEffectiveScale()
	local r, g, b = unpack(U.ACCENT)
	local count = 0

	local function Add(isVertical, offset, isCentre)
		count = count + 1
		local line = Line(count)
		if isCentre then
			line:SetColorTexture(r, g, b, 0.6)
		else
			line:SetColorTexture(1, 1, 1, 0.12)
		end
		if isVertical then
			line:SetPoint("TOP", f, "TOP", offset, 0)
			line:SetPoint("BOTTOM", f, "BOTTOM", offset, 0)
			line:SetWidth(pixel)
		else
			line:SetPoint("LEFT", f, "LEFT", 0, offset)
			line:SetPoint("RIGHT", f, "RIGHT", 0, offset)
			line:SetHeight(pixel)
		end
	end

	-- From the centre outwards, so the centre lines always exist.
	-- Del centro hacia afuera, así las líneas del centro siempre existen.
	Add(true, 0, true)
	for x = size, width / 2, size do
		Add(true, x)
		Add(true, -x)
	end
	Add(false, 0, true)
	for y = size, height / 2, size do
		Add(false, y)
		Add(false, -y)
	end
	for i = count + 1, #self.lines do
		self.lines[i]:Hide()
	end
	self.drawnSize = size
	self.drawnWidth, self.drawnHeight = width, height
end

-- Shown only in free mode or Edit Mode, and only if enabled.
-- Solo se ve en modo libre o Modo Edición, y solo si está activada.
function Grid:Show(active)
	local show = active and self:Settings().enabled
	if not show then
		if self.frame then self.frame:Hide() end
		return
	end
	if not self.frame then
		self.frame = CreateFrame("Frame", nil, UIParent)
		self.frame:SetAllPoints(UIParent)
		self.frame:SetFrameStrata("BACKGROUND")
		self.frame:EnableMouse(false)
	end
	local width, height = UIParent:GetSize()
	if self.drawnSize ~= self:Settings().size or self.drawnWidth ~= width or self.drawnHeight ~= height then
		self:Draw()
	end
	self.frame:Show()
end

---------------------------------------------------------------------------
-- Magnetism (D-32) / Magnetismo (D-32)
-- Everything in UIParent units, as offsets from the screen centre.
-- Todo en unidades de UIParent, como distancia al centro de la pantalla.
---------------------------------------------------------------------------
-- 35% stronger than the first 10 px, so it is felt (0.3.7).
-- 35% más fuerte que los 10 px iniciales, para que se sienta (0.3.7).
local MAGNET_DISTANCE = 13.5

-- Blizzard's action bars: only their position is read (D-11).
-- Las barras de acción de Blizzard: solo se lee su posición (D-11).
local BLIZZARD_BARS = {
	"MainActionBar", "MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight",
	"MultiBarRight", "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7",
	"StanceBar", "PetActionBar",
}

local function Rect(frame)
	local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
	if not (left and right and top and bottom) then return nil end
	local k = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
	local cx, cy = UIParent:GetWidth() / 2, UIParent:GetHeight() / 2
	return { left = left * k - cx, right = right * k - cx, top = top * k - cy, bottom = bottom * k - cy }
end

-- A Blizzard bar's frame has empty margins: use the area of its visible
-- buttons instead, so OnlyBars lines up with the buttons (0.3.9).
-- El marco de una barra de Blizzard tiene márgenes vacíos: se usa el área de
-- sus botones visibles, así OnlyBars se alinea con los botones (0.3.9).
local function ButtonsRect(bar)
	local area
	if type(bar.actionButtons) == "table" then
		for _, button in pairs(bar.actionButtons) do
			local r = button.IsVisible and button:IsVisible() and Rect(button)
			if r then
				if area then
					area.left, area.right = math.min(area.left, r.left), math.max(area.right, r.right)
					area.top, area.bottom = math.max(area.top, r.top), math.min(area.bottom, r.bottom)
				else
					area = r
				end
			end
		end
	end
	-- Second value: true if the area came from the buttons / Segundo valor: true si el área salió de los botones
	return area or Rect(bar), area ~= nil
end

-- Icon size (as a fraction of the 45 px button) and margin of Blizzard's
-- action bar 1, read once when a bar is created (D-40). Nil if not measurable.
-- Tamaño de iconos (fracción del botón de 45 px) y margen de la barra de
-- acción 1 de Blizzard, leídos al crear una barra (D-40). Nil si no se puede medir.
local MAIN_BARS = { "MainActionBar", "MainMenuBar" }

function Grid:BlizzardBar()
	for _, name in ipairs(MAIN_BARS) do
		local bar = _G[name]
		local buttons = bar and type(bar.actionButtons) == "table" and bar.actionButtons
		local a = buttons and buttons[1] and Rect(buttons[1])
		local b = buttons and buttons[2] and Rect(buttons[2])
		if a and b and a.right > a.left then
			local margin
			if math.abs(b.top - a.top) < 1 then
				margin = b.left - a.right          -- horizontal bar / barra horizontal
			elseif math.abs(b.left - a.left) < 1 then
				margin = a.bottom - b.top          -- vertical bar / barra vertical
			end
			return (a.right - a.left) / ns.Settings.BASE_SIZE, margin
		end
	end
	return nil, nil
end

-- The space left between two joined bars: the same margin as between their
-- buttons, so stacked bars read as one grid, like Blizzard's own bars (D-38).
-- El espacio entre dos barras unidas: el mismo margen que entre sus botones,
-- así las barras apiladas se ven como una sola cuadrícula, igual que las de
-- Blizzard (D-38).
function Grid:JoinGap(f)
	local layout = f.layout
	if not layout then return 0 end
	return layout.spacing * f:GetScale()
end

local function JoinGap(f)
	return Grid:JoinGap(f)
end

-- An OnlyBars bar's rect, plus the space it keeps when joined and its anchor key (D-47).
-- El rectángulo de una barra de OnlyBars, más el espacio que deja al unirse y su clave de anclaje (D-47).
local function BarRect(f)
	local r = Rect(f)
	if r then
		r.gap = JoinGap(f)
		r.frame, r.key = f, "ob:" .. f.id
	end
	return r
end
Grid.Rect = BarRect
-- The frame's own rect, margins included (anchor offsets) / El rectángulo del marco, con márgenes (distancias de anclaje)
Grid.FrameRect = Rect

-- Is f anchored, directly or along a chain, to the moving bar? Those bars move
-- with it, so they cannot be magnet targets (0.4.10: it caused flicker).
-- ¿Está f anclada, directa o en cadena, a la barra que se mueve? Esas barras se
-- mueven con ella, así que no pueden ser objetivo del magnetismo (0.4.10: causaba parpadeo).
local function FollowsMoving(f, moving)
	local seen = 0
	local anchor = f.layout and f.layout.anchor
	while anchor and seen < ns.MAX_BARS do
		local id = tonumber(anchor.to:match("^ob:(%d+)$") or "")
		if not id then return false end
		if id == moving.id then return true end
		local parent = ns.Bars.frames[id]
		anchor = parent and parent.layout and parent.layout.anchor
		seen = seen + 1
	end
	return false
end

-- Every visible bar the moving one can stick to / Cada barra visible a la que se puede pegar la que se mueve
local function Targets(moving)
	local rects = {}
	for _, f in pairs(ns.Bars.frames) do
		if f ~= moving and f.data and f:IsVisible() and not FollowsMoving(f, moving) then
			rects[#rects + 1] = BarRect(f)
		end
	end
	for _, name in ipairs(BLIZZARD_BARS) do
		local f = _G[name]
		if f and f.IsVisible and f:IsVisible() then
			local r = ButtonsRect(f)
			if r then
				r.frame, r.key = f, "bz:" .. name
				rects[#rects + 1] = r
			end
		end
	end
	return rects
end

-- The smallest shift (within reach) that lines one of our edges up with a
-- candidate, where that line is (red guide) and, for side-by-side joins,
-- which bar and side it joined (anchor, D-47).
-- El menor desplazamiento (a la distancia de alcance) que alinea uno de
-- nuestros bordes con un candidato, dónde está esa línea (guía roja) y, al
-- unir lado a lado, con qué barra y de qué lado (anclaje, D-47).
local function BestShift(pairsList)
	local best, line, join
	for _, pair in ipairs(pairsList) do
		local shift = pair[2] - pair[1]
		if math.abs(shift) <= MAGNET_DISTANCE and (not best or math.abs(shift) < math.abs(best)) then
			best, line, join = shift, pair[2], pair[3]
		end
	end
	return best, line, join
end

-- Returns, per axis, the new centre and the guide line if it stuck, or nil,
-- plus the side-by-side join per axis (D-47).
-- Devuelve, por eje, el nuevo centro y la línea guía si se pegó, o nil, más
-- la unión lado a lado de cada eje (D-47).
local function Magnet(f, x, y, width, height, targets)
	local left, right, top, bottom = x - width / 2, x + width / 2, y + height / 2, y - height / 2
	local halfW, halfH = UIParent:GetWidth() / 2, UIParent:GetHeight() / 2
	-- Side-by-side joins keep the native gap, like two Blizzard bars; aligned
	-- edges have no gap (D-36).
	-- Al unir lado a lado se deja el espacio nativo, como dos barras de
	-- Blizzard; los bordes alineados no llevan espacio (D-36).
	local gap = JoinGap(f)
	-- Screen edges and centre / Bordes y centro de la pantalla
	local xs = { { left, -halfW }, { right, halfW }, { x, 0 } }
	local ys = { { top, halfH }, { bottom, -halfH }, { y, 0 } }
	for _, r in ipairs(targets or Targets(f)) do
		local rx, ry = (r.left + r.right) / 2, (r.top + r.bottom) / 2
		-- Aligned edges, side by side (with the bar and side, for anchoring), and centres.
		-- Bordes alineados, lado a lado (con la barra y el lado, para anclar), y centros.
		xs[#xs + 1] = { left, r.left };  xs[#xs + 1] = { left, r.right + gap, { rect = r, side = "right" } }
		xs[#xs + 1] = { right, r.right }; xs[#xs + 1] = { right, r.left - gap, { rect = r, side = "left" } }
		xs[#xs + 1] = { x, rx }
		ys[#ys + 1] = { top, r.top };     ys[#ys + 1] = { top, r.bottom - gap, { rect = r, side = "below" } }
		ys[#ys + 1] = { bottom, r.bottom }; ys[#ys + 1] = { bottom, r.top + gap, { rect = r, side = "above" } }
		ys[#ys + 1] = { y, ry }
	end
	local dx, lineX, joinX = BestShift(xs)
	local dy, lineY, joinY = BestShift(ys)
	return dx and x + dx, dy and y + dy, lineX, lineY, joinX, joinY
end

---------------------------------------------------------------------------
-- Landing / Dónde queda
---------------------------------------------------------------------------
-- x, y: the bar's centre as an offset from the screen centre (UIParent units).
-- Magnetism first; an axis that did not stick snaps to the grid if it is on.
-- Also returns the guide lines of the axes that stuck.
-- x, y: el centro de la barra como distancia al centro de la pantalla
-- (unidades de UIParent). Primero el magnetismo; un eje que no se pegó se
-- ajusta a la rejilla si está activada. También devuelve las líneas guía de
-- los ejes que se pegaron.
-- targets: the bars measured once at the start of a drag (0.4.10); nil measures now.
-- targets: las barras medidas una vez al empezar a arrastrar (0.4.10); nil mide ahora.
function Grid:Land(f, x, y, targets)
	local settings = self:Settings()
	local scale = f:GetScale()
	local width, height = f:GetWidth() * scale, f:GetHeight() * scale

	local mx, my, lineX, lineY, joinX, joinY
	if settings.magnet then mx, my, lineX, lineY, joinX, joinY = Magnet(f, x, y, width, height, targets) end
	if settings.enabled then
		local size = settings.size
		if not mx then x = U.Round((x - width / 2) / size) * size + width / 2 end
		if not my then y = U.Round((y + height / 2) / size) * size - height / 2 end
	end
	-- Fifth value: the side-by-side join to anchor to; above/below wins (D-47).
	-- Quinto valor: la unión lado a lado para anclar; arriba/abajo tiene prioridad (D-47).
	return mx or x, my or y, lineX, lineY, joinY or joinX
end

-- A join only anchors if the bars really touch along that side (D-47).
-- Una unión solo ancla si las barras de verdad se tocan a lo largo de ese lado (D-47).
local function Touches(mine, join)
	local r = join.rect
	if join.side == "above" or join.side == "below" then
		return math.min(mine.right, r.right) - math.max(mine.left, r.left) > 0
	end
	return math.min(mine.top, r.top) - math.max(mine.bottom, r.bottom) > 0
end

---------------------------------------------------------------------------
-- Live drag with red guides (D-34) / Arrastre en vivo con guías rojas (D-34)
-- Each frame the bar goes where the cursor says, then magnetism and grid pull
-- it, like in Blizzard's Edit Mode. A red line marks each axis that stuck.
-- En cada cuadro la barra va donde dice el cursor, y luego el magnetismo y la
-- rejilla la jalan, como en el Modo Edición de Blizzard. Una línea roja marca
-- cada eje que se pegó.
---------------------------------------------------------------------------
local GUIDE_COLOR = { 1, 0.2, 0.2, 0.9 }

-- The cursor as an offset from the screen centre / El cursor como distancia al centro de la pantalla
local function Cursor()
	local scale = UIParent:GetEffectiveScale()
	local cx, cy = GetCursorPosition()
	return cx / scale - UIParent:GetWidth() / 2, cy / scale - UIParent:GetHeight() / 2
end

local function Guides()
	if not Grid.guides then
		local frame = CreateFrame("Frame", nil, UIParent)
		frame:SetAllPoints()
		frame:SetFrameStrata("HIGH")
		frame:EnableMouse(false)
		local vertical = frame:CreateTexture(nil, "OVERLAY")
		vertical:SetColorTexture(unpack(GUIDE_COLOR))
		local horizontal = frame:CreateTexture(nil, "OVERLAY")
		horizontal:SetColorTexture(unpack(GUIDE_COLOR))
		Grid.guides = { frame = frame, vertical = vertical, horizontal = horizontal }
	end
	return Grid.guides
end

function Grid:ShowGuides(lineX, lineY)
	local g = Guides()
	local thickness = 2 / UIParent:GetEffectiveScale()
	g.vertical:SetShown(lineX ~= nil)
	if lineX then
		g.vertical:ClearAllPoints()
		g.vertical:SetPoint("TOP", UIParent, "TOP", lineX, 0)
		g.vertical:SetPoint("BOTTOM", UIParent, "BOTTOM", lineX, 0)
		g.vertical:SetWidth(thickness)
	end
	g.horizontal:SetShown(lineY ~= nil)
	if lineY then
		g.horizontal:ClearAllPoints()
		g.horizontal:SetPoint("LEFT", UIParent, "LEFT", 0, lineY)
		g.horizontal:SetPoint("RIGHT", UIParent, "RIGHT", 0, lineY)
		g.horizontal:SetHeight(thickness)
	end
	g.frame:Show()
end

function Grid:HideGuides()
	if self.guides then self.guides.frame:Hide() end
end

function Grid:BeginDrag(f)
	if InCombatLockdown() or not f.layout then return end
	-- Dragging frees an anchored bar; dropping it may anchor it again (D-47).
	-- Arrastrar suelta una barra anclada; al soltarla puede anclarse otra vez (D-47).
	ns.Bars:Detach(f)
	local cx, cy = Cursor()
	-- Keep the grab point under the cursor; the other bars do not move while
	-- dragging, so they are measured once (0.4.10).
	-- Mantener el punto agarrado bajo el cursor; las demás barras no se mueven
	-- mientras se arrastra, así que se miden una vez (0.4.10).
	self.dragging = { frame = f, dx = f.layout.x - cx, dy = f.layout.y - cy, targets = Targets(f) }
	self.driver = self.driver or CreateFrame("Frame")
	self.driver:SetScript("OnUpdate", ns.Log.Wrap(function() Grid:UpdateDrag() end))
end

function Grid:UpdateDrag()
	local drag = self.dragging
	if not drag then return end
	-- Combat locks the bars, and a released button ends the drag even if
	-- OnDragStop never arrives (the selection may have closed).
	-- El combate bloquea las barras, y soltar el botón termina el arrastre aunque
	-- OnDragStop no llegue (la selección pudo cerrarse).
	if InCombatLockdown() or not drag.frame.layout or not IsMouseButtonDown("LeftButton") then
		self:EndDrag()
		return
	end
	local cx, cy = Cursor()
	local x, y, lineX, lineY, join = self:Land(drag.frame, cx + drag.dx, cy + drag.dy, drag.targets)
	drag.frame.layout.x, drag.frame.layout.y = x, y
	drag.join = join
	ns.Bars:Place(drag.frame)
	self:ShowGuides(lineX, lineY)
end

function Grid:EndDrag()
	local drag = self.dragging
	if not drag then return end
	self.dragging = nil
	self.driver:SetScript("OnUpdate", nil)
	self:HideGuides()
	local layout = drag.frame.layout
	if layout then
		layout.x, layout.y = U.Round(layout.x), U.Round(layout.y)
		if not InCombatLockdown() then
			ns.Bars:Place(drag.frame)
			-- Joined side by side to another bar: anchor to it (D-47).
			-- Unida lado a lado a otra barra: anclarse a ella (D-47).
			local join, mine = drag.join, Rect(drag.frame)
			if join and mine and Touches(mine, join) then
				ns.Bars:Attach(drag.frame, join.rect.frame, join.rect.key, join.side)
			end
		end
	end
end

---------------------------------------------------------------------------
-- Pushing joined bars (D-33) / Empujar barras unidas (D-33)
-- When a bar changes size, the OnlyBars bars touching its sides move with
-- that side, in a chain, so they stay joined without overlapping.
-- Cuando una barra cambia de tamaño, las barras de OnlyBars que tocan sus
-- lados se mueven con ese lado, en cadena, así siguen unidas sin encimarse.
---------------------------------------------------------------------------
local TOUCH = 2

local function Overlap(lowA, highA, lowB, highB)
	return math.min(highA, highB) - math.max(lowA, lowB) > 0
end

-- Which side of rect r the rect g touches, or nil. Joined bars keep a gap
-- between them (0.3.9), so the reach includes the larger of the two gaps.
-- Qué lado de r toca g, o nil. Las barras unidas dejan una separación entre
-- ellas (0.3.9), así que el alcance incluye la mayor de las dos.
local function TouchingSide(r, g)
	local reach = TOUCH + math.max(r.gap or 0, g.gap or 0)
	local sameRow = Overlap(r.bottom, r.top, g.bottom, g.top)
	local sameColumn = Overlap(r.left, r.right, g.left, g.right)
	if sameRow and g.left >= r.right - TOUCH and g.left - r.right <= reach then return "right" end
	if sameRow and g.right <= r.left + TOUCH and r.left - g.right <= reach then return "left" end
	if sameColumn and g.bottom >= r.top - TOUCH and g.bottom - r.top <= reach then return "top" end
	if sameColumn and g.top <= r.bottom + TOUCH and r.bottom - g.top <= reach then return "bottom" end
	return nil
end

-- Moves every bar touching `rect` on `side`, and the ones touching those, by dx, dy.
-- Mueve cada barra que toca `rect` por `side`, y las que tocan a esas, por dx, dy.
local function PushSide(rect, side, dx, dy, moved)
	for _, g in pairs(ns.Bars.frames) do
		if not moved[g] and g.data and g.layout and g:IsVisible() then
			local gr = BarRect(g)
			if gr and TouchingSide(rect, gr) == side then
				moved[g] = true
				g.layout.x = U.Round(g.layout.x + dx)
				g.layout.y = U.Round(g.layout.y + dy)
				ns.Bars:Place(g)
				PushSide(gr, side, dx, dy, moved)
			end
		end
	end
end

-- before: the bar's rect before the change (Grid.Rect). Out of combat only.
-- before: el rectángulo de la barra antes del cambio (Grid.Rect). Solo fuera de combate.
function Grid:Push(f, before)
	if not before or InCombatLockdown() then return end
	local after = Rect(f)
	if not after then return end
	local moved = { [f] = true }
	PushSide(before, "right", after.right - before.right, 0, moved)
	PushSide(before, "left", after.left - before.left, 0, moved)
	PushSide(before, "top", 0, after.top - before.top, moved)
	PushSide(before, "bottom", 0, after.bottom - before.bottom, moved)
end

-- Redraw if the screen size or UI scale changes / Redibujar si cambia el tamaño de pantalla o la escala
local function Redraw()
	Grid.drawnSize = nil
	if ns.DB.db then Grid:Show(ns.Modes:IsFree()) end
end
ns:On("UI_SCALE_CHANGED", Redraw)
ns:On("DISPLAY_SIZE_CHANGED", Redraw)
