--[[
	OnlyBars · UI/Panel.lua
	The /ob panel: this character's bars on the left, everything about the
	selected bar on the right (Shape and Show tabs), quick actions below (D-18).
	El panel /ob: las barras de este personaje a la izquierda, todo sobre la
	barra elegida a la derecha (pestañas Forma y Mostrar), acciones rápidas
	abajo (D-18).
	© 2026 iAthVo_Kr
]]

local _, ns = ...
local L, W, Style = ns.L, ns.Widgets, ns.Style

local Panel = {}
ns.Panel = Panel

local WIDTH, HEIGHT = 780, 728
local LIST_WIDTH = 210
local LIST_ROW = 22
local LIST_HEADER = 26   -- the character's name above the bars (D-67) / el nombre del personaje sobre las barras
local RIGHT_X = LIST_WIDTH + 24
local RIGHT_WIDTH = WIDTH - RIGHT_X - 14
local COLUMN = 260
local CONTENT_TOP = -112
local MAX_SPECS = 4
local MAX_SETS = 8

-- The panel list follows the order chosen with Subir / Bajar (D-56); bars
-- without one go after, by number.
-- La lista del panel sigue el orden elegido con Subir / Bajar (D-56); las
-- barras sin orden van después, por número.
-- bars: another character's bars (D-67); this character's by default.
-- bars: las barras de otro personaje (D-67); las de este por defecto.
local function SortedBars(bars)
	local list = {}
	for _, data in pairs(bars or ns.DB:Bars()) do list[#list + 1] = data end
	table.sort(list, function(a, b)
		local oa, ob = a.order or (1000 + a.id), b.order or (1000 + b.id)
		if oa ~= ob then return oa < ob end
		return a.id < b.id
	end)
	return list
end

-- Moves the selected bar one place up (-1) or down (+1) in the list (D-56).
-- Mueve la barra elegida un lugar arriba (-1) o abajo (+1) en la lista (D-56).
local function MoveSelected(delta)
	local list = SortedBars()
	for i, data in ipairs(list) do
		data.order = i   -- give every bar a fixed place first / primero, a cada barra un lugar fijo
	end
	for i, data in ipairs(list) do
		if data.id == Panel.selectedID then
			local other = list[i + delta]
			if other then data.order, other.order = other.order, data.order end
			break
		end
	end
	Panel:Refresh()
end

local function IDs()
	local ids = {}
	for id in pairs(ns.DB:Bars()) do ids[id] = true end
	return ids
end

-- The id that is in the bars now but was not before / El id que está ahora y antes no
local function NewID(before)
	for id in pairs(ns.DB:Bars()) do
		if not before[id] then return id end
	end
end

local function SetNames()
	local names = {}
	for _, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs() or {}) do
		local name = C_EquipmentSet.GetEquipmentSetInfo(setID)
		if name then names[#names + 1] = name end
	end
	table.sort(names)
	return names
end

-- The names of the checked specs of a Per-spec bar (D-60).
-- Los nombres de las specs marcadas de una barra por spec (D-60).
local function SpecList(data)
	local names, byID = {}, {}
	for _, spec in ipairs(ns.DB:ClassSpecs()) do byID[spec.id] = spec.name end
	for _, id in ipairs(ns.DB:BarSpecs(data)) do names[#names + 1] = byID[id] or tostring(id) end
	return names
end

-- "Aflicción, Demonología y Destrucción"
local function SpecNames(data)
	local names = SpecList(data)
	if #names <= 1 then return names[1] or "" end
	return table.concat(names, ", ", 1, #names - 1) .. L.AND .. names[#names]
end

-- The first four letters of a spec name, safe with accents: "Demonología" → "Demo".
-- Las primeras cuatro letras del nombre de una spec, seguro con acentos: "Demonología" → "Demo".
local function Short(name)
	local letters = {}
	for char in name:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
		letters[#letters + 1] = char
		if #letters == 4 then break end
	end
	return table.concat(letters)
end

-- Any spec's name, also of another class (D-67) / El nombre de cualquier spec, también de otra clase (D-67)
local function SpecName(id)
	local _, name = GetSpecializationInfoByID(id)
	return name or tostring(id)
end

-- "(General)" or the checked specs, short: "(Demo, Dest)" / "(General)" o las specs marcadas, cortas: "(Demo, Dest)"
local function SavedTag(data)
	if data.scope ~= "spec" then return L.PANEL_SAVED:format(L.SCOPE_GLOBAL) end
	local names = {}
	for _, id in ipairs(ns.DB:BarSpecs(data)) do names[#names + 1] = Short(SpecName(id)) end
	return L.PANEL_SAVED:format(table.concat(names, ", "))
end

-- A bar's name read straight from its saved sets, for another character's
-- bars, which never have an active set here (D-67).
-- El nombre de una barra leído directo de sus conjuntos guardados, para las
-- barras de otro personaje, que aquí nunca tienen conjunto activo (D-67).
local function StoredName(data)
	local key = data.scope == "spec" and ns.DB:BarSpecs(data)[1] or "global"
	local set = key and data.sets[key] or select(2, next(data.sets))
	return set and set.name or L.BAR_NAME:format(data.id)
end

function Panel:Selected()
	return self.selectedID and ns.DB:Bars()[self.selectedID]
end

---------------------------------------------------------------------------
-- Left: list of bars / Izquierda: lista de barras
---------------------------------------------------------------------------
local function CreateListRow(parent, index)
	local row = Style.Button(parent, "", LIST_WIDTH - 12)
	row:SetHeight(LIST_ROW)
	row:SetPoint("TOPLEFT", 6, -6 - LIST_HEADER - (index - 1) * (LIST_ROW + 1))
	-- Where the bar is saved, before the eye: "(General)" or "(Demo, Dest)" (0.6.1).
	-- Dónde está guardada la barra, antes del ojo: "(General)" o "(Demo, Dest)" (0.6.1).
	row.tag = row:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	row.tag:SetPoint("RIGHT", -28, 0)
	row.text:ClearAllPoints()
	row.text:SetPoint("LEFT", 10, 0)
	row.text:SetPoint("RIGHT", row.tag, "LEFT", -4, 0)
	row.text:SetJustifyH("LEFT")
	row.text:SetWordWrap(false)

	-- Accent mark on the selected bar / Marca de acento en la barra elegida
	row.mark = row:CreateTexture(nil, "ARTWORK")
	row.mark:SetPoint("TOPLEFT", 1, -1)
	row.mark:SetPoint("BOTTOMLEFT", 1, 1)
	row.mark:SetWidth(3)
	row.mark:SetColorTexture(Style.ACCENT[1], Style.ACCENT[2], Style.ACCENT[3], 1)

	-- Visible / hidden / Visible / oculta
	local eye = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
	eye:SetSize(20, 20)
	eye:SetPoint("RIGHT", -2, 0)
	eye:SetScript("OnClick", ns.Log.Wrap(function(self)
		if row.data then ns.Bars:SetHidden(row.data, not self:GetChecked()) end
	end))
	eye:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.PANEL_EYE)
		GameTooltip:Show()
	end)
	eye:SetScript("OnLeave", function() GameTooltip:Hide() end)
	row.eye = eye

	row:SetScript("OnClick", ns.Log.Wrap(function()
		if row.data then Panel:Select(row.data.id) end
	end))
	return row
end

local function CreateList(f)
	local box = CreateFrame("Frame", nil, f, "BackdropTemplate")
	box:SetPoint("TOPLEFT", 10, -38)
	box:SetPoint("BOTTOMLEFT", 10, 188)
	box:SetWidth(LIST_WIDTH)
	Style.Flat(box, Style.PANEL)

	-- This character's name on top, and the button that opens "copy from
	-- another character" on the left side (D-67).
	-- El nombre de este personaje arriba, y el botón que abre "copiar de otro
	-- personaje" al lado izquierdo (D-67).
	f.charName = box:CreateFontString(nil, "OVERLAY", "OnlyBarsFontNormalLarge")
	f.charName:SetPoint("TOPLEFT", 10, -8)
	f.charName:SetPoint("RIGHT", -34, 0)
	f.charName:SetJustifyH("LEFT")
	f.charName:SetText(strupper(UnitName("player") or ""))
	local copy = Style.Button(box, "<", 22)
	copy:SetHeight(20)
	copy:SetPoint("TOPRIGHT", -6, -6)
	copy:SetScript("OnClick", ns.Log.Wrap(function() Panel:ToggleCopy() end))
	copy:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.COPY_OPEN)
		GameTooltip:Show()
	end)
	copy:HookScript("OnLeave", function() GameTooltip:Hide() end)
	f.copyToggle = copy

	f.listRows = {}
	for i = 1, ns.MAX_BARS do
		f.listRows[i] = CreateListRow(box, i)
	end

	local function Action(text, offset, onClick)
		local button = W.FlatButton(f, text, LIST_WIDTH, onClick)
		button:SetPoint("BOTTOMLEFT", 10, offset)
		return button
	end
	-- ▲ / ▼ side by side, under the list (D-56) / ▲ / ▼ lado a lado, debajo de la lista (D-56)
	local half = (LIST_WIDTH - 6) / 2
	local up = W.FlatButton(f, L.PANEL_UP, half, function() MoveSelected(-1) end)
	up:SetPoint("BOTTOMLEFT", 10, 156)
	local down = W.FlatButton(f, L.PANEL_DOWN, half, function() MoveSelected(1) end)
	down:SetPoint("LEFT", up, "RIGHT", 6, 0)

	Action(L.PANEL_NEW, 128, function()
		local before = IDs()
		ns.Bars:Create()
		Panel:Select(NewID(before) or Panel.selectedID)
	end)
	Action(L.PANEL_DUPLICATE, 100, function()
		local data = Panel:Selected()
		if not data then return end
		local before = IDs()
		ns.Bars:Duplicate(data)
		Panel:Select(NewID(before) or data.id)
	end)
	Action(L.PANEL_DELETE, 72, function()
		local data = Panel:Selected()
		if data then StaticPopup_Show("ONLYBARS_DELETE_BAR", ns.Bars:Name(data), nil, data.id) end
	end)
	-- Key assignment mode (D-51) / Modo de asignación de teclas (D-51)
	Action(L.PANEL_KEYS, 44, function() ns.Keybinds:Toggle() end)
end

---------------------------------------------------------------------------
-- Right header: name and tabs. General / Per spec lives in the Show tab,
-- under Especialización (D-60).
-- Encabezado derecho: nombre y pestañas. General / Por spec vive en la
-- pestaña Mostrar, en Especialización (D-60).
---------------------------------------------------------------------------
local function CreateHeader(f)
	local name = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	name:SetSize(220, 22)
	name:SetPoint("TOPLEFT", RIGHT_X + 6, -46)
	name:SetAutoFocus(false)
	name:SetMaxLetters(32)
	local function Commit(self)
		local data = Panel:Selected()
		if data and ns.DB:InSpec(data) then ns.Bars:Rename(data, self:GetText()) end
		self:ClearFocus()
	end
	name:SetScript("OnEnterPressed", ns.Log.Wrap(Commit))
	name:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		Panel:Refresh()
	end)
	f.name = name

	local nameLabel = f:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	nameLabel:SetPoint("BOTTOMLEFT", name, "TOPLEFT", -4, 2)
	nameLabel:SetText(L.PANEL_NAME)

	-- A bar of another spec: shown, not edited; each spec is edited in its own spec (D-60).
	-- Next to the tabs, where there is room.
	-- Una barra de otra spec: se ve, no se edita; cada spec se edita en su propia spec (D-60).
	-- Junto a las pestañas, donde hay espacio.
	f.otherSpec = f:CreateFontString(nil, "OVERLAY", "OnlyBarsFontNormalSmall")
	f.otherSpec:SetPoint("TOPLEFT", RIGHT_X + 280, -76)
	f.otherSpec:SetPoint("RIGHT", f, "RIGHT", -14, 0)
	f.otherSpec:SetJustifyH("LEFT")

	f.tabs = {}
	local function Tab(key, text, x)
		local tab = W.FlatButton(f, text, 130, function() Panel:ShowTab(key) end)
		tab:SetHeight(24)
		tab:SetPoint("TOPLEFT", RIGHT_X + x, -78)
		f.tabs[key] = tab
	end
	Tab("shape", L.PANEL_TAB_SHAPE, 0)
	Tab("show", L.PANEL_TAB_SHOW, 136)
