--[[
	OnlyBars · UI/KeyList.lua
	Key list (D-75): every key of OnlyBars and of Blizzard's action bars, bar by
	bar in sections that open and close. Read only: keys are set with "Set keybinds".
	Repeated keys are marked: red when two OnlyBars bars can show at the same
	time, orange when the key is also on a Blizzard bar.
	Lista de teclas (D-75): cada tecla de OnlyBars y de las barras de acción de
	Blizzard, barra por barra en secciones que se abren y se cierran. Solo para
	consultar: las teclas se ponen con «Asignar teclas». Las teclas repetidas se
	marcan: rojo si dos barras de OnlyBars pueden verse al mismo tiempo, naranja
	si la tecla también está en una barra de Blizzard.
	© 2026 iAthVo_Kr
]]

local _, ns = ...
local L, U, Style = ns.L, ns.U, ns.Style

local KeyList = { expanded = {}, options = { hideEmpty = false, allSpecs = false, search = "" } }
ns.KeyList = KeyList

local WIDTH, HEIGHT = 400, 540
local ROW, HEAD, GROUP = 22, 24, 22
local RED, ORANGE = "ff4040", "ffa020"

---------------------------------------------------------------------------
-- Collecting / Reunir
-- section = { id, group = "ob" | "bz", title, rows = { { index, icon, keys,
--   clash, blizzard, others } } }
---------------------------------------------------------------------------
-- Blizzard's action bars: binding prefix, button frame prefix, how many, title.
-- Las barras de acción de Blizzard: prefijo del atajo, prefijo del botón, cuántos, título.
local function BarLabel(n)
	local pattern = HUD_EDIT_MODE_ACTION_BAR_LABEL
	return type(pattern) == "string" and pattern:find("%%d") and pattern:format(n) or L.KEYLIST_BAR:format(n)
end

local BLIZZARD = {
	{ "ACTIONBUTTON", "ActionButton", 12, function() return BarLabel(1) end },
	{ "MULTIACTIONBAR1BUTTON", "MultiBarBottomLeftButton", 12, function() return BarLabel(2) end },
	{ "MULTIACTIONBAR2BUTTON", "MultiBarBottomRightButton", 12, function() return BarLabel(3) end },
	{ "MULTIACTIONBAR3BUTTON", "MultiBarRightButton", 12, function() return BarLabel(4) end },
	{ "MULTIACTIONBAR4BUTTON", "MultiBarLeftButton", 12, function() return BarLabel(5) end },
	{ "MULTIACTIONBAR5BUTTON", "MultiBar5Button", 12, function() return BarLabel(6) end },
	{ "MULTIACTIONBAR6BUTTON", "MultiBar6Button", 12, function() return BarLabel(7) end },
	{ "MULTIACTIONBAR7BUTTON", "MultiBar7Button", 12, function() return BarLabel(8) end },
	{ "BONUSACTIONBUTTON", "PetActionButton", 10, function()
		return type(HUD_EDIT_MODE_PET_ACTION_BAR_LABEL) == "string" and HUD_EDIT_MODE_PET_ACTION_BAR_LABEL or L.KEYLIST_PET
	end },
	{ "SHAPESHIFTBUTTON", "StanceButton", 10, function()
		return type(HUD_EDIT_MODE_STANCE_BAR_LABEL) == "string" and HUD_EDIT_MODE_STANCE_BAR_LABEL or L.KEYLIST_STANCE
	end },
}

-- The icon a Blizzard button shows now, if it can be read / El ícono que muestra ahora un botón de Blizzard, si se puede leer
local function BlizzardIcon(name)
	local button = _G[name]
	local icon = button and button.icon
	if not (icon and icon.GetTexture) then return nil end
	local ok, texture = pcall(icon.GetTexture, icon)
	if not ok or U.IsSecret(texture) or (icon.IsShown and not icon:IsShown()) then return nil end
	return texture
end

local function SpecName(id)
	local _, name = GetSpecializationInfoByID(id)
	return name or tostring(id)
end

