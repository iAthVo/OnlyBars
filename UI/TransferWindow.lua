--[[
	OnlyBars · UI/TransferWindow.lua
	Import / Export window (D-76), two tabs.
	• Export: check bars, give a name, "Export": the text to copy appears and the
	  export is saved in the account's list.
	• Import: pick a saved export or paste a text; each bar is added as new or
	  replaces one; with or without icons and spells, with or without keys.
	Ventana Importar / Exportar (D-76), dos pestañas.
	• Exportar: marcar barras, ponerle nombre, «Exportar»: aparece el texto para
	  copiar y la exportación se guarda en la lista de la cuenta.
	• Importar: elegir una exportación guardada o pegar un texto; cada barra se
	  agrega como nueva o reemplaza a una; con o sin iconos y hechizos, con o sin teclas.
	© 2026 iAthVo_Kr
]]

local _, ns = ...
local L, W, Style = ns.L, ns.Widgets, ns.Style

local Window = { tab = "export", picked = {}, targets = {}, options = { content = true, keys = false } }
ns.TransferWindow = Window

local WIDTH, HEIGHT = 560, 640
local INNER = WIDTH - 20
local ROW = 22
local RED = "ff4040"

-- A bar's name here; one of another spec uses its first spec's name (D-60).
-- El nombre de una barra aquí; una de otra spec usa el de su primera spec (D-60).
local function BarName(data)
	if ns.DB:InSpec(data) then return ns.Bars:Name(data) end
	return ns.Bars:Name(data, ns.DB:BarSpecs(data)[1])
end

-- "Warlock" in its class colour, or "" / "Brujo" en el color de su clase, o ""
local function ClassText(class)
	if not class then return "" end
	local name = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class] or class
	local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
	return color and color.colorStr and ("|c%s%s|r"):format(color.colorStr, name) or name
end

local function Tooltip(frame, text)
	frame:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(text, 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

-- A box with a scrolling multi-line text field / Una caja con un campo de texto de varias líneas con desplazamiento
local function TextBox(parent, height)
	local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	box:SetSize(INNER, height)
	Style.Flat(box, Style.PANEL)
	local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 6, -6)
	scroll:SetPoint("BOTTOMRIGHT", -28, 6)
	local edit = CreateFrame("EditBox", nil, scroll)
	edit:SetMultiLine(true)
	edit:SetAutoFocus(false)
	edit:SetMaxLetters(0)
	edit:SetFontObject(ChatFontSmall or ChatFontNormal)
	edit:SetWidth(INNER - 40)
	edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	scroll:SetScrollChild(edit)
	box:EnableMouse(true)
	box:SetScript("OnMouseDown", function() edit:SetFocus() end)
	box.edit = edit
	return box
end

-- A plain clickable row / Una fila simple que se puede hacer clic
local function ListRow(parent, width)
	local row = Style.Button(parent, "", width)
	row:SetHeight(ROW)
	row.text:ClearAllPoints()
	row.text:SetPoint("LEFT", 10, 0)
	row.text:SetJustifyH("LEFT")
	row.text:SetWordWrap(false)
	row.tag = row:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	row.tag:SetPoint("RIGHT", -8, 0)
	row.text:SetPoint("RIGHT", row.tag, "LEFT", -6, 0)
	row.mark = row:CreateTexture(nil, "ARTWORK")
	row.mark:SetPoint("TOPLEFT", 1, -1)
	row.mark:SetPoint("BOTTOMLEFT", 1, 1)
	row.mark:SetWidth(3)
	row.mark:SetColorTexture(Style.ACCENT[1], Style.ACCENT[2], Style.ACCENT[3], 1)
	row.mark:Hide()
	return row
end