end

---------------------------------------------------------------------------
-- Shape tab / Pestaña Forma
---------------------------------------------------------------------------
local function CreateShapeTab(f)
	local tab = CreateFrame("Frame", nil, f)
	tab:SetPoint("TOPLEFT", RIGHT_X, CONTENT_TOP)
	tab:SetSize(RIGHT_WIDTH, HEIGHT + CONTENT_TOP - 50)
	f.shapeRows = {}

	local y = 0
	for _, def in ipairs(ns.Settings.LAYOUT) do
		local function OnChange(value)
			local data = Panel:Selected()
			if not data then return end
			ns.Bars:SetLayout(data, def.key, value, "panel")
			-- A check can enable other rows ("needs") / Una casilla puede habilitar otras filas ("needs")
			if def.kind == "check" then Panel:Refresh() end
		end
		local row
		if def.kind == "slider" then
			row = W.SliderRow(tab, def, 440, 150, OnChange)
		else
			row = W.Check(tab, def.label, 440, OnChange)
		end
		if row then
			row.def = def
			row:SetPoint("TOPLEFT", 0, y)
			y = y - W.ROW - 4
			f.shapeRows[#f.shapeRows + 1] = row
		end
	end

	local reset = W.FlatButton(tab, L.DIALOG_RESET_POSITION, 220, function()
		local data = Panel:Selected()
		local frame = data and ns.Bars.frames[data.id]
		if frame then ns.Bars:ResetPosition(frame) end
	end)
	reset:SetHeight(24)
	reset:SetPoint("TOPLEFT", 0, y - 10)

	local hint = tab:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	hint:SetPoint("TOPLEFT", reset, "BOTTOMLEFT", 0, -10)
	hint:SetWidth(RIGHT_WIDTH)
	hint:SetJustifyH("LEFT")
	hint:SetText(L.PANEL_SHAPE_HINT)
	f.shapeTab = tab
end

---------------------------------------------------------------------------
-- Show tab: situations (D-26) / Pestaña Mostrar: situaciones (D-26)
---------------------------------------------------------------------------
local function CreateShowTab(f)
	local tab = CreateFrame("Frame", nil, f)
	tab:SetPoint("TOPLEFT", RIGHT_X, CONTENT_TOP)
	tab:SetSize(RIGHT_WIDTH, HEIGHT + CONTENT_TOP - 50)

	local function SetVis(key, value, option)
		local data = Panel:Selected()
		if data then ns.Bars:SetVisibility(data, key, value, option) end
	end

	-- Left column: location and state / Columna izquierda: ubicación y estado
	local y = 0
	W.Header(tab, L.CAT_LOCATION, COLUMN - 10):SetPoint("TOPLEFT", 0, y)
	y = y - 24
	f.locationChecks = {}
	for _, def in ipairs(ns.Settings.LOCATIONS) do
		local row = W.Check(tab, def.label, COLUMN - 10, function(checked) SetVis("location", checked, def.key) end)
		row.key = def.key
		row:SetPoint("TOPLEFT", 0, y)
		y = y - 24
		f.locationChecks[#f.locationChecks + 1] = row
	end
	-- PvE / PvP: mark all of them, or clear them if all were marked.
	-- PvE / PvP: marca todas, o las quita si ya estaban todas marcadas.
	local x = 0
	for _, shortcut in ipairs(ns.Settings.LOCATION_SHORTCUTS) do
		local button = W.FlatButton(tab, shortcut.label, 80, function()
			local data = Panel:Selected()
			if not data then return end
			local marked = Panel:EditedSet(data).visibility.location
			local all = true
			for _, key in ipairs(shortcut.keys) do
				if not marked[key] then all = false end
			end
			for _, key in ipairs(shortcut.keys) do SetVis("location", not all, key) end
			Panel:Refresh()
		end)
		button:SetHeight(22)
		button:SetPoint("TOPLEFT", x, y - 2)
		x = x + 88
	end
	y = y - 34

	f.stateHeader = W.Header(tab, L.CAT_STATE, COLUMN - 10)
	f.stateHeader:SetPoint("TOPLEFT", 0, y)
	y = y - 26
	f.stateRows = {}
	for _, def in ipairs(ns.Settings.STATES) do
		local row
		if def.kind == "choice" then
			-- One check per option, one or none marked (0.6.3) / Una casilla por opción, una o ninguna marcada (0.6.3)
			for _, option in ipairs(def.options) do
				local check = W.Check(tab, option[2], COLUMN - 10, function(checked)
					SetVis(def.key, checked and option[1] or def.none)
					Panel:Refresh()
				end)
				check:SetPoint("TOPLEFT", 0, y)
				y = y - 24
				check.def = def
				local load = check.Load
				check.Load = function(self, value) load(self, value == option[1]) end
				f.stateRows[#f.stateRows + 1] = check
			end
			y = y - 4
		elseif def.kind == "cycle" then
			row = W.Cycle(tab, def, COLUMN - 20, function(value)
				SetVis(def.key, value)
				Panel:Refresh()
			end)
			row:SetPoint("TOPLEFT", 0, y)
			y = y - 28
		else
			row = W.Check(tab, def.label, COLUMN - 10, function(checked)
				SetVis(def.key, checked)
				Panel:Refresh()
			end)
			row:SetPoint("TOPLEFT", 0, y)
			y = y - 24
		end
		if row then
			row.def = def
			f.stateRows[#f.stateRows + 1] = row
		end
	end

	-- Why Estado or "Mostrar solo si…" is locked (D-61) / Por qué Estado o "Mostrar solo si…" está bloqueado (D-61)
	f.lockNote = tab:CreateFontString(nil, "OVERLAY", "OnlyBarsFontNormalSmall")
	f.lockNote:SetPoint("TOPLEFT", 0, y - 6)
	f.lockNote:SetWidth(COLUMN - 10)
	f.lockNote:SetJustifyH("LEFT")

	-- Right column: the bar's specs (D-60) and equipment set.
	-- General on top locks the specs: the same bar in all of them. The specs
	-- stay usable for a bar of another spec, above the lock (Panel:Refresh).
	-- Columna derecha: las specs de la barra (D-60) y conjunto de equipo.
	-- General arriba bloquea las specs: la misma barra en todas. Las specs se
	-- pueden usar en una barra de otra spec, encima del bloqueo (Panel:Refresh).
	y = 0
	W.Header(tab, L.CAT_SPEC, COLUMN - 10):SetPoint("TOPLEFT", COLUMN + 10, y)
	y = y - 24
	local specBox = CreateFrame("Frame", nil, tab)
	specBox:SetAllPoints()
	specBox:SetFrameLevel(tab:GetFrameLevel() + 30)
	local SPEC_WIDTH = 140
	f.general = W.Check(specBox, L.SCOPE_GLOBAL, SPEC_WIDTH, function(checked)
		local data = Panel:Selected()
		if data then ns.Bars:SetScope(data, checked and "global" or "spec") end
	end)
	f.general:SetPoint("TOPLEFT", COLUMN + 10, y)
	local top = y
	y = y - 24
	f.specChecks = {}
	for i = 1, MAX_SPECS do
		local row = W.Check(specBox, "", SPEC_WIDTH, function(checked, self)
			local data = Panel:Selected()
			if data then ns.Bars:SetSpec(data, self.key, checked) end
		end)
		row:SetPoint("TOPLEFT", COLUMN + 10, y)
		y = y - 24
		f.specChecks[i] = row
	end
	y = y - 10

	-- What General or Per spec means, next to the checks / Qué significa General o Por spec, junto a las casillas
	local note = CreateFrame("Frame", nil, specBox, "BackdropTemplate")
	note:SetPoint("TOPLEFT", COLUMN + 10 + SPEC_WIDTH + 4, top - 2)
	note:SetSize(COLUMN - SPEC_WIDTH - 24, 64)
	Style.Flat(note, Style.PANEL)
	note.title = note:CreateFontString(nil, "OVERLAY", "OnlyBarsFontNormalSmall")
	note.title:SetPoint("TOPLEFT", 8, -8)
	note.body = note:CreateFontString(nil, "OVERLAY", "OnlyBarsFontHighlightSmall")
	note.body:SetPoint("TOPLEFT", note.title, "BOTTOMLEFT", 0, -4)
	note.body:SetPoint("RIGHT", -8, 0)
	note.body:SetJustifyH("LEFT")
	f.specNote = note

	W.Header(tab, L.CAT_EQUIPSET, COLUMN - 10):SetPoint("TOPLEFT", COLUMN + 10, y)
	y = y - 24
	f.noSets = tab:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	f.noSets:SetPoint("TOPLEFT", COLUMN + 14, y - 4)
	f.noSets:SetText(L.PANEL_NO_SETS)
	f.setChecks = {}
	for i = 1, MAX_SETS do
		local row = W.Check(tab, "", COLUMN - 10, function(checked, self) SetVis("equipset", checked, self.key) end)
		row:SetPoint("TOPLEFT", COLUMN + 10, y)
		y = y - 24
		f.setChecks[i] = row
	end
	y = y - 10

	-- "Mostrar solo si…" (D-55, D-61): two columns of checks.
	-- "Mostrar solo si…" (D-55, D-61): dos columnas de casillas.
	f.showIfHeader = W.Header(tab, L.CAT_SHOW_IF, COLUMN - 10)
	f.showIfHeader:SetPoint("TOPLEFT", COLUMN + 10, y)
	y = y - 24
	f.showIfChecks = {}
	local half = (COLUMN - 10) / 2
	for i, def in ipairs(ns.Settings.SHOW_IF) do
		local row = W.Check(tab, def.label, half, function(checked)
			SetVis("showIf", checked, def.key)
			Panel:Refresh()
		end)
		row.key = def.key
		local column = (i - 1) % 2
		row:SetPoint("TOPLEFT", COLUMN + 10 + column * half, y - math.floor((i - 1) / 2) * 24)
		f.showIfChecks[#f.showIfChecks + 1] = row
	end
	y = y - math.ceil(#ns.Settings.SHOW_IF / 2) * 24

	-- Left column only: the right one reaches the bottom / Solo la columna izquierda: la derecha llega hasta abajo
	local hint = tab:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	hint:SetPoint("BOTTOMLEFT", 0, 4)
	hint:SetWidth(COLUMN - 10)
	hint:SetJustifyH("LEFT")
	hint:SetText(L.PANEL_SHOW_HINT)
	f.showTab = tab
end

---------------------------------------------------------------------------
-- Footer / Pie
---------------------------------------------------------------------------
local GRID_SIZE = {
	label = "", min = ns.Grid.MIN, max = ns.Grid.MAX, step = ns.Grid.STEP,
	format = function(value) return L.GRID_PX:format(value) end,
}

local function CreateFooter(f)
	f.free = W.FlatButton(f, "", 130, function()
		ns.Modes:SetFree(not ns.Modes:IsFree())
		Panel:Refresh()
	end)
	f.free:SetHeight(26)
	f.free:SetPoint("BOTTOMLEFT", RIGHT_X, 12)

	-- OnlyBars' grid (D-31) and magnetism (D-32) / La rejilla (D-31) y el magnetismo (D-32) de OnlyBars
	f.grid = W.Check(f, L.GRID, 76, function(checked) ns.Grid:SetEnabled(checked) end)
	f.grid:SetPoint("LEFT", f.free, "RIGHT", 10, 0)
	f.gridSize = W.SliderRow(f, GRID_SIZE, 200, 1, function(value) ns.Grid:SetSize(value) end)
	if f.gridSize then f.gridSize:SetPoint("LEFT", f.grid, "RIGHT", 4, 0) end
	f.magnet = W.Check(f, L.MAGNET, 104, function(checked) ns.Grid:SetMagnet(checked) end)
	f.magnet:SetPoint("LEFT", f.grid, "RIGHT", 212, 0)

	-- Under the list, where there is room / Debajo de la lista, donde hay espacio
	local report = W.FlatButton(f, L.PANEL_REPORT, LIST_WIDTH, function() ns.Report:Show() end)
	report:SetHeight(26)
	report:SetPoint("BOTTOMLEFT", 10, 12)
end

---------------------------------------------------------------------------
-- Copy from another character (D-67): a side panel on the left. A menu picks
-- the character; its bars are listed with checks; the button below copies the
-- checked ones into this character.
-- Copiar de otro personaje (D-67): un panel lateral a la izquierda. Un menú
-- elige el personaje; sus barras salen con casillas; el botón de abajo copia
-- las marcadas a este personaje.
---------------------------------------------------------------------------
local COPY_WIDTH = LIST_WIDTH + 20

local function CreateCopyRow(parent, index)
	local row = Style.Button(parent, "", LIST_WIDTH - 12)
	row:SetHeight(LIST_ROW)
	row:SetPoint("TOPLEFT", 6, -6 - (index - 1) * (LIST_ROW + 1))
	row.tag = row:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	row.tag:SetPoint("RIGHT", -28, 0)
	row.text:ClearAllPoints()
	row.text:SetPoint("LEFT", 10, 0)
	row.text:SetPoint("RIGHT", row.tag, "LEFT", -4, 0)
	row.text:SetJustifyH("LEFT")
	row.text:SetWordWrap(false)
	local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
	check:SetSize(20, 20)
	check:SetPoint("RIGHT", -2, 0)
	local function Toggle(checked)
		if not row.data then return end
		Panel.copyPicked[row.data] = checked or nil
		Panel:RefreshCopy()
	end
	check:SetScript("OnClick", ns.Log.Wrap(function(self) Toggle(self:GetChecked()) end))
	-- Clicking the row toggles it too / Hacer clic en la fila también la marca
	row:SetScript("OnClick", ns.Log.Wrap(function() Toggle(not check:GetChecked()) end))
	row.check = check
	return row
end

-- The character menu, or going through them on click if Blizzard's menu is missing.
-- El menú de personajes, o pasar de uno en uno al hacer clic si falta el menú de Blizzard.
local function ChooseCharacter(owner)
	local chars = ns.DB:OtherChars()
	if #chars == 0 then return end
	local function Pick(key)
		Panel.copyFrom, Panel.copyPicked = key, {}
		Panel:RefreshCopy()
	end
	if MenuUtil and MenuUtil.CreateContextMenu then
		MenuUtil.CreateContextMenu(owner, function(_, root)
			for _, char in ipairs(chars) do
				local label = ("%s - %s (%d)"):format(char.name, char.realm, ns.U.Count(char.bars))
				root:CreateRadio(label,
					function() return Panel.copyFrom == char.key end,
					function() ns.Log.Call(Pick, char.key) end)
			end
		end)
		return
	end
	local index = 1
	for i, char in ipairs(chars) do
		if char.key == Panel.copyFrom then index = i % #chars + 1 end
	end
	Pick(chars[index].key)
end

local function CreateCopyPanel(f)
	local c = CreateFrame("Frame", nil, f, "BackdropTemplate")
	c:SetPoint("TOPRIGHT", f, "TOPLEFT", -2, 0)
	c:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", -2, 0)
	c:SetWidth(COPY_WIDTH)
	Style.Flat(c)
	c:EnableMouse(true)

	local title = c:CreateFontString(nil, "OVERLAY", "OnlyBarsFontHighlight")
	title:SetPoint("TOPLEFT", 12, -8)
	title:SetText(L.COPY_OPEN)

	-- Which way it copies; a click turns it around (0.10.1).
	-- En qué sentido copia; un clic lo invierte (0.10.1).
	c.direction = W.FlatButton(c, "", LIST_WIDTH, function()
		Panel.copyToOther, Panel.copyPicked = not Panel.copyToOther, {}
		Panel:RefreshCopy()
	end)
	c.direction:SetHeight(22)
	c.direction:SetPoint("TOPLEFT", 10, -30)
	c.direction:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.COPY_SWAP)
		GameTooltip:Show()
	end)
	c.direction:HookScript("OnLeave", function() GameTooltip:Hide() end)

	local box = CreateFrame("Frame", nil, c, "BackdropTemplate")
	box:SetPoint("TOPLEFT", 10, -58)
	box:SetPoint("BOTTOMLEFT", 10, 178)
	box:SetWidth(LIST_WIDTH)
	Style.Flat(box, Style.PANEL)

	-- The other character's name, with the menu button next to it.
	-- El nombre del otro personaje, con el botón del menú junto.
	c.charName = box:CreateFontString(nil, "OVERLAY", "OnlyBarsFontNormalLarge")
	c.charName:SetPoint("TOPLEFT", 10, -8)
	c.charName:SetPoint("RIGHT", -34, 0)
	c.charName:SetJustifyH("LEFT")
	c.charName:SetWordWrap(false)
	local menu = Style.Button(box, "v", 22)
	menu:SetHeight(20)
	menu:SetPoint("TOPRIGHT", -6, -6)
	menu:SetScript("OnClick", ns.Log.Wrap(function(self) ChooseCharacter(self) end))

	local rowsBox = CreateFrame("Frame", nil, box)
	rowsBox:SetPoint("TOPLEFT", 0, -LIST_HEADER)
	rowsBox:SetPoint("BOTTOMRIGHT")
	c.rows = {}
	for i = 1, ns.MAX_BARS do
		c.rows[i] = CreateCopyRow(rowsBox, i)
	end
	c.empty = box:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	c.empty:SetPoint("TOPLEFT", 10, -LIST_HEADER - 8)
	c.empty:SetPoint("RIGHT", -10, 0)
	c.empty:SetJustifyH("LEFT")
	c.empty:SetText(L.COPY_NONE)

	local hint = c:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	hint:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 2, -10)
	hint:SetWidth(LIST_WIDTH - 4)
	hint:SetJustifyH("LEFT")
	hint:SetText(L.COPY_HINT)

	c.copy = W.FlatButton(c, "", LIST_WIDTH, function()
		local other = Panel.copyFrom
		if not (other and ns.DB.db.chars[other]) then return end
		local sources = {}
		for _, data in ipairs(Panel:CopySources()) do
			if Panel.copyPicked[data] then sources[#sources + 1] = data end
		end
		if #sources == 0 then return end
		local toOther = Panel.copyToOther
		ns.Bars:CopyBars(sources, toOther and other or nil, other:match("^(.-)%-") or other, function(last)
			Panel.copyPicked = {}
			-- A copy made here gets selected / Una copia hecha aquí queda seleccionada
			if last and not toOther then Panel:Select(last.id) end
			Panel:RefreshCopy()
		end)
	end)
	c.copy:SetHeight(26)
	c.copy:SetPoint("BOTTOMLEFT", 10, 12)

	c:Hide()
	f.copyPanel = c
end

local function Create()
	local f = Style.Window("OnlyBarsPanel", L.PANEL_TITLE, WIDTH, HEIGHT)
	CreateList(f)
	CreateHeader(f)
	CreateShapeTab(f)
	CreateShowTab(f)
	CreateFooter(f)
	CreateCopyPanel(f)

	f.empty = f:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisable")
	f.empty:SetPoint("CENTER", RIGHT_X / 2, 0)
	f.empty:SetText(L.PANEL_EMPTY)

	-- Covers the settings of a bar of another spec: they are shown dimmed and
	-- cannot be changed; only its specs stay usable (D-60).
	-- Tapa los ajustes de una barra de otra spec: se ven atenuados y no se
	-- pueden cambiar; solo sus specs se pueden usar (D-60).
	local lock = CreateFrame("Frame", nil, f)
	lock:SetPoint("TOPLEFT", RIGHT_X, CONTENT_TOP)
	lock:SetPoint("BOTTOMRIGHT", -14, 46)
	lock:SetFrameLevel(f:GetFrameLevel() + 20)
	lock:EnableMouse(true)
	local dim = lock:CreateTexture(nil, "BACKGROUND")
	dim:SetAllPoints()
	dim:SetColorTexture(0, 0, 0, 0.5)
	lock:Hide()
	f.lock = lock

	f:SetScript("OnShow", ns.Log.Wrap(function()
		Panel:Refresh()
		ns.Keybinds:PlaceBanner()
	end))
	-- Closing the panel locks the bars, unless Blizzard's Edit Mode is open (D-45).
	-- Cerrar el panel bloquea las barras, salvo que esté abierto el Modo Edición (D-45).
	f:SetScript("OnHide", ns.Log.Wrap(function()
		ns.Keybinds:PlaceBanner()
		local editMode = EditModeManagerFrame and EditModeManagerFrame:IsShown()
		-- Not while assigning keys: that mode restores the lock itself when it ends.
		-- No mientras se asignan teclas: ese modo regresa el bloqueo al terminar.
		if ns.Modes:IsFree() and not editMode and not ns.Keybinds:IsActive() then ns.Modes:SetFree(false) end
	end))
	return f
end

-- The key assignment notice (Modules/Keybinds.lua) goes over the bottom of the
-- right column, above the footer, while the panel is open (0.5.9).
-- El aviso de asignar teclas (Modules/Keybinds.lua) va sobre la parte de abajo
-- de la columna derecha, arriba del pie, mientras el panel está abierto (0.5.9).
function Panel:PlaceKeyBanner(banner)
	local f = self.frame
	if not (f and f:IsShown()) then return false end
	banner:SetParent(f)
	banner:SetFrameStrata(f:GetFrameStrata())
	banner:SetFrameLevel(f:GetFrameLevel() + 50)
	banner:SetSize(RIGHT_WIDTH, 64)
	banner:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", RIGHT_X, 46)
	return true
end

---------------------------------------------------------------------------
-- Refresh / Actualizar
---------------------------------------------------------------------------
function Panel:RefreshList(f, bars)
	for i, row in ipairs(f.listRows) do
		local data = bars[i]
		row.data = data
		if data then
			-- A bar of another spec: its name there, greyed (D-54); the tag says which spec.
			-- Una barra de otra spec: su nombre allá, en gris (D-54); la etiqueta dice cuál spec.
			if ns.DB:InSpec(data) then
				row.text:SetText(ns.Bars:Name(data))
				row.text:SetTextColor(1, 1, 1)
			else
				row.text:SetText(ns.Bars:Name(data, ns.DB:BarSpecs(data)[1]))
				row.text:SetTextColor(0.5, 0.5, 0.5)
			end
			row.tag:SetText(SavedTag(data))
			row.mark:SetShown(data.id == self.selectedID)
			row.eye:SetChecked(not data.hidden)
			row:Show()
		else
			row:Hide()
		end
	end
end

function Panel:RefreshShape(f, data)
	local layout = self:EditedSet(data).layout
	for _, row in ipairs(f.shapeRows) do
		row:Load(layout[row.def.key])
		if row.def.needs then row:SetEnabled(layout[row.def.needs] and true or false) end
	end
end

function Panel:RefreshShow(f, data)
	local vis = self:EditedSet(data).visibility
	for _, row in ipairs(f.locationChecks) do
		row:Load(vis.location[row.key])
	end
	for _, row in ipairs(f.stateRows) do
		row:Load(vis[row.def.key])
	end

	-- General checked: every spec shows checked and locked (D-60).
	-- General marcada: todas las specs se ven marcadas y bloqueadas (D-60).
	local general = data.scope ~= "spec"
	f.general:Load(general)
	f.general:SetEnabled(ns.DB:InSpec(data))
	local specs = ns.DB:ClassSpecs()
	for i, row in ipairs(f.specChecks) do
		local spec = specs[i]
		row.key = spec and spec.id
		if spec then
			row.label:SetText(spec.name)
			row:Load(general or (data.sets[spec.id] ~= nil and not data.off[spec.id]))
			row:SetEnabled(not general)
		end
		row:SetShown(spec ~= nil)
	end
	-- General · one spec (its name as title) · several (no title) (0.6.2).
	-- General · una spec (su nombre de título) · varias (sin título) (0.6.2).
	local note, specNames = f.specNote, SpecList(data)
	if general then
		note.title:SetText(L.SCOPE_GLOBAL)
		note.body:SetText(L.SPEC_NOTE_GLOBAL)
	elseif #specNames == 1 then
		note.title:SetText(specNames[1])
		note.body:SetText(L.SPEC_NOTE_ONE)
	else
		note.title:SetText("")
		note.body:SetText(L.SPEC_NOTE_SOME:format(SpecNames(data)))
	end
	local titled = note.title:GetText() ~= ""
	note.body:ClearAllPoints()
	if titled then
		note.body:SetPoint("TOPLEFT", note.title, "BOTTOMLEFT", 0, -4)
	else
		note.body:SetPoint("TOPLEFT", 8, -8)
	end
	note.body:SetPoint("RIGHT", -8, 0)
	-- Grows with the text / Crece con el texto
	note:SetHeight(note.body:GetStringHeight() + (titled and note.title:GetStringHeight() + 4 or 0) + 16)

	local names = SetNames()
	for i, row in ipairs(f.setChecks) do
		local name = names[i]
		row.key = name
		if name then
			row.label:SetText(name)
			row:Load(vis.equipset[name])
		end
		row:SetShown(name ~= nil)
	end
	f.noSets:SetShown(#names == 0)

	-- "Mostrar solo si…" (D-55, D-61)
	for _, row in ipairs(f.showIfChecks) do
		row:Load(vis.showIf[row.key])
	end
	self:RefreshLocks(f, vis)
end

-- Combat and group lock each other with "Mostrar solo si…" (D-61). Filters
-- (mount, target, vehicle) always apply, so they never lock (D-66). A bar that
-- already uses both keeps both usable, with a warning, so one can be cleared.
-- Combate y grupo se bloquean con "Mostrar solo si…" (D-61). Los filtros
-- (montura, objetivo, vehículo) siempre se aplican, así que nunca se bloquean
-- (D-66). Una barra que ya usa los dos los deja usables, con aviso, para poder quitar uno.
function Panel:RefreshLocks(f, vis)
	local state, showIf = ns.Visibility:UsesState(vis), ns.Visibility:UsesShowIf(vis)
	local both = state and showIf
	local lockState = showIf and not both
	local lockShowIf = state and not both
	for _, row in ipairs(f.stateRows) do
		if not row.def.filter then row:SetEnabled(not lockState) end
	end
	for _, row in ipairs(f.showIfChecks) do
		row:SetEnabled(not lockShowIf)
	end
	f.stateHeader.label:SetText(lockState and L.LOCKED:format(L.CAT_STATE) or L.CAT_STATE)
	f.showIfHeader.label:SetText(lockShowIf and L.LOCKED:format(L.CAT_SHOW_IF) or L.CAT_SHOW_IF)
	f.lockNote:SetText(both and L.STATE_SHOWIF_BOTH or (state or showIf) and L.STATE_SHOWIF_NOTE or "")
end

-- Footer only; also called when the mode changes (Modes:SetFree). The grid can
-- only be changed in free mode or Edit Mode, where it is visible (D-31).
-- Solo el pie; también se llama al cambiar de modo (Modes:SetFree). La rejilla
-- solo se cambia en modo libre o Modo Edición, donde se ve (D-31).
function Panel:RefreshFooter()
	local f = self.frame
	if not (f and f:IsShown()) then return end
	local free = ns.Modes:IsFree()
	f.free.text:SetText(free and L.PANEL_LOCK or L.PANEL_FREE)
	local grid = ns.Grid:Settings()
	f.grid:Load(grid.enabled)
	f.grid:SetEnabled(free)
	f.magnet:Load(grid.magnet)
	if f.gridSize then
		f.gridSize:Load(grid.size)
		f.gridSize:SetEnabled(free)
	end
end

function Panel:Refresh()
	local f = self.frame
	if not (f and ns.DB.char) then return end
	local bars = SortedBars()
	if not self:Selected() then
		self.selectedID = bars[1] and bars[1].id or nil
	end
	self:RefreshList(f, bars)

	local data = self:Selected()
	f.empty:SetShown(data == nil)
	f.name:SetShown(data ~= nil)
	for _, tab in pairs(f.tabs) do tab:SetShown(data ~= nil) end
	f.shapeTab:SetShown(data ~= nil and self.tab == "shape")
	f.showTab:SetShown(data ~= nil and self.tab == "show")
	self:RefreshFooter()
	local here = data ~= nil and ns.DB:InSpec(data)
	f.lock:SetShown(data ~= nil and not here)
	f.otherSpec:SetShown(data ~= nil and not here)
	if not data then return end

	if not f.name:HasFocus() then f.name:SetText(ns.Bars:Name(data, self:ShownKey())) end
	f.name:SetEnabled(here)
	if not here then f.otherSpec:SetText(L.PANEL_OTHER_SPEC_NOTE:format(SpecNames(data))) end
	for key, tab in pairs(f.tabs) do
		tab.text:SetTextColor(1, key == self.tab and 0.82 or 1, key == self.tab and 0 or 1)
	end
	if self.tab == "shape" then self:RefreshShape(f, data) else self:RefreshShow(f, data) end
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------
Panel.tab = "shape"

function Panel:ShowTab(key)
	self.tab = key
	self:Refresh()
end

function Panel:Select(id)
	self.selectedID = id
	self:Refresh()
end

-- Copy from another character (D-67) / Copiar de otro personaje (D-67)
Panel.copyPicked = {}

function Panel:ToggleCopy()
	local c = self.frame and self.frame.copyPanel
	if not c then return end
	c:SetShown(not c:IsShown())
	self:RefreshCopy()
end

-- The bars that can be copied, in list order: the chosen character's, or
-- this character's when copying to it (0.10.1).
-- Las barras que se pueden copiar, en orden de lista: las del personaje
-- elegido, o las de este cuando se le copia a él (0.10.1).
function Panel:CopySources()
	if self.copyToOther then return SortedBars() end
	local char = self.copyFrom and ns.DB.db.chars[self.copyFrom]
	return char and SortedBars(char.bars) or {}
end

function Panel:RefreshCopy()
	local c = self.frame and self.frame.copyPanel
	if not (c and c:IsShown()) then return end
	-- The first other character until one is chosen / El primer otro personaje hasta que se elija uno
	local chars = ns.DB:OtherChars()
	local valid = false
	for _, char in ipairs(chars) do
		if char.key == self.copyFrom then valid = true end
	end
	if not valid then self.copyFrom, self.copyPicked = chars[1] and chars[1].key, {} end

	local sources = self:CopySources()
	local me = strupper(UnitName("player") or "")
	local other = self.copyFrom and strupper(self.copyFrom:match("^(.-)%-") or self.copyFrom)
	c.charName:SetText(other or L.COPY_CHOOSE)
	c.direction.text:SetText(L.COPY_DIRECTION:format(
		self.copyToOther and me or (other or "?"), self.copyToOther and (other or "?") or me))
	c.direction:SetEnabled(other ~= nil)
	c.empty:SetText(#chars == 0 and L.COPY_NONE or L.COPY_NO_BARS)
	c.empty:SetShown(#chars == 0 or #sources == 0)
	local picked = 0
	for i, row in ipairs(c.rows) do
		local data = sources[i]
		row.data = data
		if data then
			-- This character's bars by their current name / Las barras de este personaje con su nombre actual
			row.text:SetText(self.copyToOther and ns.Bars:Name(data) or StoredName(data))
			row.tag:SetText(SavedTag(data))
			row.check:SetChecked(self.copyPicked[data] and true or false)
			if self.copyPicked[data] then picked = picked + 1 end
			row:Show()
		else
			row:Hide()
		end
	end
	c.copy.text:SetText(L.COPY_TO:format(self.copyToOther and (other or "?") or me))
	c.copy:SetEnabled(picked > 0)
	c.copy:SetAlpha(picked > 0 and 1 or 0.5)
end

-- The set the panel shows: the active one, or for a bar of another spec, the
-- set of its first spec, shown locked (D-60). Viewing it never adds the bar here (D-54).
-- El conjunto que muestra el panel: el activo, o en una barra de otra spec, el
-- de su primera spec, bloqueado (D-60). Verla nunca agrega la barra aquí (D-54).
function Panel:ShownKey()
	local data = self:Selected()
	if data and not ns.DB:InSpec(data) then return ns.DB:BarSpecs(data)[1] end
end

function Panel:EditedSet(data)
	return ns.DB:SetFor(data, self:ShownKey())
end

function Panel:Show(id)
	self.frame = self.frame or Create()
	if id then self.selectedID = id end
	self.frame:Show()
	self:Refresh()
end

function Panel:Toggle()
	if self.frame and self.frame:IsShown() then
		self.frame:Hide()
	else
		self:Show()
	end
end

function Panel:RefreshIfOpen()
	if self.frame and self.frame:IsShown() then self:Refresh() end
end

---------------------------------------------------------------------------
-- Options → AddOns: a page with a button to the panel.
-- Opciones → AddOns: una página con un botón al panel.
---------------------------------------------------------------------------
local function RegisterOptions()
	if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
	local canvas = CreateFrame("Frame")
	local title = canvas:CreateFontString(nil, "OVERLAY", "OnlyBarsFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(L.PANEL_TITLE)
	local text = canvas:CreateFontString(nil, "OVERLAY", "OnlyBarsFontHighlight")
	text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	text:SetText(L.OPTIONS_TEXT)
	local open = CreateFrame("Button", nil, canvas, "UIPanelButtonTemplate")
	open:SetSize(220, 26)
	open:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -12)
	open:SetText(L.OPTIONS_OPEN)
	open:SetScript("OnClick", ns.Log.Wrap(function() Panel:Show() end))

	local category = Settings.RegisterCanvasLayoutCategory(canvas, L.PANEL_TITLE)
	Settings.RegisterAddOnCategory(category)
end
ns.Log.Call(RegisterOptions)