-- One section per OnlyBars bar (one per spec with "All specs").
-- Una sección por barra de OnlyBars (una por spec con «Todas las specs»).
local function OnlyBarsSections(list, allSpecs)
	local DB = ns.DB
	local current = DB:SpecID()
	for _, data in ipairs(ns.Panel.SortedBars()) do
		local entries = {}
		if data.scope == "spec" then
			if allSpecs then
				for _, id in ipairs(DB:BarSpecs(data)) do entries[#entries + 1] = { set = data.sets[id], spec = id } end
			elseif DB:InSpec(data) then
				entries[1] = { set = DB:ActiveSet(data), spec = current }
			end
		else
			entries[1] = { set = DB:SetFor(data, "global") }
		end
		for _, entry in ipairs(entries) do
			local set = entry.set
			local title = set.name or L.BAR_NAME:format(data.id)
			if allSpecs and data.scope == "spec" then title = title .. " · " .. ns.Panel.Short(SpecName(entry.spec)) end
			local section = {
				id = "ob:" .. data.id .. ":" .. tostring(entry.spec or "general"),
				group = "ob", title = title, data = data, set = set, spec = entry.spec, rows = {},
			}
			local count = U.Clamp(set.layout.buttons or 0, 0, ns.MAX_BUTTONS)
			for i = 1, count do
				local key = set.keys and set.keys[i]
				section.rows[i] = { index = i, icon = ns.Buttons.SlotIcon(set.slots and set.slots[i]), keys = { key } }
			end
			list[#list + 1] = section
		end
	end
end

-- One section per Blizzard action bar / Una sección por barra de acción de Blizzard
local function BlizzardSections(list)
	for n, bar in ipairs(BLIZZARD) do
		local command, frameName, count, title = bar[1], bar[2], bar[3], bar[4]
		local section = { id = "bz:" .. n, group = "bz", title = title(), rows = {} }
		for i = 1, count do
			local keys = GetBindingKey and { GetBindingKey(command .. i) } or {}
			section.rows[i] = { index = i, icon = BlizzardIcon(frameName .. i), keys = keys }
		end
		list[#list + 1] = section
	end
end

-- Two OnlyBars sets that can be on in the same spec / Dos conjuntos de OnlyBars que pueden estar en la misma spec
local function SameSpec(a, b)
	return a.spec == nil or b.spec == nil or a.spec == b.spec
end

-- Marks repeated keys and who else has them / Marca las teclas repetidas y quién más las tiene
local function MarkRepeated(list)
	local owners = {}
	for _, section in ipairs(list) do
		for _, row in ipairs(section.rows) do
			for _, key in ipairs(row.keys) do
				owners[key] = owners[key] or {}
				table.insert(owners[key], { section = section, row = row })
			end
		end
	end
	for key, all in pairs(owners) do
		for _, mine in ipairs(all) do
			local row, section = mine.row, mine.section
			row.others = row.others or {}
			for _, other in ipairs(all) do
				if other ~= mine then
					local o = other.section
					table.insert(row.others, L.KEY_WHERE:format(o.title, other.row.index))
					if section.group == "bz" or o.group == "bz" then
						if section.group ~= o.group then row.blizzard = true end
					elseif SameSpec(section, o) then
						if o.data == section.data
							or ns.Visibility:CanOverlap(section.data, o.data, section.set, o.set) then
							row.clash = true
						else
							row.shared = true
						end
					end
				end
			end
			row.key = row.key or key
		end
	end
end

-- Every section, marked / Todas las secciones, marcadas
function KeyList:Collect(allSpecs)
	local list = {}
	OnlyBarsSections(list, allSpecs)
	BlizzardSections(list)
	MarkRepeated(list)
	return list
end

---------------------------------------------------------------------------
-- Filtering / Filtrar
---------------------------------------------------------------------------
local function Matches(key, search)
	if search == "" then return true end
	for _, text in ipairs({ key, ns.Keybinds.Readable(key), ns.Keybinds.Abbreviate(key) }) do
		if text:lower():find(search, 1, true) then return true end
	end
	return false
end

-- The rows that pass the filters / Las filas que pasan los filtros
function KeyList.Visible(section, options)
	local search = (options.search or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	local rows = {}
	for _, row in ipairs(section.rows) do
		local show = not options.hideEmpty and search == "" or false
		for _, key in ipairs(row.keys) do
			if Matches(key, search) then show = true end
		end
		if show then rows[#rows + 1] = row end
	end
	return rows, search ~= ""
end

---------------------------------------------------------------------------
-- Window / Ventana
---------------------------------------------------------------------------
local function KeyText(row)
	if #row.keys == 0 then return "|cff808080" .. L.KEYLIST_NONE .. "|r" end
	local texts = {}
	for _, key in ipairs(row.keys) do texts[#texts + 1] = ns.Keybinds.Readable(key) end
	local text = table.concat(texts, ", ")
	if row.clash then return "|cff" .. RED .. text .. "|r" end
	if row.blizzard then return "|cff" .. ORANGE .. text .. "|r" end
	return text
end

local function RowTooltip(self)
	local row = self.row
	if not (row and row.others and #row.others > 0) then return end
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(KeyText(row))
	if row.clash then GameTooltip:AddLine(L.KEYLIST_CLASH, 1, 0.25, 0.25, true) end
	if row.blizzard then GameTooltip:AddLine(L.KEYLIST_OVER_BLIZZARD, 1, 0.63, 0.13, true) end
	if row.shared and not row.clash then GameTooltip:AddLine(L.KEYLIST_SHARED, 0.6, 0.8, 1, true) end
	GameTooltip:AddLine(L.KEYLIST_ALSO, 1, 1, 1)
	for _, text in ipairs(row.others) do GameTooltip:AddLine("  " .. text, 0.8, 0.8, 0.8) end
	GameTooltip:Show()
end

-- Pools: frames are reused on every refresh / Reservas: los marcos se reusan en cada actualización
local function Pool(create)
	return { free = {}, used = {}, create = create }
end

local function Take(pool, parent)
	local frame = table.remove(pool.free) or pool.create(parent)
	pool.used[#pool.used + 1] = frame
	frame:Show()
	return frame
end

local function ReleaseAll(pool)
	for _, frame in ipairs(pool.used) do
		frame:Hide()
		pool.free[#pool.free + 1] = frame
	end
	pool.used = {}
end

local groups = Pool(function(parent)
	local text = parent:CreateFontString(nil, "OVERLAY", "OnlyBarsFontNormal")
	text:SetJustifyH("LEFT")
	return text
end)

local heads = Pool(function(parent)
	local b = Style.Button(parent, "", 100)
	b:SetHeight(HEAD - 2)
	b.text:ClearAllPoints()
	b.text:SetPoint("LEFT", 8, 0)
	b.text:SetJustifyH("LEFT")
	b.count = b:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	b.count:SetPoint("RIGHT", -8, 0)
	b:SetScript("OnClick", ns.Log.Wrap(function(self)
		KeyList.expanded[self.id] = not KeyList.expanded[self.id]
		KeyList:Refresh()
	end))
	return b
end)

local rows = Pool(function(parent)
	local f = CreateFrame("Frame", nil, parent)
	f:SetHeight(ROW)
	f:EnableMouse(true)
	f.number = f:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	f.number:SetPoint("LEFT", 14, 0)
	f.number:SetWidth(22)
	f.number:SetJustifyH("RIGHT")
	f.icon = f:CreateTexture(nil, "ARTWORK")
	f.icon:SetSize(ROW - 4, ROW - 4)
	f.icon:SetPoint("LEFT", f.number, "RIGHT", 8, 0)
	f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	f.key = f:CreateFontString(nil, "OVERLAY", "OnlyBarsFontHighlightSmall")
	f.key:SetPoint("LEFT", f.icon, "RIGHT", 10, 0)
	f.key:SetPoint("RIGHT", -8, 0)
	f.key:SetJustifyH("LEFT")
	f.key:SetWordWrap(false)
	f:SetScript("OnEnter", RowTooltip)
	f:SetScript("OnLeave", function() GameTooltip:Hide() end)
	return f
end)

-- The "N keys" text of a section, with a mark if it has repeated keys.
-- El texto «N teclas» de una sección, con una marca si tiene teclas repetidas.
local function CountText(section)
	local count, clash, blizzard = 0, false, false
	for _, row in ipairs(section.rows) do
		if #row.keys > 0 then count = count + 1 end
		clash = clash or row.clash
		blizzard = blizzard or row.blizzard
	end
	local text = L.KEYLIST_COUNT:format(count)
	if clash then text = "|cff" .. RED .. "!|r " .. text
	elseif blizzard then text = "|cff" .. ORANGE .. "!|r " .. text end
	return text
end

local function Create()
	local f = Style.Window("OnlyBarsKeyList", L.KEYLIST_TITLE, WIDTH, HEIGHT)

	local search = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	search:SetSize(WIDTH - 40, 22)
	search:SetPoint("TOPLEFT", 18, -38)
	search:SetAutoFocus(false)
	search.hint = search:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	search.hint:SetPoint("LEFT", 2, 0)
	search.hint:SetText(L.KEYLIST_SEARCH)
	search:SetScript("OnTextChanged", ns.Log.Wrap(function(self)
		local text = self:GetText() or ""
		self.hint:SetShown(text == "")
		KeyList.options.search = text
		KeyList:Refresh()
	end))
	search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	f.search = search

	f.hideEmpty = ns.Widgets.Check(f, L.KEYLIST_HIDE_EMPTY, 200, function(checked)
		KeyList.options.hideEmpty = checked
		KeyList:Refresh()
	end)
	f.hideEmpty:SetPoint("TOPLEFT", 12, -66)
	f.allSpecs = ns.Widgets.Check(f, L.KEYLIST_ALL_SPECS, 150, function(checked)
		KeyList.options.allSpecs = checked
		KeyList:Refresh()
	end)
	f.allSpecs:SetPoint("LEFT", f.hideEmpty, "RIGHT", 16, 0)

	local box = CreateFrame("Frame", nil, f, "BackdropTemplate")
	box:SetPoint("TOPLEFT", 10, -94)
	box:SetPoint("BOTTOMRIGHT", -10, 44)
	Style.Flat(box, Style.PANEL)

	local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 6, -6)
	scroll:SetPoint("BOTTOMRIGHT", -28, 6)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(WIDTH - 20 - 34, 10)
	scroll:SetScrollChild(content)
	f.content = content

	f.empty = content:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	f.empty:SetPoint("TOP", 0, -20)
	f.empty:SetText(L.KEYLIST_EMPTY)

	local legend = f:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	legend:SetPoint("BOTTOMLEFT", 12, 18)
	legend:SetText(L.KEYLIST_LEGEND:format(RED, ORANGE))

	local close = Style.Button(f, L.REPORT_CLOSE, 100)
	close:SetPoint("BOTTOMRIGHT", -10, 12)
	close:SetScript("OnClick", function() f:Hide() end)

	f:SetScript("OnShow", function() KeyList:Refresh() end)
	return f
end

-- Lays the list out again / Vuelve a acomodar la lista
function KeyList:Refresh()
	local f = self.frame
	if not (f and f:IsShown()) then return end
	f.hideEmpty:Load(self.options.hideEmpty)
	f.allSpecs:Load(self.options.allSpecs)

	local content = f.content
	local width = content:GetWidth()
	ReleaseAll(groups)
	ReleaseAll(heads)
	ReleaseAll(rows)

	local y, shown, lastGroup = 0, 0, nil
	for _, section in ipairs(self:Collect(self.options.allSpecs)) do
		local visible, searching = KeyList.Visible(section, self.options)
		local filtering = searching or self.options.hideEmpty
		if #visible > 0 or not filtering then
			if section.group ~= lastGroup then
				lastGroup = section.group
				local g = Take(groups, content)
				g:ClearAllPoints()
				g:SetPoint("TOPLEFT", 4, -y - 4)
				g:SetText(section.group == "ob" and L.KEYLIST_ONLYBARS or L.KEYLIST_BLIZZARD)
				y = y + GROUP
			end
			local open = searching or self.expanded[section.id]
			local h = Take(heads, content)
			h.id = section.id
			h:ClearAllPoints()
			h:SetPoint("TOPLEFT", 0, -y)
			h:SetWidth(width)
			h.text:SetText((open and "–  " or "+  ") .. section.title)
			h.count:SetText(CountText(section))
			y = y + HEAD
			if open then
				for _, row in ipairs(visible) do
					local r = Take(rows, content)
					r.row = row
					r:ClearAllPoints()
					r:SetPoint("TOPLEFT", 0, -y)
					r:SetWidth(width)
					r.number:SetText(row.index)
					r.icon:SetTexture(row.icon or 0)
					r.icon:SetShown(row.icon ~= nil)
					r.key:SetText(KeyText(row))
					y = y + ROW
				end
			end
			shown = shown + 1
		end
	end
	f.empty:SetShown(shown == 0)
	content:SetHeight(math.max(y, 10))
end

-- Refreshes on the next frame, once, if shown / Actualiza en el siguiente cuadro, una vez, si se ve
function KeyList:RefreshIfShown()
	if not (self.frame and self.frame:IsShown()) or self.pending then return end
	self.pending = true
	C_Timer.After(0, function()
		self.pending = nil
		ns.Log.Wrap(function() self:Refresh() end)()
	end)
end

for _, event in ipairs({ "UPDATE_BINDINGS", "ACTIONBAR_SLOT_CHANGED", "PLAYER_SPECIALIZATION_CHANGED" }) do
	ns:On(event, function() KeyList:RefreshIfShown() end)
end

function KeyList:Show()
	self.frame = self.frame or Create()
	self.frame:Show()
end

-- /ob listateclas and the panel button open or close it / /ob listateclas y el botón del panel la abren o la cierran
function KeyList:Toggle()
	if self.frame and self.frame:IsShown() then
		self.frame:Hide()
	else
		self:Show()
	end
end