---------------------------------------------------------------------------
-- Export tab / Pestaña Exportar
---------------------------------------------------------------------------
local function CreateExport(f)
	local tab = CreateFrame("Frame", nil, f)
	tab:SetPoint("TOPLEFT", 10, -70)
	tab:SetPoint("BOTTOMRIGHT", -10, 44)

	local header = W.Header(tab, L.EXPORT_PICK, INNER)
	header:SetPoint("TOPLEFT", 0, 0)

	-- Two columns of checks, one per bar / Dos columnas de casillas, una por barra
	tab.checks = {}
	local half = INNER / 2
	for i = 1, ns.MAX_BARS do
		local check = W.Check(tab, "", half - 10, function(checked, self)
			if self.data then Window.picked[self.data.id] = checked or nil end
			Window:RefreshExport()
		end)
		local column, line = (i - 1) % 2, math.floor((i - 1) / 2)
		check:SetPoint("TOPLEFT", 4 + column * half, -24 - line * 22)
		tab.checks[i] = check
	end
	local y = -24 - (ns.MAX_BARS / 2) * 22 - 6

	local all = W.FlatButton(tab, L.EXPORT_ALL, 110, function()
		for _, data in ipairs(ns.Panel.SortedBars()) do Window.picked[data.id] = true end
		Window:RefreshExport()
	end)
	all:SetPoint("TOPLEFT", 0, y)
	local none = W.FlatButton(tab, L.EXPORT_NONE, 110, function()
		Window.picked = {}
		Window:RefreshExport()
	end)
	none:SetPoint("LEFT", all, "RIGHT", 6, 0)
	y = y - 40

	local nameLabel = tab:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	nameLabel:SetPoint("TOPLEFT", 2, y + 14)
	nameLabel:SetText(L.EXPORT_NAME)
	local name = CreateFrame("EditBox", nil, tab, "InputBoxTemplate")
	name:SetSize(300, 22)
	name:SetPoint("TOPLEFT", 6, y)
	name:SetAutoFocus(false)
	name:SetMaxLetters(32)
	name:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	name:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	tab.name = name

	tab.go = W.FlatButton(tab, L.EXPORT_GO, INNER - 320, function() Window:DoExport() end)
	tab.go:SetHeight(24)
	tab.go:SetPoint("TOPRIGHT", 0, y + 1)
	y = y - 34

	local text = TextBox(tab, 150)
	text:SetPoint("TOPLEFT", 0, y)
	-- Read only: typing puts the exported text back / Solo lectura: escribir regresa el texto exportado
	text.edit:SetScript("OnTextChanged", function(self, user)
		if user then
			self:SetText(Window.exported or "")
			self:HighlightText()
		end
	end)
	text.edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
	tab.text = text

	tab.hint = tab:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	tab.hint:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 2, -8)
	tab.hint:SetWidth(INNER - 4)
	tab.hint:SetJustifyH("LEFT")
	tab.hint:SetText(L.EXPORT_HINT)

	f.exportTab = tab
end

-- Exports the checked bars, saves them in the list and shows the text.
-- Exporta las barras marcadas, las guarda en la lista y muestra el texto.
function Window:DoExport()
	local tab = self.frame.exportTab
	local list = {}
	for _, data in ipairs(ns.Panel.SortedBars()) do
		if self.picked[data.id] then list[#list + 1] = data end
	end
	if #list == 0 then return end
	local text = ns.Transfer:Export(list)
	if not text then
		ns.U.Print(L.EXPORT_FAILED)
		return
	end
	local name = strtrim(tab.name:GetText() or "")
	if name == "" then
		name = BarName(list[1]) .. (#list > 1 and L.EXPORT_MORE:format(#list - 1) or "")
	end
	ns.Transfer:Save(name, text, #list)
	ns.U.Print(L.EXPORT_SAVED, name)
	self.exported = text
	tab.name:SetText("")
	tab.text.edit:SetText(text)
	tab.text.edit:SetFocus()
	tab.text.edit:HighlightText()
	self.selected = 1   -- the new one is at the top of the list / la nueva queda arriba en la lista
end

function Window:RefreshExport()
	local tab = self.frame.exportTab
	local bars, picked = ns.Panel.SortedBars(), 0
	for i, check in ipairs(tab.checks) do
		local data = bars[i]
		check.data = data
		if data then
			check.label:SetText(BarName(data))
			check:Load(self.picked[data.id])
			if self.picked[data.id] then picked = picked + 1 end
		end
		check:SetShown(data ~= nil)
	end
	tab.go.text:SetText(picked > 0 and L.EXPORT_GO_COUNT:format(picked) or L.EXPORT_GO)
	tab.go:SetEnabled(picked > 0)
	tab.go:SetAlpha(picked > 0 and 1 or 0.5)
end

---------------------------------------------------------------------------
-- Import tab / Pestaña Importar
---------------------------------------------------------------------------
local LIBRARY_ROWS = 6

-- Where each bar goes: new, or a bar of this character not chosen by another row.
-- A dónde va cada barra: nueva, o una barra de este personaje que no eligió otra fila.
local function ChooseTarget(owner, index)
	if not (MenuUtil and MenuUtil.CreateContextMenu) then
		-- Without Blizzard's menu: go through them on click / Sin el menú de Blizzard: pasar de una en una con clic
		local options, current = { false }, Window.targets[index]
		for _, data in ipairs(ns.Panel.SortedBars()) do options[#options + 1] = data.id end
		for i, id in ipairs(options) do
			if (id or nil) == current then
				Window.targets[index] = options[i % #options + 1] or nil
				break
			end
		end
		Window:RefreshImport()
		return
	end
	MenuUtil.CreateContextMenu(owner, function(_, root)
		root:CreateRadio(L.IMPORT_AS_NEW,
			function() return Window.targets[index] == nil end,
			function() Window.targets[index] = nil; ns.Log.Call(function() Window:RefreshImport() end) end)
		for _, data in ipairs(ns.Panel.SortedBars()) do
			local taken = false
			for other, id in pairs(Window.targets) do
				if other ~= index and id == data.id then taken = true end
			end
			if not taken then
				root:CreateRadio(L.IMPORT_REPLACE:format(BarName(data)),
					function() return Window.targets[index] == data.id end,
					function() Window.targets[index] = data.id; ns.Log.Call(function() Window:RefreshImport() end) end)
			end
		end
	end)
end

local function CreateImport(f)
	local tab = CreateFrame("Frame", nil, f)
	tab:SetPoint("TOPLEFT", 10, -70)
	tab:SetPoint("BOTTOMRIGHT", -10, 44)

	-- Saved list / Lista guardada
	local header = W.Header(tab, L.IMPORT_SAVED, INNER)
	header:SetPoint("TOPLEFT", 0, 0)
	local box = CreateFrame("Frame", nil, tab, "BackdropTemplate")
	box:SetPoint("TOPLEFT", 0, -22)
	box:SetSize(INNER, LIBRARY_ROWS * (ROW + 1) + 10)
	Style.Flat(box, Style.PANEL)
	local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 4, -5)
	scroll:SetPoint("BOTTOMRIGHT", -26, 5)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(INNER - 32, 10)
	scroll:SetScrollChild(content)
	tab.libraryContent, tab.libraryRows = content, {}
	tab.libraryEmpty = box:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	tab.libraryEmpty:SetPoint("CENTER")
	tab.libraryEmpty:SetText(L.IMPORT_SAVED_EMPTY)

	local y = -22 - box:GetHeight() - 6
	tab.rename = W.FlatButton(tab, L.IMPORT_RENAME, 120, function()
		local entry = Window.selected and ns.Transfer:Library()[Window.selected]
		if entry then StaticPopup_Show("ONLYBARS_RENAME_EXPORT", entry.name, nil, Window.selected) end
	end)
	tab.rename:SetPoint("TOPLEFT", 0, y)
	tab.delete = W.FlatButton(tab, L.IMPORT_DELETE, 120, function()
		local entry = Window.selected and ns.Transfer:Library()[Window.selected]
		if entry then StaticPopup_Show("ONLYBARS_DELETE_EXPORT", entry.name, nil, Window.selected) end
	end)
	tab.delete:SetPoint("LEFT", tab.rename, "RIGHT", 6, 0)
	y = y - 40

	-- Pasted text / Texto pegado
	local pasteLabel = tab:CreateFontString(nil, "OVERLAY", "OnlyBarsFontDisableSmall")
	pasteLabel:SetPoint("TOPLEFT", 2, y + 14)
	pasteLabel:SetText(L.IMPORT_PASTE)
	local paste = TextBox(tab, 56)
	paste:SetPoint("TOPLEFT", 0, y)
	paste.edit:SetScript("OnTextChanged", function(self, user)
		if not user then return end
		Window.selected = nil
		Window:Load(self:GetText())
	end)
	tab.paste = paste
	y = y - 62

	tab.summary = tab:CreateFontString(nil, "OVERLAY", "OnlyBarsFontHighlightSmall")
	tab.summary:SetPoint("TOPLEFT", 2, y)
	tab.summary:SetWidth(INNER - 4)
	tab.summary:SetJustifyH("LEFT")
	y = y - 20

	-- One row per bar of the text: its name and where it goes.
	-- Una fila por barra del texto: su nombre y a dónde va.
	local targetsBox = CreateFrame("Frame", nil, tab, "BackdropTemplate")
	targetsBox:SetPoint("TOPLEFT", 0, y)
	targetsBox:SetSize(INNER, 5 * (ROW + 1) + 10)
	Style.Flat(targetsBox, Style.PANEL)
	local tscroll = CreateFrame("ScrollFrame", nil, targetsBox, "UIPanelScrollFrameTemplate")
	tscroll:SetPoint("TOPLEFT", 4, -5)
	tscroll:SetPoint("BOTTOMRIGHT", -26, 5)
	local tcontent = CreateFrame("Frame", nil, tscroll)
	tcontent:SetSize(INNER - 32, 10)
	tscroll:SetScrollChild(tcontent)
	tab.targetContent, tab.targetRows = tcontent, {}
	y = y - targetsBox:GetHeight() - 8

	tab.content = W.Check(tab, L.IMPORT_CONTENT, 240, function(checked)
		Window.options.content = checked
	end)
	tab.content:SetPoint("TOPLEFT", -2, y)
	Tooltip(tab.content, L.IMPORT_CONTENT_TIP)
	tab.keys = W.Check(tab, L.IMPORT_KEYS_CHECK, 240, function(checked)
		Window.options.keys = checked
	end)
	tab.keys:SetPoint("TOPLEFT", INNER / 2, y)
	Tooltip(tab.keys, L.IMPORT_KEYS_TIP)

	tab.go = W.FlatButton(f, L.IMPORT_GO, 200, function() Window:DoImport() end)
	tab.go:SetHeight(26)
	tab.go:SetPoint("BOTTOMLEFT", 10, 12)   -- on the window's foot; Refresh shows it only here / en el pie de la ventana; Refresh solo lo muestra aquí

	f.importTab = tab
end

-- Reads a text: keeps the bars to import or says what is wrong.
-- Lee un texto: guarda las barras a importar o dice qué está mal.
function Window:Load(text)
	self.targets = {}
	text = text or ""
	if text:gsub("%s+", "") == "" then
		self.package, self.problem = nil, nil
	else
		self.package, self.problem = ns.Transfer:Read(text)
	end
	self:RefreshImport()
end

-- Saved list row: name · bars · date, and the class / Fila de la lista: nombre · barras · fecha, y la clase
local function LibraryRow(tab, i)
	local row = tab.libraryRows[i]
	if row then return row end
	row = ListRow(tab.libraryContent, INNER - 32)
	row:SetPoint("TOPLEFT", 0, -(i - 1) * (ROW + 1))
	row:SetScript("OnClick", ns.Log.Wrap(function(self)
		Window.selected = self.index
		local entry = ns.Transfer:Library()[self.index]
		tab.paste.edit:SetText(entry and entry.text or "")
		Window:Load(entry and entry.text)
	end))
	tab.libraryRows[i] = row
	return row
end

-- Row of a bar to import: name on the left, destination on the right.
-- Fila de una barra a importar: el nombre a la izquierda, el destino a la derecha.
local function TargetRow(tab, i)
	local row = tab.targetRows[i]
	if row then return row end
	row = CreateFrame("Frame", nil, tab.targetContent)
	row:SetSize(INNER - 32, ROW)
	row:SetPoint("TOPLEFT", 0, -(i - 1) * (ROW + 1))
	row.text = row:CreateFontString(nil, "OVERLAY", "OnlyBarsFontHighlightSmall")
	row.text:SetPoint("LEFT", 8, 0)
	row.text:SetJustifyH("LEFT")
	row.text:SetWordWrap(false)
	row.target = W.FlatButton(row, "", 230, function(self) ChooseTarget(self, row.index) end)
	row.target:SetHeight(ROW - 2)
	row.target:SetPoint("RIGHT", 0, 0)
	row.text:SetPoint("RIGHT", row.target, "LEFT", -6, 0)
	tab.targetRows[i] = row
	return row
end

local PROBLEMS = { format = "IMPORT_BAD_FORMAT", version = "IMPORT_BAD_VERSION", damaged = "IMPORT_DAMAGED", empty = "IMPORT_EMPTY" }

function Window:RefreshImport()
	local tab = self.frame.importTab
	local library = ns.Transfer:Library()
	if self.selected and not library[self.selected] then self.selected = nil end

	for i, entry in ipairs(library) do
		local row = LibraryRow(tab, i)
		row.index = i
		row.text:SetText(("%s  |cff999999· %s · %s|r"):format(entry.name or "?",
			L.IMPORT_BARS:format(entry.count or 0), entry.date or ""))
		row.tag:SetText(ClassText(entry.class))
		row.mark:SetShown(i == self.selected)
		row:Show()
	end
	for i = #library + 1, #tab.libraryRows do tab.libraryRows[i]:Hide() end
	tab.libraryContent:SetHeight(math.max(10, #library * (ROW + 1)))
	tab.libraryEmpty:SetShown(#library == 0)
	local chosen = self.selected ~= nil
	for _, button in ipairs({ tab.rename, tab.delete }) do
		button:SetEnabled(chosen)
		button:SetAlpha(chosen and 1 or 0.5)
	end

	local package = self.package
	if package then
		local mine = select(2, UnitClass("player"))
		local text = L.IMPORT_SUMMARY:format(#package.bars, ClassText(package.class)):gsub(" · $", "")
		if package.class and package.class ~= mine then text = text .. "  " .. L.IMPORT_OTHER_CLASS end
		tab.summary:SetText(text)
	elseif self.problem then
		tab.summary:SetText("|cff" .. RED .. L[PROBLEMS[self.problem] or "IMPORT_DAMAGED"] .. "|r")
	else
		tab.summary:SetText("|cff999999" .. L.IMPORT_NOTHING .. "|r")
	end

	local count = package and #package.bars or 0
	local replacing = 0
	for i = 1, count do
		local row = TargetRow(tab, i)
		row.index = i
		row.text:SetText(ns.Transfer.BarName(package.bars[i], i))
		local id = self.targets[i]
		local target = id and ns.DB:Bars()[id]
		if id and not target then self.targets[i], target = nil, nil end
		row.target.text:SetText(target and L.IMPORT_REPLACE:format(BarName(target)) or L.IMPORT_AS_NEW)
		if target then replacing = replacing + 1 end
		row:Show()
	end
	for i = count + 1, #tab.targetRows do tab.targetRows[i]:Hide() end
	tab.targetContent:SetHeight(math.max(10, count * (ROW + 1)))

	tab.content:Load(self.options.content)
	tab.keys:Load(self.options.keys)
	tab.go.text:SetText(count > 0 and L.IMPORT_GO_COUNT:format(count) or L.IMPORT_GO)
	tab.go:SetEnabled(count > 0)
	tab.go:SetAlpha(count > 0 and 1 or 0.5)
	self.replacing = replacing
end

-- Imports; asks first when it replaces bars / Importa; pregunta antes si reemplaza barras
function Window:DoImport()
	if not self.package then return end
	if InCombatLockdown() then
		ns.U.Print(L.COMBAT_BLOCKED)
		return
	end
	if (self.replacing or 0) > 0 then
		StaticPopup_Show("ONLYBARS_IMPORT_REPLACE", self.replacing)
	else
		self:Run()
	end
end

function Window:Run()
	local package = self.package
	if not package then return end
	local options = { content = self.options.content, keys = self.options.keys, targets = CopyTable(self.targets) }
	ns.Transfer:Import(package, options, function(result)
		self.targets = {}
		if result.last and ns.Panel then ns.Panel:Select(result.last.id) end
		self:Refresh()
	end)
end

StaticPopupDialogs["ONLYBARS_IMPORT_REPLACE"] = {
	text = L.IMPORT_CONFIRM_REPLACE,
	button1 = YES,
	button2 = NO,
	OnAccept = ns.Log.Wrap(function() Window:Run() end),
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

-- The edit box of a popup; its name changed between patches.
-- La caja de texto de una ventana emergente; su nombre cambió entre parches.
local function PopupBox(popup)
	return popup.GetEditBox and popup:GetEditBox() or popup.editBox or popup.EditBox
end

StaticPopupDialogs["ONLYBARS_RENAME_EXPORT"] = {
	text = L.IMPORT_RENAME_TEXT,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	maxLetters = 32,
	OnShow = function(self, index)
		local entry = ns.Transfer:Library()[index]
		local box = PopupBox(self)
		if box and entry then
			box:SetText(entry.name or "")
			box:HighlightText()
		end
	end,
	OnAccept = ns.Log.Wrap(function(self, index)
		local box = PopupBox(self)
		if box then ns.Transfer:Rename(index, box:GetText()) end
		Window:Refresh()
	end),
	-- Enter accepts too / Enter también acepta
	EditBoxOnEnterPressed = ns.Log.Wrap(function(box, index)
		ns.Transfer:Rename(index, box:GetText())
		box:GetParent():Hide()
		Window:Refresh()
	end),
	EditBoxOnEscapePressed = function(box) box:GetParent():Hide() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["ONLYBARS_DELETE_EXPORT"] = {
	text = L.IMPORT_DELETE_TEXT,
	button1 = YES,
	button2 = NO,
	OnAccept = ns.Log.Wrap(function(_, index)
		ns.Transfer:Delete(index)
		Window.selected = nil
		Window:Refresh()
	end),
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

---------------------------------------------------------------------------
-- Window / Ventana
---------------------------------------------------------------------------
local function Create()
	local f = Style.Window("OnlyBarsTransfer", L.TRANSFER_TITLE, WIDTH, HEIGHT)
	f.tabs = {}
	local function Tab(key, text, x)
		local tab = W.FlatButton(f, text, 130, function() Window:ShowTab(key) end)
		tab:SetPoint("TOPLEFT", 10 + x, -38)
		f.tabs[key] = tab
	end
	Tab("export", L.TRANSFER_EXPORT, 0)
	Tab("import", L.TRANSFER_IMPORT, 136)
	CreateExport(f)
	CreateImport(f)

	local close = Style.Button(f, L.REPORT_CLOSE, 100)
	close:SetPoint("BOTTOMRIGHT", -10, 12)
	close:SetScript("OnClick", function() f:Hide() end)
	f:SetScript("OnShow", ns.Log.Wrap(function() Window:Refresh() end))
	return f
end

function Window:Refresh()
	local f = self.frame
	if not (f and f:IsShown()) then return end
	f.exportTab:SetShown(self.tab == "export")
	f.importTab:SetShown(self.tab == "import")
	f.importTab.go:SetShown(self.tab == "import")
	for key, tab in pairs(f.tabs) do
		tab.text:SetTextColor(1, key == self.tab and 0.82 or 1, key == self.tab and 0 or 1)
	end
	-- Bars that no longer exist are not exported / Las barras que ya no existen no se exportan
	for id in pairs(self.picked) do
		if not ns.DB:Bars()[id] then self.picked[id] = nil end
	end
	if self.tab == "export" then self:RefreshExport() else self:RefreshImport() end
end

function Window:ShowTab(key)
	self.tab = key
	self:Refresh()
end

-- Opens it on a tab: "export" or "import" / La abre en una pestaña: "export" o "import"
function Window:Show(tab)
	self.frame = self.frame or Create()
	if tab then self.tab = tab end
	-- The bar selected in the panel starts checked / La barra elegida en el panel empieza marcada
	if self.tab == "export" and not next(self.picked) and ns.Panel.selectedID then
		self.picked[ns.Panel.selectedID] = true
	end
	self.frame:Show()
	self:Refresh()
end

-- The panel button and /ob exportar, /ob importar / El botón del panel y /ob exportar, /ob importar
function Window:Toggle(tab)
	if self.frame and self.frame:IsShown() and (not tab or tab == self.tab) then
		self.frame:Hide()
	else
		self:Show(tab)
	end
end
